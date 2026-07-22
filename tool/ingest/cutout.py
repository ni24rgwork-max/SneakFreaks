import json, os, io, re, urllib.request, collections
import numpy as np
from PIL import Image

OUT = 'shoes'
os.makedirs(OUT, exist_ok=True)
picked = json.load(open('picked.json'))

def slug(*parts):
    s = re.sub(r'[^a-z0-9]+', '-', ' '.join(parts).lower()).strip('-')
    return re.sub(r'-+', '-', s)[:52]

def cutout(data):
    """Key out the studio background.

    Flood-fills inward from the border rather than thresholding every light
    pixel — a global threshold punches holes through white midsoles, which is
    most of a sneaker photo.
    """
    im = Image.open(io.BytesIO(data)).convert('RGB')
    a = np.asarray(im).astype(np.int16)
    h, w, _ = a.shape

    # Background estimated from the corners, not assumed to be pure white.
    corners = np.concatenate([a[:6, :6].reshape(-1, 3), a[:6, -6:].reshape(-1, 3),
                              a[-6:, :6].reshape(-1, 3), a[-6:, -6:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    near = (np.abs(a - bg).max(axis=2) <= 18)

    # BFS from the border over the near-background mask.
    keep = np.zeros((h, w), bool)
    stack = [(0, x) for x in range(w) if near[0, x]] + \
            [(h-1, x) for x in range(w) if near[h-1, x]] + \
            [(y, 0) for y in range(h) if near[y, 0]] + \
            [(y, w-1) for y in range(h) if near[y, w-1]]
    for y, x in stack: keep[y, x] = True
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y+dy, x+dx
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not keep[ny, nx]:
                keep[ny, nx] = True
                stack.append((ny, nx))

    alpha = np.where(keep, 0, 255).astype(np.uint8)
    rgba = np.dstack([a.astype(np.uint8), alpha])
    out = Image.fromarray(rgba, 'RGBA')

    bbox = out.getbbox()
    if bbox: out = out.crop(bbox)
    # Fit inside 520x520 with a little breathing room; the card scales it.
    out.thumbnail((520, 520), Image.LANCZOS)
    return out

ok, fail = [], []
for i, p in enumerate(picked):
    name = slug(p['brand'], p['model'], p['colourway'] or str(i)) + '.png'
    path = os.path.join(OUT, name)
    p['asset'] = f'assets/shoes/{name}'
    if os.path.exists(path):
        ok.append(p); continue
    try:
        req = urllib.request.Request(p['image'] + '?width=900',
                                     headers={'User-Agent': 'Mozilla/5.0'})
        data = urllib.request.urlopen(req, timeout=45).read()
        img = cutout(data)
        if img.width < 120 or img.height < 90:
            raise ValueError(f'too small after trim: {img.size}')
        img.save(path, 'PNG', optimize=True)
        ok.append(p)
    except Exception as e:
        fail.append((p['brand'], p['model'][:40], str(e)[:60]))
    if (i+1) % 40 == 0:
        print(f"  {i+1}/{len(picked)} ... ok={len(ok)} fail={len(fail)}", flush=True)

print(f"\ndownloaded {len(ok)}, failed {len(fail)}")
for f in fail[:10]: print("  FAIL", f)
json.dump(ok, open('withassets.json','w'))
