"""Legacy diagnostic: NOT an acceptance test (mixed timestamps, one-sided threshold).
Use probe_resize_stability.py for same-screenshot corner measurements instead.
"""
import argparse
import ctypes as c
import json
import time
from ctypes import wintypes as w
from pathlib import Path

from PIL import ImageGrab

parser = argparse.ArgumentParser()
parser.add_argument("--pid", type=int, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

u = c.WinDLL("user32", use_last_error=True)
u.SetProcessDpiAwarenessContext(c.c_void_p(-4))
u.GetWindowThreadProcessId.argtypes = [w.HWND, c.POINTER(w.DWORD)]
u.GetWindowRect.argtypes = [w.HWND, c.POINTER(w.RECT)]
u.SetWindowPos.argtypes = [w.HWND, w.HWND, c.c_int, c.c_int, c.c_int, c.c_int, c.c_uint]
u.CreateWindowExW.argtypes = [w.DWORD, w.LPCWSTR, w.LPCWSTR, w.DWORD, c.c_int,
                              c.c_int, c.c_int, c.c_int, w.HWND, w.HMENU,
                              w.HINSTANCE, c.c_void_p]
u.CreateWindowExW.restype = w.HWND

handles = []
callback_type = c.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)


@callback_type
def visit(hwnd, _):
    pid = w.DWORD()
    u.GetWindowThreadProcessId(hwnd, c.byref(pid))
    class_name = c.create_unicode_buffer(128)
    u.GetClassNameW(hwnd, class_name, 128)
    if pid.value == args.pid and u.IsWindowVisible(hwnd) and "QWindow" in class_name.value:
        handles.append(hwnd)
    return True


u.EnumWindows(visit, 0)
if not handles:
    raise SystemExit("No visible Qt window for PID")
window = handles[0]
dpi = u.GetDpiForWindow(window) / 96


def window_rect():
    rect = w.RECT()
    u.GetWindowRect(window, c.byref(rect))
    return [rect.left, rect.top, rect.right, rect.bottom]


def click(x, y):
    u.SetCursorPos(x, y)
    u.mouse_event(2, 0, 0, 0, 0)
    time.sleep(0.03)
    u.mouse_event(4, 0, 0, 0, 0)


background = u.CreateWindowExW(0x80, "STATIC", "Corner continuity probe", 0x90000004,
                               350, 150, 1100, 900, None, None, None, None)
if not background:
    raise c.WinError(c.get_last_error())
u.SetWindowPos(background, w.HWND(-1), 350, 150, 1100, 900, 0x0040)
u.UpdateWindow(background)
u.SetWindowPos(window, w.HWND(-1), 0, 0, 0, 0, 0x0003)


def differs(pixel, background_color):
    return max(abs(int(a) - int(b)) for a, b in zip(pixel[:3], background_color)) > 18


def horizontal_inset(rect, top):
    y = (rect[1] + round(2 * dpi)) if top else (rect[3] - 1 - round(2 * dpi))
    span = round(45 * dpi)
    image = ImageGrab.grab(bbox=(rect[2] - span, y, rect[2], y + 1))
    bg = ImageGrab.grab(bbox=(360, 160, 361, 161)).getpixel((0, 0))[:3]
    pixels = [image.getpixel((x, 0)) for x in range(image.width - 1, -1, -1)]
    return next((index for index, pixel in enumerate(pixels) if differs(pixel, bg)), span)


def vertical_inset(rect, left):
    x = (rect[0] + round(2 * dpi)) if left else (rect[2] - 1 - round(2 * dpi))
    span = round(45 * dpi)
    image = ImageGrab.grab(bbox=(x, rect[3] - span, x + 1, rect[3]))
    bg = ImageGrab.grab(bbox=(360, 160, 361, 161)).getpixel((0, 0))[:3]
    pixels = [image.getpixel((0, y)) for y in range(image.height - 1, -1, -1)]
    return next((index for index, pixel in enumerate(pixels) if differs(pixel, bg)), span)


results = {}
try:
    current = window_rect()
    if current[3] - current[1] < round(100 * dpi):
        click(current[2] - round(18 * dpi), (current[1] + current[3]) // 2)
        time.sleep(0.5)
    if window_rect()[3] - window_rect()[1] < round(100 * dpi):
        raise SystemExit("Expand card before running corner continuity probe")
    u.SetWindowPos(window, 0, 500, 220, round(500 * dpi), round(490 * dpi), 0x0044)
    time.sleep(0.4)
    ImageGrab.grab().save(str(args.output.with_suffix(".png")))
    initial = window_rect()
    right_baseline = [horizontal_inset(initial, True), horizontal_inset(initial, False)]
    x, y = initial[2] - 2, (initial[1] + initial[3]) // 2
    u.SetCursorPos(x, y)
    u.mouse_event(2, 0, 0, 0, 0)
    right_samples = []
    for step in range(1, 81):
        u.SetCursorPos(x - round(step * 3 * dpi), y)
        time.sleep(0.003)
        rect = window_rect()
        right_samples.append([horizontal_inset(rect, True), horizontal_inset(rect, False)])
    u.mouse_event(4, 0, 0, 0, 0)

    u.SetWindowPos(window, 0, 500, 220, round(500 * dpi), round(490 * dpi), 0x0044)
    time.sleep(0.4)
    initial = window_rect()
    bottom_baseline = [vertical_inset(initial, True), vertical_inset(initial, False)]
    x, y = (initial[0] + initial[2]) // 2, initial[3] - 2
    u.SetCursorPos(x, y)
    u.mouse_event(2, 0, 0, 0, 0)
    bottom_samples = []
    for step in range(1, 81):
        u.SetCursorPos(x, y - round(step * 3 * dpi))
        time.sleep(0.003)
        rect = window_rect()
        bottom_samples.append([vertical_inset(rect, True), vertical_inset(rect, False)])
    u.mouse_event(4, 0, 0, 0, 0)

    results = {
        "dpiScale": dpi,
        "right": {"baseline": right_baseline, "minimum": [min(v[i] for v in right_samples) for i in range(2)], "samples": right_samples},
        "bottom": {"baseline": bottom_baseline, "minimum": [min(v[i] for v in bottom_samples) for i in range(2)], "samples": bottom_samples},
    }
finally:
    u.mouse_event(4, 0, 0, 0, 0)
    u.DestroyWindow(background)
    u.SetWindowPos(window, 0, 550, 220, round(380 * dpi), round(490 * dpi), 0x0044)

args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(results, indent=2), encoding="utf-8")
summary = {edge: {"baseline": value["baseline"], "minimum": value["minimum"]}
           for edge, value in results.items() if edge != "dpiScale"}
print(json.dumps(summary))
passed = all(minimum >= baseline - round(2 * dpi)
             for value in results.values() if isinstance(value, dict)
             for baseline, minimum in zip(value["baseline"], value["minimum"]))
raise SystemExit(0 if passed else 1)
