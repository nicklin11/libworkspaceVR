# ADR-0002: Window capture via xdg-desktop-portal ScreenCast (PipeWire)

- Status: Accepted
- Date: 2026-09-15
- Supersedes: nothing; contributes to Issue #2

## Context

The MVP needs: capture one Sway/niri window on the host, feed it to GStreamer.
Host compositor is niri (sway also installed). Available on host: pipewire,
wireplumber, xdg-desktop-portal-gnome/gtk, GStreamer. wf-recorder is NOT installed.

Constraints:

1. Wayland clients cannot peek other windows — capture must go through a
   compositor-sanctioned channel.
2. The capture path must survive compositor swaps (niri↔sway) without rewrite.
3. We cannot assume root/sudo installs client-side at runtime.

## Decision

Primary path: **org.freedesktop.portal.ScreenCast → PipeWire node →
`pipewiresrc`** in the GStreamer pipeline.

- The portal session is established by a persistent D-Bus connection from a
  small Python helper (`host/portalcapture.py`) using `dbus-next`.
  Why persistent: `gdbus call` opens a fresh connection per invocation, and
  portal sessions are keyed to the caller's unique bus name — an ephemeral
  connection cannot perform CreateSession/SelectSources/Start as one sender.
- Target selection uses the portal picker dialog (interactive, by design:
  compositor-mediated consent). Foreground/automated target selection is a
  later hardening item, not MVP.
- GStreamer consumes the PipeWire node id printed by the helper.

Fallback evaluated and rejected for MVP: wlr-screencopy clients
(`wf-recorder`, `wl-screenrec`). Rejected because they encode themselves
instead of exposing raw frames, which bypasses the encoder stage that is
Issue #3's concern, and they hard-bind to wlroots-family proxies.

## Consequences

+ Compositor-agnostic (niri and sway both implement portal ScreenCast).
+ Consent-driven: no bypass of Wayland security model.
+ Raw frames reach GStreamer; encoder choice remains free.
− Requires `dbus-next` (pip, user-level) on the host.
− MVP target pick is interactive (portal dialog); automation needs
  restore-token work later.
