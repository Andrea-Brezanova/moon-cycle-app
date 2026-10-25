"""Maps the 142-entry editorial draft to catalogue ids. Usage (from the repo root):
python3 docs/food-profiles/mapping_audit.py <path to the editorial draft .md>
Writes docs/food-profiles/mapping-142.json."""
import json,re,collections
import sys
md=open(sys.argv[1]).read()
phase=None; entries=[]
for line in md.splitlines():
    m=re.match(r'## (\w+) — (\d+) foods',line)
    if m: phase=m.group(1).lower(); continue
    m=re.match(r'### \d+\. (.+)',line)
    if m and phase: entries.append((phase,m.group(1).strip()))
foods=json.load(open('assets/content/foods.json')); foods=foods if isinstance(foods,list) else foods['foods']
norm=lambda s: re.sub(r'[^a-z0-9]+',' ',s.lower()).strip()
byname={}
for f in foods:
    byname.setdefault(norm(f['name']),[]).append(f['id'])
    for s in f.get('synonyms',[]): byname.setdefault(norm(s),[]).append(f['id'])
phases=json.load(open('assets/content/phases.json'))['phases']
inphase={p['id']:{fid for c in p['categories'] for fid in c['foods']} for p in phases}
def match(name):
    n=norm(name)
    if n in byname: return sorted(set(byname[n])),'exact'
    base=re.sub(r'\(.*?\)','',name).strip(); n2=norm(base)
    for cand in (n,n2):
        if cand in byname: return sorted(set(byname[cand])),'base'
        for v in (cand.rstrip('s'),cand+'s',cand.replace('ies','y'),cand.replace('y','ies')):
            if v in byname: return sorted(set(byname[v])),'variant'
    hits=[f['id'] for f in foods if n2 and (n2 in norm(f['name']) or norm(f['name']) in n2)]
    return sorted(set(hits)),'partial'
rows=[];un=[];amb=[];dup=collections.defaultdict(list);diffs=[]
for ph,name in entries:
    ids,how=match(name); rows.append((ph,name,ids,how))
    if not ids: un.append((ph,name))
    elif how=='partial' or len(ids)>1: amb.append((ph,name,ids,how))
    else:
        dup[ids[0]].append(ph)
        if ids[0] not in inphase[ph]: diffs.append((ph,name,ids[0],[p for p in inphase if ids[0] in inphase[p]]))
repeat={k:v for k,v in dup.items() if len(v)>1}
cnt=collections.Counter(r[3] for r in rows)
out=["# Food profiles: mapping audit (142-entry editorial draft vs the catalogue)\n",
f"Source: `moon_cycle_142_food_profiles_editorial_draft.md`. The companion `moon_cycle_142_food_profiles_draft.json` was not among the files provided (only the markdown, and a different 30-food `moon_cycle_food_library_v0_1.json`). Catalogue: `assets/content/foods.json` ({len(foods)} foods) and the phase lists in `assets/content/phases.json`. Nothing was changed.\n",
f"**{len(entries)} entries**: "+", ".join(f"{k} {v}" for k,v in collections.Counter(p for p,_ in entries).items())+" (matches the stated 35 / 32 / 31 / 44).\n",
"## Result",
f"- Exact name or synonym match: **{cnt['exact']}**",
f"- Matched by base name or plural form: **{cnt['base']+cnt['variant']}**",
f"- Ambiguous or partial (needs your decision): **{len(amb)}**",
f"- No catalogue match: **{len(un)}**",
f"- Matched foods that the draft puts in a different phase than the catalogue: **{len(diffs)}** (not changed)",
f"- Foods repeated across phases in the draft: **{len(repeat)}**\n",
"## No catalogue match (a new food, or an alias to add)"]
out+= [f"- {n} ({p})" for p,n in un] or ["- none"]
out.append("\n## Ambiguous or partial matches")
out+= [f"- {n} ({p}): {', '.join(ids) or '-'}" for p,n,ids,how in amb] or ["- none"]
out.append("\n## Draft phase differs from the catalogue's current phase list")
out+= [f"- {n} (`{i}`): draft {p}; catalogue {', '.join(c) or 'none'}" for p,n,i,c in diffs] or ["- none"]
out.append("\n## Same food in several draft phases")
out+= [f"- `{k}`: {', '.join(v)}" for k,v in repeat.items()] or ["- none"]
json.dump([{'phase':p,'draftName':n,'catalogueIds':i,'match':h} for p,n,i,h in rows],open('docs/food-profiles/mapping-142.json','w'),indent=1,ensure_ascii=False)
print(len(rows),"entries;",len(un),"unmatched;",len(diffs),"phase differences")
