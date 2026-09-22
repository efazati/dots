#!/usr/bin/env python3
"""Checks for auto-ext.py, against captured xrandr output.

    python3 bin/test_auto_ext.py

No framework and no dependencies, because the point is that it runs anywhere
this repo is checked out, including on a machine with no monitors attached at
all, which is exactly where the layout is hardest to reason about.
"""
import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('auto_ext', HERE / 'auto-ext.py')
auto_ext = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auto_ext)

SAME = """Screen 0: minimum 320 x 200, current 5120 x 1440, maximum 16384 x 16384
eDP connected 1920x1080+0+0 (normal left inverted right x axis y axis) 344mm x 194mm
   1920x1080     60.00*+  59.97
DisplayPort-0 connected 2560x1440+0+0 (normal) 597mm x 336mm
   2560x1440     59.95*+  99.95
   1920x1080     60.00
DisplayPort-1 connected 2560x1440+2560+0 (normal) 597mm x 336mm
   2560x1440     59.95*+
   1920x1080     60.00
HDMI-A-0 disconnected (normal left inverted right x axis y axis)
"""

MIXED = """Screen 0: minimum 320 x 200, current 6400 x 1440, maximum 16384 x 16384
DisplayPort-0 connected 2560x1440+0+0 (normal) 597mm x 336mm
   2560x1440     59.95*+
   1920x1080     60.00
DisplayPort-1 connected 1920x1080+2560+0 (normal) 527mm x 296mm
   1920x1080     60.00*+
   1280x1024     75.02
DisplayPort-10 connected 1920x1080+4480+0 (normal) 527mm x 296mm
   1920x1080     60.00*+
"""

LAPTOP_ONLY = """Screen 0: minimum 320 x 200, current 1920 x 1080, maximum 16384 x 16384
eDP connected primary 1920x1080+0+0 (normal) 344mm x 194mm
   1920x1080     60.00*+
"""

failures = []


def check(name, got, want):
    if got != want:
        failures.append(f'{name}\n     got: {got}\n    want: {want}')
    else:
        print(f'  ok  {name}')


# Two identical panels, which is the setup this was written on. The output has
# to be what it always was, or this change is a regression dressed as a fix.
check(
    'two matching panels lay out unchanged',
    auto_ext.build_command(auto_ext.displays(SAME)),
    'xrandr --output eDP --off '
    '--output DisplayPort-0 --mode 2560x1440 --pos 0x0 --rotate normal '
    '--output DisplayPort-1 --mode 2560x1440 --pos 2560x0 --rotate normal --primary',
)

# The case the old code got wrong: it forced 2560x1440 on all three and placed
# them at 0, 2560 and 5120, so the third overlapped the second by 640px.
check(
    'mixed resolutions use real modes and real offsets',
    auto_ext.build_command(auto_ext.displays(MIXED)),
    'xrandr --output eDP --off '
    '--output DisplayPort-0 --mode 2560x1440 --pos 0x0 --rotate normal '
    '--output DisplayPort-1 --mode 1920x1080 --pos 2560x0 --rotate normal '
    '--output DisplayPort-10 --mode 1920x1080 --pos 4480x0 --rotate normal --primary',
)

# DisplayPort-10 sorts before DisplayPort-2 as a string, which would put the
# screens in the wrong order on any machine that gets that far.
check(
    'outputs order by number, not by name',
    [name for _, name, _ in auto_ext.displays(MIXED)],
    ['DisplayPort-0', 'DisplayPort-1', 'DisplayPort-10'],
)

check('the laptop panel alone is not a DisplayPort layout',
      auto_ext.displays(LAPTOP_ONLY), [])

check('preferred mode wins over the first listed',
      auto_ext.preferred_mode('\n   3840x2160     30.00\n   2560x1440     59.95*+\n'),
      (2560, 1440))

if failures:
    print('\nFAILED:')
    for f in failures:
        print(' ', f)
    sys.exit(1)
print('\nall checks passed')
