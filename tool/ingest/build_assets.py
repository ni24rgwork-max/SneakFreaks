import json, os, re, io, urllib.request, collections
import numpy as np
from PIL import Image

QUOTA = {  # Nike and Jordan weighted heaviest, as asked.
    'NIKE': 40, 'JORDAN': 32, 'ADIDAS': 28, 'NEW BALANCE': 22,
    'CONVERSE': 20, 'PUMA': 20, 'ASICS': 18, 'GULLY LABS': 10,
    'REEBOK': 7, 'CROCS': 6, 'THAELY': 6,
}

rows = json.load(open('pool.json'))
by = collections.defaultdict(list)
for r in rows:
    by[r['brand']].append(r)

def family(model):
    """Group by the first two words, so a quota spreads across model lines
    instead of returning twelve colourways of one shoe."""
    return ' '.join(re.sub(r'[^A-Za-z0-9 ]', ' ', model).split()[:2]).upper()

picked = []
for brand, quota in QUOTA.items():
    pool = by.get(brand, [])
    # Prefer discounted items (they exercise the MRP/% off UI) and spread
    # across model families round-robin.
    fams = collections.defaultdict(list)
    for r in sorted(pool, key=lambda r: (r['mrp'] is None, -r['price'])):
        fams[family(r['model'])].append(r)
    order = sorted(fams.values(), key=len, reverse=True)
    take, i = [], 0
    while len(take) < quota and any(order):
        for f in order:
            if i < len(f) and len(take) < quota:
                take.append(f[i])
        i += 1
        if i > 40: break
    picked += take[:quota]

print(f"selected {len(picked)}")
for b, n in collections.Counter(p['brand'] for p in picked).most_common():
    print(f"  {b:14s} {n}")
json.dump(picked, open('picked.json','w'))
