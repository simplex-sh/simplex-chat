#!/bin/bash

set -euo pipefail

package=$1
out=$2
mode=${3:-extract}
mkdir -p "$out"

case "$package" in
  *.deb)
    if [ "$mode" = install ]; then
      sudo apt-get update
      sudo mkdir -p /usr/share/applications /usr/share/desktop-directories
      sudo apt-get install -y "$(realpath "$package")" xvfb
      bin=$(dpkg -L simplex | grep '/bin/simplex$')
    else
      dpkg-deb -x "$package" "$out/root"
      bin=$(find "$out/root" -path '*/bin/simplex' | head -n 1)
    fi
    ;;
  *.dmg)
    hdiutil attach -nobrowse -readonly -mountpoint "$out/dmg" "$package"
    cp -R "$out/dmg/SimpleX.app" "$out/"
    hdiutil detach "$out/dmg"
    bin="$out/SimpleX.app/Contents/MacOS/SimpleX"
    ;;
  *.msi)
    powershell -NoProfile -Command "Start-Process msiexec -Wait -ArgumentList '/a','$(cygpath -w "$package")','/qn','TARGETDIR=$(cygpath -w "$out/msi")'"
    bin=$(cygpath -m "$(find "$out/msi" -name SimpleX.exe | head -n 1)")
    ;;
esac

jars=$(dirname "$(find "$(dirname "$(dirname "$bin")")" -name 'vlcj-[0-9]*.jar' | head -n 1)")
echo "$bin" > "$out/bin"
echo "$jars" > "$out/jars-dir"
echo "$jars/resources" > "$out/resources-dir"
echo "app: $bin"
ls "$jars/resources" "$jars/resources/vlc"
