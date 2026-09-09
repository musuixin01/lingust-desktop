"""Visible-window smoke check: card -> actions -> Escape, with cropped evidence."""
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

main = windows()['Linguist 桌面悬浮翻译']
u.SetWindowPos(main,w.HWND(-1),0,0,0,0,0x0003)
u.SetForegroundWindow(main)
time.sleep(.3)
r = rect(main)
scale = u.GetDpiForWindow(main) / 96
if r[3]-r[1] < 100*scale:
    raise RuntimeError('Run after the resize probe has expanded the card')
ImageGrab.grab(bbox=r).save(a.output/'card.png')
x = r[2]-round(32*scale)
y = r[1]+round(24*scale)
u.SetCursorPos(x,y)
time.sleep(.15)
if u.WindowFromPoint(w.POINT(x,y)) != main:
    raise RuntimeError('Card action is occluded; refusing to click another app')
u.mouse_event(2,0,0,0,0)
time.sleep(.05)
u.mouse_event(4,0,0,0,0)
time.sleep(.7)
actions = windows().get('快捷操作')
if not actions: raise RuntimeError('More action did not open its independent window')
ImageGrab.grab(bbox=rect(actions)).save(a.output/'actions.png')
u.SetForegroundWindow(actions)
time.sleep(.1)
u.keybd_event(0x1B,0,0,0)
u.keybd_event(0x1B,0,2,0)
time.sleep(.3)
if '快捷操作' in windows(): raise RuntimeError('Escape did not close the actions window')
print('PASS: visible card, independent actions window, Escape close')
