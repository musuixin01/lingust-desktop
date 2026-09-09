"""Windows desktop drag probe. Geometry and silhouette are separate measurements.

Silhouette bounds and all four corner samples come from ONE screenshot; no
GetWindowRect/screenshot timestamp mixing. Requires Pillow, controls the mouse.
"""
import argparse
import ctypes as c
from ctypes import wintypes as w
import json
from pathlib import Path
import time
from PIL import Image, ImageGrab, ImageChops

p = argparse.ArgumentParser()
p.add_argument('--pid', type=int, required=True)
p.add_argument('--output', type=Path, required=True)
p.add_argument('--edges', nargs='+', choices=['left','right','top','bottom','top-left','top-right','bottom-left','bottom-right'],
               default=['left','right','top','bottom','top-left','top-right','bottom-left','bottom-right'])
a = p.parse_args()
a.output.parent.mkdir(parents=True, exist_ok=True)
u = c.WinDLL('user32', use_last_error=True)
u.SetProcessDpiAwarenessContext.argtypes = [c.c_void_p]
u.SetProcessDpiAwarenessContext(c.c_void_p(-4))
u.GetWindowRect.argtypes = [w.HWND, c.POINTER(w.RECT)]
u.GetWindowThreadProcessId.argtypes = [w.HWND, c.POINTER(w.DWORD)]
u.GetClassNameW.argtypes = [w.HWND, w.LPWSTR, c.c_int]
u.IsWindowVisible.argtypes = [w.HWND]
u.GetDpiForWindow.argtypes = [w.HWND]
u.SetForegroundWindow.argtypes = [w.HWND]
u.WindowFromPoint.argtypes = [w.POINT]
u.WindowFromPoint.restype = w.HWND
u.SetWindowPos.argtypes = [w.HWND, w.HWND, c.c_int, c.c_int, c.c_int, c.c_int, w.UINT]
u.CreateWindowExW.argtypes = [w.DWORD,w.LPCWSTR,w.LPCWSTR,w.DWORD,c.c_int,c.c_int,c.c_int,c.c_int,w.HWND,w.HMENU,w.HINSTANCE,c.c_void_p]
u.CreateWindowExW.restype = w.HWND
u.DestroyWindow.argtypes = [w.HWND]
u.UpdateWindow.argtypes = [w.HWND]
handles = []
callback = c.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)
@callback
def visit(hwnd, _):
    pid = w.DWORD()
    name = c.create_unicode_buffer(256)
    u.GetWindowThreadProcessId(hwnd, c.byref(pid))
    u.GetClassNameW(hwnd, name, 256)
    if pid.value == a.pid and u.IsWindowVisible(hwnd) and 'QWindow' in name.value:
        handles.append(hwnd)
    return True
u.EnumWindows(visit, 0)
if len(handles) != 1:
    raise SystemExit('Expected exactly one visible QWindow for the supplied PID')
hwnd = handles[0]
scale = u.GetDpiForWindow(hwnd) / 96
def rect():
    r = w.RECT()
    if not u.GetWindowRect(hwnd, c.byref(r)): raise c.WinError()
    return [r.left, r.top, r.right, r.bottom]
original = rect()
background = None
def snapshot():
    # Entire sampling area is inside the solid STATIC background.
    frame = ImageGrab.grab(bbox=(360,160,1400,1040)).convert('RGB')
    bg = frame.getpixel((0,0))
    delta = ImageChops.difference(frame, Image.new('RGB', frame.size, bg))
    channels = delta.split()
    mask = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2]).point(lambda x: 255 if x > 18 else 0)
    bounds = mask.getbbox()
    if not bounds: raise RuntimeError('No visible silhouette')
    l,t,r,b = bounds
    if l == 0 or t == 0 or r == frame.width or b == frame.height:
        frame.save(a.output.with_name('invalid-sampling-area.png'))
        raise RuntimeError('Window outside sampling area')
    inset = max(2, round(2*scale))
    span = round(45*scale)
    values = []
    for y in [t+inset, b-1-inset]:
        for x, direction in [(l,1),(r-1,-1)]:
            found = next((i for i in range(span) if mask.getpixel((x+direction*i,y))), None)
            if found is None: raise RuntimeError('Missing corner edge')
            values.append(found)
    return values, [l+360,t+160,r+360,b+160], frame

