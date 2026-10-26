"""Validate GitHub CI and TestFlight evidence before any Apple-side mutation."""
import argparse
import json
import re
from pathlib import Path


def require_sha(sha):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Expected a full lowercase commit SHA")


def verify_ci(payload, sha):
    require_sha(sha)
    runs = [r for r in payload["workflow_runs"]
            if r.get("head_sha") == sha and r.get("head_branch") == "main"
            and r.get("event") in ("push", "workflow_dispatch")
            and r.get("path") == ".github/workflows/build-and-test.yml"]
    if not runs:
        raise ValueError("No main CI run exists for this candidate SHA")
    latest = max(runs, key=lambda r: (r["id"], r["run_attempt"]))
    if latest.get("status") != "completed" or latest.get("conclusion") != "success":
        raise ValueError("Latest candidate CI is not successful")


def verify_testflight_run(run, run_id):
    if (str(run.get("id")) != run_id or run.get("status") != "completed"
            or run.get("conclusion") != "success"
            or run.get("event") != "workflow_dispatch"
            or run.get("path") != ".github/workflows/testflight.yml"
            or run.get("head_branch") != "main"):
        raise ValueError("Expected the specified successful manual TestFlight run on main")


def verify_identity(identity, run, sha, version, build):
    require_sha(sha)
    if not re.fullmatch(r"\d+\.\d+\.\d+", version) or not re.fullmatch(r"\d+", build):
        raise ValueError("Invalid app version/build")
    expected = {"sha": sha, "version": version, "build": build,
                "run_id": str(run["id"]), "run_attempt": str(run["run_attempt"])}
    if identity != expected:
        raise ValueError("Artifact does not match source/version/build and the current upload attempt")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["ci", "run", "identity"])
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--sha")
    parser.add_argument("--run")
    parser.add_argument("--run-id")
    parser.add_argument("--version")
    parser.add_argument("--build")
    args = parser.parse_args()
    evidence = json.loads(Path(args.evidence).read_text())
    if args.mode == "ci":
        verify_ci(evidence, args.sha)
    elif args.mode == "run":
        verify_testflight_run(evidence, args.run_id)
    else:
        run = json.loads(Path(args.run).read_text())
        verify_testflight_run(run, args.run_id)
        verify_identity(evidence, run, args.sha, args.version, args.build)
    print("Delivery evidence verified")


if __name__ == "__main__":
    main()
