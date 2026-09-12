"""Exercise the real global screenshot shortcut and verify the overlay lifecycle."""

from __future__ import annotations

import argparse
import ctypes
import time
from ctypes import wintypes


user32 = ctypes.windll.user32
KEYEVENTF_KEYUP = 0x0002
VK_CONTROL = 0x11
VK_SHIFT = 0x10
VK_S = 0x53
VK_ESCAPE = 0x1B


def visible_titles(pid: int) -> list[str]:
    titles: list[str] = []

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def callback(hwnd: int, _: int) -> bool:
        window_pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(window_pid))
        if window_pid.value == pid and user32.IsWindowVisible(hwnd):
            length = user32.GetWindowTextLengthW(hwnd)
            buffer = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buffer, length + 1)
            titles.append(buffer.value)
        return True

    user32.EnumWindows(callback, 0)
    return titles


def key_event(key: int, up: bool = False) -> None:
    user32.keybd_event(key, 0, KEYEVENTF_KEYUP if up else 0, 0)


def send_screenshot_shortcut() -> None:
    key_event(VK_CONTROL)
    key_event(VK_SHIFT)
    key_event(VK_S)
    key_event(VK_S, True)
    key_event(VK_SHIFT, True)
    key_event(VK_CONTROL, True)


def wait_for(predicate, timeout: float = 3.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.05)
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pid", type=int, required=True)
    args = parser.parse_args()

    send_screenshot_shortcut()
    assert wait_for(
        lambda: any("Linguist 截图框选" in title for title in visible_titles(args.pid))
    ), (
        "Ctrl+Shift+S did not open the real screenshot overlay"
    )
    key_event(VK_ESCAPE)
    key_event(VK_ESCAPE, True)
    assert wait_for(
        lambda: all("Linguist 截图框选" not in title for title in visible_titles(args.pid))
    ), (
        "Escape did not close the screenshot overlay"
    )
    print("PASS: screenshot shortcut opened the selection overlay and Escape restored the app")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
