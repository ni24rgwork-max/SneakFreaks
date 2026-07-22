import json, glob, re, collections, unicodedata

APPAREL = re.compile(r'shirt|tee|top|bottom|pant|short|hoodie|jacket|cap|sock|bag|watch|belt|apparel|accessor|fragrance|perfume|jersey|track|sweat|beanie|glove|wallet|backpack|crossbody|tote', re.I)
FOOTWEAR = re.compile(r'sneaker|shoe|footwear|low|high|mid|slide|clog|boot|runner', re.I)

# Vendor strings are inconsistent across shops; several are model names.
BRAND = {
    'nike':'NIKE','sb dunk low':'NIKE','dunk low':'NIKE','air force 1':'NIKE','nike sb':'NIKE',
    'jordan':'JORDAN','air jordan':'JORDAN',
    'adidas':'ADIDAS','adidas originals':'ADIDAS','adidas performance':'ADIDAS',
    'puma':'PUMA','new balance':'NEW BALANCE','converse':'CONVERSE','asics':'ASICS',
    'reebok':'REEBOK','hoka':'HOKA','on':'ON','salomon':'SALOMON','vans':'VANS',
    'under armour':'UNDER ARMOUR','skechers':'SKECHERS','crocs':'CROCS',
    'gully labs':'GULLY LABS','thaely':'THAELY','evrhood':'EVRHOOD',
}

def clean(s):
    s = unicodedata.normalize('NFKD', s or '')
    return re.sub(r'\s+', ' ', s.replace('™','').replace('®','')).strip()

def parse(title):
    """`BRAND | MODEL { COLOURWAY` — falls back to the whole title."""
    t = clean(title)
    model, colour = t, ''
    if '|' in t:
        model = t.split('|', 1)[1]
    if '{' in model:
        model, colour = model.split('{', 1)
    model = clean(model).strip(' -')
    colour = clean(colour).strip(' -}')
    return model, colour

rows, seen = [], set()
for f in glob.glob('feed/*.json'):
    for p in json.load(open(f))['products']:
        vendor = clean(p.get('vendor'))
        brand = BRAND.get(vendor.lower())
        if not brand:
            continue
        ptype = clean(p.get('product_type'))
        title = clean(p.get('title'))
        if APPAREL.search(ptype) or APPAREL.search(title):
            continue
        if not (FOOTWEAR.search(ptype) or FOOTWEAR.search(title)):
            continue
        if not p.get('images'):
            continue

        model, colour = parse(title)
        if not model or len(model) < 3:
            continue

        # UK sizes only, and only the ones the shop actually lists.
        sizes, sold_out = [], []
        for v in p['variants']:
            s = clean(v.get('title'))
            if not re.fullmatch(r'\d{1,2}(\.5)?', s):
                continue
            (sizes if v.get('available') else sold_out).append(s)
        if len(sizes) + len(sold_out) < 2:
            continue

        var = p['variants'][0]
        try:
            price = float(var['price'])
        except (TypeError, ValueError):
            continue
        if price < 999 or price > 90000:
            continue
        mrp = var.get('compare_at_price')
        mrp = float(mrp) if mrp else None
        if mrp and mrp <= price:
            mrp = None

        key = (brand, re.sub(r'[^a-z0-9]', '', (model + colour).lower())[:60])
        if key in seen:
            continue
        seen.add(key)

        rows.append(dict(
            brand=brand, model=model, colourway=colour, ptype=ptype,
            price=price, mrp=mrp,
            sizes=sorted(set(sizes), key=float),
            soldOut=sorted(set(sold_out), key=float),
            image=p['images'][0]['src'].split('?')[0],
            sku=clean(var.get('sku')) or None,
            tags=[clean(t) for t in p.get('tags', [])],
            handle=p['handle'],
        ))

by = collections.Counter(r['brand'] for r in rows)
print(f"usable products: {len(rows)}\n")
for b, n in by.most_common(): print(f"  {b:16s} {n}")
json.dump(rows, open('pool.json','w'))
