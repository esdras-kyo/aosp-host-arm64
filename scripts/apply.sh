#!/usr/bin/env bash
#
# Apply the ARM64 host bring-up patches onto a clean AOSP 13 tree.
#
# Usage: scripts/apply.sh <AOSP_TREE>
#
# Reads patches/series (project + patch, in application order), maps each
# AOSP project path to its patch dir (build/soong -> patches/build-soong),
# runs `git apply --check` before `git apply`, and aborts on the first error.
#
# No --3way: if the baseline source does not match, the patch MUST fail loudly
# instead of silently merging. Does not touch prebuilts.

set -euo pipefail

AOSP="${1:?usage: scripts/apply.sh <AOSP_TREE>}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERIES="$REPO/patches/series"

# Validate target tree.
[ -d "$AOSP/build/soong" ] || { echo "ERROR: not an AOSP tree: $AOSP/build/soong missing" >&2; exit 1; }
[ -d "$AOSP/build/make" ]  || { echo "ERROR: not an AOSP tree: $AOSP/build/make missing"  >&2; exit 1; }
[ -f "$SERIES" ]           || { echo "ERROR: series not found: $SERIES" >&2; exit 1; }

n=0
while read -r proj patch; do
  [ -z "${proj:-}" ] && continue          # skip blank lines
  case "$proj" in \#*) continue ;; esac   # skip comments

  patchdir="patches/${proj//\//-}"        # build/soong -> patches/build-soong
  pf="$REPO/$patchdir/$patch"
  tgt="$AOSP/$proj"

  [ -f "$pf" ]  || { echo "ERROR: missing patch: $pf" >&2; exit 1; }
  [ -d "$tgt" ] || { echo "ERROR: missing project: $tgt" >&2; exit 1; }

  echo ">> $proj : $patch"
  git -C "$tgt" apply --check "$pf"        # fail loudly on baseline mismatch
  git -C "$tgt" apply "$pf"
  n=$((n + 1))
done < "$SERIES"

echo "OK: applied $n patches to $AOSP"
