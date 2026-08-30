#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$REPO_ROOT/scripts/superpowers-config"

FAILURES=0
# Resolved: on macOS mktemp hands back /var/..., a symlink to /private/var,
# and git reports the resolved form. Comparing the two forms fails everywhere.
TEST_ROOT="$(cd "$(mktemp -d)" && pwd -P)"

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() { echo "  [PASS] $1"; }
fail() {
    echo "  [FAIL] $1"
    shift
    if [ $# -gt 0 ]; then
        printf '    %s\n' "$@"
    fi
    FAILURES=$((FAILURES + 1))
}

# A throwaway git repo per test, so project config never leaks between cases
# and never touches the real checkout.
make_repo() {
    local name="$1"
    local repo="$TEST_ROOT/$name"
    mkdir -p "$repo"
    git -C "$repo" init --quiet
    git -C "$repo" -c user.email=t@t -c user.name=t commit --quiet --allow-empty -m init
    printf '%s\n' "$repo"
}

# run DIR ARGS... : invoke the config script from inside DIR.
run() {
    local dir="$1"
    shift
    (cd "$dir" && "$CONFIG" "$@" 2>&1)
}

assert_eq() {
    local description="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$description"
    else
        fail "$description" "expected: $expected" "actual:   $actual"
    fi
}

assert_contains() {
    local description="$1" needle="$2" haystack="$3"
    case "$haystack" in
        *"$needle"*) pass "$description" ;;
        *) fail "$description" "expected to contain: $needle" "actual: $haystack" ;;
    esac
}

echo "superpowers-config resolution from the main checkout"

repo="$(make_repo main-checkout)"
assert_eq "specs falls back to its documented default" \
    "$repo/docs/superpowers/specs" "$(run "$repo" get specs)"
assert_eq "plans falls back to its documented default" \
    "$repo/docs/superpowers/plans" "$(run "$repo" get plans)"

run "$repo" set specs "$TEST_ROOT/chosen-specs" >/dev/null
run "$repo" set plans "$TEST_ROOT/chosen-plans" >/dev/null
assert_eq "a configured specs path is returned" \
    "$TEST_ROOT/chosen-specs" "$(run "$repo" get specs)"
assert_eq "a configured plans path is returned" \
    "$TEST_ROOT/chosen-plans" "$(run "$repo" get plans)"

# git rev-parse --git-common-dir answers a *relative* ".git" from the repo root
# and "../.git" from a subdirectory. Resolving it naively breaks this case.
mkdir -p "$repo/src/deep"
assert_eq "the setting resolves from a subdirectory of the main checkout" \
    "$TEST_ROOT/chosen-specs" "$(run "$repo/src/deep" get specs)"

echo "superpowers-config resolution from a linked worktree"

# --show-toplevel inside a worktree is the worktree itself, so anchoring
# project config there hides the setting exactly where writing-plans runs.
wt="$TEST_ROOT/linked-worktree"
git -C "$repo" worktree add --quiet -b wt "$wt" >/dev/null 2>&1

assert_eq "specs resolves from inside a linked worktree" \
    "$TEST_ROOT/chosen-specs" "$(run "$wt" get specs)"
assert_eq "plans resolves from inside a linked worktree" \
    "$TEST_ROOT/chosen-plans" "$(run "$wt" get plans)"
mkdir -p "$wt/src/deep"
assert_eq "the setting resolves from a subdirectory of a worktree" \
    "$TEST_ROOT/chosen-specs" "$(run "$wt/src/deep" get specs)"

assert_eq "path reports the main checkout config from inside a worktree" \
    "$repo/.superpowers/config" "$(run "$wt" path)"

# A set from inside a worktree must persist in the main checkout, not in the
# worktree that is about to be deleted.
run "$wt" set specs "$TEST_ROOT/reset-specs" >/dev/null
assert_contains "set from a worktree writes to the main checkout config" \
    "specs_dir=$TEST_ROOT/reset-specs" "$(cat "$repo/.superpowers/config")"
if [ -e "$wt/.superpowers/config" ]; then
    fail "set from a worktree leaves no config inside the worktree" \
        "found $wt/.superpowers/config"
else
    pass "set from a worktree leaves no config inside the worktree"
fi

echo "superpowers-config path anchoring"

# A relative configured value still anchors to the checkout you are standing
# in: only the config file location is shared, not the paths it names.
relative_repo="$(make_repo relative-value)"
mkdir -p "$relative_repo/.superpowers"
printf 'specs_dir=%s\n' "docs/here" > "$relative_repo/.superpowers/config"
relative_wt="$TEST_ROOT/relative-worktree"
git -C "$relative_repo" worktree add --quiet -b wt "$relative_wt" >/dev/null 2>&1
assert_eq "a relative value anchors to the worktree you are in" \
    "$relative_wt/docs/here" "$(run "$relative_wt" get specs)"

# Outside a git repo at all, the working directory is the anchor.
plain="$TEST_ROOT/not-a-repo"
mkdir -p "$plain"
assert_eq "a non-git directory falls back to the working directory" \
    "$plain/docs/superpowers/specs" "$(run "$plain" get specs)"

if [ "$FAILURES" -gt 0 ]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
