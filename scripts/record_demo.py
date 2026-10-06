#!/usr/bin/env python3
"""Record the real app through XCTest, using an isolated example database."""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--device", default="26647DE8-12B7-4160-806C-BF49265DD70F", help="Dedicated simulator UDID")
parser.add_argument("--language", choices=["en", "es"], default="en", help="Recording language (README assets use English)")
options = parser.parse_args()
run_dir = ROOT / "build" / ("demo-" + time.strftime("%Y%m%d-%H%M%S"))
run_dir.mkdir(parents=True)
output = ROOT / "docs" / "demo"
output.mkdir(parents=True, exist_ok=True)
raw_video = run_dir / "capture.mov"
video = output / f"fasting-demo-{options.language}.mp4"
log_path = run_dir / "capture.log"
result = run_dir / "Capture.xcresult"


def run(*command):
    return subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


run("python3", "scripts/create_project.py")
run("xcrun", "simctl", "ui", options.device, "appearance", "light")
run("xcrun", "simctl", "status_bar", options.device, "override", "--time", "9:41",
    "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3",
    "--cellularMode", "active", "--cellularBars", "4", "--batteryState", "charged", "--batteryLevel", "100")
recorder = None
done = False
dark = False
test = None
record_log = None
record_started = None
frame_times = {}
test_method = "testCaptureEnglishDemo" if options.language == "en" else "testCaptureDemo"
try:
    with log_path.open("w") as log:
        test = subprocess.Popen([
            "xcodebuild", "test", "-project", "iOSFasting.xcodeproj", "-scheme", "FastingDemo",
            "-destination", f"platform=iOS Simulator,id={options.device}",
            "-derivedDataPath", "build/DerivedData", "-resultBundlePath", str(result),
            "-parallel-testing-enabled", "NO", f"-only-testing:FastingUITests/FastingDemoCapture/{test_method}",
            "CODE_SIGNING_ALLOWED=NO"
        ], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        print(f"Preparing the app. Log: {log_path}", flush=True)
        deadline = time.monotonic() + 900
        while test.poll() is None:
            if time.monotonic() > deadline:
                raise TimeoutError("The capture exceeded 15 minutes; check capture.log.")
            contents = log_path.read_text(errors="replace")
            if "FASTING_DEMO_READY" in contents and recorder is None:
                record_log = (run_dir / "recording.log").open("w")
                recorder = subprocess.Popen([
                    "xcrun", "simctl", "io", options.device, "recordVideo", "--codec=h264", str(raw_video)
                ], stdout=record_log, stderr=subprocess.STDOUT)
                record_started = time.monotonic()
                print(f"Recording the {options.language.upper()} walkthrough…", flush=True)
            if record_started is not None:
                for name in ["timer", "guide", "history", "editor", "settings", "multiday", "ketones", "goal", "multiday-history", "dark"]:
                    marker = "FASTING_DEMO_FRAME_" + name.upper()
                    if marker in contents and name not in frame_times:
                        frame_times[name] = max(0, time.monotonic() - record_started)
            if "FASTING_DEMO_DARK" in contents and not dark:
                run("xcrun", "simctl", "ui", options.device, "appearance", "dark")
                dark = True
                print("Recording dark mode…", flush=True)
            if "FASTING_DEMO_DONE" in contents and not done:
                done = True
                if recorder and recorder.poll() is None:
                    recorder.send_signal(signal.SIGINT)
                    recorder.wait(timeout=30)
                print("Walkthrough recorded. Finalizing the test result…", flush=True)
            time.sleep(0.25)
        if test.returncode != 0 or not done:
            raise RuntimeError(f"Capture did not complete successfully. Read {log_path}.")
        if not raw_video.exists():
            raise RuntimeError("No recording was produced.")
    run("ffmpeg", "-y", "-i", str(raw_video), "-vf", "scale=720:-2,fps=30", "-c:v", "libx264",
        "-preset", "medium", "-crf", "22", "-pix_fmt", "yuv420p", "-an", "-movflags", "+faststart",
        "-metadata", f"title=Fasting · {options.language.upper()} walkthrough", str(video))
    probe = json.loads(run("ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(video)).stdout)
    duration = float(probe["format"]["duration"])
    (output / f"fasting-demo-{options.language}.json").write_text(json.dumps({
        "language": options.language, "video": video.name, "duration": duration, "frames": frame_times
    }, indent=2) + "\n")

    # Gallery frames come from named XCTest attachments, not fragile video offsets.
    attachments = run_dir / "attachments"
    run("xcrun", "xcresulttool", "export", "attachments", "--path", str(result), "--output-path", str(attachments))
    gallery = {
        "timer": "fasting-timer-en.png", "history": "fasting-history-en.png", "editor": "fasting-editor-en.png",
        "settings": "fasting-settings-en.png", "dark": "fasting-dark-en.png", "guide": "milestones-guide-en.png",
        "multiday": "milestones-multiday-en.png", "ketones": "milestones-ketones-en.png",
        "goal": "goal-multiday-en.png", "multiday-history": "history-multiday-en.png"
    }
    exported = set()
    for test_info in json.loads((attachments / "manifest.json").read_text()):
        for attachment in test_info["attachments"]:
            for name, filename in gallery.items():
                prefix = f"readme-{name}-{options.language}_"
                if attachment["suggestedHumanReadableName"].startswith(prefix):
                    destination = ROOT / "docs" / "assets" / (filename if options.language == "en" else f"readme-{name}-es.png")
                    run("ffmpeg", "-y", "-loglevel", "error", "-i", str(attachments / attachment["exportedFileName"]),
                        "-vf", "scale=720:-2", "-frames:v", "1", str(destination))
                    exported.add(name)
    if exported != set(gallery):
        raise RuntimeError(f"Missing gallery frames: {set(gallery) - exported}")
    print(f"Saved {video} · {duration:.1f}s · {video.stat().st_size / 1_000_000:.1f} MB", flush=True)
finally:
    if test and test.poll() is None:
        test.terminate()
        try: test.wait(timeout=15)
        except subprocess.TimeoutExpired: test.kill()
    if recorder and recorder.poll() is None:
        recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=30)
    if record_log:
        record_log.close()
    run("xcrun", "simctl", "ui", options.device, "appearance", "light")
    run("xcrun", "simctl", "status_bar", options.device, "clear")
