import json, re, html, os, collections
import numpy as np
from PIL import Image

rows = json.load(open('withassets.json'))

# ── category, for CardType.forProduct ────────────────────────────────────
RUN = re.compile(r'\b(GEL|PEGASUS|ULTRABOOST|VOMERO|ZOOM|CLIFTON|BONDI|NOVABLAST|KAYANO|NIMBUS|CUMULUS|STRUCTURE|ADIZERO|SUPERNOVA|RUNNER|RUN|INFINITY|VAPORFLY|ALPHAFLY|DEVIATE|VELOCITY|EVO SL|ADISTAR|TRIUMPH|RIDE)\b', re.I)
COURT = re.compile(r'\b(JORDAN|DUNK|FORUM|SUPERSTAR|CHUCK|ALL STAR|AIR FORCE|BLAZER|CAMPUS|SAMBA|GAZELLE|STAN SMITH|CLUB C|COURT|SPEZIAL|HANDBALL|TERRACE|PRO LEATHER|SHAQNOSIS|BASKETBALL|SABRINA|GT CUT|KOBE|LEBRON|CURRY)\b', re.I)
TRAIN = re.compile(r'\b(METCON|TRAINER|TRAINING|DROPSET|GYM|LIFTER|TAEKWONDO|FLEX)\b', re.I)

def category(r):
    hay = f"{r['model']} {r['ptype']}"
    if TRAIN.search(hay): return 'training'
    if RUN.search(hay):   return 'running'
    if COURT.search(hay): return 'court'
    return 'lifestyle'

def style_code(sku):
    """Superkicks appends the size to the manufacturer code: A23950C-7."""
    if not sku: return None
    m = re.match(r'^([A-Z0-9]{4,}(?:-[A-Z0-9]{2,4})?)-\d{1,2}(\.5)?$', sku.strip(), re.I)
    code = m.group(1) if m else sku.strip()
    return code if re.fullmatch(r'[A-Z0-9\-]{5,18}', code, re.I) else None

def describe(r):
    body = re.sub(r'<[^>]+>', ' ', r.get('body') or '')
    body = html.unescape(re.sub(r'\s+', ' ', body)).strip()
    body = re.sub(r'\s*(SKU|Style Code|MRP)\s*[:#].*$', '', body, flags=re.I)
    return body[:420].strip() if len(body) > 60 else None

def dominant(path):
    """Same rule the app uses: saturation-weighted hue buckets, cut-out only."""
    im = Image.open(path).convert('RGBA')
    im.thumbnail((72, 72))
    a = np.asarray(im).astype(float)
    rgb, alpha = a[..., :3] / 255.0, a[..., 3]
    mx, mn = rgb.max(2), rgb.min(2)
    l = (mx + mn) / 2
    d = mx - mn
    sat = np.where(d == 0, 0, d / (1 - np.abs(2 * l - 1) + 1e-6))
    ok = (alpha > 200) & (sat > 0.25) & (l > 0.12) & (l < 0.92)
    if ok.sum() < 12:
        v = l[alpha > 200]
        g = int(round((v.mean() if v.size else 0.5) * 255))
        return (g, g, g)
    r_, g_, b_ = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.zeros_like(mx)
    m = (mx == r_) & (d > 0); hue[m] = (60 * ((g_ - b_)[m] / d[m]) + 360) % 360
    m = (mx == g_) & (d > 0); hue[m] = 60 * ((b_ - r_)[m] / d[m]) + 120
    m = (mx == b_) & (d > 0); hue[m] = 60 * ((r_ - g_)[m] / d[m]) + 240
    w = (sat ** 2)[ok]
    bucket = (hue[ok] / 15).astype(int).clip(0, 23)
    tot = np.bincount(bucket, weights=w, minlength=24)
    best = int(tot.argmax())
    h = float(np.bincount(bucket, weights=hue[ok] * w, minlength=24)[best] / tot[best])
    import colorsys
    r2, g2, b2 = colorsys.hls_to_rgb(h / 360, 0.45, 0.6)
    return (int(r2 * 255), int(g2 * 255), int(b2 * 255))

def dart_str(s):
    return "'" + s.replace('\\', r'\\').replace("'", r"\'").replace('$', r'\$').replace('\n', ' ') + "'"

rows.sort(key=lambda r: (r['brand'], r['model']))
out = []
for i, r in enumerate(rows, 1):
    if not os.path.exists(r['asset'].replace('assets/shoes/', 'shoes_webp/')):
        continue
    cat = category(r)
    code = style_code(r.get('sku'))
    desc = describe(r)
    cr, cg, cb = dominant(r['asset'].replace('assets/shoes/', 'shoes_webp/'))
    tags = [cat]
    if any('new arrival' in t.lower() for t in r.get('tags', [])):
        tags.append('new')
    lines = [
        '  ShoeModel(',
        f"    id: 'sku-{i:03d}',",
        f"    name: {dart_str(r['brand'])},",
        f"    model: {dart_str(r['model'][:46])},",
        f"    price: Money.rupees({int(round(r['price']))}),",
    ]
    if r['mrp']:
        lines.append(f"    mrp: Money.rupees({int(round(r['mrp']))}),")
    lines.append(f"    imgAddress: {dart_str(r['asset'])},")
    lines.append(f"    modelColor: const Color(0xff{cr:02X}{cg:02X}{cb:02X}),")
    if r['sizes'] or r['soldOut']:
        allsz = sorted(set(r['sizes']) | set(r['soldOut']), key=float)
        lines.append("    sizes: const [" + ', '.join(dart_str(s) for s in allsz) + "],")
    if r['soldOut']:
        lines.append("    soldOutSizes: const [" + ', '.join(dart_str(s) for s in r['soldOut']) + "],")
    if desc:
        lines.append(f"    description: {dart_str(desc)},")
    if code:
        lines.append(f"    styleCode: {dart_str(code)},")
    if r.get('preorder'):
        lines.append('    isPreOrder: true,')
    if 'new' in tags:
        lines.append('    isNew: true,')
    lines.append("    tags: const [" + ', '.join(dart_str(t) for t in tags) + "],")
    lines.append('  ),')
    out.append('\n'.join(lines))

header = '''import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/utils/money.dart';

/// The catalogue.
///
/// Harvested from the public Shopify product feeds of Indian multi-brand
/// sneaker retailers (Superkicks, Kicksmachine, Holy Grails, Crepdog Crew).
/// Brand, model, colourway, INR price, MRP, per-size availability, style code
/// and description are the retailers' own values, not invented ones.
///
/// Regenerate with `tool/ingest/` rather than editing by hand.
///
/// See docs/ARCHITECTURE.md for the licensing position on the imagery.
final List<ShoeModel> availableShoes = [
'''
open('dummy_data.dart', 'w').write(header + '\n'.join(out) + '\n];\n')
print(f"emitted {len(out)} products")
print(collections.Counter(r['brand'] for r in rows).most_common())
