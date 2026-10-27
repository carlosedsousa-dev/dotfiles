# Tailscale + Cloudflare WARP: diagnóstico e correção

> Registro do problema em que o `tailscaled` ficava permanentemente em
> `Needs login` (sem gerar URL de autenticação) por conflito de roteamento com
> o cliente Cloudflare WARP (Zero Trust) em modo túnel total.

- **Data:** 19/10/2026
- **Host:** `opensuse-maker-pc2` (openSUSE, NetworkManager)
- **Tailscale:** 1.104.1 (`tailscaled` ativo, estado `Needs login`)
- **Cloudflare WARP:** conectado, política de rede `WarpWithDnsOverHttps`,
  `Always On: true`, modo **exclude** (túnel total)
- **Saída física:** `br0` (`10.113.90.100/24`, rede do IFTO)

---

## 1. Sintoma

```text
$ systemctl status tailscaled
Active: active (running)
Status: "Needs login: "

$ tailscale status
Logged out.
```

O comando `tailscale up` ficava pendurado por dezenas de segundos e **não
imprimia a URL de autenticação**:

```text
$ sudo tailscale up
context canceled        # somente ao ser interrompido
```

O log do `tailscaled` mostrava a tentativa de buscar a chave de controle:

```text
control: doLogin(regen=true, hasUrl=false)
health(warnable=login-state): error: You are logged out. The last login error
  was: fetch control key: Get "https://controlplane.tailscale.com/key?v=148":
  context canceled
```

---

## 2. Diagnóstico

### 2.1 O Tailscale não alcança o control plane

Com o `tailscale up` rodando, os sockets do `tailscaled` ficavam parados em
`SYN-SENT`:

```text
$ sudo ss -tanp | grep tailscaled
SYN-SENT  10.113.90.100:59830  176.58.92.254:443   users:(("tailscaled",...))
SYN-SENT  10.113.90.100:37254  192.200.0.106:443   users:(("tailscaled",...))
SYN-SENT  10.113.90.100:39092  192.200.0.111:443   users:(("tailscaled",...))
...
```

Ou seja: os pacotes saíam, mas **nenhuma resposta voltava**.

O `netcheck` confirmava o isolamento:

```text
$ sudo tailscale netcheck
	* UDP: false
	* IPv4: (no addr found)
	* IPv6: no, but OS has support
	* Nearest DERP: unknown (no response to latency probes)
```

### 2.2 Quem manda no roteamento é o WARP

```text
$ ip rule
0:      from all lookup local
5210:   from all fwmark 0x80000/0xff0000 lookup main
5230:   from all fwmark 0x80000/0xff0000 lookup default
5250:   from all fwmark 0x80000/0xff0000 unreachable
5270:   from all lookup 52
32765:  not from all fwmark 0x100cf lookup 65743
32766:  from all lookup main
32767:  from all lookup default
```

- As regras `5210/5230/5250/5270` são instaladas pelo **próprio Tailscale** e
  valem para o `fwmark 0x80000` (constante `LinuxBypassMark` no código do
  Tailscale: “packet originated by tailscaled itself, and must not be routed
  over the Tailscale network”).
- A regra `32765` e a tabela `65743` são do **Cloudflare WARP**: todo tráfego
  sem marca vai para a interface `CloudflareWARP`.

Resultado da consulta de rota:

```text
$ ip route get 192.200.0.113
192.200.0.113 dev CloudflareWARP table 65743 src 100.96.0.1

$ ip route get 192.200.0.113 mark 0x80000
192.200.0.113 via 10.113.90.1 dev br0 src 10.113.90.100
```

O tráfego **marcado pelo Tailscale escapa do túnel do WARP** e sai pela
interface física `br0`.

### 2.3 O firewall do WARP descarta as respostas na interface física

O WARP instala uma tabela nftables com `policy drop` na entrada:

```text
table inet cloudflare-warp {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		iif "CloudflareWARP" accept
		...
		ip saddr 10.0.0.0/8 accept
		ip saddr 100.64.0.0/10 accept
		ip saddr 172.16.0.0/12 accept
		ip saddr 192.168.0.0/16 accept
		...
	}
	chain output {
		type filter hook output priority filter; policy drop;
		oif "lo" accept
		oif "CloudflareWARP" goto tun
		...
	}
	chain tun {
		ip saddr 100.96.0.1 accept
		...
		ip protocol tcp reject with tcp reset
		reject
	}
}
```

Consequências:

1. Respostas TCP vindas de IP público pela `br0` não casam com nenhum `accept`
   da chain `input` → **DROP**.
2. Se um socket tentar sair pela `CloudflareWARP` com source address diferente
   de `100.96.0.1`, a chain `tun` rejeita com RST.

### 2.4 Prova experimental

Teste com um socket Python controlando o `SO_MARK`:

```text
mark=0x80000 (marca do Tailscale) -> FALHOU em 8007ms: timed out
mark=0x0     (tráfego comum)      -> Conectado em 203ms  local=('100.96.0.1', 55402)
```

E, com uma regra temporária desviando o tráfego marcado para a tabela do WARP:

```text
$ sudo ip rule add fwmark 0x80000/0xff0000 lookup 65743 priority 5205
$ ip route get 192.200.0.113 mark 0x80000
192.200.0.113 dev CloudflareWARP table 65743 src 100.96.0.1 mark 0x80000

mark=0x80000 -> Conectado em 205ms  local=('100.96.0.1', 55412)
```

Com essa regra, o `tailscale up` finalmente imprimiu a URL de login.

---

## 3. Causa raiz

