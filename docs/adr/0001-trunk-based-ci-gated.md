# ADR-0001: Trunk-based development with CI-gated PRs

- Status: Accepted
- Date: 2026-09-15

## Context

Project couples aggressively-changing host-side shell code (Sway/GStreamer/systemd)
with a Godot client targeting a physical Quest 2. Hardware QA is manual and
cannot be automated in CI. Risk: an untested host script corrupts the desktop
session; an unreviewed Godot change is only discoverable on-device.

## Decision

1. Single trunk (`main`), short-lived feature branches.
2. No direct pushes to `main`; every change passes GitHub Actions CI + human review.
3. Every functional change is linked to a GitHub Issue; hardware validation is
   tracked through the Hardware/VR QA issue template, since CI cannot
   exercise headset-side behavior.
4. Architecture decisions are recorded as ADRs (`docs/adr/NNNN-title.md`),
   immutable once accepted; a reversal is a new ADR superseding the old one.

## Consequences

+ Binary "what changed and why" survives across sessions.
+ Human remains the merge gate for everything CI cannot see (visual, latency, comfort).
− Shorter feedback loop than free-form hacking; intentional.
