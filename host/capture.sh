#!/usr/bin/env bash
# capture.sh — MVP single-window capture (ADR-0002).
# Acquires a PipeWire node via the portal, then records a test MP4 with
# software x264 (encoder tuning is Issue #3, not this script's concern).
#
# Usage: capture.sh [--mode window|monitor] [--duration N] [--out PATH]
# Requires: dbus-next (pip --user), gst-launch-1.0, running PipeWire.
set -euo pipefail

mode="window"
duration=60
out=""

usage() {
	sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
	exit 2
}

while (($# > 0)); do
	case $1 in
	--mode)
		mode=$2
		shift 2
		;;
	--duration)
		duration=$2
		shift 2
		;;
	--out)
		out=$2
		shift 2
		;;
	-h | --help) usage ;;
	*)
		echo "unknown arg: $1" >&2
		usage
		;;
	esac
done
outdir=$(dirname "${out:-$PWD/capture.mp4}")
[[ -d $outdir ]] || {
	echo "no such directory: $outdir" >&2
	exit 1
}
[[ $duration =~ ^[0-9]+$ ]] || {
	echo "--duration must be an integer" >&2
	exit 1
}

script_dir=$(cd "$(dirname "$0")" && pwd)

echo ':: acquiring portal session (a picker dialog will appear on the desktop)'
node_id=$(python3 "$script_dir/portalcapture.py" --mode "$mode")
echo ":: pipewire node $node_id — recording ${duration}s"

# zerolatency tune is irrelevant for offline recording; keep encoder boring.
gst-launch-1.0 -e \
	pipewiresrc "path=$node_id" always-copy=true keepalive-time-ms=1000 stream=true ! \
	"video/x-raw" ! \
	videoconvert ! \
	videorate ! \
	"video/x-raw,framerate=30/1" ! \
	x264enc "tune=zerolatency" "bitrate=20000" "key-int-max=60" ! \
	mp4mux ! \
	filesink "location=$out"

echo ":: recorded: $out"
