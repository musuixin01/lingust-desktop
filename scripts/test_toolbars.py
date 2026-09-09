"""Run real QML toolbar components against a UI-only state fixture."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--qt-bin", type=Path, required=True)
parser.add_argument("--ui-root", type=Path, help="Optional pre-build QML copy for before/after regression checks")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
ui_root = args.ui_root or root / "ui"
output = root / "build" / "toolbar-check"
output.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env["QT_QUICK_CONTROLS_STYLE"] = "Basic"
env["QT_QPA_FONTDIR"] = str(Path(os.environ["WINDIR"]) / "Fonts")
env["PATH"] = str(root / "build" / "bin") + os.pathsep + str(args.qt_bin) + os.pathsep + env["PATH"]
with tempfile.TemporaryDirectory(prefix="linguist-toolbar-") as temp:
    stage = Path(temp)
    for folder in ["components", "card", "pill"]:
        for source in (ui_root / folder).glob("*.qml"):
            text = source.read_text(encoding="utf-8").replace("import Linguist\n", "")
            text = text.replace("qrc:/qt/qml/Linguist/resources/", (root / "resources").as_uri() + "/")
            (stage / source.name).write_text(text, encoding="utf-8")
    (stage / "qmldir").write_text("singleton DesignTokens 1.0 DesignTokens.qml\n", encoding="utf-8")
    for source in (root / "tests" / "qml").glob("tst_*.qml"):
        shutil.copy2(source, stage / source.name)
    result = subprocess.run([str(args.qt_bin / "qmltestrunner.exe"), "-input", str(stage), "-platform", "offscreen", "-o", str(output / "results.txt") + ",txt"], env=env, cwd=output)
    report = output / "results.txt"
    if report.exists():
        print(report.read_text(encoding="utf-8", errors="replace"))
    raise SystemExit(result.returncode)
