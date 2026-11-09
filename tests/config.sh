#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
relay="$repo_root/bin/relay"

export RELAY_IP=192.168.0.50 BOSE_IP=192.168.0.100
export CAST_ALLOW=192.168.4.10/32 API_ALLOW=192.168.4.10/32
export CAST_NAME='Bose 900 Relay' CAST_ID=01234567-89ab-cdef-0123-456789abcdef
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
export CAST_TXT_FILE="$tmpdir/cast.txt"
cat > "$CAST_TXT_FILE" <<'EOF'
rs=
bs=EXAMPLE_BS
ca=198660
md=Bose Smart Soundbar 900
ve=05
ic=/setup/icon.png
cd=EXAMPLE_CD
id=physical-bose-id
fn=Awesome bar
EOF

# A complete configuration retains the Bose metadata but replaces its identity.
advertisement="$("$relay" --check)"
[[ $advertisement == *'Advertised TXT: ve=05'* &&
   $advertisement == *'Advertised TXT: ic=/setup/icon.png'* &&
   $advertisement == *'Advertised TXT: rs='* &&
   $advertisement == *'Advertised TXT: bs=EXAMPLE_BS'* &&
   $advertisement == *'Advertised TXT: cd=EXAMPLE_CD'* &&
   $advertisement == *'Advertised TXT: id=01234567-89ab-cdef-0123-456789abcdef'* &&
   $advertisement == *'Advertised TXT: fn=Bose 900 Relay'* &&
   $advertisement != *'physical-bose-id'* &&
   $advertisement != *'fn=Awesome bar'* ]] || {
  echo 'Expected copied metadata and a substituted receiver ID' >&2
  exit 1
}

# A missing setting is a configuration error, not a transient service failure.
env -u BOSE_IP "$relay" --check >/dev/null 2>&1 && {
  echo 'Expected missing BOSE_IP to fail' >&2
  exit 1
}

# An invalid listener address is rejected before starting the service.
RELAY_IP=192.168.0.999 "$relay" --check >/dev/null 2>&1 && {
  echo 'Expected invalid RELAY_IP to fail' >&2
  exit 1
}

# A placeholder identity cannot accidentally be advertised.
CAST_ID=REPLACE_WITH_STABLE_UUID "$relay" --check >/dev/null 2>&1 && {
  echo 'Expected placeholder CAST_ID to fail' >&2
  exit 1
}

# An unrestricted or malformed source range cannot silently open the listener.
CAST_ALLOW=0.0.0.0/0 "$relay" --check >/dev/null 2>&1 && {
  echo 'Expected unrestricted CAST_ALLOW to fail' >&2
  exit 1
}

# Discovery placeholders must be replaced before advertising.
printf 'md=REPLACE_WITH_ACTUAL_MODEL\nca=198660\nve=05\n' > "$CAST_TXT_FILE"
"$relay" --check >/dev/null 2>&1 && {
  echo 'Expected placeholder Cast metadata to fail' >&2
  exit 1
}

echo 'Configuration checks passed.'
