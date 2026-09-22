#!/usr/bin/env python3
"""Print the xrandr command that lays out whatever DisplayPort monitors are on.

It prints rather than runs, so the layout can be read before it is applied.
bin/external.sh is what runs it.

Two things this got wrong on any setup that is not identical panels:

  * every monitor was assumed to be 2560x1440, so a screen that cannot do that
    mode was asked for it anyway;
  * each monitor was positioned at index * 2560, so the moment one of them was a
    different width, every screen after it sat in the wrong place, overlapping
    or leaving a gap.

Both come from the same shortcut, guessing the geometry rather than asking
xrandr, which already knows it. The preferred mode is the one xrandr marks with
'+', and each position is the running sum of the widths actually chosen.
"""
import re
import subprocess
import sys

# A connected output plus the indented mode lines that follow it, so each
# output's modes can be read without guessing where its block ends.
OUTPUT_RE = re.compile(
    r'^(?P<name>\S+) connected.*?$(?P<modes>(?:\n[ \t]+\d+x\d+.*)*)',
    re.MULTILINE,
)
# "   2560x1440     59.95*+  59.95": + marks preferred, * marks current.
MODE_RE = re.compile(r'^[ \t]+(?P<w>\d+)x(?P<h>\d+)(?P<rates>.*)$')


def preferred_mode(block):
    """The mode xrandr prefers for one output, as (width, height).

    Falls back to the first mode listed, which xrandr orders best first, and to
    None when the output lists no modes at all.
    """
    first = None
    for line in block.splitlines():
        m = MODE_RE.match(line)
        if not m:
            continue
        size = (int(m.group('w')), int(m.group('h')))
        if first is None:
            first = size
        if '+' in m.group('rates'):
            return size
    return first


def displays(xrandr_output):
    """Connected DisplayPort outputs in numeric order, with their modes."""
    found = []
    for m in OUTPUT_RE.finditer(xrandr_output):
        number = re.fullmatch(r'DisplayPort-(\d+)', m.group('name'))
        if not number:
            continue
        mode = preferred_mode(m.group('modes'))
        if mode is None:
            continue
        found.append((int(number.group(1)), m.group('name'), mode))
    # Sorted on the number rather than the name: DisplayPort-10 comes before
    # DisplayPort-2 alphabetically, which would order the screens wrongly on any
    # machine that reaches double digits.
    found.sort(key=lambda d: d[0])
    return found


def build_command(found):
    parts = ['xrandr', '--output', 'eDP', '--off']
    x = 0
    for i, (_, name, (width, height)) in enumerate(found):
        parts += ['--output', name, '--mode', f'{width}x{height}',
                  '--pos', f'{x}x0', '--rotate', 'normal']
        # The last one, which is the rightmost, stays primary as before.
        if i == len(found) - 1:
            parts.append('--primary')
        x += width
    return ' '.join(parts)


def main():
    try:
        result = subprocess.run(['xrandr'], stdout=subprocess.PIPE, check=True)
    except (OSError, subprocess.CalledProcessError) as err:
        print(f'could not run xrandr: {err}', file=sys.stderr)
        return 1

    found = displays(result.stdout.decode('utf-8', 'replace'))
    if not found:
        # On stderr, and a non-zero exit. This used to go to stdout, where the
        # caller was running whatever it printed as a command.
        print('No DisplayPort monitors found.', file=sys.stderr)
        return 1

    print(build_command(found))
    return 0


if __name__ == '__main__':
    sys.exit(main())
