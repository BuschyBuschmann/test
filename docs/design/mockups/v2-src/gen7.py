# Mockups Brief v2, Ergänzung 2 (Paket F2-D2 Teil A und B), Abend-Welt, 390 x 844.
# Ergänzt gen5.py/gen6.py (nicht ersetzt): gleiche Welt, gleiche Stilbausteine.
# Ausgabe: v2-e2-*.html (PNG per r9.js nach ../v2-e2-*.png). Beispieldaten, Namen erfunden.
import re
ab = open('v2-ansatz3-abend.html').read()
STYLE = re.search(r'<style>(.*?)</style>', ab, re.S).group(1)
BG = re.search(r'<svg class="bgl".*?</svg>', ab, re.S).group().replace('</svg>', '', 1)
BG = re.sub(r'<path d="M200 700[^>]*/>', '', BG) + '</svg>'
src5 = open('gen5.py').read()
EX = re.search(r"EX='''(.*?)'''", src5, re.S).group(1)
M = '../../manny/'
EX += '''
.mbtn{position:absolute;z-index:4;right:18px;width:56px;height:56px;border-radius:50%;background:rgba(255,255,255,.78);border:1px solid rgba(255,255,255,.9);box-shadow:inset 0 1px 0 #fff,0 12px 22px -8px rgba(60,35,25,.5);display:grid;place-items:center}
.look{flex:1;border-radius:28px;background:rgba(255,255,255,.92);border:3px solid rgba(33,27,22,.45);box-shadow:0 18px 30px -16px rgba(60,35,25,.45),inset 0 1px 0 #fff;padding:10px 8px 12px;display:flex;flex-direction:column;align-items:center;gap:5px;min-height:272px}
.look.on{border-color:#FF7A2E;background:#FFF1E4}
.look img{height:164px;width:auto}
.look .t1{font:800 19px Bric}
.radio{width:28px;height:28px;border-radius:50%;border:2.5px solid rgba(33,27,22,.55);background:#fff;display:grid;place-items:center;font:800 16px DMS;color:#211B16}
.look.on .radio{background:#FF7A2E;border-color:#C2540F}
.sel{font:700 13px DMS;min-height:18px;color:#8A3A0C}
.c92{background:rgba(255,255,255,.92)}
.steps{display:flex;gap:6px}.steps i{flex:1;height:8px;border-radius:4px;background:rgba(255,255,255,.25)}.steps i.on{background:#FF7A2E}
.q{font:800 19px/1.2 Bric}
.st{flex:1;height:88px;border-radius:20px;background:#fff;border:2px solid rgba(33,27,22,.55);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:7px;position:relative;font:700 14px DMS;color:#211B16}
.st.on{border:3px solid #FF7A2E;background:#FFF1E4}
.st .ck{position:absolute;right:5px;top:5px;width:20px;height:20px;border-radius:50%;background:#FF7A2E;color:#211B16;font:800 12px DMS;display:grid;place-items:center}
.gl{display:flex;gap:3px;align-items:flex-end;height:22px}.gl b{width:9px;border-radius:3px;border:2px solid #211B16;background:transparent;display:block}.gl b.f{background:#211B16}
.gl b:nth-child(1){height:10px}.gl b:nth-child(2){height:16px}.gl b:nth-child(3){height:22px}
.nt{border-radius:24px;background:#fff;border:2.5px solid rgba(33,27,22,.7);padding:14px 16px;display:flex;gap:12px;box-shadow:0 14px 24px -14px rgba(60,35,25,.5)}
.nt .ic{width:36px;height:36px;border-radius:50%;background:#211B16;color:#fff;display:grid;place-items:center;font:800 19px DMS;flex:none}
.nt h3{font:800 17px/1.2 Bric}.nt p{font:500 14.5px/1.35 DMS;margin-top:3px;color:#211B16}
.fld{height:68px;border-radius:22px;background:#fff;border:3px solid rgba(33,27,22,.55);display:flex;align-items:center;padding:0 18px;font:800 27px Bric;letter-spacing:2px;color:#211B16}
.fld.err{border-color:#B3261E}
.lbl2{font:700 14px DMS;color:#211B16}
.sbtn{height:52px;border-radius:26px;display:flex;align-items:center;justify-content:center;gap:6px;font:700 15px DMS;color:#211B16;background:rgba(255,255,255,.9);border:1.5px solid rgba(33,27,22,.55);padding:0 20px}
.stat{display:inline-flex;align-items:center;gap:5px;font:700 13px DMS;padding:3px 10px;border-radius:99px;background:rgba(33,27,22,.08)}
.stat.ok{background:#DDF3E6;color:#14532D}.stat.wait{background:#FFE9D6;color:#7A3A0C}
.cl{display:flex;gap:10px;align-items:flex-start;padding:7px 0}.cl+.cl{border-top:1px solid rgba(33,27,22,.10)}
.cl .t{flex:none;width:24px;height:24px;border-radius:50%;background:#1B6E47;color:#fff;font:800 14px DMS;display:grid;place-items:center;margin-top:1px}
.cl .x{flex:none;width:24px;height:24px;border-radius:50%;background:#211B16;color:#fff;font:800 14px DMS;display:grid;place-items:center;margin-top:1px}
.cl div.b{font:500 14.5px/1.35 DMS}.cl div.b b{font-weight:800}
'''
tabs = re.findall(r'<div class="t[^"]*">.*?(?=<div class="t|\Z)', open('nav.frag').read(), re.S)
tabs = [t for i, t in enumerate(tabs) if i != 2]  # Ausschnitt 2: kein Feed-Ziel
def nav(active):
    out = ''
    for i, t in enumerate(tabs):
        t = t.replace('class="t a"', 'class="t"')
        if i == active: t = t.replace('class="t"', 'class="t a"', 1)
        out += t.strip()
    return f'<div class="nav">{out}</div>'
