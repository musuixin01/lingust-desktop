"""Verify that the native resize cursor returns to the arrow in the content area."""
import argparse
import ctypes as c
import time
from ctypes import wintypes as w


parser = argparse.ArgumentParser()
parser.add_argument("--pid", required=True, type=int)
args = parser.parse_args()

user32 = c.WinDLL("user32", use_last_error=True)
user32.LoadCursorW.restype = w.HANDLE
callback_type = c.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)


class CursorInfo(c.Structure):
    _fields_ = [("cbSize", w.DWORD), ("flags", w.DWORD),
                ("hCursor", w.HANDLE), ("ptScreenPos", w.POINT)]


window = None


@callback_type
def visit(hwnd, _):
    global window
    pid = w.DWORD()
    user32.GetWindowThreadProcessId(hwnd, c.byref(pid))
    if pid.value == args.pid and user32.IsWindowVisible(hwnd):
        window = hwnd
        return False
    return True


user32.EnumWindows(visit, 0)
if not window:
    raise RuntimeError("No visible translator window found")

rect = w.RECT()
if not user32.GetWindowRect(window, c.byref(rect)):
    raise c.WinError(c.get_last_error())


def cursor_handle():
    info = CursorInfo(cbSize=c.sizeof(CursorInfo))
    if not user32.GetCursorInfo(c.byref(info)):
        raise c.WinError(c.get_last_error())
    return info.hCursor


arrow = user32.LoadCursorW(None, w.LPCWSTR(32512))
size_we = user32.LoadCursorW(None, w.LPCWSTR(32644))
center_y = (rect.top + rect.bottom) // 2
user32.SetForegroundWindow(window)
user32.SetCursorPos(rect.left + 2, center_y)
time.sleep(0.15)
edge_cursor = cursor_handle()
user32.SetCursorPos((rect.left + rect.right) // 2, center_y)
time.sleep(0.15)
center_cursor = cursor_handle()

print(f"edge_is_resize={edge_cursor == size_we}")
print(f"center_is_arrow={center_cursor == arrow}")
if edge_cursor != size_we:
    raise RuntimeError("Left edge did not expose the horizontal resize cursor")
if center_cursor != arrow:
    raise RuntimeError("Resize cursor remained active in the content area")
print("PASS: resize cursor is limited to the edge and resets over content")
