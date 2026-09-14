#!/usr/bin/env python3
"""Establish an xdg-desktop-portal ScreenCast session; print PipeWire node id.

Flow (org.freedesktop.portal.ScreenCast):
    CreateSession -> SelectSources -> Start -> Request::Response(streams)

MUST remain a single D-Bus connection for the entire flow: portal sessions
are keyed to the caller's unique bus name, so ephemeral `gdbus call` per
step cannot drive one session. Hence Python (dbus-next), not shell.

Target (window/monitor) is chosen in the compositor's picker dialog —
interactive by design (ADR-0002). Timeout 180 s covers a user sitting in
the dialog; on timeout we fail loudly instead of leaking a live session.
"""

import argparse
import asyncio
import sys

from dbus_next import Variant
from dbus_next.aio import MessageBus

PORTAL_DEST = "org.freedesktop.portal.Desktop"
PORTAL_PATH = "/org/freedesktop/portal/desktop"
SC_IFACE = "org.freedesktop.portal.ScreenCast"
REQ_IFACE = "org.freedesktop.portal.Request"

# Portal source types bitmask: 1=monitor, 2=window
_TYPE = {"monitor": 1, "window": 2}
_TIMEOUT_S = 180


def sv(value: str) -> Variant:
    """Anyway a{sv} entry requires explicit string Variant typing."""
    return Variant("s", value)


async def acquire_node(mode: str) -> int:
    bus = await MessageBus().connect()
    introspection = await bus.introspect(PORTAL_DEST, PORTAL_PATH)
    sc = bus.get_proxy_object(PORTAL_DEST, PORTAL_PATH, introspection).get_interface(
        SC_IFACE
    )

    _code, session_path = await sc.call_create_session(
        {
            "handle_token": sv("create"),
            "session_handle_token": sv("libworkspacevr"),
        }
    )
    await sc.call_select_sources(
        session_path,
        {
            "handle_token": sv("select"),
            "multiple": Variant("b", False),
            "types": Variant("u", _TYPE[mode]),
        },
    )
    req_handle, _ = await sc.call_start(
        session_path,
        "",  # parent_window: none -> picker dialog stays independent
        {"handle_token": sv("start")},
    )

    req_int = await bus.introspect(PORTAL_DEST, req_handle)
    req = bus.get_proxy_object(PORTAL_DEST, req_handle, req_int).get_interface(
        REQ_IFACE
    )

    holder: dict = {}
    got = asyncio.Event()

    def on_response(code: int, results: dict) -> None:
        if code != 0:
            holder["error"] = f"Start replied code={code}"
        else:
            streams = results.get("streams", [])
            if not streams:
                holder["error"] = "response miss: streams empty"
            else:
                holder["node"] = int(streams[0][0])
        got.set()

    req.on_response(on_response)
    try:
        await asyncio.wait_for(got.wait(), timeout=_TIMEOUT_S)
    except asyncio.TimeoutError:
        holder["error"] = f"portal dialog unanswered in {_TIMEOUT_S}s"
    bus.disconnect()

    if "error" in holder:
        print(f"portal: {holder['error']}", file=sys.stderr)
        return 1
    print(holder["node"])
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=("window", "monitor"),
        default="window",
        help="target type offered by the portal picker",
    )
    try:
        asyncio.run(acquire_node(parser.parse_args().mode))
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
