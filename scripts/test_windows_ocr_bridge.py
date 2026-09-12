"""Fast integration check for the Windows OCR process bridge."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
BRIDGE = ROOT / "platform" / "windows" / "ocr" / "SystemOcrBridge.ps1"


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="lingust-ocr-") as temp_dir:
        temp_path = Path(temp_dir)
        image_path = temp_path / "ocr-fixture.png"
        image = Image.new("RGB", (900, 180), "white")
        draw = ImageDraw.Draw(image)
        font = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 72)
        draw.text((32, 42), "SCREENSHOT 4827", fill="black", font=font)
        image.save(image_path)

        result = subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-NonInteractive",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(BRIDGE),
                "-ImagePath",
                str(image_path),
                "-LanguageTag",
                "en-US",
            ],
            capture_output=True,
            text=True,
            encoding="utf-8-sig",
            timeout=15,
        )

        assert result.returncode == 0, result.stderr.strip() or "OCR bridge failed"
        payload = json.loads(result.stdout.strip())
        assert payload["ok"] is True, payload
        normalized = payload["text"].upper().replace(" ", "")
        assert "SCREENSHOT4827" in normalized, payload

        small_path = temp_path / "small-dark-text.png"
        small = Image.new("RGB", (360, 46), (15, 23, 42))
        small_draw = ImageDraw.Draw(small)
        small_font = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 12)
        small_draw.text((14, 11), "have dreams in our hearts.",
                        fill=(150, 160, 176), font=small_font)
        small.save(small_path)
        small_result = subprocess.run(
            ["powershell.exe", "-NoProfile", "-NonInteractive",
             "-ExecutionPolicy", "Bypass", "-File", str(BRIDGE),
             "-ImagePath", str(small_path), "-LanguageTag", "en-US"],
            capture_output=True, text=True, encoding="utf-8-sig", timeout=15,
        )
        assert small_result.returncode == 0, small_result.stderr.strip()
        small_payload = json.loads(small_result.stdout.strip())
        small_text = small_payload["text"].lower().replace(" ", "")
        assert "havedreamsinourhearts" in small_text, small_payload

    print("PASS: Windows OCR recognized large and small dark screenshot fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
