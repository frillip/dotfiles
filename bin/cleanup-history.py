#!/usr/bin/env python
"""
Edits history to deduplicate, leaving the last occurrence of each command. Also normalises whitespace.

To install, add this to .bashrc:

    trap "~/.local/bin/cleanup-history.py ~/.bash_history" EXIT

"""
from sys import argv

history_file = argv[1]

with open(history_file) as f:
    lines = [line.strip() for line in f]

seen = set()
new_lines = list()

# note that reversed() does not copy lines, just results in reversed iteration
for line in reversed(lines):
    line = ' '.join(line.split())  # remove multiple whitespace
    if line not in seen:
        new_lines.append(line)
        seen.add(line)

new_lines.reverse()

with open(history_file, "w") as f:
    for line in new_lines:
        f.write(line + "\n")