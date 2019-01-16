#! /usr/bin/env python2.7

import sys
import os
import subprocess
import email.parser as ep
import hashlib

submission_dir = os.getcwd()
grading_dir = os.getcwd()

os.chdir(submission_dir)

if os.path.exists('Makefile'):
    subprocess.call('make')

scr = './smtp'
if not os.path.exists(scr):
    print('--- No smtp found ---')
    sys.exit(1)

def do_hash(fname):
    with open(fname) as f:
        return hashlib.sha1( f.read() ).hexdigest()

def run_script(fromAddr, toAddr, subj, body, attachments=list()):
    cmd = [scr, '-m', fromAddr, '-t', toAddr, '-s', subj, '-f', body]
    cmd.extend(attachments)
    p = subprocess.Popen( cmd, universal_newlines=True, stdout=subprocess.PIPE )
    oput, _ = p.communicate()
    return oput

def test_attach():
    snd = 'tservo@gizmonic.cs.umd.edu'
    rcv = 'ctrobot@gizmonic.cs.umd.edu'
    subj = 'This is funny'
    bodyFile = 'sample_fileB'
    bodyHash = do_hash(bodyFile)
    aFile = 'far_side.jpg'
    aHash = do_hash(aFile)
    print(' --> attachment has hash {}'.format(aHash))
    msg = run_script(snd, rcv, subj, bodyFile, [aFile])
    parsed = ep.Parser().parsestr(msg)
    found = False
    for elem in parsed.walk():
        payload = elem.get_payload(decode=True)
        if payload:
            pHash = hashlib.sha1(payload).hexdigest()
            print(' --> decoded message part has hash {}'.format(pHash))
            if pHash == aHash:
                found = True
    if not found:
        print('--- Did not find single attachment ---')
        sys.exit(1)

def test_simple():
    snd = 'alice@umiacs.umd.edu'
    rcv = 'bob@terpmail.umd.edu'
    subj = 'This is the test header'
    bodyFile = 'sample_fileB'
    bodyHash = do_hash(bodyFile)
    msg = run_script(snd, rcv, subj, bodyFile)
    parsed = ep.Parser().parsestr(msg)
    parsedFrom = None
    parsedTo = None
    parsedSubj = None
    if 'From' in parsed:
        parsedFrom = parsed['From']
    if 'To' in parsed:
        parsedTo = parsed['To']
    if 'Subject' in parsed:
        parsedSubj = parsed['Subject']
    if parsedFrom != snd:
        print('--- Incorrect From address ---')
        print('    expected: {e}'.format(e=snd))
        print('    received: {a}'.format(a=parsedFrom))
        sys.exit(1)
    if parsedTo != rcv:
        print('--- Incorrect To address ---')
        print('    expected: {e}'.format(e=rcv))
        print('    received: {a}'.format(a=parsedTo))
        sys.exit(1)
    if parsedSubj != subj:
        print('--- Incorrect Subject ---')
        print('    expected: {e}'.format(e=subj))
        print('    received: {a}'.format(a=parsedSubj))
        sys.exit(1)


def test_mult_attach():
    snd = 'tservo@gizmonic.cs.umd.edu'
    rcv = 'ctrobot@gizmonic.cs.umd.edu'
    subj = 'This is funny'
    bodyFile = 'sample_fileB'
    bodyHash = do_hash(bodyFile)
    attachments = ['far_side.jpg', 'little.pdf', 'audio.aac']
    aHashes = dict()
    for a in attachments:
        aHashes[a] = do_hash(a)
        print(' --> attachment has hash {}'.format(aHashes[a]))
    msg = run_script(snd, rcv, subj, bodyFile, attachments)
    parsed = ep.Parser().parsestr(msg)
    found = list()
    for elem in parsed.walk():
        payload = elem.get_payload(decode=True)
        if payload:
            pHash = hashlib.sha1(payload).hexdigest()
            found.append(pHash)
            print(' --> decoded message part has hash {}'.format(pHash))
    for a in attachments:
        if aHashes[a] not in found:
            print('--- Did not find attachment ---')
            sys.exit(1)

test_attach()
test_simple()
test_mult_attach()

