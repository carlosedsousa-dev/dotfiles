#!/bin/bash
# Wrapper para xdg-terminal-exec — abre kitty no diretório informado.
# Compatível com o protocolo xdg-terminal-exec v0.3.
# Nemo chama: xdg-terminal-exec -- /path/to/dir

# Pula -- se presente
[ "$1" = "--" ] && shift

DIR="${1:-.}"
shift 2>/dev/null

[ -d "$DIR" ] && DIR="$(cd "$DIR" && pwd)"

exec kitty --directory "$DIR" "$@"
