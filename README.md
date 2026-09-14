# libworkspaceVR

Linux Wayland (Sway) VR workspace streamed to Meta Quest 2.

- `host/` — Linux side: Sway management scripts, GStreamer pipelines, systemd user units.
- `client/` — Godot 4 OpenXR client project running on the headset.
- `docs/` — Architecture Decision Records (ADRs) and setup guides.
- `scripts/` — development tooling, linters, build helpers.

## Development process

Trunk-based development: no direct commits to `main`. Work happens via
feature branches → Conventional Commits → GitHub Actions CI → Pull Request.

ADRs live in `docs/adr/`; decisions are numbered once and never rewritten in place.
