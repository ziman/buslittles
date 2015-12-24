#!/usr/bin/env python3

import pysrt
import json
import os

srts = []
for fname in os.listdir('srt'):
    events = []
    srts.append({
        'name': fname,
        'events': events,
    })

with open('list.js', 'w') as f:
    f.write('window.SRTS = ' + json.dumps(srts, indent=2) + ';')
