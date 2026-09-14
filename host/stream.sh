#!/usr/bin/env bash
# stream.sh — capture window via portal and push H.264/RTP to a peer (ADR-0003).
#
# Usage:
#   stream.sh --to HOST [--port N] [--encoder hw|sw] [--mode window]
#
# hw: vaapih264enc (RX 6700 VCE). sw: x264enc zerolatency fallback.
# Peer must be listening with host/receive.sh (or any RTP receiver).
set -euo pipefail

to=""
port=5004
encoder="hw"
mode="window"

usage() {
	sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
	exit 2
}

while (($# > 0)); do
	case $1 in
	--port)
		port=$2
		shift 2
		;;
	--encoder)
		encoder=$2
		shift 2
		;;
	--to)
		to=$2
		shift 2
		;;
	--mode)
		mode=$2
		shift 2
		;;
	-h | --help) usage ;;
	*)
		echo "unknown arg: $1" >&2
		exit 2
		;;
	esac
done
[[ -n $to ]] || usage
[[ $port =~ ^[0-9]+$ ]] || {
	echo "port must be numeric" >&2
	exit 1
}

script_dir=$(cd "$(dirname "$0")" && pwd)
node_id=$(python3 "$script_dir/portalcapture.py" --mode "$mode")

case $encoder in
hw) venc=(vaapih264enc "rate-control=cbr" "bitrate=30000" "key-int-period=150") ;;
sw) venc=(x264enc "tune=zerolatency" "bitrate=30000" "key-int-max=150") ;;
*)
	echo "--encoder must be hw|sw" >&2
	exit 1
	;;
esac

echo ':: streaming node' "$node_id" '-> rtp' "$to:$port" "($encoder)"

exec gst-launch-1.0 \
	pipewiresrc "path=$node_id" always-copy=true keepalive-time-ms=1000 stream=true ! \
	videoconvert ! \
	videoscale ! \
	"video/x-raw,framerate=60/1" ! \
	"${venc[@]}" ! \
	h264parse "config-interval=1" ! \
	rtph264pay "name=pay0" "pt=96" "config-interval=1" ! \
	udpsink "host=$to" "port=$port" "bind-port=$((port + 1))" "sync=false"
