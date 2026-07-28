# Helpers for the scripts that install binaries straight from an upstream
# release, where no package manager is watching for new versions. Source it:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"
#
# (rather than via $HM_REPO, so the scripts still run when invoked by hand)
#
# Lives in a subdirectory with a .bash extension so `hm run`'s scripts/*.sh
# glob never picks it up as a script in its own right.
#
# The shape every caller follows: resolve the newest release, compare it to
# what's installed, and no-op when they match. That keeps `hm apply` cheap on
# a current host while still pulling upgrades — the install-once guard these
# scripts used to carry meant a binary was frozen at whatever version the
# host happened to be provisioned with.

# latest_release <owner/repo>
# Print the newest release version, leading "v" stripped.
#
# Resolved from the redirect /releases/latest serves rather than the GitHub
# API: unauthenticated API calls are capped at 60/hr per IP and several
# scripts ask this on every apply. Returns nonzero without printing when the
# redirect can't be resolved (offline, rate-limited, repo moved) so callers
# can skip the run instead of reinstalling blindly.
latest_release() {
  local url tag
  url=$(curl -sSfL -o /dev/null -w '%{url_effective}' \
    "https://github.com/$1/releases/latest") || return 1
  tag=${url##*/tag/}
  [[ -n "$tag" && "$tag" != "$url" ]] || return 1
  printf '%s\n' "${tag#v}"
}

# current_version <cmd> [args...]
# Print the first dotted version triple the command emits, or nothing at all
# when it isn't installed. Normalizes the various house styles — "atuin
# 18.18.1 (hash)", "NVIM v0.12.4", "starship 1.26.0", bare "0.88.0" — so
# callers can string-compare against latest_release. Always succeeds; an
# empty result is the "not installed / unknown" signal, which compares
# unequal to any real version and so triggers an install.
current_version() {
  "$@" 2>/dev/null | grep -oEm1 '[0-9]+\.[0-9]+\.[0-9]+' || true
}

# install_from_tarball <url> <path-in-tarball> <dest>
# Stream a .tar.gz to a tempdir and move one binary out of it to <dest>,
# executable. Unpacking to a tempdir first means a truncated download or a
# moved asset leaves the existing binary untouched rather than half-written.
install_from_tarball() {
  local url=$1 member=$2 dest=$3 tmp rc=0
  tmp=$(mktemp -d)
  curl -sSfL "$url" | tar xz -C "$tmp" \
    && install -m 755 "$tmp/$member" "$dest" \
    || rc=1
  rm -rf "$tmp"
  return $rc
}
