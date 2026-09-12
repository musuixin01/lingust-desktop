"""Visible-window smoke check: card -> settings -> Escape, with cropped evidence."""
import argparse
import ctypes as c
from ctypes import wintypes as w
from pathlib import Path
import time
from PIL import ImageGrab

p = argparse.ArgumentParser()
p.add_argument('--pid', type=int, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)
u = c.WinDLL('user32', use_last_error=True)
u.SetProcessDpiAwarenessContext.argtypes = [c.c_void_p]
u.SetProcessDpiAwarenessContext(c.c_void_p(-4))
u.GetWindowThreadProcessId.argtypes = [w.HWND, c.POINTER(w.DWORD)]
u.GetWindowTextW.argtypes = [w.HWND, w.LPWSTR, c.c_int]
u.IsWindowVisible.argtypes = [w.HWND]
u.GetWindowRect.argtypes = [w.HWND, c.POINTER(w.RECT)]
u.GetDpiForWindow.argtypes = [w.HWND]
u.SetForegroundWindow.argtypes = [w.HWND]
u.SetWindowPos.argtypes = [w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,w.UINT]
u.WindowFromPoint.argtypes = [w.POINT]
u.WindowFromPoint.restype = w.HWND
u.ScreenToClient.argtypes = [w.HWND, c.POINTER(w.POINT)]
callback = c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)

def windows():
    found = {}
    @callback
    def visit(hwnd, _):
        pid = w.DWORD()
        u.GetWindowThreadProcessId(hwnd,c.byref(pid))
        if pid.value == a.pid and u.IsWindowVisible(hwnd):
            title = c.create_unicode_buffer(256)
            u.GetWindowTextW(hwnd,title,256)
            found[title.value] = hwnd
        return True
    u.EnumWindows(visit,0)
    return found

def rect(hwnd):
    r = w.RECT()
    if not u.GetWindowRect(hwnd,c.byref(r)): raise c.WinError()
    return (r.left,r.top,r.right,r.bottom)

def click_client(hwnd, screen_x, screen_y):
    point = w.POINT(screen_x, screen_y)
    if not u.ScreenToClient(hwnd, c.byref(point)): raise c.WinError()
    packed = (point.y << 16) | (point.x & 0xffff)
    u.SendMessageW(hwnd, 0x0201, 0x0001, packed)
    time.sleep(.04)
    u.SendMessageW(hwnd, 0x0202, 0, packed)

def save_crop(hwnd, name):
    try:
        ImageGrab.grab(bbox=rect(hwnd)).save(a.output/name)
        return True
    except OSError as error:
        print(f'WARN: desktop capture unavailable ({error}); interaction checks continue')
        return False

main = None
for _ in range(30):
    main = windows().get('Linguist 桌面悬浮翻译')
    if main:
        break
    time.sleep(.1)
if not main:
    raise RuntimeError('Translator window did not become ready')
u.SetWindowPos(main,w.HWND(-1),0,0,0,0,0x0003)
u.SetForegroundWindow(main)
time.sleep(.3)
r = rect(main)
scale = u.GetDpiForWindow(main) / 96
if r[3]-r[1] < 100*scale:
    expand_x = r[2] - round(18*scale)
    expand_y = (r[1] + r[3]) // 2
    if u.WindowFromPoint(w.POINT(expand_x,expand_y)) != main:
        raise RuntimeError('Card expand action is occluded')
    u.SetCursorPos(expand_x,expand_y)
    click_client(main, expand_x, expand_y)
    time.sleep(.45)
    r = rect(main)
if r[3]-r[1] < 100*scale:
    raise RuntimeError('Card did not expand from pill mode')
save_crop(main, 'card.png')
x = r[2]-round(32*scale)
y = r[1]+round(24*scale)
u.SetCursorPos(x,y)
time.sleep(.15)
if u.WindowFromPoint(w.POINT(x,y)) != main:
    raise RuntimeError('Card action is occluded; refusing to click another app')
click_client(main, x, y)
time.sleep(.7)
settings = next((hwnd for title, hwnd in windows().items()
                 if title == 'Linguist 设置' or title.startswith('Linguist 设置 - ')), None)
if not settings: raise RuntimeError('Settings action did not open its independent window')
save_crop(settings, 'settings.png')
u.SetForegroundWindow(settings)
time.sleep(.1)
u.SendMessageW(settings, 0x0100, 0x1B, 0)
u.SendMessageW(settings, 0x0101, 0x1B, 0)
time.sleep(.3)
if any(title == 'Linguist 设置' or title.startswith('Linguist 设置 - ')
       for title in windows()):
    raise RuntimeError('Escape did not close the settings window')
print('PASS: visible card, independent settings window, animated Escape close')
