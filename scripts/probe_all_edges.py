"""Drag all four native edges and sample painted edges over a black background (Windows)."""
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
if not background: raise c.WinError(c.get_last_error())
u.SetWindowPos(background,w.HWND(-1),400,180,1000,800,0x0040)
u.UpdateWindow.argtypes=[w.HWND]
u.UpdateWindow(background)
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
results={}
try:
    for edge in ["left","right","top","bottom"]:
        u.SetWindowPos(h,0,450,220,round(500*dpi),round(490*dpi),0x0044)
        time.sleep(.25)
        initial=rect()
        axis=0 if edge in ["left","right"] else 1
        moving={"left":0,"top":1,"right":2,"bottom":3}[edge]
        fixed=(moving+2)%4
        x=initial[moving]+(2 if moving<2 else -2) if axis==0 else (initial[0]+initial[2])//2
        y=initial[moving]+(2 if moving<2 else -2) if axis==1 else (initial[1]+initial[3])//2
        u.SetCursorPos(x,y);u.mouse_event(2,0,0,0,0);time.sleep(.05)
        samples=[]
        for step in range(1,61):
            offset=round(step*3*dpi)*(1 if moving<2 else -1)
            u.SetCursorPos(x+offset if axis==0 else x,y+offset if axis==1 else y)
            time.sleep(.016)
            geometry=rect()
            # Scan away from the pointer, over the black probe background.
            if axis==0:
                scan=(400,geometry[1]+80,1400,geometry[1]+81)
            else:
                scan=(geometry[0]+80,180,geometry[0]+81,980)
            frame=ImageGrab.grab(bbox=scan)
            if step==30:
                ImageGrab.grab().save(str(a.output.parent / (edge+"-probe.png")))
            bg=frame.getpixel((0,0))[:3]
            values=[max(abs(p-b) for p,b in zip(frame.getpixel((i,0) if axis==0 else (0,i))[:3],bg)) for i in range(frame.width if axis==0 else frame.height)]
            painted=[i for i,v in enumerate(values) if v>10]
            paint=(min(painted) if moving<2 else max(painted)+1)+(scan[0] if axis==0 else scan[1]) if painted else None
            samples.append({"rect":geometry,"painted":paint,"paintError":None if paint is None else paint-geometry[moving]})
        u.mouse_event(4,0,0,0,0)
        results[edge]={"fixedDrift":max(abs(s["rect"][fixed]-initial[fixed]) for s in samples),"travel":abs(samples[-1]["rect"][moving]-initial[moving]),"maxPaintError":max(abs(s["paintError"]) for s in samples if s["paintError"] is not None),"samples":samples}
finally:
    u.mouse_event(4,0,0,0,0)
    u.DestroyWindow(background)
    u.SetWindowPos(h,0,550,220,round(380*dpi),round(490*dpi),0x0044)
a.output.parent.mkdir(parents=True,exist_ok=True)
a.output.write_text(json.dumps(results,indent=2))
print(json.dumps({e:{k:v for k,v in r.items() if k!="samples"} for e,r in results.items()}))
raise SystemExit(0 if all(r["travel"]>100 and r["fixedDrift"]<=1 and r["maxPaintError"]<=1 for r in results.values()) else 1)
