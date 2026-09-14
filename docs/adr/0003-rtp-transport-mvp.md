# ADR-0003: MVP transport — direct RTP over UDP (no WebRTC)

- Status: Proposed
- Date: 2026-09-15
- Contributes to Issue #3

## Context

Capture (ADR-0002) delivers raw frames from a PipeWire node. MVP target:
one desktop window on the local tailnet, viewed on a Quest 2 via a Godot
OpenXR client (Issue #4). Host GPU: RX 6700 (VCE/VCN hardware encoder,
exposed via Mesa VA-API).

Options evaluated:

1. Direct RTP/UDP (LAN or tailnet link) — stateless, single UDP flow.
2. WebRTC (SDP/ICE/DTLS) — browser-grade, NAT-traversal machinery.
3. SRT — robust over lossy WAN, but the tailnet is a clean wire.

## Decision

**Direct RTP over UDP**: `... ! vaapih264enc ! rtph264pay name=pay0 !
udpsink host=<peer> port=<N>`. Link integrity is delegated to the tailnet
layer (WireGuard retransmits, LAN jitter); the transport stage does not
own retransmission.

Encoder: `vaapih264enc`, hardware. Rationale: RX 6700's VCN is otherwise
idle; software x264 at 20–40 Mbps 1080p60 eats a full core and adds
latency. Fallback chain to `x264enc tune=zerolatency` is kept in the run
script behind `--encoder sw` for debugging when VA-API misbehaves
(driver-level, not architectural).

## Consequences

+ Zero signaling infrastructure; peer address is configuration, not a protocol.
+ Terminal latency nears rtp payload+encoder only.
− Not reachable over public Internet; acceptable for MVP, revisit with
  WebRTC only if away-from-tailnet use becomes a requirement.
− UDP: no retransmit; a lost tailnet packet is a visible glitch, not an
  error. Accepted for MVP; recovery paths are reconnection, not re-transmit.
