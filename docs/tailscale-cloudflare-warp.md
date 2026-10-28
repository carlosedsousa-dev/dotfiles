# Tailscale + Cloudflare WARP: diagnóstico e configuração

> Registro da convivência entre o Tailscale e o cliente Cloudflare WARP
> (Zero Trust) no host `opensuse-maker-pc2`.

- **Atualizado:** 27/10/2026
- **Host:** `opensuse-maker-pc2` (openSUSE, NetworkManager)
- **Interface física:** `br0` (`10.113.90.100/24`, rede do IFTO)
- **Interface Tailscale:** `tailscale0` (`100.112.103.80`)
- **Interface WARP:** `CloudflareWARP` (`100.96.0.1`)
- **Tailscale:** 1.104.1
- **Cloudflare WARP:** `WarpWithDnsOverHttps`, Always On, split tunnel em
  **Exclude mode**

---

## 1. Resumo da solução atual

A configuração está dividida em três partes:

1. O tráfego marcado pelo `tailscaled` (`fwmark 0x80000`) é encaminhado para
   a tabela do WARP antes das regras padrão do Tailscale.
2. O WARP encaminha o domínio do tailnet para o MagicDNS local do Tailscale.
3. O WARP encaminha o domínio interno do IFTO para os DNS internos da rede.

No Cloudflare Zero Trust, o perfil do dispositivo contém estes Local Domain
Fallbacks:

```text
tail49460f.ts.net -> 100.100.100.100
ifto.local        -> 10.11.0.64, 10.13.0.1
```

Os demais domínios públicos continuam sendo resolvidos pelo Cloudflare
Gateway/DoH.

---

## 2. Problema original

Com o WARP conectado em modo de túnel total, o `tailscaled` ficava sem
conseguir completar o login ou atualizar o mapa da rede. Os sintomas eram:

```text
Status: "Needs login: "
tailscale status: Logged out.
tailscale up: context canceled
```

Em outro momento, já autenticado, o problema aparecia como:

```text
Tailscale hasn't received a network map from the coordination server
```

Também havia falha na resolução de nomes do tailnet:

```text
ping opensuse-maker-pc2
Falha temporário na resolução de nome
```

---

## 3. Diagnóstico de roteamento

### 3.1 Regras relevantes

O Tailscale marca o tráfego originado pelo daemon com `0x80000`. O WARP
instala uma regra que envia tráfego não marcado para a tabela `65743`:

```text
5204: not from all fwmark 0x100cf lookup 65743
5205: from all fwmark 0x80000/0xff0000 lookup 65743
5210: from all fwmark 0x80000/0xff0000 lookup main
5230: from all fwmark 0x80000/0xff0000 lookup default
5250: from all fwmark 0x80000/0xff0000 unreachable
5270: from all lookup 52
```

A regra `5205` é necessária porque tem prioridade maior que as regras padrão
do Tailscale (`5210`, `5230` e `5250`). Assim, o tráfego marcado do
`tailscaled` usa a interface `CloudflareWARP`, em vez de escapar para `br0`,
onde o firewall do WARP pode descartar as respostas.

### 3.2 Dispatcher do NetworkManager

O arquivo instalado é:

```text
/etc/NetworkManager/dispatcher.d/90-tailscale-warp-route
```

Conteúdo:

```sh
#!/bin/sh

# Mantém o tráfego marcado do tailscaled dentro do túnel do Cloudflare WARP.
IP=/usr/bin/ip
[ -x "$IP" ] || exit 0

case "$2" in
    up|dhcp4-change|dhcp6-change|reapply|connectivity-change) ;;
    *) exit 0 ;;
esac

# Descobre a tabela usada pelo WARP; 65743 é o valor usual.
TABLE=$("$IP" rule show |
    sed -n 's/.*not from all fwmark 0x100cf lookup \([0-9][0-9]*\).*/\1/p' |
    head -n1)
[ -n "$TABLE" ] || TABLE=65743

"$IP" rule del fwmark 0x80000/0xff0000 lookup "$TABLE" priority 5205 2>/dev/null
"$IP" rule add fwmark 0x80000/0xff0000 lookup "$TABLE" priority 5205 2>/dev/null

exit 0
```

Aplicar manualmente após instalar ou depois de uma alteração de rede:

```sh
sudo /etc/NetworkManager/dispatcher.d/90-tailscale-warp-route \
    CloudflareWARP up
```

Validar:

```sh
ip rule show | grep 5205
ip route get 192.200.0.113 mark 0x80000
```

O segundo comando deve apontar para `CloudflareWARP` e para a tabela `65743`.

---

## 4. DNS: Local Domain Fallback no WARP

### 4.1 Por que o DNS falhava

Quando o WARP era o dono do `/etc/resolv.conf`, o arquivo continha:

```text
nameserver 127.0.2.2
nameserver 127.0.2.3
search tail49460f.ts.net ifto.local
```

O proxy DNS do WARP não conhecia o tailnet e devolvia `NXDOMAIN` para:

```text
opensuse-maker-pc2.tail49460f.ts.net
```

O MagicDNS local, por outro lado, respondia corretamente:

```text
dig @100.100.100.100 opensuse-maker-pc2.tail49460f.ts.net
100.112.103.80
```

Além disso, o domínio `ifto.local` aparecia no search domain, mas não era
resolvido pelo upstream do WARP. Consultas que falhavam podiam levar dezenas
de segundos, atrasando inclusive o long-poll do `tailscaled`.

### 4.2 Configuração no painel Cloudflare

No Cloudflare Zero Trust:

```text
Zero Trust
  > Team & Resources
  > Devices
  > Device profiles
  > General profiles
  > Configure
  > Local Domain Fallback
  > Manage
```

