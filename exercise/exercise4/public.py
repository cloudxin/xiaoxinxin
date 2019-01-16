#! /usr/bin/env python

import sys
import os
import subprocess

submission_dir = os.getcwd()
grading_dir = os.getcwd()

os.chdir(submission_dir)

if os.path.exists('Makefile'):
    subprocess.call('make')

if not os.path.exists('tcp'):
    print('--- No file tcp found ---')
    sys.exit(1)
stat_res = os.stat('tcp')
if not 1 & stat_res.st_mode:
    print('--- tcp not executable ---')
    sys.exit(1)

input_file = 'test_input'
mss = 100
cmd = ['timeout', '1m', './tcp', str(mss), input_file]
p = subprocess.Popen(cmd, universal_newlines=True, stdout=subprocess.PIPE)
output, _ = p.communicate()
olines = output.split()
ilines = list()
with open(input_file) as infile:
    for l in infile:
        ilines.append(l.strip())
if mss != int(olines[0]):
    print('--- First line is not MSS ---')
    sys.exit(1)
zipped = zip(ilines,olines[1:])

cwnd = mss
slowStart = True

def handle_ack():
    ss = cwnd + mss
    ai = cwnd + int(mss*mss/cwnd)
    if slowStart:
        return (ss,ai)
    return (ai,ai)

def handle_drop():
    global slowStart
    slowStart = False
    return int(cwnd/2)

slowStartGood = True
aimdGood = True
cwndIntGood = True

for s,o in zipped:
    if s == '+':
        cwnd,ai = handle_ack()
    elif s == '-':
        cwnd = handle_drop()
        ai = cwnd
    if str(cwnd) == o:
        pass
    elif str(ai) == o:
        if slowStart:
            print('--- Did not implement slow start ---')
            sys.exit(1)
        cwnd = ai
    else:
        print('--- Did not implement AIMD correctly ---')
        sys.exit(1)

print('+++ Correctly implemented congestion control +++')

