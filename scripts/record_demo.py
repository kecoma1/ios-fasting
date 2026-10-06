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
options = parser.parse_args()
run_dir = ROOT / "build" / ("demo-" + time.strftime("%Y%m%d-%H%M%S"))
run_dir.mkdir(parents=True)
output = ROOT / "docs" / "demo"
output.mkdir(parents=True, exist_ok=True)
raw_video = run_dir / "capture.mov"
video = output / "fasting-demo-es.mp4"
log_path = run_dir / "capture.log"
result = run_dir / "Capture.xcresult"


def run(*command):
    return subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)


run("python3", "scripts/create_project.py")
run("xcrun", "simctl", "ui", options.device, "appearance", "light")
recorder = None
done = False
dark = False
test = None
record_log = None
try:
    with log_path.open("w") as log:
        test = subprocess.Popen([
            "xcodebuild", "test", "-project", "iOSFasting.xcodeproj", "-scheme", "FastingDemo",
            "-destination", f"platform=iOS Simulator,id={options.device}",
            "-derivedDataPath", "build/DerivedData", "-resultBundlePath", str(result),
            "-parallel-testing-enabled", "NO", "-only-testing:FastingUITests/FastingDemoCapture/testCaptureDemo",
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
                print("Recording the Spanish walkthrough…", flush=True)
                run("xcrun", "simctl", "io", options.device, "screenshot", str(output / "poster.png"))
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
        "-metadata", "title=Fasting · demo en español", str(video))
    probe = json.loads(run("ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json", str(video)).stdout)
    duration = float(probe["format"]["duration"])
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
