#!/bin/sh
#
# Smoke test: load the nDPI plugin into Suricata, run a pcap containing
# HTTP basic authentication (nDPI's tests/cfgs/default/pcap/
# http-basic-auth.pcap) and check that the ndpi-protocol and ndpi-risk
# keywords match, and that EVE records are enriched with nDPI metadata.
#
# Usage: smoke-test.sh <suricata> <ndpi.so> <http-basic-auth.pcap>

set -e

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <suricata> <ndpi.so> <http-basic-auth.pcap>" >&2
    exit 1
fi

suricata="$1"
plugin="$(realpath "$2")"
pcap="$(realpath "$3")"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/suricata.yaml" <<EOF
%YAML 1.1
---
plugins:
  - $plugin

outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert
        - flow
EOF

cat > "$tmpdir/test.rules" <<EOF
alert tcp any any -> any any (msg:"ndpi HTTP"; requires: keyword ndpi-protocol; ndpi-protocol:HTTP; sid:1;)
alert tcp any any -> any any (msg:"ndpi not TLS"; requires: keyword ndpi-protocol; ndpi-protocol:!TLS; sid:2;)
alert tcp any any -> any any (msg:"ndpi clear text creds"; requires: keyword ndpi-risk; ndpi-risk:NDPI_CLEAR_TEXT_CREDENTIALS; sid:3;)
EOF

# Rule parse errors must be fatal.
cat > "$tmpdir/bad.rules" <<EOF
alert tcp any any -> any any (msg:"bad"; ndpi-protocol:NoSuchProtocol; sid:10;)
EOF
if "$suricata" -T -c "$tmpdir/suricata.yaml" -S "$tmpdir/bad.rules" \
        --set engine-analysis.rules=false > "$tmpdir/bad.log" 2>&1; then
    cat "$tmpdir/bad.log"
    echo "FAIL: invalid ndpi-protocol value was accepted" >&2
    exit 1
fi

"$suricata" -c "$tmpdir/suricata.yaml" -S "$tmpdir/test.rules" \
    -k none --runmode single -l "$tmpdir" -r "$pcap" > "$tmpdir/run.log" 2>&1 || {
    cat "$tmpdir/run.log"
    echo "FAIL: suricata exited with an error" >&2
    exit 1
}
cat "$tmpdir/run.log"

if ! grep -q "Initializing plugin ndpi" "$tmpdir/run.log" \
        "$tmpdir/suricata.log" 2>/dev/null; then
    echo "FAIL: plugin was not loaded" >&2
    exit 1
fi

count() {
    grep -c "$1" "$tmpdir/eve.json" || true
}

failed=0
for sid in 1 2 3; do
    n=$(count "\"signature_id\":$sid,")
    echo "sid $sid alerts: $n"
    if [ "$n" -eq 0 ]; then
        echo "FAIL: no alerts for sid $sid" >&2
        failed=1
    fi
done

n=$(count '"ndpi": *{')
echo "EVE records with ndpi metadata: $n"
if [ "$n" -eq 0 ]; then
    echo "FAIL: no EVE records with ndpi metadata" >&2
    failed=1
fi

if [ "$failed" -ne 0 ]; then
    exit 1
fi
echo "OK"
