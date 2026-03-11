"""
add_grid_coords.py
Adds grid_row / grid_col / is_horizontal and assigned_word to all 50 hand-crafted puzzles.
Fixes triangle-topology boss levels (32, 42, 50) by removing one redundant intersection.
Recomputes letter_pool as one entry per grid cell (intersections counted once).
Validates all 50 puzzles and writes the result back to the JSON file.
"""

import json, os, sys
from collections import deque, defaultdict

# ---------------------------------------------------------------------------
# Category lists
# ---------------------------------------------------------------------------
CAT_BASE = 'assets/word_lists/category_lists'
CATEGORIES = {}
for fname in os.listdir(CAT_BASE):
    name = fname.replace('.txt', '')
    with open(f'{CAT_BASE}/{fname}') as f:
        CATEGORIES[name] = {w.strip().lower() for w in f if w.strip()}

CONSTRAINT_MAP = {
    'is_animal':      'animals',
    'is_body_part':   'body_parts',
    'is_clothing':    'clothing',
    'is_color':       'colors',
    'is_food':        'foods',
    'is_fruit':       'fruits',
    'is_kitchen_item':'kitchen_items',
    'is_sport':       'sports',
    'is_vegetable':   'vegetables',
    'is_water_body':  'water_bodies',
    'is_weather':     'weather',
}


def check_constraint(cid, word):
    w = word.lower()
    if cid in CONSTRAINT_MAP:
        return w in CATEGORIES.get(CONSTRAINT_MAP[cid], set())
    if cid == 'no_repeated_letters':
        return len(set(w)) == len(w)
    if cid == 'has_double_letter':
        return any(w[i] == w[i + 1] for i in range(len(w) - 1))
    if cid == 'exact_length_4':
        return len(w) == 4
    if cid == 'exact_length_5':
        return len(w) == 5
    return True  # unknown: pass-through


# ---------------------------------------------------------------------------
# Grid coordinate computation (2-colour BFS)
# ---------------------------------------------------------------------------
def compute_coords(slot_ids, intersections):
    """
    Slot slot_ids[0] is placed at (0, 0) Horizontal.
    Neighbours alternate H / V via BFS.
    Returns {slot_id: (row, col, is_horizontal)}.
    """
    adj = defaultdict(list)
    for ix in intersections:
        a, b, pa, pb = ix['slot_a'], ix['slot_b'], ix['position_in_a'], ix['position_in_b']
        adj[a].append((b, pa, pb))
        adj[b].append((a, pb, pa))

    is_horiz = {slot_ids[0]: True}
    coords   = {slot_ids[0]: (0, 0)}
    queue    = deque([slot_ids[0]])
    visited  = {slot_ids[0]}

    while queue:
        curr = queue.popleft()
        cr, cc = coords[curr]
        ch = is_horiz[curr]
        for (nb, p_curr, p_nb) in adj[curr]:
            if nb in visited:
                continue
            visited.add(nb)
            queue.append(nb)
            nb_h = not ch
            is_horiz[nb] = nb_h
            # Cell of curr at position p_curr
            cell_r = cr if ch else cr + p_curr
            cell_c = cc + p_curr if ch else cc
            # Place nb so its p_nb lands on (cell_r, cell_c)
            if nb_h:
                nb_r, nb_c = cell_r, cell_c - p_nb
            else:
                nb_r, nb_c = cell_r - p_nb, cell_c
            coords[nb] = (nb_r, nb_c)

    # Normalise to non-negative origin
    min_r = min(r for r, c in coords.values())
    min_c = min(c for r, c in coords.values())
    return {sid: (r - min_r, c - min_c, is_horiz[sid])
            for sid, (r, c) in coords.items()}


# ---------------------------------------------------------------------------
# Geometry verification
# ---------------------------------------------------------------------------
def verify_geometry(word_slots, intersections, coords):
    errors = []
    for ix in intersections:
        sa, sb, pa, pb = ix['slot_a'], ix['slot_b'], ix['position_in_a'], ix['position_in_b']
        ra, ca, ha = coords[sa]
        rb, cb, hb = coords[sb]
        cell_a = (ra, ca + pa) if ha else (ra + pa, ca)
        cell_b = (rb, cb + pb) if hb else (rb + pb, cb)
        if cell_a != cell_b:
            errors.append(
                f'  Intersection slot{sa}[{pa}] @ {cell_a} != slot{sb}[{pb}] @ {cell_b}')
    return errors


def verify_no_accidental_overlap(word_slots, intersections, coords):
    declared = set()
    for ix in intersections:
        declared.add((ix['slot_a'], ix['slot_b']))
        declared.add((ix['slot_b'], ix['slot_a']))

    cell_map = defaultdict(list)
    for s in word_slots:
        sid = s['id']
        r, c, h = coords[sid]
        for pos in range(s['required_length']):
            cell = (r, c + pos) if h else (r + pos, c)
            cell_map[cell].append(sid)

    errors = []
    for cell, occupants in cell_map.items():
        if len(occupants) <= 1:
            continue
        for i in range(len(occupants)):
            for j in range(i + 1, len(occupants)):
                si, sj = occupants[i], occupants[j]
                if (si, sj) not in declared:
                    errors.append(f'  Undeclared overlap at {cell}: slot{si} and slot{sj}')
    return errors


