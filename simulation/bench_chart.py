#!/usr/bin/env python3
"""Draw the benchmark comparison chart from the RESULT lines of robot_bench_tb."""
import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

rows = {}
for line in open(sys.argv[1]):
    if line.startswith('RESULT'):
        d = dict(kv.split('=') for kv in line.split()[1:])
        rows[d['mode']] = {k: (int(v) if v.lstrip('-').isdigit() else v) for k, v in d.items()}

order = [('sw', 'A\nsoftware only'), ('mmio', 'B\nmemory-mapped'), ('custom', 'C\ncustom\ninstruction'), ('auto', 'D\nautonomous\nhardware')]
colors = ['#b0bec5', '#64b5f6', '#1565c0', '#2e7d32']
labels = [l for _, l in order]
lat = [rows[m]['lat_avg'] for m, _ in order]
latmax = [rows[m]['lat_max'] for m, _ in order]
path = [rows[m]['path_avg'] if rows[m]['path_n'] else 0 for m, _ in order]
load = [100.0 if m == 'sw' else (100.0 * (rows[m]['path_avg'] if rows[m]['path_n'] else 0) / 256) for m, _ in order]

fig, ax = plt.subplots(1, 3, figsize=(14, 4.8))

def panel(a, vals, title, ylabel, texts, log=False, ymax=None):
    a.bar(range(4), vals, color=colors, width=0.7)
    a.set_xticks(range(4)); a.set_xticklabels(labels, fontsize=8)
    a.set_title(title, fontsize=11, fontweight='bold', pad=10)
    a.set_ylabel(ylabel, fontsize=9)
    if log:
        a.set_yscale('log'); a.set_ylim(1, max(vals) * 6)
    else:
        a.set_ylim(0, (ymax or max(vals)) * 1.18)
    for i, v in enumerate(vals):
        y = v * 1.15 if log else v + (ymax or max(vals)) * 0.02
        a.text(i, y, texts[i], ha='center', va='bottom', fontsize=9)
    a.spines[['top', 'right']].set_visible(False)

panel(ax[0], lat, 'Reaction latency (average)', 'CPU cycles (log scale)',
      [f'{v}  (max {latmax[i]})' for i, v in enumerate(lat)], log=True)
panel(ax[1], path, 'Instructions per steering decision', 'instructions (average)',
      [str(v) for v in path])
panel(ax[2], load, 'CPU load of motor control', '% of CPU cycles @ 256-cycle control period',
      [f'{v:.1f} %' for v in load], ymax=100)
fig.suptitle('Same line-following task, four implementations (simulation, 24 sensor transitions)', fontsize=12, fontweight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.93])
fig.savefig(sys.argv[2], dpi=150)
