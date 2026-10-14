# Mockups mit den finalen Manny-Grafiken (Brief v2 Ergänzung 1): v2-manny-wahl, v2-heute (neu).
# Ergänzt gen5.py (nicht ersetzt): gleiche Welt (Abend) und Stilbausteine, Quellen von gen5 bleiben unverändert.
# Heute wird hier als v2-heute-neu.html erzeugt (PNG: ../v2-heute.png), damit v2-heute.html unberührt bleibt.
import re
ab=open('v2-ansatz3-abend.html').read()
STYLE=re.search(r'<style>(.*?)</style>',ab,re.S).group(1)
BG=re.search(r'<svg class="bgl".*?</svg>',ab,re.S).group().replace('</svg>','',1)
BG=re.sub(r'<path d="M200 700[^>]*/>','',BG)+'</svg>'
src5=open('gen5.py').read()
EX=re.search(r"EX='''(.*?)'''",src5,re.S).group(1)
M='../../manny/'
EX+='''
.look{flex:1;border-radius:28px;background:rgba(255,255,255,.80);border:3px solid rgba(33,27,22,.22);box-shadow:0 18px 30px -16px rgba(60,35,25,.45),inset 0 1px 0 #fff;padding:12px 8px 14px;display:flex;flex-direction:column;align-items:center;gap:6px;position:relative;min-height:300px}
.look.on{border-color:#FF7A2E;background:#FFF1E4;box-shadow:0 0 0 3px rgba(255,122,46,.35),0 18px 30px -16px rgba(60,35,25,.45)}
.look img{height:190px;width:auto}
.look .t1{font:800 19px Bric}
.radio{width:28px;height:28px;border-radius:50%;border:2.5px solid rgba(33,27,22,.45);background:#fff;display:grid;place-items:center;font:800 16px DMS;color:#211B16}
.look.on .radio{background:#FF7A2E;border-color:#C2540F}
.sel{font:700 13px DMS;min-height:18px;color:#8A3A0C}
.mbtn{position:absolute;z-index:4;right:18px;width:56px;height:56px;border-radius:50%;background:rgba(255,255,255,.78);backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,.9);box-shadow:inset 0 1px 0 #fff,0 12px 22px -8px rgba(60,35,25,.5);display:grid;place-items:center}
.mbtn img{width:48px;height:48px}
'''
def page(name,body,navhtml='',veil=True):
    sb='<div class="sb"><span>9:41</span><span>●●●</span></div>'
    html=f'<!doctype html><html lang="de"><meta charset="utf-8"><title>{name}</title><style>{STYLE}{EX}</style><body>{BG}{sb}{body}{"<div class=veil></div>" if veil else ""}{navhtml}</body></html>'
    open(f'v2-{name}.html','w').write(html)
# ---------- Onboarding: Wie soll Manny aussehen?
steps=''.join(f'<i style="flex:1;height:8px;border-radius:4px;background:{"#FF7A2E" if i==0 else "rgba(33,27,22,.15)"}"></i>' for i in range(5))
hd=f'''<div class="hd" style="top:44px;height:128px;padding:14px 18px"><div class="row" style="gap:6px;margin-bottom:10px">{steps}</div><div style="font:700 13px DMS;opacity:.9">Schritt 1 von 5</div><h1 style="font:800 28px/1.08 Bric;margin-top:2px">Wie soll Manny aussehen?</h1></div>'''
def look(img,name,on):
    return f'<div class="look{" on" if on else ""}" role="radio"><img src="{M}{img}/3.0x/normal.png" alt=""><div class="t1">{name}</div><div class="radio">{"✓" if on else ""}</div><div class="sel">{"Ausgewählt" if on else "&nbsp;"}</div></div>'
body=hd+f'''<div class="col" style="top:190px">
<div class="row" style="gap:12px;align-items:stretch">{look("brille","Mit Brille",True)}{look("ohne","Ohne Brille",False)}</div>
<div class="card" style="padding:12px 16px"><div class="m" style="color:#211B16;font-size:14px">Du kannst das jederzeit im Profil ändern.</div></div>
</div>
<div style="position:absolute;z-index:4;left:14px;right:14px;bottom:30px;display:flex;gap:12px"><div class="glassbtn" style="width:112px;height:56px;border-radius:28px;font-size:16px">Zurück</div><div class="pillbtn" style="flex:1">Weiter</div></div>'''
page('manny-wahl',body,veil=False)
# ---------- Heute mit neuem Manny (Variante mit Brille): Manny-Knopf (Kopf, 56 dp)
h=open('v2-heute.html').read()
h=h.replace('<title>heute</title>','<title>heute-neu</title>').replace('</style>',EX+'</style>',1) if EX not in h else h
btn=f'<div class="mbtn" style="top:672px" role="img" aria-label="Manny, dein Begleiter"><img src="{M}brille/3.0x/kopf.png" alt=""></div>'
h=h.replace('class="lst"','class="lst"',1)
h=h.replace('<div class="veil">',btn+'<div class="veil">',1) if '<div class="veil">' in h else h.replace('<div class=veil>',btn+'<div class=veil>',1)
h=h.replace('.lst>.row{padding:7px 0}','.lst>.row{padding:4px 0}')
h=h.replace('top:152px','top:146px',1)
open('v2-heute-neu.html','w').write(h)
