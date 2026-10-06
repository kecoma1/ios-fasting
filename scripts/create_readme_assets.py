#!/usr/bin/env python3
"""Build the README gallery, short GIF and device composition from the recorded app."""
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
VIDEO = ROOT / "docs" / "demo" / "fasting-demo-es.mp4"
ASSETS.mkdir(parents=True, exist_ok=True)


def run(*command):
    subprocess.run(command, cwd=ROOT, check=True)


shutil.copyfile(ROOT / "docs" / "demo" / "poster.png", ASSETS / "fasting-timer.png")
for name, seconds in [("history", 39), ("editor", 48), ("settings", 90), ("dark", 104)]:
    run("ffmpeg", "-y", "-loglevel", "error", "-ss", str(seconds), "-i", str(VIDEO),
        "-frames:v", "1", str(ASSETS / f"fasting-{name}.png"))

# A brief excerpt of the same real walkthrough, with cuts and 1.25x playback.
segments = [(0, 3), (11, 16), (21, 25), (36, 40), (47, 50), (89, 93), (102, 107)]
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
    "-map", "[gif]", "-loop", "0", str(ASSETS / "fasting-demo.gif"))
run("swift", "scripts/draw_readme.swift")
print("Created README assets from the real Spanish simulator recording.")
