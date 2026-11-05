#!/usr/bin/env bash
# Android SDK, command-line only — no Android Studio. Enough to build an app
# with Gradle, push it to a phone over adb, and run it in an emulator.
#
# Lives in ~/Android/Sdk, the same place Android Studio would put it, so
# adopting Studio later just finds it. .zshrc exports ANDROID_HOME and puts
# platform-tools, emulator and cmdline-tools on PATH when that dir exists;
# Gradle reads ANDROID_HOME, so projects need no local.properties.
#
# Not from dnf: Fedora's android-tools only carries adb/fastboot, and a
# second adb on PATH fights the SDK's over the shared server on :5037.
#
# Only the bootstrap zip is fetched by hand. After that sdkmanager owns
# everything, cmdline-tools included, and `--update` on each apply keeps it
# current. Platforms and build-tools a project needs beyond these get
# downloaded by the Android Gradle plugin on demand — it can, since the
# licenses are accepted here.
set -euo pipefail

case ",$HOMIE_TAGS," in *,container,*) exit 0 ;; esac
# Google ships the emulator and system images for x86_64 Linux and macOS;
# only Linux is wired up here.
[[ "$(uname -s)_$(uname -m)" == Linux_x86_64 ]] || exit 0

# sdkmanager is a Java program. Fedora's java-*-openjdk is enough.
command -v java >/dev/null 2>&1 || {
  echo "no java on PATH; skipping Android SDK" >&2; exit 0
}

export ANDROID_HOME="$HOME/Android/Sdk"
sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

# Newest system image at time of writing. The emulator is for eyeballing
# against current Android; real-device testing covers the older ones.
API=37.0
IMAGE="system-images;android-${API};google_apis;x86_64"
AVD=pixel

if [[ ! -x "$sdkmanager" ]]; then
  # The bootstrap zip's build number is only published in the repository
  # index, not at a stable URL. Take the highest one listed.
  zip=$(curl -fsSL https://dl.google.com/android/repository/repository2-3.xml \
    | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' | sort -uV | tail -1) || true
  [[ -n "$zip" ]] || { echo "could not resolve cmdline-tools; skipping" >&2; exit 0; }

  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/tools.zip" "https://dl.google.com/android/repository/$zip"
  unzip -q "$tmp/tools.zip" -d "$tmp"
  # The zip unpacks to cmdline-tools/; sdkmanager insists on living at
  # cmdline-tools/latest/ (or a version dir) to know where the SDK root is.
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi

yes | "$sdkmanager" --licenses >/dev/null 2>&1 || true
"$sdkmanager" --install \
  "cmdline-tools;latest" \
  "platform-tools" \
  "emulator" \
  "$IMAGE" >/dev/null
"$sdkmanager" --update >/dev/null

# One emulator, created once. Recreate it by deleting ~/.android/avd/$AVD.*
# — the AVD's own settings (and its data partition) aren't overwritten here.
avdmanager="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
if ! "$avdmanager" list avd -c 2>/dev/null | grep -qx "$AVD"; then
  echo no | "$avdmanager" create avd --name "$AVD" --package "$IMAGE" --device pixel_9
fi
