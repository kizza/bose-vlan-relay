#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/mock"
cp "$repo_root/bin/discover" "$tmpdir/bin/discover"
cat > "$tmpdir/mock/avahi-browse" <<'EOF'
#!/usr/bin/env bash
[[ $* == '-rt _googlecast._tcp' ]] || exit 1
echo 'Bose Smart Soundbar 900: md=Bose Smart Soundbar 900'
EOF
chmod +x "$tmpdir/mock/avahi-browse"

# A repeat discovery saves the Bose announcement beside the command.
PATH="$tmpdir/mock:$PATH" "$tmpdir/bin/discover" >/dev/null

[[ $(cat "$tmpdir/cast.original.txt") == 'Bose Smart Soundbar 900: md=Bose Smart Soundbar 900' ]] || {
  echo 'Expected Cast discovery to be saved' >&2
  exit 1
}

echo 'Discovery check passed.'
