#!/usr/bin/env python3
"""Build the English README GIF and device composition from the recorded app."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
VIDEO = ROOT / "docs" / "demo" / "fasting-demo-en.mp4"
ASSETS.mkdir(parents=True, exist_ok=True)


def run(*command):
    subprocess.run(command, cwd=ROOT, check=True)


metadata = json.loads((ROOT / "docs" / "demo" / "fasting-demo-en.json").read_text())
assert metadata["language"] == "en"
for filename in ["fasting-timer-en.png", "fasting-history-en.png", "fasting-editor-en.png", "fasting-settings-en.png", "fasting-dark-en.png"]:
    if not (ASSETS / filename).exists():
        raise FileNotFoundError(f"Missing {filename}; first run scripts/record_demo.py --language en.")

# A brief excerpt of the same real walkthrough, with cuts and 1.25x playback.
segments = [(metadata["frames"][name], min(metadata["frames"][name] + 3, metadata["duration"]))
            for name in ["timer", "guide", "history", "editor", "settings", "multiday", "ketones", "dark"]]
count = len(segments)
filters = [f"[0:v]split={count}" + "".join(f"[v{i}]" for i in range(count))]
for i, (start, end) in enumerate(segments):
    filters.append(f"[v{i}]trim=start={start}:end={end},setpts=(PTS-STARTPTS)/1.25[s{i}]")
filters.append("".join(f"[s{i}]" for i in range(count)) + f"concat=n={count}:v=1:a=0[sequence]")
filters.extend([
    "[sequence]fps=8,scale=360:-2:flags=lanczos,split[colors][frames]",
    "[colors]palettegen=max_colors=128:stats_mode=diff[palette]",
    "[frames][palette]paletteuse=dither=bayer:bayer_scale=3[gif]"
])
run("ffmpeg", "-y", "-loglevel", "error", "-i", str(VIDEO), "-filter_complex", ";".join(filters),
    "-map", "[gif]", "-loop", "0", str(ASSETS / "fasting-demo-en.gif"))
run("swift", "scripts/draw_readme.swift")
print("Created README assets from the real English simulator recording.")
