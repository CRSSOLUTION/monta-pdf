#!/usr/bin/env python3
"""Converts Xcode code coverage (.xcresult) to SonarQube generic coverage XML.

Usage: xccov-to-sonar.py <TestResults.xcresult> <repo-root> > coverage.xml
"""
import os
import re
import subprocess
import sys
from xml.sax.saxutils import quoteattr

result, root = sys.argv[1], os.path.abspath(sys.argv[2])


def xccov(*args):
    return subprocess.run(
        ["xcrun", "xccov", "view", "--archive", *args, result],
        check=True, capture_output=True, text=True,
    ).stdout


print('<coverage version="1">')
for path in xccov("--file-list").splitlines():
    path = path.strip()
    # Only the app's own sources (not tests, not generated files).
    if not path.endswith(".swift") or "/MontaPDF/MontaPDF/" not in path or "DerivedData" in path:
        continue
    relative = os.path.relpath(path, root) if path.startswith(root) else path[path.index("MontaPDF/MontaPDF/"):]
    lines = []
    for line in xccov("--file", path).splitlines():
        match = re.match(r"\s*(\d+):\s*(\*|\d+)", line)
        if match and match.group(2) != "*":
            covered = "true" if int(match.group(2)) > 0 else "false"
            lines.append(f'    <lineToCover lineNumber="{match.group(1)}" covered="{covered}"/>')
    if lines:
        print(f"  <file path={quoteattr(relative)}>")
        print("\n".join(lines))
        print("  </file>")
print("</coverage>")