ic=lambda d:f'<svg viewBox="0 0 24 24">{d}</svg>'
def pnav(active):
    items=[('Patienten',ic('<circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-4 3-6 6-6s6 2 6 6M16 5a3.5 3.5 0 010 7M18 14c2 1 3 3 3 6"/>')),('Übungen',ic('<path d="M4 9v6M7 7v10M17 7v10M20 9v6M7 12h10"/>')),('Chats',ic('<path d="M5 5h14a2 2 0 012 2v8a2 2 0 01-2 2h-7l-5 4v-4H5a2 2 0 01-2-2V7a2 2 0 012-2z"/>')),('Konto',ic('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-5 4-7 8-7s8 2 8 7"/>'))]
    return '<div class="nav">'+''.join(f'<div class="t{" a" if i==active else ""}" style="width:76px">{sv}{n}</div>' for i,(n,sv) in enumerate(items))+'</div>'
def page(name, body, navhtml='', veil=True):
    sb = '<div class="sb"><span>9:41</span><span>●●●</span></div>'
    html = f'<!doctype html><html lang="de"><meta charset="utf-8"><title>{name}</title><style>{STYLE}{EX}</style><body>{BG}{sb}{body}{"<div class=veil></div>" if veil else ""}{navhtml}</body></html>'
    open(f'v2-e2-{name}.html', 'w').write(html)
def steps(n, total):
    return '<div class="steps">' + ''.join(f'<i class="{"on" if i < n else ""}"></i>' for i in range(total)) + '</div>'
def hdcard(title, sub='', top=44, h=96, extra=''):
    return f'<div class="hd" style="top:{top}px;height:{h}px;padding:14px 18px"><h1 style="font:800 30px/1.05 Bric">{title}</h1><p style="font-size:14px;margin-top:2px">{sub}</p>{extra}</div>'
def look(img, name, on):
    return f'<div class="look{" on" if on else ""}" role="radio"><img src="{M}{img}/3.0x/normal.png" alt=""><div class="t1">{name}</div><div class="radio">{"✓" if on else ""}</div><div class="sel">{"Ausgewählt" if on else "&nbsp;"}</div></div>'