Foram adicionadas estas entradas:

| Domínio | DNS Servers | Descrição |
|---|---|---|
| `tail49460f.ts.net` | `100.100.100.100` | MagicDNS Tailscale |
| `ifto.local` | `10.11.0.64`, `10.13.0.1` | DNS interno IFTO |

O domínio informado deve ser o sufixo, sem `*.`. O cliente aplica a regra a
nomes abaixo desse sufixo.

O fallback de `ifto.local` é alcançável porque `10.0.0.0/8` está excluído do
túnel WARP. Os DNS internos foram testados diretamente:

```text
dig @10.13.0.1 ifto.local
status: NOERROR
Query time: aproximadamente 1–8 ms
```

### 4.3 Resultado confirmado

A política recebida pelo cliente ficou:

```text
{'suffix': 'tail49460f.ts.net',
 'description': 'MagicDNS Tailscale',
 'dns_server': ['100.100.100.100']}

{'suffix': 'ifto.local',
 'description': 'DNS interno IFTO',
 'dns_server': ['10.11.0.64', '10.13.0.1']}
```

O WARP passou a resolver o domínio interno sem o timeout anterior:

```text
dig @127.0.2.2 ifto.local
status: NOERROR
Query time: aproximadamente 58 ms
```

Um host inexistente passou a retornar rapidamente `NXDOMAIN`, em vez de
causar uma espera de dezenas de segundos:

```text
getent hosts nome-inexistente-xyz-abc
tempo total: aproximadamente 0,1 s
```

`NXDOMAIN` para um host que realmente não existe é o resultado esperado; o
importante é a resposta rápida.

### 4.4 Verificação de nomes do tailnet

```sh
dig @127.0.2.2 opensuse-maker-pc2.tail49460f.ts.net
getent hosts opensuse-maker-pc2
getent hosts opensuse-x543mar
getent hosts pc-lab2
getent hosts poco-x6-pro-5g
```

O WARP encaminha `*.tail49460f.ts.net` ao `100.100.100.100`, e os nomes do
tailnet são resolvidos pelo MagicDNS.

---

## 5. Validação do novo dispositivo

O dispositivo conectado durante o diagnóstico foi:

```text
poco-x6-pro-5g
100.98.179.86
```

Validação:

```text
tailscale ping poco-x6-pro-5g
pong from poco-x6-pro-5g (100.98.179.86)

ping 100.98.179.86
3 pacotes enviados, 3 recebidos, 0% de perda
```

O primeiro teste usou o endereço local `10.113.90.106:50584`, indicando uma
conexão direta pela rede local naquele momento.

---

## 6. Estado atual do UDP e DERP

O DNS e o control plane estão funcionando, mas o `netcheck` ainda informa:

```text
UDP: false
IPv4: no addr found
Nearest DERP: unknown
```

O DERP por TCP conecta normalmente:

```text
derp-11 connected; connGen=1
```

Os testes mostraram que alguns servidores STUN funcionam:

```text
stun.cloudflare.com:3478 -> funciona
stun.l.google.com:3478   -> funciona
```

Mas os STUNs do Tailscale/DERP testados não responderam quando roteados pela
tabela do WARP:

```text
derp11.tailscale.com:3478 -> timeout
```

Portanto, `UDP: false` é um problema separado do DNS. O funcionamento atual
é:

- DNS MagicDNS: funcionando;
- control plane: funcionando após recuperação do `tailscaled`;
- DERP por TCP: funcionando;
- alguns peers locais: podem conectar diretamente;
- descoberta de endpoint UDP público: ainda não confirmada;
- peers remotos: podem usar DERP e apresentar maior latência.

Não adicionar rotas permanentes para IPs individuais do DERP sem nova
validação: o WARP também instala um firewall que pode descartar respostas que
entrem pela interface física `br0`.

---

## 7. Alerta `dns-fight`

O Tailscale pode continuar exibindo:

```text
System DNS config not ideal.
/etc/resolv.conf overwritten.
```

Esse alerta indica que o `/etc/resolv.conf` é gerenciado diretamente por um
arquivo, e não por um gerenciador reconhecido pelo Tailscale, como
`systemd-resolved`. Ele não significa que o DNS esteja falhando.

O estado funcional atual é:

```text
nameserver 100.100.100.100
nameserver fd7a:115c:a1e0::53
search tail49460f.ts.net ifto.local
```

Se o WARP voltar a tomar posse do arquivo, reaplicar o Tailscale pode restaurar
o estado:

```sh
sudo tailscale set --accept-dns=true
sudo systemctl restart tailscaled
```

Depois, validar:

```sh
getent hosts poco-x6-pro-5g
```

---

## 8. Checklist de diagnóstico

```sh
# Estado geral
tailscale status
sudo tailscale netcheck

# Rota do tráfego marcado pelo tailscaled
ip rule show | grep 5205
ip route get 192.200.0.113 mark 0x80000

# DNS do tailnet via WARP
dig @127.0.2.2 opensuse-maker-pc2.tail49460f.ts.net

# DNS interno via WARP
dig @127.0.2.2 ifto.local

# Resolução pela configuração do sistema
getent hosts opensuse-maker-pc2
getent hosts poco-x6-pro-5g

# Arquivo atualmente usado pelo sistema
grep -vE '^#|^$' /etc/resolv.conf
```

---

## 9. Alternativa

Se o WARP não for obrigatório, desconectá-lo elimina a disputa de roteamento:

```sh
sudo warp-cli disconnect
```

Como a política atual usa `Always On: true`, o cliente pode reconectar
automaticamente. Para manter WARP e Tailscale juntos, a combinação do
dispatcher de rota com os dois Local Domain Fallbacks é a configuração
recomendada neste host.
