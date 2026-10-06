#!/usr/bin/env python3
"""Refresh the English three-tab gallery from the real app without recording a video."""
import argparse
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--device", required=True, help="Already booted dedicated simulator UDID")
options = parser.parse_args()
run_dir = ROOT / "build" / ("readme-" + time.strftime("%Y%m%d-%H%M%S"))
run_dir.mkdir(parents=True)
log_path = run_dir / "capture.log"
result = run_dir / "Capture.xcresult"


def run(*command):
    return subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, text=True)


run("python3", "scripts/create_project.py")
test = None
try:
    run("xcrun", "simctl", "ui", options.device, "appearance", "light")
    run("xcrun", "simctl", "status_bar", options.device, "override", "--time", "9:41",
        "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3",
        "--cellularMode", "active", "--cellularBars", "4", "--batteryState", "charged", "--batteryLevel", "100")
    with log_path.open("w") as log:
        test = subprocess.Popen([
            "xcodebuild", "test", "-project", "iOSFasting.xcodeproj", "-scheme", "FastingDemo",
            "-destination", f"platform=iOS Simulator,id={options.device}",
            "-derivedDataPath", "build/LastMealDerivedData", "-resultBundlePath", str(result),
            "-parallel-testing-enabled", "NO",
            "-only-testing:FastingUITests/FastingDemoCapture/testCaptureThreeTabScreens",
            "CODE_SIGNING_ALLOWED=NO"
        ], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        print(f"Capturing the three tabs. Log: {log_path}", flush=True)
        deadline = time.monotonic() + 300
        dark = False
        while test.poll() is None:
            if time.monotonic() > deadline:
                raise TimeoutError(f"The capture exceeded five minutes. Read {log_path}.")
            if not dark and "FASTING_DEMO_DARK" in log_path.read_text(errors="replace"):
                run("xcrun", "simctl", "ui", options.device, "appearance", "dark")
                dark = True
            time.sleep(0.25)
        if test.returncode != 0 or "FASTING_DEMO_DONE" not in log_path.read_text(errors="replace"):
            raise RuntimeError(f"Capture did not finish successfully. Read {log_path}.")

    attachments = run_dir / "attachments"
    run("xcrun", "xcresulttool", "export", "attachments", "--path", str(result), "--output-path", str(attachments))
    gallery = {"timer": "fasting-timer-en.png", "history": "fasting-history-en.png",
               "meal": "last-meal-en.png", "meal-dark": "last-meal-dark-en.png", "dark": "fasting-dark-en.png"}
    exported = set()
    for test_info in json.loads((attachments / "manifest.json").read_text()):
        for attachment in test_info["attachments"]:
            for name, filename in gallery.items():
                if attachment["suggestedHumanReadableName"].startswith(f"readme-{name}-en_"):
                    destination = ROOT / "docs" / "assets" / filename
                    run("ffmpeg", "-y", "-loglevel", "error", "-i", str(attachments / attachment["exportedFileName"]),
                        "-vf", "scale=720:-2", "-frames:v", "1", str(destination))
                    exported.add(name)
    if exported != set(gallery):
        raise RuntimeError(f"Missing gallery frames: {set(gallery) - exported}")
    run("swift", "scripts/draw_readme.swift")
    print("Saved the English gallery and three-iPhone cover.", flush=True)
finally:
    if test and test.poll() is None:
        test.terminate()
        try:
            test.wait(timeout=15)
        except subprocess.TimeoutExpired:
            test.kill()
            test.wait(timeout=15)
    run("xcrun", "simctl", "ui", options.device, "appearance", "light")
    run("xcrun", "simctl", "status_bar", options.device, "clear")