results = {}
try:
    background = u.CreateWindowExW(0x80,'STATIC','Resize stability probe',0x90000004,350,150,1100,900,None,None,None,None)
    if not background: raise c.WinError()
    u.SetWindowPos(background,w.HWND(-1),350,150,1100,900,0x0040)
    u.UpdateWindow(background)
    u.SetWindowPos(hwnd,w.HWND(-1),0,0,0,0,0x0003)
    current = rect()
    if current[3]-current[1] < 100*scale:
        u.SetCursorPos(current[2]-round(18*scale),(current[1]+current[3])//2)
        time.sleep(.12)
        u.mouse_event(2,0,0,0,0);time.sleep(.03);u.mouse_event(4,0,0,0,0)
        time.sleep(.5)
    if rect()[3]-rect()[1] < 100*scale: raise RuntimeError('Card did not expand')
    for edge in a.edges:
        # UpdateLayeredWindow can leave Qt's cached size unchanged. Force a
        # distinct reset size first so the test-only SetWindowPos reset causes
        # a fresh content render instead of probing the previous smaller bitmap.
        u.SetWindowPos(hwnd,w.HWND(-1),500,220,round(503*scale),round(493*scale),0x0040)
        time.sleep(.2)
        u.SetWindowPos(hwnd,w.HWND(-1),500,220,round(500*scale),round(490*scale),0x0040)
        u.SetForegroundWindow(hwnd)
        time.sleep(.3)
        initial = rect()
        base, _, _ = snapshot()
        corner = '-' in edge
        offset = round(12*scale) if corner else 2
        x = initial[0]+offset if 'left' in edge else initial[2]-offset if 'right' in edge else (initial[0]+initial[2])//2
        y = initial[1]+offset if 'top' in edge else initial[3]-offset if 'bottom' in edge else (initial[1]+initial[3])//2
        if corner:
            # Test reference uses an 8px edge strip and 34px corner range.
            # (28, 4) is opaque on its round arc; (12, 12) is outside the strip.
            x = initial[0]+round(28*scale) if 'left' in edge else initial[2]-round(28*scale)
            y = initial[1]+round(4*scale) if 'top' in edge else initial[3]-round(4*scale)
        fixed = [i for i,name in enumerate(['left','top','right','bottom']) if name not in edge]
        u.SetCursorPos(x,y)
        time.sleep(.12)
        hit = u.WindowFromPoint(w.POINT(x,y))
        if hit != hwnd:
            raise RuntimeError(f'{edge}: pointer targets HWND {hit}, expected {hwnd}; window is occluded or pixel transparent')
        u.mouse_event(2,0,0,0,0)
        time.sleep(.05)
        samples = []
        for step in range(41):
            travel = round(step*6*scale)
            u.SetCursorPos(x + (travel if 'left' in edge else -travel if 'right' in edge else 0),
                           y + (travel if 'top' in edge else -travel if 'bottom' in edge else 0))
            time.sleep(.008)
            corners, painted, frame = snapshot()
            samples.append({'phase':'press' if step==0 else 'drag','corners':corners,'painted':painted,'rect':rect()})
            if step == 20: frame.save(a.output.with_name(edge+'-stable.png'))
        u.mouse_event(4,0,0,0,0)
        time.sleep(.1)
        corners,painted,_ = snapshot()
        samples.append({'phase':'release','corners':corners,'painted':painted,'rect':rect()})
        drift = max(abs(s['rect'][i]-initial[i]) for s in samples for i in fixed)
        shape = max(abs(v-base[i]) for s in samples for i,v in enumerate(s['corners']))
        moved = max(abs(samples[-1]['rect'][i]-initial[i]) for i in range(4))
        results[edge] = {'fixedDrift':drift,'cornerDeviation':shape,'travel':moved,'baseline':base,'samples':samples}
        print(edge, drift, shape, moved, flush=True)
finally:
    u.mouse_event(4,0,0,0,0)
    if background: u.DestroyWindow(background)
    screen_w, screen_h = u.GetSystemMetrics(0), u.GetSystemMetrics(1)
    restore_w, restore_h = min(round(380*scale),screen_w), min(round(490*scale),screen_h)
    restore_x = max(0,min(original[0],screen_w-restore_w))
    restore_y = max(0,min(original[1],screen_h-restore_h))
    u.SetWindowPos(hwnd,0,restore_x,restore_y,restore_w,restore_h,0x0044)
    a.output.write_text(json.dumps({'dpiScale':scale,'edges':results},indent=2),encoding='utf-8')
raise SystemExit(0 if len(results)==len(a.edges) and all(r['fixedDrift']==0 and r['cornerDeviation']<=2 and r['travel']>150 for r in results.values()) else 1)
