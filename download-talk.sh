#!/usr/bin/env bash

set -euo pipefail
umask 077

usage() {
    cat <<'EOF'
Download and restore Codex sessions into ~/.codex-imported.

Usage:
  ./download-talk.sh HTTPS_ARCHIVE_URL
  ./download-talk.sh --ssh USER@HOST CONTAINER

The HTTPS source must be a private tar.gz containing sessions/ and optionally
archived_sessions/, session_index.jsonl, and attachments/. Use a signed URL or
credentials configured in ~/.netrc. The SSH mode reads directly from Codex's
home in a running Docker container on the source host.

Set CODEX_IMPORT_HOME to use a different destination for an additional import.
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --ssh)
        if [[ $# -ne 3 || ! "$3" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
            usage >&2
            exit 2
        fi
        ;;
    https://*)
        if [[ $# -ne 1 ]]; then
            usage >&2
            exit 2
        fi
        ;;
    *) usage >&2; exit 2 ;;
esac

destination="${CODEX_IMPORT_HOME:-$HOME/.codex-imported}"
if [[ -e "$destination" || -L "$destination" ]]; then
    printf 'Import destination already exists: %s\n' "$destination" >&2
    exit 1
fi

mkdir -p -- "$(dirname -- "$destination")"
staging="$(mktemp -d -- "$destination.download.XXXXXX")"
trap 'rm -rf -- "$staging"' EXIT
archive="$staging/talk.tar.gz"

if [[ "$1" == --ssh ]]; then
    ssh -- "$2" docker exec -i "$3" sh -s > "$archive" <<'REMOTE'
set -eu
cd "${CODEX_HOME:-$HOME/.codex}"
set -- sessions
for path in archived_sessions session_index.jsonl attachments; do
    if [ -e "$path" ]; then
        set -- "$@" "$path"
    fi
done
exec tar -czf - "$@"
REMOTE
else
    curl --fail --silent --show-error --location --netrc-optional \
        --proto '=https' --proto-redir '=https' --url "$1" -o "$archive"
fi

if ! LC_ALL=C tar -tvzf "$archive" | awk '/^[-d]/ { next } { invalid = 1 } END { exit invalid }'; then
    printf 'The archive must contain only regular files and directories.\n' >&2
    exit 1
fi

history="$staging/history"
mkdir -- "$history"
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$history"

shopt -s dotglob nullglob
for path in "$history"/*; do
    case "${path##*/}" in
        sessions|archived_sessions|attachments) test -d "$path" ;;
        session_index.jsonl) test -f "$path" ;;
        *) printf 'Unexpected archive entry: %s\n' "${path##*/}" >&2; exit 1 ;;
    esac
done

if [[ ! -d "$history/sessions" ]] || [[ -z $(find "$history/sessions" -type f \
    \( -name 'rollout-*.jsonl' -o -name 'rollout-*.jsonl.zst' \) -print -quit) ]]; then
    printf 'The archive contains no Codex session files.\n' >&2
    exit 1
fi

mv -nT -- "$history" "$destination"
if [[ -d "$history" ]]; then
    printf 'Import destination already exists: %s\n' "$destination" >&2
    exit 1
fi

printf 'Codex history restored to %s\n' "$destination"
printf 'If sign-in is needed, run:\n  CODEX_HOME=%q codex login\n' "$destination"
printf 'From your project directory, run:\n  CODEX_HOME=%q codex -c '\''tui.resume_cwd="current"'\'' resume --all --include-non-interactive\n' "$destination"