def botbar(*items):
    return '<div style="position:absolute;z-index:4;left:14px;right:14px;bottom:30px;display:flex;gap:12px">' + ''.join(items) + '</div>'
Z = '<div class="glassbtn" style="width:112px;height:56px;border-radius:28px;font-size:16px">Zurück</div>'
def W(t): return f'<div class="pillbtn" style="flex:1">{t}</div>'

# ---------- 1) Code-Start, Schritt 1 von 3: Look
hd = f'<div class="hd" style="top:44px;height:128px;padding:14px 18px">{steps(1,3)}<div style="font:700 13px DMS;opacity:.9;margin-top:10px">Schritt 1 von 3</div><h1 style="font:800 28px/1.08 Bric;margin-top:2px">Wie soll Manny aussehen?</h1></div>'
body = hd + f'''<div class="col" style="top:190px">
<div class="row" style="gap:12px;align-items:stretch">{look("brille","Mit Brille",True)}{look("ohne","Ohne Brille",False)}</div>
<div class="card c92" style="padding:12px 16px"><div class="m" style="color:#211B16;font-size:14px">Du kannst das jederzeit im Profil ändern.</div></div>
<div class="card c92" style="padding:12px 16px"><div class="m" style="color:#211B16;font-size:14px"><b>Danach:</b> Code von deinem Physio eingeben.</div></div>
</div>''' + botbar('<div style="width:112px"></div>', W('Weiter'))
page('codestart-look', body, veil=False)

# ---------- 2) Code-Start, Schritt 2 von 3: Zugang über deinen Physio (Ergebnis: Code schon benutzt)
hd = f'<div class="hd" style="top:44px;height:128px;padding:14px 18px">{steps(2,3)}<div style="font:700 13px DMS;opacity:.9;margin-top:10px">Schritt 2 von 3</div><h1 style="font:800 28px/1.08 Bric;margin-top:2px">Zugang über deinen Physio</h1></div>'
body = hd + f'''<div class="col" style="top:188px">
<div class="row" style="align-items:flex-end;gap:6px"><img src="{M}brille/3.0x/normal.png" style="height:112px;width:auto" alt=""><div style="background:rgba(255,255,255,.92);border-radius:20px;padding:10px 14px;font:700 15px/1.25 DMS;margin-bottom:34px;box-shadow:0 10px 18px -10px rgba(60,35,25,.5)">Moin! Den Code bekommst du von deinem Physio.</div></div>
<div class="card c92" style="padding:14px 16px"><div class="lbl2">Dein Code</div>
<div class="fld err" style="margin-top:6px">K7M2Q-9XH4T</div>
<div class="row" style="gap:8px;margin-top:10px;align-items:flex-start"><span style="width:26px;height:26px;border-radius:50%;background:#B3261E;color:#fff;font:800 15px DMS;display:grid;place-items:center;flex:none">!</span><div style="font:600 14.5px/1.3 DMS;color:#B3261E">Dieser Code wurde schon benutzt. Bitte deinen Physio um einen neuen Code.</div></div>
</div>
<div class="card c92" style="padding:12px 16px"><div class="m" style="color:#211B16;font-size:14px">Dein Physio legt dich an und gibt dir einen Code oder QR-Code. Ohne Code geht es nicht weiter. Hast du einen Link bekommen, öffne ihn: Der Code steht dann schon im Feld.</div></div>
</div>''' + botbar(Z, W('Weiter'))
page('codestart-code', body, veil=False)

