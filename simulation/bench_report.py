#!/usr/bin/env python3
"""Turn the RESULT lines printed by robot_bench_tb into a Markdown comparison table."""
import re, sys

CLK_MHZ = 6.25         # default Basys 3 CPU clock (100 MHz / 16); cycle counts are clock-independent
CTRL_PERIOD = 256       # control period (cycles) used for the "CPU load" column

names = {
    'sw':     'A. Software only (GPIO + software PWM, software obstacle check)',
    'mmio':   'B. Hardware PWM + reflex, software steering (memory-mapped)',
    'custom': 'C. Hardware PWM + reflex, `ROBOTSTEP` custom instruction',
    'auto':   'D. Autonomous hardware mode (CPU free)',
}
rows = {}
for line in open(sys.argv[1]):
    if not line.startswith('RESULT'):
        continue
    d = dict(kv.split('=') for kv in line.split()[1:])
    rows[d['mode']] = {k: (int(v) if v.lstrip('-').isdigit() else v) for k, v in d.items()}

words = {}
for m in rows:
    try:
        words[m] = sum(1 for _ in open(f'programs/hex/bench_{m}.hex'))
    except OSError:
        words[m] = '-'

def us(c): return f'{c / CLK_MHZ:.2f}'

out = []
out.append('| Implementation | Program (words) | Decision path (instr.) avg [min-max] | Reaction latency, cycles avg / max | Reaction latency avg / max @ %g MHz | CPU load of motor control @ %d-cycle period | Left-motor PWM duty, centre line (ideal 27.3 %%) |' % (CLK_MHZ, CTRL_PERIOD))
out.append('|---|---|---|---|---|---|---|')
for m in ('sw', 'mmio', 'custom', 'auto'):
    if m not in rows: continue
    r = rows[m]
    if r['path_n'] > 0:
        path = f"{r['path_avg']} [{r['path_min']}-{r['path_max']}]"
        pavg = r['path_avg']
    else:
        path = '0 (none)'
        pavg = 0
    if m == 'sw':
        load = '~100 % (PWM loop never stops)'
    else:
        load = f'{100.0 * pavg / CTRL_PERIOD:.1f} %'
    out.append(f"| {names[m]} | {words[m]} | {path} | {r['lat_avg']} / {r['lat_max']} | {us(r['lat_avg'])} us / {us(r['lat_max'])} us | {load} | {r['pin_duty_pct']} % |")
print('\n'.join(out))
