#!/usr/bin/env python
"""Edits history to deduplicate, leaving the last occurance or each line"""
from os import path

history_file = path.expanduser("~/.history")

with open(history_file) as f:
    lines = [line.strip() for line in f]

seen = set()
lines.reverse()
new_lines = list()

for line in lines:
    if line not in seen:
        new_lines.append(line)
        seen.add(line)

new_lines.reverse()

with open(history_file, "w") as f:
    for line in new_lines:
        f.write(line + "\n")