# ---------- 3) Einwilligung (physio_sharing-2)
hd = f'<div class="hd" style="top:44px;height:128px;padding:14px 18px">{steps(3,3)}<div style="font:700 13px DMS;opacity:.9;margin-top:10px">Schritt 3 von 3</div><h1 style="font:800 28px/1.08 Bric;margin-top:2px">Was dein Physio sieht</h1></div>'
body = hd + f'''<div class="col" style="top:184px;bottom:104px;overflow:hidden">
<div class="card c92" style="padding:12px 16px 8px"><div class="h2" style="font-size:17px">Damit dein Physio dich begleiten kann, sieht er:</div>
<div class="cl"><span class="t">✓</span><div class="b"><b>deinen Verlauf:</b> erledigte und übersprungene Übungen, bei übersprungenen mit Grund</div></div>
<div class="cl"><span class="t">✓</span><div class="b"><b>deine Check-ups:</b> Schmerz, Schwellung, Einschränkungen, Wohlbefinden, Motivation und Stimmung</div></div>
<div class="cl"><span class="t">✓</span><div class="b"><b>deine Fragen</b> an deinen Physio</div></div>
<div class="cl"><span class="t">✓</span><div class="b"><b>Warnzeichen,</b> zum Beispiel bei hohem Schmerz oder starker Schwellung. Auch Warnzeichen aus deinem Chat mit Manny, bis hin zu Hinweisen auf eine Krise. Dazu sieht er nur Stufe und Zeitpunkt, keinen Text aus dem Chat.</div></div>
<div class="cl"><span class="t">✓</span><div class="b"><b>eine Meldung zur Stimmung:</b> War sie an 5 Tagen mit Check-up hintereinander sehr schlecht (die zwei schlechtesten Smileys), bekommt er eine Meldung, an jedem weiteren Tag wieder. Details sieht er nicht. Die App zeigt dir diese Meldung nicht an.</div></div>
</div>
<div class="card c92" style="padding:12px 16px 8px"><div class="h2" style="font-size:17px">Das sieht er nie</div>
<div class="cl"><span class="x">✕</span><div class="b"><b>Deinen Chat mit Manny.</b> Er bleibt privat.</div></div></div>
</div>
''' + botbar(W('Ich bin einverstanden'))
body += '<div style="position:absolute;z-index:4;left:14px;right:14px;bottom:4px;text-align:center;font:700 14px DMS;color:#211B16">Datenschutzerklärung lesen</div>'
page('einwilligung', body, veil=False)

# ---------- 4/5) Tages-Check-up Frage 3 (Schwellung) und Frage 5 (Einschränkungen)
def glyph(n):
    return '<div class="gl">' + ''.join(f'<b class="{"f" if i < n else ""}"></b>' for i in range(3)) + '</div>'
def scale(sel):
    words = ['keine', 'leicht', 'deutlich', 'stark']
    return '<div class="row" style="gap:8px;margin-top:14px;align-items:stretch">' + ''.join(
        f'<div class="st{" on" if i == sel else ""}" role="radio">{"<span class=ck>✓</span>" if i == sel else ""}{glyph(i)}<span>{w}</span></div>' for i, w in enumerate(words)) + '</div>'
def checkup(n, question, control, selected_txt):
    prog = '<div class="steps" style="margin-top:10px">' + ''.join(f'<i style="background:{"#FF7A2E" if i < n else "rgba(33,27,22,.14)"}"></i>' for i in range(6)) + '</div>'
    return f'''<div class="card c92" style="padding:14px 16px 16px"><div class="row"><div><div class="h2">Wie geht's dir heute?</div><div class="m">Einmal am Tag · 6 schnelle Fragen</div></div><div class="chev" style="font-weight:700">✕</div></div>
<div style="font:700 14px DMS;margin-top:12px">Frage {n} von 6</div>{prog}
<div class="q" style="margin-top:14px">{question}</div>{control}
<div class="m" style="margin-top:8px;color:#211B16">{selected_txt}</div>
<div class="row" style="margin-top:12px;gap:10px"><div class="sbtn" style="width:112px;height:56px;border-radius:28px">Zurück</div><div class="pillbtn" style="flex:1">Weiter</div></div></div>'''
heute_hd = hdcard('Heute, Jakob', 'Dienstag, 14. Oktober · Woche 5', extra='<div class="pills" style="top:16px"><div class="pill">🔥 12</div></div>')
trainings = '<div class="card c92" style="padding:14px 16px 6px"><div class="row"><div class="h2">Dein Training</div><span class="m" style="margin-left:auto">ca. 20 Min · 0 von 3</span></div></div>'
page('checkup-schwellung', heute_hd + '<div class="col" style="top:152px">' + checkup(3, 'Wie geschwollen ist die verletzte Stelle heute?', scale(2), 'Ausgewählt: deutlich') + trainings + '</div>', nav(1))
page('checkup-einschraenkung', heute_hd + '<div class="col" style="top:152px">' + checkup(5, 'Wie sehr schränkt dich die Verletzung heute im Alltag ein?', scale(1), 'Ausgewählt: leicht') + trainings + '</div>', nav(1))

