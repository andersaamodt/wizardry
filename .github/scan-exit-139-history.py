#!/usr/bin/env python3
"""Scan recent PRs for exit code 139 evidence.

Uses PR descriptions (collect-failures output) when available.
Falls back to scanning workflow logs for the PR head SHA.
"""
from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
import time
import zipfile
from typing import Iterable
import urllib.request
import urllib.parse
import urllib.error

OWNER = "andersaamodt"
REPO = "wizardry"
API = "https://api.github.com"

PATTERN = re.compile(r"exit code 139|Segmentation fault|\b139\b", re.IGNORECASE)


def make_request(url: str, token: str | None = None) -> urllib.request.Request:
    headers = {"User-Agent": "wizardry-agent"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return urllib.request.Request(url, headers=headers)


def get_json(url: str, token: str | None = None):
    req = make_request(url, token)
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)


def iter_prs(limit: int, token: str | None = None) -> Iterable[dict]:
    collected = 0
    page = 1
    per_page = 100
    while collected < limit:
        url = f"{API}/repos/{OWNER}/{REPO}/pulls?state=all&per_page={per_page}&page={page}"
        data = get_json(url, token)
        if not data:
            break
        for pr in data:
            yield pr
            collected += 1
            if collected >= limit:
                return
        page += 1


def pr_has_failure_section(body: str) -> bool:
    return "## \ud83d\udd0d Latest Test Failures" in body


def scan_text(text: str) -> bool:
    return bool(PATTERN.search(text))


def scan_run_logs(run_id: int, token: str | None = None) -> bool:
    url = f"{API}/repos/{OWNER}/{REPO}/actions/runs/{run_id}/logs"
    req = make_request(url, token)
    try:
        with urllib.request.urlopen(req) as resp:
            data = resp.read()
    except urllib.error.HTTPError as exc:
        if exc.code == 403:
            raise PermissionError("403 forbidden while fetching workflow logs") from exc
        raise
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        for name in zf.namelist():
            if not name.endswith(".txt"):
                continue
            try:
                content = zf.read(name).decode("utf-8", errors="ignore")
            except Exception:
                continue
            if scan_text(content):
                return True
    return False


def scan_runs_for_sha(
    sha: str,
    token: str | None = None,
    max_runs: int = 5,
) -> tuple[bool, list[int], str | None]:
    url = f"{API}/repos/{OWNER}/{REPO}/actions/runs?head_sha={sha}&per_page={max_runs}"
    data = get_json(url, token)
    runs = data.get("workflow_runs", [])
    run_ids = []
    for run in runs:
        run_id = run.get("id")
        if run_id is None:
            continue
        run_ids.append(run_id)
        try:
            if scan_run_logs(run_id, token):
                return True, run_ids, None
        except PermissionError as exc:
            return False, run_ids, str(exc)
        time.sleep(0.5)
    return False, run_ids, None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=150, help="Number of recent PRs to scan")
    parser.add_argument("--max-runs", type=int, default=5, help="Max workflow runs to scan per PR when logs needed")
    parser.add_argument("--output", default="/tmp/exit-139-scan.json", help="Write JSON results to file")
    args = parser.parse_args()

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")

    results = []
    first_hit = None

    prs = list(iter_prs(args.limit, token))
    prs_sorted = sorted(prs, key=lambda p: p["number"])  # ascending

    for pr in prs_sorted:
        number = pr["number"]
        body = pr.get("body") or ""
        head_sha = (pr.get("head") or {}).get("sha")
        entry = {
            "pr": number,
            "has_failure_section": pr_has_failure_section(body),
            "body_hit": False,
            "logs_scanned": False,
            "log_hit": False,
            "run_ids": [],
            "log_error": None,
        }
        if entry["has_failure_section"]:
            entry["body_hit"] = scan_text(body)
            if entry["body_hit"] and first_hit is None:
                first_hit = number
        else:
            if head_sha:
                hit, run_ids, log_error = scan_runs_for_sha(head_sha, token, args.max_runs)
                entry["logs_scanned"] = True
                entry["log_hit"] = hit
                entry["run_ids"] = run_ids
                entry["log_error"] = log_error
                if hit and first_hit is None:
                    first_hit = number
        results.append(entry)

    output = {
        "limit": args.limit,
        "max_runs": args.max_runs,
        "first_hit": first_hit,
        "range": {
            "min": prs_sorted[0]["number"] if prs_sorted else None,
            "max": prs_sorted[-1]["number"] if prs_sorted else None,
        },
        "results": results,
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)

    print(json.dumps({"first_hit": first_hit, "range": output["range"], "output": args.output}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
