#!/usr/bin/env bash
# receive.sh — decode the RTP stream from host/stream.sh and display it.
#
# Usage: receive.sh [--port N] [--sink ximagesink|fakesink]
# Runs GStreamer with a jitterbuffer; used to verify transport before the
# Godot client (Issue #4) exists. Keep this window on the laptop screen.
set -euo pipefail

port=5004
sink=ximagesink

while (($# > 0)); do
	case $1 in
	--port)
		port=$2
		shift 2
		;;
	--sink)
		sink=$2
		shift 2
		;;
	*) exit 2 ;;
	esac
done
[[ $port =~ ^[0-9]+$ ]] || {
	echo "port must be numeric" >&2
	exit 1
}

exec gst-launch-1.0 \
	udpsrc "port=$port" "caps=application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96" ! \
	rtph264depay ! \
	h264parse ! \
	avdec_h264 ! \
	videoconvert ! \
	"$sink" "sync=false"