# ---------- 6) Frage an meinen Physio
def qitem(text, date, status):
    return f'<div style="padding:12px 0"><div style="font:500 15px/1.35 DMS">{text}</div><div class="row" style="margin-top:8px;gap:8px;flex-wrap:wrap"><span class="stat {status[0]}">{status[1]}</span><span class="m">{date}</span></div></div>'
body = hdcard('Frage an meinen Physio', 'Kein Chat. Dein Physio liest sie und bespricht sie mit dir.', h=150) + f'''<div class="col" style="top:206px">
<div class="card c92" style="padding:14px 16px"><div class="lbl2">Deine Frage</div>
<div style="margin-top:6px;border-radius:18px;background:#fff;border:3px solid rgba(33,27,22,.55);padding:10px 14px;min-height:92px;font:500 15.5px/1.35 DMS">Darf ich beim Treppensteigen schon das ganze Bein belasten oder lieber noch mit Geländer?</div>
<div class="row" style="margin-top:6px"><span class="m">Gesendete Fragen lassen sich nicht ändern.</span><span class="m" style="margin-left:auto;white-space:nowrap">88 / 500</span></div>
<div class="pillbtn" style="margin-top:10px">Frage senden</div></div>
<div class="card c92" style="padding:8px 16px 4px"><div class="h2" style="font-size:17px;padding-top:6px">Deine Fragen</div>
{qitem('Wann darf ich wieder Fahrrad fahren?','heute, 08:12',('wait','↻ Wird gesendet'))}
<div style="border-top:1px solid rgba(33,27,22,.10)"></div>
{qitem('Ist das Ziehen hinten im Knie normal?','gestern',('','○ offen'))}
<div style="border-top:1px solid rgba(33,27,22,.10)"></div>
{qitem('Reicht das Theraband in Grün noch?','12. Okt. · besprochen am 13. Okt.',('ok','✓ besprochen'))}
</div></div>'''
page('frage-physio', body, nav(3))

# ---------- 7) Heute: fester Hinweis und „Heute etwas kürzer“
rows = ''.join(f'<div class="row"><div class="tile" style="width:48px;height:48px;border-radius:16px"></div><div style="min-width:0"><div style="font:700 15.5px DMS">{n}</div><div class="m">{m}</div></div><span class="stat" style="margin-left:auto">▾ gekürzt</span></div>' for n, m in [('Kniebeuge am Stuhl', '2 × 12 statt 3 × 12'), ('Brücke mit Band', '2 × 10 statt 3 × 10')])
body = heute_hd + f'''<div class="col" style="top:152px">
<div class="card c92" style="padding:12px 16px"><div class="row"><div><div class="h2" style="font-size:18px">Erledigt, danke!</div><div class="m">Check-up von heute</div></div><span class="stat ok" style="margin-left:auto">✓ Gesendet</span></div></div>
<div class="nt" role="status"><div class="ic">!</div><div><h3>Hinweis zu deinen Werten</h3><p>Deine Angaben zu Schmerz oder Schwellung sind heute auffällig. Dein Physio sieht sie in deinem Verlauf. Bist du unsicher oder wird es schlimmer, sprich ihn an oder such ärztliche Hilfe.</p></div></div>
<div class="card c92" style="padding:14px 16px 10px"><div class="row"><div class="h2">Dein Training</div><span class="m" style="margin-left:auto">ca. 10 Min · 0 von 2</span></div>
<div class="row" style="margin-top:8px;align-items:flex-start;gap:10px;background:rgba(33,27,22,.06);border-radius:16px;padding:10px 12px"><span style="font:800 18px DMS;width:24px;text-align:center">▾</span><div><div style="font:800 15px DMS">Heute etwas kürzer</div><div style="font:500 14px/1.3 DMS">Weil dein Schmerz heute höher ist, ist dein Programm kürzer: ca. 10 statt 20 Min.</div></div></div>
<div class="lst" style="margin-top:4px">{rows}</div></div></div>'''
page('hinweis-heute', body, nav(1))

