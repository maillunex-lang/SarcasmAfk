#!/usr/bin/env bash
# Probe for an existing release keystore. Never prints passwords or key material.
set -euo pipefail
FOUND=0
report() { echo "$1"; }

# Env path only (value never echoed beyond path existence)
if [[ -n "${ANDROID_RELEASE_KEYSTORE:-}" ]]; then
  if [[ -f "$ANDROID_RELEASE_KEYSTORE" ]]; then
    report "FOUND env ANDROID_RELEASE_KEYSTORE path_ok=1"
    FOUND=1
  else
    report "MISS ANDROID_RELEASE_KEYSTORE path set but file missing"
  fi
else
  report "MISS ANDROID_RELEASE_KEYSTORE unset"
fi

# Common non-secret locations (names only)
for p in \
  "$HOME/.android/release.keystore" \
  "$HOME/.android/bashlegends-release.keystore" \
  "/opt/android/release.keystore" \
  "/workspace/secrets/release.keystore"; do
  if [[ -f "$p" ]]; then
    report "FOUND path=$p"
    FOUND=1
  fi
done

# CI secret *names* — we cannot list GitHub Actions secrets with current token (403).
report "NOTE gh_actions_secrets: not readable with current credentials (need owner)"
report "NOTE no_new_keystore: will not create or overwrite any release key (D-ADMIN-03)"

if [[ "$FOUND" -eq 0 ]]; then
  report "release_keystore_unavailable → use debug APK; owner must supply ANDROID_RELEASE_KEYSTORE + alias/pass via secure env"
  exit 2
fi
report "release_keystore_available"
exit 0
