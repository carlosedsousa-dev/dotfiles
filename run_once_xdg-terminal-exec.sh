#!/bin/bash
# Wrapper para xdg-terminal-exec — abre kitty no diretório informado.
# Compatível com o protocolo xdg-terminal-exec v0.3.

DIR="${1:-.}"
shift 2>/dev/null

# Resolve caminho absoluto
if [ -d "$DIR" ]; then
    DIR="$(cd "$DIR" && pwd)"
fi

exec kitty --directory "$DIR" "$@"
