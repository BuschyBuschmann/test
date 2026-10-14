# Volles Grunddesign v2: sechs Kern-Screens in der Abend-Welt (Beispieldaten, Manny = Platzhalter)
import re
from mannyA import manny, head, sized
ab=open('v2-ansatz3-abend.html').read()
STYLE=re.search(r'<style>(.*?)</style>',ab,re.S).group(1)
BG=re.search(r'<svg class="bgl".*?</svg>',ab,re.S).group().replace('</svg>','',1)
BG=re.sub(r'<path d="M200 700[^>]*/>','',BG)+'</svg>'
tabs=re.findall(r'<div class="t[^"]*">.*?(?=<div class="t|\Z)',open('nav.frag').read(),re.S)
def nav(active):
    out=''
    for i,t in enumerate(tabs):
        t=t.replace('class="t a"','class="t"')
        if i==active: t=t.replace('class="t"','class="t a"',1)
        out+=t.strip()
    return f'<div class="nav">{out}</div>'
ic=lambda d:f'<svg viewBox="0 0 24 24">{d}</svg>'
def pnav(active):
    items=[('Patienten',ic('<circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-4 3-6 6-6s6 2 6 6M16 5a3.5 3.5 0 010 7M18 14c2 1 3 3 3 6"/>')),('Übungen',ic('<path d="M4 9v6M7 7v10M17 7v10M20 9v6M7 12h10"/>')),('Chats',ic('<path d="M5 5h14a2 2 0 012 2v8a2 2 0 01-2 2h-7l-5 4v-4H5a2 2 0 01-2-2V7a2 2 0 012-2z"/>')),('Konto',ic('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-5 4-7 8-7s8 2 8 7"/>'))]
    return '<div class="nav">'+''.join(f'<div class="t{" a" if i==active else ""}" style="width:76px">{s}{n}</div>' for i,(n,s) in enumerate(items))+'</div>'
EX='''
.col{position:absolute;left:14px;right:14px;z-index:3;display:flex;flex-direction:column;gap:12px}
.card{background:rgba(255,255,255,.80);border:1px solid rgba(255,255,255,.9);border-radius:28px;box-shadow:0 18px 30px -16px rgba(60,35,25,.45),inset 0 1px 0 #fff;padding:16px}
.h2{font:800 20px/1.15 Bric;letter-spacing:-.2px}.m{font-size:13px;font-weight:600;color:#5A5048}
.row{display:flex;align-items:center;gap:12px}
.tile{width:56px;height:56px;border-radius:18px;flex:none;background:radial-gradient(circle at 30% 20%,#fff,#FFE2B8 60%,#F5B778);box-shadow:inset 0 1px 2px #fff,inset 0 -6px 10px rgba(150,90,40,.18),0 8px 12px -6px rgba(90,50,30,.35);display:grid;place-items:center}
.chip{display:inline-flex;align-items:center;gap:4px;font-size:13px;font-weight:700;padding:2px 10px;border-radius:99px;background:rgba(33,27,22,.07);color:#211B16}
.pillbtn{height:56px;border-radius:28px;display:flex;align-items:center;justify-content:center;font:800 18px Bric;color:#211B16;background:linear-gradient(180deg,#FFA063,#FF7A2E);box-shadow:inset 0 1px 0 rgba(255,255,255,.7),0 14px 24px -8px rgba(255,122,46,.7)}
.glassbtn{height:52px;border-radius:26px;display:flex;align-items:center;justify-content:center;gap:6px;font:700 14px DMS;color:#211B16;background:rgba(255,255,255,.55);backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,.85);box-shadow:inset 0 1px 0 #fff,0 10px 20px -10px rgba(60,35,25,.4)}
.sm{width:46px;height:46px;border-radius:50%;display:grid;place-items:center;font-size:24px;background:#fff;border:2px solid rgba(33,27,22,.12)}
.sm.on{border-color:#FF7A2E;background:#FFE9D6;box-shadow:0 0 0 3px rgba(255,122,46,.3)}
.chev{margin-left:auto;font-size:20px;color:#5A5048}
.ava{width:48px;height:48px;border-radius:50%;flex:none;display:grid;place-items:center;font:800 18px Bric;color:#fff;background:linear-gradient(135deg,#8A7F9A,#4A4468);border:2px solid #fff}
.badge{min-width:24px;height:24px;border-radius:12px;background:#B3261E;color:#fff;font:700 13px DMS;display:grid;place-items:center;padding:0 6px}
.close{position:absolute;z-index:4;width:48px;height:48px;border-radius:50%;background:rgba(255,255,255,.6);backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,.85);display:grid;place-items:center;font-size:20px;font-weight:700;box-shadow:inset 0 1px 0 #fff}
.bar{height:12px;border-radius:7px;background:rgba(33,27,22,.12);overflow:hidden}.bar i{display:block;height:100%;border-radius:7px;background:linear-gradient(90deg,#FFB070,#FF7A2E)}
.lst>.row{padding:7px 0}.lst>.row+.row{border-top:1px solid rgba(33,27,22,.10)}
'''
def page(name,body,navhtml='',veil=True,hd=None):
    sb='<div class="sb"><span>9:41</span><span>●●●</span></div>'
    html=f'<!doctype html><html lang="de"><meta charset="utf-8"><title>{name}</title><style>{STYLE}{EX}</style><body>{BG}{sb}{body}{"<div class=veil></div>" if veil else ""}{navhtml}</body></html>'
    open(f'v2-{name}.html','w').write(html)