```text
tailscaled (fwmark 0x80000)
        │
        ├─ ip rule 5210/5230/5250 → tabela main → br0 (uplink físico)
        │        └─ firewall do WARP (input policy drop) descarta as respostas
        │
        └─ ✗ nunca chega ao controlplane.tailscale.com
```

O Tailscale marca o próprio tráfego para evitar loop de roteamento, mas essa
marca também o tira do túnel do WARP. Como o WARP está em modo túnel total e
descarta respostas que chegam pela interface física, o `tailscaled` nunca
completa o handshake de controle — logo, nunca há URL de login.

---

## 4. Correção

A correção tem duas partes independentes: **rota** (para o Tailscale
funcionar) e **DNS** (para os dois resolvers conviverem).

### 4.1 Rota: manter o tráfego marcado dentro do WARP

Criar `/etc/NetworkManager/dispatcher.d/90-tailscale-warp-route` (root, `755`):

```sh
#!/bin/sh
# Mantem o trafego marcado do tailscaled (fwmark 0x80000) dentro do tunel do
# Cloudflare WARP. Sem isso, o tailscaled sai pela interface fisica (br0), onde
# o firewall do WARP (nftables, chain input policy drop) descarta as respostas
# e o login/controle do Tailscale nunca completa.

IP=/usr/bin/ip
[ -x "$IP" ] || exit 0

case "$2" in
	up|dhcp4-change|dhcp6-change|reapply|connectivity-change) ;;
	*) exit 0 ;;
esac

# Descobre a tabela de roteamento usada pelo WARP (normalmente 65743).
TABLE=$("$IP" rule show | sed -n 's/.*not from all fwmark 0x100cf lookup \([0-9][0-9]*\).*/\1/p' | head -n1)
[ -n "$TABLE" ] || TABLE=65743

"$IP" rule del fwmark 0x80000/0xff0000 lookup "$TABLE" priority 5205 2>/dev/null
"$IP" rule add fwmark 0x80000/0xff0000 lookup "$TABLE" priority 5205 2>/dev/null

exit 0
```

Instalar e aplicar sem esperar o próximo evento de rede:

```sh
sudo install -o root -g root -m 755 \
    /caminho/para/90-tailscale-warp-route \
    /etc/NetworkManager/dispatcher.d/90-tailscale-warp-route

sudo /etc/NetworkManager/dispatcher.d/90-tailscale-warp-route CloudflareWARP up
```

A regra fica antes das regras do Tailscale (`5205 < 5210`) e é recriada a cada
evento de rede, inclusive quando o WARP reconecta. Se o WARP estiver
desconectado, a tabela não existe e a consulta simplesmente segue para a
tabela `main` (comportamento original).

### 4.2 DNS: MagicDNS + WARP como upstream

```sh
sudo tailscale set --accept-dns=true
```

Com isso, depois do login:

```text
aplicações → 100.100.100.100 (MagicDNS do Tailscale)
                ├── nomes do tailnet (*.ts.net) → resolvidos localmente
                └── demais nomes → 127.0.2.2 / 127.0.2.3 (WARP DoH)
```

Por que não há conflito:

- `100.100.100.100` pertence a `100.64.0.0/10`, faixa **não capturada** pela
  tabela do WARP (que cobre `100.0.0.0/10` e `100.128.0.0/9`) → a consulta cai
  na tabela `main` e vai para `tailscale0`.
- O Tailscale guarda os resolvers originais do sistema (os stubs do WARP) como
  upstream, então a filtragem do Cloudflare Gateway continua valendo.
- Enquanto não há login, o Tailscale não altera o `/etc/resolv.conf`.

---

## 5. Validação

```sh
# 1. A regra existe e aponta para a tabela do WARP
ip rule | grep 5205
ip route get 192.200.0.113 mark 0x80000

# 2. O control plane responde
sudo tailscale netcheck          # UDP/IPv4/DERP devem aparecer
sudo tailscale status            # deve sair de "Logged out"

# 3. DNS dos dois mundos
getent hosts www.google.com      # resolve via WARP
getent hosts <host>.<tailnet>.ts.net   # resolve via MagicDNS

# 4. Resolv.conf após login
cat /etc/resolv.conf             # nameserver 100.100.100.100 + search do WARP
```

---

## 6. Manutenção e limitações

- **WARP reescrevendo o `resolv.conf`:** se o WARP sobrescrever o arquivo
  (ele o gerencia), o MagicDNS sai até reaplicar:

  ```sh
  sudo tailscale set --accept-dns=true
  ```

  Ou reiniciar o serviço: `sudo systemctl restart tailscaled`.
- **Tabela do WARP:** a regra descobre o número dinamicamente; se o WARP mudar
  a estratégia de tabelas, o dispatcher se adapta na próxima execução.
- **Rede sem NetworkManager:** o dispatcher não é executado. Nesse caso, a
  regra precisa ser adicionada por outro mecanismo (systemd unit, networkd
  dispatcher etc.).
- **IPv6:** o mesmo raciocínio vale para `ip -6 rule` se o WARP estiver
  capturando IPv6. Nesta máquina o problema observado foi IPv4; o dispatcher
  cobre apenas IPv4.

---

## 7. Alternativa

Se o WARP **não** for obrigatório, a solução mais simples é desconectá-lo
enquanto o Tailscale é usado:

```sh
warp-cli disconnect
```

Como o cliente está sob política gerenciada (`Always On: true`), ele pode
reconectar sozinho — por isso a correção de rota acima é o caminho estável para
manter os dois ativos.
