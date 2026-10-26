#!/usr/bin/env python3
"""Export named, successful XCUITest screenshots without UUID filenames."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('result', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
if args.output.exists():
    parser.error('Output already exists; choose a new directory to avoid mixing runs.')
with tempfile.TemporaryDirectory(prefix='rundiary-ui-export-') as temporary:
    subprocess.run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(args.result),
                    '--output-path', temporary], check=True)
    manifest = json.loads((Path(temporary) / 'manifest.json').read_text())
    selected = {}
    for test in manifest:
        for attachment in test.get('attachments', []):
            name = attachment.get('suggestedHumanReadableName', '')
            match = re.match(r'^(\d{2}-[a-z0-9-]+)_', name)
            if match and not attachment.get('isAssociatedWithFailure'):
                filename = match[1] + '.png'
                if filename in selected:
                    parser.error(f'Duplicate capture {filename}; export one test run at a time.')
                selected[filename] = Path(temporary) / attachment['exportedFileName']
    if not selected:
        parser.error('No named successful screenshots found.')
    args.output.mkdir(parents=True)
    for filename, source in sorted(selected.items()):
        shutil.copyfile(source, args.output / filename)
    print(f'Exported {len(selected)} screenshots to {args.output}')
