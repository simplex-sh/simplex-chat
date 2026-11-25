#!/bin/bash

set -uo pipefail

bin=$1
name=$2
seconds=40
log="$RUNNER_TEMP/$name.log"
shot="$RUNNER_TEMP/$name.png"

if [ "$RUNNER_OS" = Linux ]; then
  xvfb-run -a -s "-screen 0 1440x900x24" "$bin" > "$log" 2>&1 &
else
  "$bin" > "$log" 2>&1 &
fi
pid=$!
sleep "$seconds"
alive=0
kill -0 "$pid" 2>/dev/null && alive=1
case "$RUNNER_OS" in
  macOS) screencapture -x "$shot" || true ;;
  Windows)
    powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; \$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; \$i=New-Object System.Drawing.Bitmap \$b.Width,\$b.Height; [System.Drawing.Graphics]::FromImage(\$i).CopyFromScreen(\$b.Location,[System.Drawing.Point]::Empty,\$b.Size); \$i.Save('$(cygpath -w "$shot")')" || true
    ;;
esac
kill "$pid" 2>/dev/null || true
if [ "$RUNNER_OS" = Linux ]; then
  pkill -f "$bin" 2>/dev/null || true
  pkill Xvfb 2>/dev/null || true
fi
if [ "$RUNNER_OS" = Windows ]; then
  taskkill //F //IM SimpleX.exe 2>/dev/null || true
fi
echo "::group::$name log"
cat "$log"
echo "::endgroup::"
if grep -E "UnsatisfiedLinkError|startup error" "$log"; then
  echo "$name logged an error"
  exit 1
fi
if [ "$alive" != 1 ]; then
  echo "$name exited within $seconds s"
  exit 1
fi
echo "$name ran for $seconds s"
