#! /usr/bin/env python

import sys
import os
import subprocess

if os.path.exists('Makefile'):
    subprocess.call('make')

if not os.path.exists('switch'):
    print('--- switch not found ---')
    sys.exit(1)
stat_res = os.stat('switch')
if not 1 & stat_res.st_mode:
    print('--- switch not executable ---')
    sys.exit(1)

input_file = 'test_input'
cmd = ['./switch', '4', input_file]
p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
output,_ = p.communicate()

expected = [
    [[1, 2, 3],[1, 2, 3]],
    [[0, 2, 3],[0]],
    [[0],[1]],
    [[2],[0]],
    [[1],[2]],
    [[2],[2]],
    [[0],[0]],
    [[1],[0]],
    [[1],[0, 1, 2]],
    [[3],[3]]
    ]

zipped = zip(output.split('\n'),expected)
for z in zipped:
    oline = z[0]
    truth = [str(x) for x in z[1][0]]
    flip = [str(x) for x in z[1][1]]
    oresp = oline.split()
    oresp.sort()
    ntruth = len(truth)
    nflip = len(flip)
    nresp = len(oresp)
    if oresp != truth:
        print('--- Incorrect frame forwarding ---')
        print('    expected: {}'.format(' '.join([str(x) for x in truth])))
        print('    received: {}'.format(oline))
        sys.exit(1)

print('+++ Frame forwarding correct +++')