def hdcard(title,sub,top=44,h=96,extra=''):
    return f'<div class="hd" style="top:{top}px;height:{h}px;padding:14px 18px"><h1 style="font:800 30px/1.05 Bric">{title}</h1><p style="font-size:14px;margin-top:2px">{sub}</p>{extra}</div>'
img=lambda d:f'<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#8A3A0C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{d}</svg>'
# ---------- Heute
def exrow(n,meta,loc,d,done=False):
    chk='<div style="width:34px;height:34px;border-radius:50%;border:2.5px solid rgba(33,27,22,.35);margin-left:auto;flex:none"></div>'
    return f'<div class="row"><div class="tile">{img(d)}</div><div style="min-width:0"><div style="font:700 16px DMS">{n}</div><div class="m">{meta}</div><span class="chip" style="margin-top:3px">{loc}</span></div>{chk}</div>'
rows=exrow('Kniebeuge am Stuhl','3 × 12 · Stuhl','Zuhause · Praxis','<path d="M7 3h3v7h6v2h-6v8"/><circle cx="12" cy="5" r="0"/>')+exrow('Brücke mit Band','3 × 10 · Theraband','Zuhause','<path d="M3 17h18M6 17c2-8 10-8 12 0"/>')+exrow('Wadenheben','2 × 15 · ohne Material','Zuhause · Fitnessstudio','<path d="M12 4v10M8 20h8M9 14l3 6 3-6"/>')
smileys=''.join(f'<div class="sm{" on" if i==3 else ""}">{e}</div>' for i,e in enumerate(['😣','😕','😐','🙂','😄']))
body=hdcard('Heute, Jakob','Dienstag, 14. Oktober · Woche 5',extra='<div class="pills" style="top:16px"><div class="pill">🔥 12</div></div>')+f'''
<div class="col" style="top:152px">
<div class="card"><div class="row"><div><div class="h2">Wie geht's dir heute?</div><div class="m">Einmal am Tag · 5 schnelle Fragen</div></div><div class="chev" style="font-weight:700">✕</div></div>
<div class="row" style="justify-content:space-between;margin-top:12px">{smileys}</div>
<div class="row" style="margin-top:12px"><span class="m" style="width:60px">Schmerz</span><div class="bar" style="flex:1"><i style="width:30%"></i></div><b style="font:800 18px Bric;width:40px;text-align:right">3/10</b><div class="glassbtn" style="padding:0 16px;height:44px;margin-left:4px">Weiter</div></div>
</div>
<div class="card" style="padding:14px 16px 6px"><div class="row" style="margin-bottom:2px"><div class="h2">Dein Training</div><span class="m" style="margin-left:auto">ca. 20 Min · 0 von 3</span></div><div class="lst">{rows}</div></div>
<div class="pillbtn">Training starten</div></div>'''
page('heute',body,nav(1))
# ---------- Session
fig='<svg viewBox="0 0 200 140" width="200" height="140" fill="none" stroke="#211B16" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"><circle cx="86" cy="26" r="13" fill="#FFF1D8"/><path d="M88 42 L100 78 L136 82 M100 78 L84 112 L106 128 M136 82 L140 128"/><path d="M30 94h46v34M30 94v34" stroke="#8A3A0C"/><path d="M60 62 L100 66" /></svg>'
body=f'''<div class="close" style="left:14px;top:52px">✕</div>
<div style="position:absolute;z-index:4;left:72px;right:92px;top:62px"><div class="bar" style="height:14px;background:rgba(255,255,255,.55)"><i style="width:40%"></i></div><div style="text-align:center;font:700 13px DMS;color:#211B16;margin-top:4px;background:rgba(255,255,255,.72);border-radius:99px;display:inline-block;padding:0 10px;margin-left:50px">Übung 2 von 5</div></div>
<div class="pill" style="position:absolute;z-index:4;right:14px;top:56px;background:rgba(255,255,255,.72);color:#211B16;border-color:rgba(255,255,255,.9);font:800 17px Bric">08:42</div>
<div class="col" style="top:118px"><div class="card" style="padding:12px 14px 14px"><div style="height:168px;border-radius:22px;background:radial-gradient(circle at 30% 20%,#fff,#FFE2B8 55%,#F5B778);display:grid;place-items:center;position:relative;box-shadow:inset 0 1px 2px #fff">{fig}<span class="chip" style="position:absolute;left:10px;top:10px;background:rgba(255,255,255,.8)">Startposition · Bild folgt</span></div>
<div class="h2" style="font-size:24px;margin-top:12px">Kniebeuge am Stuhl</div><div class="m" style="font-size:14px;margin-top:2px">Langsam setzen, Knie über den Zehen, Rücken gerade.</div>
<div class="row" style="margin-top:8px"><span class="chip">Stuhl</span><span class="chip">Zuhause</span><span class="chip">Satz 2 von 3</span></div></div></div>
<div style="position:absolute;z-index:3;left:120px;top:512px;width:150px;height:150px" class="orb cur"><div style="position:relative;z-index:1;text-align:center;color:#211B16"><div style="font:800 52px/1 Bric">7<span style="font-size:30px"> / 12</span></div><div style="font:700 13px DMS">tippen zum Zählen</div></div></div>
<div class="shadow" style="left:122px;top:664px;width:146px"></div>
<div style="position:absolute;z-index:3;left:14px;top:560px;width:96px">{sized(manny('standard','s'),96)}</div>
<div style="position:absolute;z-index:3;right:14px;top:548px;max-width:100px;background:rgba(255,255,255,.82);border-radius:20px;padding:8px 12px;font:700 14px/1.2 DMS;box-shadow:0 10px 18px -10px rgba(60,35,25,.5)">Noch 5, du schaffst das!</div>
<div style="position:absolute;z-index:4;left:14px;right:14px;bottom:30px;display:flex;gap:10px"><div class="glassbtn" style="flex:1">⏸ Pause</div><div class="glassbtn" style="flex:1">⏭ Überspringen</div><div class="glassbtn" style="flex:1">⚠ Schmerz</div></div>'''
page('session',body,'',veil=False)
# ---------- Check-up
body=f'''<div style="position:absolute;z-index:4;left:0;right:0;top:36px;text-align:center">{sized(manny('feier','c'),170)}</div>
<div class="col" style="top:216px"><div class="card" style="padding:44px 18px 18px;margin-top:0;text-align:center"><div class="h2" style="font-size:30px">Geschafft, Jakob!</div>
<div class="row" style="justify-content:center;margin-top:10px;flex-wrap:wrap;gap:8px"><span class="chip">18 Min</span><span class="chip">5 von 5 Übungen</span><span class="chip">🔥 13 Tage</span></div></div>
<div class="card"><div class="h2">Wie lief's?</div><div class="row" style="justify-content:space-between;margin-top:12px">{''.join(f'<div class="sm{" on" if i==3 else ""}" style="width:52px;height:52px">{e}</div>' for i,e in enumerate(['😣','😕','😐','🙂','😄']))}</div></div>
<div class="card"><div class="row"><div><div class="h2" style="font-size:17px">Details je Übung?</div><div class="m">Optional · leicht, passend, schwer, Schmerz</div></div><div class="chev">›</div></div></div>
<div class="pillbtn">Speichern</div><div style="text-align:center;font:700 16px DMS;padding:10px;color:#211B16;background:rgba(255,255,255,.6);border-radius:24px">Später</div></div>'''
page('checkup',body,'',veil=False)
# ---------- Profil
def li(t,s='',i=''): return f'<div class="row" style="min-height:52px"><span style="font-size:22px;width:28px">{i}</span><div><div style="font:700 16px DMS">{t}</div>{f"<div class=m>{s}</div>" if s else ""}</div><div class="chev">›</div></div>'
body=f'''<div class="hd" style="top:44px;height:150px;padding:16px 18px"><div class="row" style="gap:16px"><div class="orb" style="position:relative;width:84px;height:84px;color:#211B16;font:800 36px Bric;box-shadow:0 14px 18px -10px rgba(0,0,0,.5),inset 0 2px 2px #fff,inset 0 -8px 12px rgba(130,90,60,.25)"><span style="position:relative;z-index:1">J</span></div><div><h1 style="font:800 30px/1.05 Bric">Jakob</h1><p style="font-size:14px">Kreuzband · Phase 2 · Woche 5</p></div></div></div>
<div class="col" style="top:208px"><div class="row" style="gap:10px">{''.join(f'<div class="card" style="flex:1;padding:12px;text-align:center"><div style="font:800 28px Bric">{n}</div><div class="m">{l}</div></div>' for n,l in [('🔥 12','Streak'),('34','Trainingstage'),('❄ 2','Freezes')])}</div>
<div class="card" style="padding:6px 16px"><div class="lst">{li('Mein Plan und meine Verletzung','','🩹')}{li('Frage an meinen Physio','2 offen','💬')}{li('Deine Daten','Export, Löschen','🔒')}{li('Erinnerungen','Täglich 18:00','🔔')}{li('Darstellung','Welt: Automatisch (Tageszeit)','🌅')}{li('Hilfe und Datenschutz','','ℹ️')}</div></div></div>'''
page('profil',body,nav(4))
# ---------- Chats
def chat(av,name,sub,prev,time,badge='',bg=''):
    return f'<div class="row" style="padding:12px 0;{bg}"><div style="position:relative">{av}</div><div style="min-width:0;flex:1"><div class="row" style="gap:6px"><b style="font:700 16px DMS">{name}</b><span class="m">{sub}</span></div><div class="m" style="font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:200px">{prev}</div></div><div style="text-align:right"><div class="m">{time}</div>{f"<span class=badge style=margin-top:4px>{badge}</span>" if badge else ""}</div></div>'
