#!/usr/bin/env python3
"""Regenerate docs/CONTENT_LINES.md's tables from sql/world/updates/*.sql.

One-way export (SQL -> readable Markdown) so the human-editable table can never drift
from what actually ships. Run from the repo root:

    python3 tools/content_to_md.py

Pairs with the edit workflow: edit CONTENT_LINES.md, hand it back, and a fresh content
SQL is generated from it (old ids DELETEd + new rows INSERTed), with the prior content
snapshotted as a versioned backup.
"""
import re, glob, sys
sys.path.insert(0, 'tools')
from check_sql import strip_line_comments, split_tuples, split_top_level_commas

CLASS={1:'Warrior',2:'Paladin',4:'Hunter',8:'Rogue',16:'Priest',32:'DeathKnight',64:'Shaman',128:'Mage',256:'Warlock',1024:'Druid'}
RACE={1:'Human',2:'Orc',4:'Dwarf',8:'NightElf',16:'Undead',32:'Tauren',64:'Gnome',128:'Troll',512:'BloodElf',1024:'Draenei'}
TEAM={1:'Alliance',2:'Horde'}
ITEM={1:'weapon',2:'2H',4:'shield',8:'ranged',16:'plate',32:'mail',64:'leather',128:'cloth'}
QUAL={0:'',2:'uncommon+',3:'rare+',4:'epic+',5:'legendary+'}
MODE={0:'say',1:'whisper',2:'emote'}
ROLE={0:'any',1:'GUARD',128:'CITIZEN'}
LOCNAME={0:'ALL capitals',126:'ALL capitals',2:'Stormwind',4:'Ironforge',8:'Darnassus',16:'Orgrimmar',32:'ThunderBluff',64:'Undercity',128:'Dalaran',256:'Darkshire'}

def bits(mask, table):
    if mask==0: return ''
    out=[table[b] for b in table if mask & b]
    return '/'.join(out) if out else str(mask)

def targets(cls,race,team,item,minq):
    parts=[]
    if cls: parts.append('class:'+bits(cls,CLASS))
    if race: parts.append('race:'+bits(race,RACE))
    if team: parts.append(TEAM.get(team,str(team))+' players')
    if item: parts.append('gear:'+bits(item,ITEM))
    if minq and QUAL.get(minq): parts.append(QUAL[minq])
    return ', '.join(parts) if parts else '—'

rows=[]
for f in sorted(glob.glob('sql/world/updates/*.sql')):
    txt=strip_line_comments(open(f,encoding='utf-8').read())
    m=re.search(r'INTO\s+`?immersive_npc_chat_line`?\s*\((.*?)\)\s*VALUES(.*)', txt, re.I|re.S)
    if not m: continue
    bodies,_,_=split_tuples(m.group(2))
    for b in bodies:
        v=split_top_level_commas(b)
        if len(v)<16: continue
        def num(i):
            try: return int(v[i].strip())
            except: return 0
        text=v[14].strip()
        if text.startswith("'"): text=text[1:-1].replace("''","'")
        rows.append(dict(id=num(0),loc=num(1),role=num(2),cls=num(4),race=num(5),team=num(6),
                         item=num(7),minq=num(9),grp=num(10),wt=num(11),mode=num(12),text=text))

# group into content sets
def setkey(r):
    if r['role']==1: 
        return '1. Guards' if r['loc']==0 else '2. Guards (faction/city-specific)'
    if r['loc']==126: return '3. Citizens (all capitals, not Dalaran)'
    if r['loc']==128: return '4. Dalaran'
    if r['loc']==256: return '5. Darkshire'
    return '9. Other'

sets={}
for r in rows: sets.setdefault(setkey(r),[]).append(r)

print("Total lines:", len(rows))
for k in sorted(sets):
    rs=sorted(sets[k], key=lambda r:(r['grp'],r['id']))
    print(f"\n### {k}  ({len(rs)} lines)\n")
    print("| id | grp | mode | wt | scope | targets | text |")
    print("|----|-----|------|----|-------|---------|------|")
    for r in rs:
        scope=LOCNAME.get(r['loc'], str(r['loc']))
        text=r['text'].replace('|','\\|')
        print(f"| {r['id']} | {r['grp']} | {MODE[r['mode']]} | {r['wt']} | {scope} | {targets(r['cls'],r['race'],r['team'],r['item'],r['minq'])} | {text} |")