# ---------- 8) Physio-Kachel 2 mit Schwellung und Einschränkung
def kv(k, v, g=None):
    gl = glyph(g) if g is not None else ''
    return f'<div class="row" style="padding:7px 0;border-top:1px solid rgba(33,27,22,.10)"><span class="m" style="width:104px;color:#211B16">{k}</span><span style="font:700 15px DMS">{v}</span><span style="margin-left:auto">{gl}</span></div>'
body = hdcard('Jakob Beispiel', 'Kreuzband · Woche 5 · Phase 2', h=96) + f'''<div class="col" style="top:152px">
<div class="card" style="background:rgba(255,255,255,.96);padding:14px 16px 6px"><div class="row"><div class="h2">Befinden, Motivation, Warnzeichen</div><div class="chev">›</div></div>
<div style="margin-top:8px;display:flex;gap:6px;flex-wrap:wrap"><span class="stat" style="background:#FFE3DD;color:#7A1A12">⚠ Schwellung stark</span><span class="stat" style="background:#FFE3DD;color:#7A1A12">⚠ Schmerz 8 von 10</span></div>
<div class="m" style="margin-top:8px;color:#211B16">Check-up von heute, 07:40</div>
<div style="margin-top:2px">{kv('Wohlbefinden','🙂 gut (4 von 5)')}{kv('Motivation','😐 mittel (3 von 5)')}{kv('Stimmung','🙂 gut (4 von 5)')}{kv('Schwellung','stark (3 von 3)',3)}{kv('Einschränkung','deutlich (2 von 3)',2)}</div></div>
<div class="card" style="background:rgba(255,255,255,.96);padding:12px 16px"><div class="m" style="color:#211B16">Beispieldaten, Namen erfunden. Am Rechner steht die Kachel in der dreispaltigen Übersicht.</div></div></div>'''
page('kachel2', body, pnav(0))

# ---------- 9) Pfad-Zustände (Zustandsbrett): erledigt, ausgelassen, aktuell, gesperrt
def orb(cls, size, top, left, inner, extra=''):
    return f'<div class="orb {cls}" style="width:{size}px;height:{size}px;top:{top}px;left:{left}px;{extra}"><span style="position:relative;z-index:1;font:800 {int(size*.42)}px DMS;color:#8A3A0C">{inner}</span></div>'
def lab(t, top, left): return f'<div class="lbl" style="top:{top}px;left:{left}px">{t}</div>'
skip = 'border:3px dashed rgba(33,27,22,.55);background:rgba(255,255,255,.38);box-shadow:inset 0 1px 1px rgba(255,255,255,.9),0 10px 14px -10px rgba(40,25,30,.35);'
body = hdcard('Pfad', 'Woche 5 · Phase 2 · Kreuzband', h=96) + orb('done', 56, 190, 70, '✓') + lab('Woche 3, Tag 2 · erledigt', 205, 140) \
    + orb('', 56, 300, 70, '↷', skip) + lab('Woche 4, Tag 1 · ausgelassen', 315, 140) \
    + orb('cur', 92, 400, 56, '⚑', '') + lab('Heute · aktuell', 430, 160) \
    + orb('lock', 56, 530, 70, '🔒', '') + lab('Woche 5, Tag 3 · gesperrt', 545, 140) \
    + '<div class="nt" style="position:absolute;z-index:3;left:14px;right:14px;top:612px"><div class="ic" style="background:#5A5048">↷</div><div><h3>Ausgelassen</h3><p>Diesen Tag hast du ausgelassen. Das ist okay. Mach mit der aktuellen Einheit weiter.</p></div></div>'
page('pfad-ausgelassen', body, nav(0))
print('ok')