mav=f'<div class="ava" style="background:#F4E9D8;overflow:hidden;padding:0">{head("ca").replace("width=\"64\" height=\"55\"","width=\"50\" height=\"43\"")}</div>'
body=hdcard('Chats','Dein Team an einem Ort',h=96)+f'''<div class="col" style="top:152px"><div class="card" style="padding:4px 16px"><div class="lst">
{chat(mav,'Manny','Angeheftet 📌','Moin Jakob, 12 Tage in Folge. Heute zählt.','18:02')}
{chat('<div class="ava">AK</div>','Anna Keller','Physio','Super gemacht! Nächste Woche steigern wir …','17:40','2')}
{chat('<div class="ava" style="background:linear-gradient(135deg,#7F9A8A,#3E5A4C)">MV</div>','Dr. M. Vogt','Arzt','Befund liegt vor, bitte Termin bestätigen.','Mo')}
{chat('<div class="ava" style="background:linear-gradient(135deg,#9A7F8A,#5A3E4C)">PT</div>','Praxis-Team','Praxis','Termin Do 16:30 ist bestätigt.','So')}
</div></div><div class="card" style="text-align:center;font:600 14px DMS;color:#5A5048">Beispieldaten · Namen erfunden</div></div>'''
page('chats',body,nav(3))
# ---------- Physio am Handy
spark='<svg width="150" height="46" viewBox="0 0 150 46" fill="none" stroke="#B8470F" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M2 14 L20 10 L38 22 L56 18 L74 30 L92 26 L110 34 L128 30 L148 36"/><circle cx="148" cy="36" r="4" fill="#B8470F"/></svg>'
def meter(l,v,w): return f'<div class="row" style="gap:8px;margin-top:4px"><span class="m" style="width:86px">{l}</span><div class="bar" style="flex:1;height:10px"><i style="width:{w}%"></i></div><b style="font:700 14px DMS;width:30px;text-align:right">{v}</b></div>'
body=f'''<div class="hd" style="top:44px;height:112px;padding:14px 18px"><h1 style="font:800 28px/1.05 Bric">Jakob M.</h1><p style="font-size:14px;margin-top:2px">VKB-Plastik · Woche 5 · Phase 2</p><p style="font-size:14px;margin-top:2px">Letzter Termin vor 6 Tagen</p></div>
<div class="col" style="top:168px;gap:10px">
<div class="card" style="padding:12px 16px"><div class="row"><b style="font:800 16px Bric">Befinden · Motivation</b><span class="chip" style="margin-left:auto;background:#FFE3DD;color:#7A1A12">⚠ 1 Warnzeichen</span></div>{meter('Wohlbefinden','7/10',70)}{meter('Motivation','6/10',60)}<div class="m" style="margin-top:6px;color:#7A1A12;font-weight:700">⚠ Schmerz an 3 Tagen ≥ 6 (nur Hinweis)</div></div>
<div class="card" style="padding:12px 16px"><div class="row"><div><b style="font:800 16px Bric">Schmerz-Trend</b><div class="m">30 Tage · jetzt 3/10 ↓</div></div><div style="margin-left:auto">{spark}</div></div></div>
<div class="card" style="padding:12px 16px"><div class="row"><div><b style="font:800 16px Bric">Training seit Termin</b><div class="m">4 von 6 Tagen · Streak 12</div></div><div style="margin-left:auto;font:800 30px/1 Bric">4/6</div></div></div>
<div class="card" style="padding:12px 16px"><b style="font:800 16px Bric">Übungen gut / schlecht</b><div class="row" style="flex-wrap:wrap;gap:6px;margin-top:8px"><span class="chip" style="background:#DDF3E6;color:#14532D">✓ Brücke passend</span><span class="chip" style="background:#DDF3E6;color:#14532D">✓ Wadenheben leicht</span><span class="chip" style="background:#FFE3DD;color:#7A1A12">⚠ Kniebeuge Schmerz</span></div></div>
<div class="card" style="padding:12px 16px"><div class="row"><b style="font:800 16px Bric">Fragen des Patienten</b><span class="chip" style="margin-left:auto">2 offen</span></div></div>
<div class="card" style="padding:12px 16px"><b style="font:800 16px Bric">Phase und nächstes Ziel</b><div class="m">Phase 2 · Treppen ohne Schmerz</div></div>
</div>'''
page('physio',body,pnav(0))
