#!/bin/bash

set -euo pipefail

sudo apt-get install -y xdotool openbox imagemagick tesseract-ocr sqlite3 fonts-dejavu-core ffmpeg pulseaudio
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=ci
pactl set-default-sink ci
pactl info | grep -E "Server Name|Default Sink"