# ---------------------------------------------------------------------------
# Letter pool computation
# ---------------------------------------------------------------------------
def compute_pool(word_slots, intersections, coords):
    canonical_ix = {}
    for ix in intersections:
        a, b, pa, pb = ix['slot_a'], ix['slot_b'], ix['position_in_a'], ix['position_in_b']
        canonical_ix[(a, pa)] = (a, pa)
        canonical_ix[(b, pb)] = (a, pa)

    seen = set()
    pool = []
    for s in word_slots:
        sid = s['id']
        word = s.get('assigned_word', '')
        for pos in range(s['required_length']):
            key = (sid, pos)
            if key in canonical_ix:
                canon = canonical_ix[key]
                if canon in seen:
                    continue
                seen.add(canon)
            pool.append(word[pos] if pos < len(word) else '?')
    return pool


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
data = json.load(open('assets/puzzles/hand_crafted_001_050.json'))
errors_by_level = {}

for p in data['puzzles']:
    lvl = p['level_number']
    slots = p['word_slots']
    slot_ids = [s['id'] for s in slots]
    solution = p['metadata']['solution']

    # -- Fix triangle topologies on boss levels -----------------------------
    if lvl == 32:
        # rain(0)-crane(1)-scarf(2): remove rain-scarf edge (slot_a=0, slot_b=2)
        p['intersections'] = [ix for ix in p['intersections']
                               if not (ix['slot_a'] == 0 and ix['slot_b'] == 2)]
        p['intersection_count'] = len(p['intersections'])

    elif lvl == 42:
        # steak(0)-teal(1)-lake(2): remove lake-steak edge (slot_a=2, slot_b=0)
        p['intersections'] = [ix for ix in p['intersections']
                               if not (ix['slot_a'] == 2 and ix['slot_b'] == 0)]
        p['intersection_count'] = len(p['intersections'])

    elif lvl == 50:
        # crane(0)-rain(1)-shin(2)-scarf(3): remove rain-shin edge (slot_a=1, slot_b=2)
        p['intersections'] = [ix for ix in p['intersections']
                               if not (ix['slot_a'] == 1 and ix['slot_b'] == 2)]
        p['intersection_count'] = len(p['intersections'])

    intersections = p['intersections']

    # -- Assign solution words to slots ------------------------------------
    for i, s in enumerate(slots):
        s['assigned_word'] = solution[i]

    # -- Compute or preserve grid coordinates ------------------------------
    if lvl == 1:
        coords = {s['id']: (s['grid_row'], s['grid_col'], s['is_horizontal'])
                  for s in slots}
    else:
        coords = compute_coords(slot_ids, intersections)
        for s in slots:
            r, c, h = coords[s['id']]
            s['grid_row'] = r
            s['grid_col'] = c
            s['is_horizontal'] = h

    # -- Geometric checks --------------------------------------------------
    errs = []
    errs += verify_geometry(slots, intersections, coords)
    errs += verify_no_accidental_overlap(slots, intersections, coords)

    # -- Recompute letter pool --------------------------------------------
    pool = compute_pool(slots, intersections, coords)
    p['letter_pool'] = pool

    # -- Constraint validation --------------------------------------------
    words = solution
    cids  = [s['constraint_id'] for s in slots]

    for word in words:
        if not any(check_constraint(cid, word) for cid in cids):
            errs.append(f'  Word "{word}" satisfies no constraint in {cids}')

    for cid in cids:
        if not any(check_constraint(cid, w) for w in words):
            errs.append(f'  Constraint "{cid}" not satisfied by any of {words}')

    for ix in intersections:
        wa = slots[ix['slot_a']]['assigned_word']
        wb = slots[ix['slot_b']]['assigned_word']
        if ix['position_in_a'] >= len(wa):
            errs.append(f'  posA={ix["position_in_a"]} out of bounds for "{wa}"')
        elif ix['position_in_b'] >= len(wb):
            errs.append(f'  posB={ix["position_in_b"]} out of bounds for "{wb}"')
        elif wa[ix['position_in_a']] != wb[ix['position_in_b']]:
            errs.append(
                f'  Intersection mismatch: {wa}[{ix["position_in_a"]}]='
                f'{wa[ix["position_in_a"]]} != {wb}[{ix["position_in_b"]}]='
                f'{wb[ix["position_in_b"]]}')

    if len(words) != len(set(words)):
        errs.append(f'  Duplicate words: {words}')

    for s in slots:
        w = s['assigned_word']
        if len(w) != s['required_length']:
            errs.append(f'  Word "{w}" len={len(w)} != required={s["required_length"]}')

    if errs:
        errors_by_level[lvl] = errs

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if errors_by_level:
    print(f'FAILED — {len(errors_by_level)} puzzles have errors:')
    for lvl, errs in sorted(errors_by_level.items()):
        print(f'\nLevel {lvl}:')
        for e in errs:
            print(e)
    sys.exit(1)
else:
    total = len(data['puzzles'])
    print(f'ALL {total}/{total} PUZZLES VALIDATED OK')
    out = json.dumps(data, indent=2, ensure_ascii=False)
    with open('assets/puzzles/hand_crafted_001_050.json', 'w') as f:
        f.write(out + '\n')
    print('Written: assets/puzzles/hand_crafted_001_050.json')
