"""Interactively drag the running app left edge and record native geometry (Windows)."""
import argparse, ctypes as c, json, time
from PIL import ImageGrab
from ctypes import wintypes as w
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument("--pid",type=int,required=True)
parser.add_argument("--output",type=Path,required=True)
a=parser.parse_args()
u=c.WinDLL("user32",use_last_error=True)
u.SetProcessDpiAwarenessContext.argtypes=[c.c_void_p]
u.SetProcessDpiAwarenessContext(c.c_void_p(-4))
u.GetWindowRect.argtypes=[w.HWND,c.POINTER(w.RECT)]
u.SetWindowPos.argtypes=[w.HWND,w.HWND,c.c_int,c.c_int,c.c_int,c.c_int,c.c_uint]
u.SetForegroundWindow.argtypes=[w.HWND]
u.GetWindowThreadProcessId.argtypes=[w.HWND,c.POINTER(w.DWORD)]
u.GetDpiForWindow.argtypes=[w.HWND]
handles=[]
callback=c.WINFUNCTYPE(w.BOOL,w.HWND,w.LPARAM)
@callback
def visit(h,l):
    pid=w.DWORD();u.GetWindowThreadProcessId(h,c.byref(pid))
    name=c.create_unicode_buffer(256);u.GetClassNameW(h,name,256)
    if pid.value==a.pid and u.IsWindowVisible(h) and "QWindow" in name.value: handles.append(h)
    return True
u.EnumWindows(visit,0)
if not handles: raise SystemExit("No visible Qt window for PID")
h=handles[0]
u.CreateWindowExW.argtypes=[w.DWORD,w.LPCWSTR,w.LPCWSTR,w.DWORD,c.c_int,c.c_int,c.c_int,c.c_int,w.HWND,w.HMENU,w.HINSTANCE,c.c_void_p]
u.CreateWindowExW.restype=w.HWND
u.DestroyWindow.argtypes=[w.HWND]
background=u.CreateWindowExW(0x80,"STATIC","Resize probe background",0x90000004,400,180,1000,800,None,None,None,None)
u.SetWindowPos(background,w.HWND(-1),400,180,1000,800,0x0040)
u.SetWindowPos(h,w.HWND(-1),0,0,0,0,0x0003)
def rect():
    r=w.RECT();u.GetWindowRect(h,c.byref(r));return [r.left,r.top,r.right,r.bottom]
def click(x,y):
    u.SetCursorPos(x,y);u.mouse_event(2,0,0,0,0);time.sleep(.03);u.mouse_event(4,0,0,0,0)
dpi=u.GetDpiForWindow(h)/96
u.SetForegroundWindow(h)
r=rect()
u.SetWindowPos(h,0,450,220,round(600*dpi),r[3]-r[1],0x0044)
time.sleep(.35)
r=rect()
if r[3]-r[1]<100:
    click(r[0]+round(50*dpi),(r[1]+r[3])//2);time.sleep(.5)
r=rect()
if r[3]-r[1]<100: raise SystemExit("Expand card before running resize probe")
u.SetWindowPos(h,0,450,220,round(500*dpi),round(490*dpi),0x0044)
time.sleep(.3)
r=rect();x=r[0]+2;y=(r[1]+r[3])//2
samples=[{"rect":r,"cursor":x}]
scanLeft=r[2]-80
scanRight=r[2]+80
scanY=y
painted=[]
u.SetCursorPos(x,y);u.mouse_event(2,0,0,0,0);time.sleep(.1)
try:
    for step in range(1,121):
        px=x+round(step*4*dpi);u.SetCursorPos(px,y);time.sleep(.016)
        samples.append({"rect":rect(),"cursor":px})
        frame=ImageGrab.grab(bbox=(scanLeft,scanY,scanRight,scanY+1))
        pixels=[frame.getpixel((i,0)) for i in range(frame.width)]
        edges=[scanLeft+i for i,p in enumerate(pixels) if max(p[:3])>25]
        if edges: painted.append(max(edges))
finally:
    u.mouse_event(4,0,0,0,0)
    u.DestroyWindow(background)
rights=[s["rect"][2] for s in samples]
result={"paintedRightRangePx":max(painted)-min(painted) if painted else None,"paintedRightEdges":painted,"dpiScale":dpi,"rightEdgeRangePx":max(rights)-min(rights),"samples":samples}
a.output.parent.mkdir(parents=True,exist_ok=True)
a.output.write_text(json.dumps(result,indent=2))
print(json.dumps({"dpiScale":dpi,"rightEdgeRangePx":result["rightEdgeRangePx"],"paintedRightRangePx":result["paintedRightRangePx"],"start":samples[0]["rect"],"end":samples[-1]["rect"]}))
if samples[-1]["rect"][0]<=samples[0]["rect"][0]+100: raise SystemExit("Drag did not exercise left resizing")
raise SystemExit(0 if result["rightEdgeRangePx"]<=1 else 1)
