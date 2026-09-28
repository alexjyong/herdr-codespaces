#!/usr/bin/env bash
# Tests for the pure helpers in bin/herdr-codespaces. Run: bash test/smoke.sh
source "$(dirname "$0")/../bin/herdr-codespaces"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail() { echo "FAIL: $*"; exit 1; }

cat > "$t/cfg" <<'C'
Host herdr-cs.bar-xyz
	User vscode

Host herdr-cs.foo-abc
	User vscode

Host herdr-cs.foo-abcd
	User vscode
C
out=$(drop_block foo-abc < "$t/cfg")
grep -qx 'Host herdr-cs.foo-abc' <<<"$out" && fail "block kept"
grep -qx 'Host herdr-cs.bar-xyz' <<<"$out" || fail "other block dropped"
grep -qx 'Host herdr-cs.foo-abcd' <<<"$out" || fail "prefix-sharing block dropped"

out=$(printf 'Host cs.foo-abc.main\n\tProxyCommand /gh cs ssh -c foo-abc --stdio\n\tUserKnownHostsFile=/dev/null\n\tStrictHostKeyChecking no\n' | patch_config foo-abc '~/.ssh/kh' /p/hc)
[[ $out == $'Host herdr-cs.foo-abc\n\tProxyCommand /p/hc guard foo-abc /gh cs ssh -c foo-abc --stdio\n\tUserKnownHostsFile ~/.ssh/kh\n\tStrictHostKeyChecking accept-new' ]] || fail "patch_config: $out"

printf 'Host x\n' > "$t/sshcfg"
ensure_include "$t/sshcfg" '~/.ssh/codespaces'; ensure_include "$t/sshcfg" '~/.ssh/codespaces'
[[ $(cat "$t/sshcfg") == $'Include ~/.ssh/codespaces\nHost x' ]] || fail "ensure_include: $(cat "$t/sshcfg")"
ensure_include "$t/new" '~/.ssh/codespaces'
[[ $(cat "$t/new") == 'Include ~/.ssh/codespaces' ]] || fail "ensure_include on missing file"

json='[
  {
    "id": "111",
    "label": "other",
    "target": "somehost",
    "session": "default"
  },
  {
    "id": "222",
    "label": "foo",
    "target": "herdr-cs.foo-abc",
    "session": "default"
  }
]'
[[ $(machine_for foo-abc <<<"$json") == $'222\tfoo' ]] || fail "machine_for"
[[ -z $(machine_for foo-ab <<<"$json") ]] || fail "machine_for prefix match"
[[ $(registered <<<"$json") == $'foo\tfoo-abc' ]] || fail "registered"
echo "ok"
