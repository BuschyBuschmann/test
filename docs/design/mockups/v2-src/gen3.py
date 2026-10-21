# Erzeugt die vier Tageszeiten-Mockups (Ansatz 3) und berechnet die Kontraste.
import json
def lin(c):
    c/=255; return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def rgb(h): h=h.lstrip('#'); return [int(h[i:i+2],16) for i in (0,2,4)]
def L(h): r,g,b=rgb(h); return .2126*lin(r)+.7152*lin(g)+.0722*lin(b)
def cr(a,b):
    x,y=L(a),L(b); x,y=max(x,y),min(x,y); return (x+.05)/(y+.05)
def mix(fg,bg,a): return '#%02X%02X%02X'%tuple(round(a*x+(1-a)*y) for x,y in zip(rgb(fg),rgb(bg)))
BK=['#000000','#FFFFFF','#FF7A2E']
day=dict(ink='#211B16',ink2='#5A5048')
T={
'morgen':dict(name='Morgen',sky=['#BCD2EA','#F3C6B6 34%','#F7DFCB 58%','#F6EDE0 80%','#F7F2EB'],bottom='#F7F2EB',
 sun=('24%','28%'),sunc='#FFE9C2',sunc2='#FFD3A0',far='#B4AFC6',mid='#D2C0BC',near='#F6EDE2',mist='255,255,255',mistA=.5,
 card='#2A211C',cardA=.66,txt='#FFFFFF',txt2='#F2EBE3',chip='#FFFFFF',chipA=.72,chipTxt='#211B16',
 navTint='#FFFFFF',navRest=.35,navAct=.78,navInk='#211B16',navInk2='#5A5048',
 lockStroke='#5A5048',lockBg='rgba(235,228,224,.55)',pathStroke='#FFFFFF',pathShadow='rgba(120,90,80,.45)',stars=0,grainBlend='multiply'),
'mittag':dict(name='Mittag',sky=['#8EC3EC','#CDE5F4 36%','#E9F2EE 60%','#F6F3EA 82%','#F7F2EB'],bottom='#F7F2EB',
 sun=('70%','9%'),sunc='#FFFFFF',sunc2='#FFF1C2',far='#9DB6C6',mid='#C4D3D1',near='#F1F0E8',mist='255,255,255',mistA=.55,
 card='#23303A',cardA=.66,txt='#FFFFFF',txt2='#EEF3F6',chip='#FFFFFF',chipA=.74,chipTxt='#211B16',
 navTint='#FFFFFF',navRest=.35,navAct=.78,navInk='#211B16',navInk2='#4F5A60',
 lockStroke='#4F5A60',lockBg='rgba(228,234,236,.6)',pathStroke='#FFFFFF',pathShadow='rgba(70,90,110,.5)',stars=0,grainBlend='multiply'),
'abend':dict(name='Abend',sky=['#F2B58C','#E8A68A 16%','#C8B1A8 36%','#DCCFC4 58%','#F1E8DD 80%','#F7F2EB'],bottom='#F7F2EB',
 sun=('78%','20%'),sunc='#FFE9C8',sunc2='#FFC48A',far='#A99AA6',mid='#9C8E9B',near='#F4ECE2',mist='255,225,200',mistA=.5,
 card='#281E18',cardA=.66,txt='#FFFFFF',txt2='#F2EBE3',chip='#FFFFFF',chipA=.72,chipTxt='#211B16',
 navTint='#FFFFFF',navRest=.35,navAct=.78,navInk='#211B16',navInk2='#5A5048',
 lockStroke='#5A5048',lockBg='rgba(235,228,224,.55)',pathStroke='#FFFFFF',pathShadow='rgba(100,60,40,.4)',stars=0,grainBlend='multiply'),
'nacht':dict(name='Nacht',sky=['#141A33','#2B2547 30%','#4A3548 55%','#2B2230 78%','#1C1620'],bottom='#1C1620',
 sun=('78%','18%'),sunc='#FFF3D6',sunc2='#8E86C8',far='#4A4468',mid='#3A3354',near='#2E2634',mist='150,130,190',mistA=.28,
 card='#0F0B1A',cardA=.58,txt='#FFFFFF',txt2='#E6DEEA',chip='#1E1626',chipA=.72,chipTxt='#FFFFFF',
 navTint='#1A1320',navRest=.45,navAct=.82,navInk='#F5EFE8',navInk2='#D3C9D2',
 lockStroke='#D9CFD6',lockBg='rgba(255,255,255,.14)',pathStroke='#FFE2B8',pathShadow='rgba(255,170,90,.6)',stars=1,grainBlend='screen'),
}
rows={}
for k,t in T.items():
    veil=.70
    def navworst(a,txt):
        res=[]
        for bk in BK:
            b=mix(t['bottom'],bk,veil); g=mix(t['navTint'],b,a); res.append(cr(txt,g))
        return min(res)
    sky_top=t['sky'][0].split()[0]
    card=[]
    for bk in [sky_top,'#FFFFFF']:
        g=mix(t['card'],bk,t['cardA']); card.append(cr(t['txt'],g))
    chipw=min(cr(t['chipTxt'],mix(t['chip'],bk,t['chipA'])) for bk in BK)
    rows[k]=dict(card=min(card),card_sky=card[0],chip=chipw,rest1=navworst(t['navRest'],t['navInk']),rest2=navworst(t['navRest'],t['navInk2']),act1=navworst(t['navAct'],t['navInk']),act2=navworst(t['navAct'],t['navInk2']))
json.dump(rows,open('kontraste3.json','w'),indent=1)
for k,v in rows.items(): print(k,{a:round(b,2) for a,b in v.items()})
nav=open('nav.frag').read(); m=open('manny.frag').read()
head=m.replace('width="124" height="156"','width="52" height="52" viewBox="10 0 104 84"')
CSS='''
@font-face{font-family:Bric;src:url("../../../../app/assets/fonts/BricolageGrotesque[opsz,wdth,wght].ttf");font-weight:200 800}
@font-face{font-family:DMS;src:url("../../../../app/assets/fonts/DMSans[opsz,wght].ttf");font-weight:100 1000}
*{box-sizing:border-box;margin:0}
body{width:390px;height:844px;overflow:hidden;font-family:DMS,sans-serif;color:#211B16;position:relative}
.bgl{position:absolute;inset:0}.grain{position:absolute;inset:0;opacity:.10}
.sb{position:absolute;z-index:5;top:14px;left:26px;right:26px;display:flex;justify-content:space-between;font-weight:700;font-size:15px;color:var(--txt)}
.hd{position:absolute;z-index:4;left:14px;right:14px;top:44px;height:150px;border-radius:32px;background:var(--card);backdrop-filter:blur(24px) saturate(1.3);border:1px solid rgba(255,255,255,.28);box-shadow:inset 0 1px 0 rgba(255,255,255,.35),0 18px 36px -14px rgba(30,20,30,.5);padding:16px 18px;color:var(--txt)}
.hd h1{font:800 36px/1.05 Bric;letter-spacing:-.5px}.hd p{font-size:15px;font-weight:500;margin-top:3px;color:var(--txt2)}
.pills{position:absolute;right:14px;top:14px;display:flex;gap:8px}
.pill{height:38px;padding:0 13px;border-radius:99px;background:rgba(255,255,255,.16);border:1px solid rgba(255,255,255,.4);display:flex;align-items:center;gap:6px;font:800 17px Bric}
.prog{margin-top:14px;height:10px;border-radius:6px;background:rgba(255,255,255,.22);overflow:hidden}
.prog i{display:block;height:100%;width:58%;border-radius:6px;background:linear-gradient(90deg,#FFB070,#FFD58A);box-shadow:0 0 12px rgba(255,190,110,.8)}
.pl{display:flex;justify-content:space-between;font-size:13px;font-weight:600;margin-top:6px;color:var(--txt2)}
.orb{position:absolute;border-radius:50%;display:grid;place-items:center;border:1px solid rgba(255,255,255,.7);background:radial-gradient(circle at 30% 22%,rgba(255,255,255,.98),rgba(255,255,255,.55) 34%,rgba(255,255,255,.22) 72%);box-shadow:inset 0 2px 2px rgba(255,255,255,.95),inset 0 -10px 16px rgba(130,90,60,.20),0 22px 24px -12px rgba(40,25,30,.5)}
.orb:after{content:"";position:absolute;left:18%;top:9%;width:46%;height:24%;border-radius:50%;background:linear-gradient(180deg,rgba(255,255,255,.95),rgba(255,255,255,0));transform:rotate(-18deg)}
.orb svg{position:relative;z-index:1}
.shadow{position:absolute;border-radius:50%;background:radial-gradient(ellipse,rgba(40,25,30,.4),transparent 70%);height:16px}
.cur{background:radial-gradient(circle at 30% 22%,#FFE0C2,#FF8A3D 46%,#D4501A 100%);border-color:rgba(255,255,255,.8);box-shadow:inset 0 3px 3px rgba(255,255,255,.9),inset 0 -14px 22px rgba(150,40,0,.35),0 0 0 9px rgba(255,255,255,.22),0 0 0 10px rgba(255,255,255,.45),0 0 60px 6px rgba(255,122,46,.55),0 26px 30px -12px rgba(120,40,10,.6)}
.done{background:radial-gradient(circle at 30% 22%,#FFFFFF,#FFE2B8 45%,#F5B778 100%)}
.lock{background:radial-gradient(circle at 30% 22%,rgba(255,255,255,.9),var(--lockBg) 45%,rgba(200,190,185,.25))}
.boss{background:radial-gradient(circle at 30% 22%,#FFFFFF,#FFE9B0 38%,#F0B54F 100%);box-shadow:inset 0 3px 3px #fff,inset 0 -14px 22px rgba(170,100,10,.35),0 0 50px 4px rgba(255,200,110,.7),0 24px 28px -12px rgba(120,70,10,.5)}
.lbl{position:absolute;font-size:13px;font-weight:700;color:var(--chipTxt);text-align:center;padding:5px 12px;border-radius:99px;background:var(--chip);border:1px solid rgba(255,255,255,.5);white-space:nowrap}
.mn{position:absolute;z-index:3;filter:drop-shadow(0 6px 8px rgba(30,20,30,.3))}
.ph{position:absolute;z-index:3;font:700 10px DMS;background:#211B16;color:#fff;border-radius:6px;padding:2px 6px;letter-spacing:.04em;border:1px solid rgba(255,255,255,.5)}
.fab{position:absolute;right:18px;bottom:116px;width:56px;height:56px;border-radius:50%;background:var(--navRest);backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,.6);box-shadow:0 10px 24px -8px rgba(30,20,30,.4),inset 0 1px 0 rgba(255,255,255,.7);overflow:hidden;display:grid;place-items:center;z-index:4}
.veil{position:absolute;left:0;right:0;bottom:0;height:150px;background:linear-gradient(180deg,rgba(var(--bot),0),rgba(var(--bot),.7) 55%,rgba(var(--bot),.8));z-index:2}
.nav{position:absolute;left:14px;right:14px;bottom:24px;height:72px;border-radius:36px;display:flex;align-items:center;justify-content:space-around;padding:0 6px;z-index:4;background:var(--navRest);backdrop-filter:blur(30px) saturate(1.5);border:1px solid rgba(255,255,255,.55);box-shadow:0 10px 30px -12px rgba(30,20,30,.4),inset 0 1px 0 rgba(255,255,255,.6)}
.t{width:62px;height:56px;border-radius:28px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;font-size:12px;font-weight:700;color:var(--navInk);position:relative}
.t.a{background:linear-gradient(180deg,#FFA063,#FF7A2E);color:#211B16;box-shadow:inset 0 1px 0 rgba(255,255,255,.7),0 6px 14px -4px rgba(255,122,46,.6)}
.t svg{width:24px;height:24px;fill:none;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round}
.dot{position:absolute;top:4px;right:11px;min-width:18px;height:18px;border-radius:9px;background:#B3261E;color:#fff;font:700 11px DMS;display:grid;place-items:center;border:2px solid #fff}
.av{width:26px;height:26px;border-radius:50%;background:linear-gradient(135deg,#FFB070,#5F5750);border:2px solid var(--navInk)}
'''
def rgba(h,a): r,g,b=rgb(h); return f'rgba({r},{g},{b},{a})'
for k,t in T.items():
    stops=','.join(t['sky'][:-1]) if False else None
    n=len(t['sky']); st=[]
    for i,s in enumerate(t['sky']):
        if ' ' in s: st.append(s)
        else: st.append(s+' '+('0%' if i==0 else '100%'))
    sky='linear-gradient(180deg,'+','.join(st)+')'
    sx,sy=t['sun']
    stars=''
    if t['stars']:
        import random; random.seed(3)
        stars=''.join(f'<circle cx="{random.randint(10,380)}" cy="{random.randint(8,330)}" r="{random.choice([.6,.9,1.3])}" fill="#fff" opacity="{random.choice([.4,.6,.85])}"/>' for _ in range(46))
    moon=''
    if k=='nacht':
        moon='<circle cx="304" cy="152" r="26" fill="#FFF3D6"/><circle cx="314" cy="146" r="23" fill="#2B2547" opacity=".0"/>'
    else:
        moon=f'<circle cx="{float(sx[:-1])*3.9:.0f}" cy="{float(sy[:-1])*8.44:.0f}" r="{34 if k!="mittag" else 26}" fill="{t["sunc"]}" opacity=".95"/>'
    bot=','.join(map(str,rgb(t['bottom'])))
    svg=f'''<svg class="bgl" width="390" height="844" viewBox="0 0 390 844"><defs>
<radialGradient id="sun" cx="{sx}" cy="{sy}" r="48%"><stop offset="0" stop-color="{t['sunc']}" stop-opacity=".95"/><stop offset=".45" stop-color="{t['sunc2']}" stop-opacity=".38"/><stop offset="1" stop-color="{t['sunc2']}" stop-opacity="0"/></radialGradient>
<linearGradient id="h1" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{t['far']}" stop-opacity=".62"/><stop offset=".55" stop-color="{t['far']}" stop-opacity=".22"/><stop offset="1" stop-color="{t['far']}" stop-opacity="0"/></linearGradient>
<linearGradient id="h2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{t['mid']}" stop-opacity=".6"/><stop offset=".5" stop-color="{t['mid']}" stop-opacity=".25"/><stop offset="1" stop-color="{t['mid']}" stop-opacity="0"/></linearGradient>
<linearGradient id="h3" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{t['near']}" stop-opacity=".85"/><stop offset="1" stop-color="{t['near']}" stop-opacity="0"/></linearGradient>
<linearGradient id="ray" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="{.30 if k!='nacht' else .10}"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<radialGradient id="mist" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="rgb({t['mist']})" stop-opacity="{t['mistA']}"/><stop offset="1" stop-color="rgb({t['mist']})" stop-opacity="0"/></radialGradient>
<filter id="b3" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation="5"/></filter><filter id="b2" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation="3"/></filter><filter id="b1" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation="1.6"/></filter><filter id="b0"><feGaussianBlur stdDeviation="14"/></filter>
<filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="4"/><feColorMatrix values="0 0 0 0 {'.3' if k!='nacht' else '.9'}  0 0 0 0 {'.2' if k!='nacht' else '.85'}  0 0 0 0 {'.15' if k!='nacht' else '.9'}  0 0 0 .9 0"/></filter></defs>
<rect width="390" height="844" fill="url(#sun)"/>{stars}
<g filter="url(#b1)">{moon}</g>
<path d="M230 0L390 0 390 520 120 520Z" fill="url(#ray)" opacity=".5" filter="url(#b0)"/>
<path d="M-20 330 C60 290 120 300 170 322 S300 270 410 300 L410 620 -20 620Z" fill="url(#h1)" filter="url(#b3)"/>
<ellipse cx="190" cy="360" rx="260" ry="46" fill="url(#mist)" filter="url(#b0)"/>
<path d="M-20 420 C70 380 140 400 210 392 S330 360 410 390 L410 720 -20 720Z" fill="url(#h2)" filter="url(#b2)"/>
<ellipse cx="200" cy="470" rx="280" ry="50" fill="url(#mist)" filter="url(#b0)"/>
<path d="M-20 520 C90 480 160 520 240 500 S340 470 410 490 L410 820 -20 820Z" fill="url(#h3)" filter="url(#b1)"/>
<ellipse cx="190" cy="560" rx="260" ry="40" fill="url(#mist)" opacity=".8" filter="url(#b0)"/>
<rect width="390" height="844" filter="url(#n)" class="grain" style="mix-blend-mode:{t['grainBlend']}"/>
<path d="M200 700 C80 650 90 590 200 560 S320 480 200 440 S90 380 200 330" fill="none" stroke="{t['pathStroke']}" stroke-opacity=".9" stroke-width="3" stroke-linecap="round" stroke-dasharray="2 12" style="filter:drop-shadow(0 0 4px {t['pathShadow']})"/></svg>'''
    lock=lambda s:f'<svg width="{s}" height="{s}" viewBox="0 0 24 24" fill="none" stroke="{t["lockStroke"]}" stroke-width="2" stroke-linecap="round"><rect x="5" y="11" width="14" height="9" rx="3"/><path d="M8 11V8a4 4 0 018 0v3"/></svg>'
    chk='<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#8A3A0C" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7"/></svg>'
    vars_=f"--txt:{t['txt']};--txt2:{t['txt2']};--card:{rgba(t['card'],t['cardA'])};--chip:{rgba(t['chip'],t['chipA'])};--chipTxt:{t['chipTxt']};--navRest:{rgba(t['navTint'],t['navRest'])};--navInk:{t['navInk']};--lockBg:{t['lockBg']};--bot:{bot}"
    nv=nav
    html=f'''<!doctype html><html lang="de"><meta charset="utf-8"><title>Pfad {t['name']}</title><style>{CSS}body{{{vars_};background:{sky}}}</style><body>{svg}
<div class="sb"><span>9:41</span><span>●●●</span></div>
<div class="hd"><div class="pills"><div class="pill">❄ 2</div><div class="pill">🔥 12</div></div><h1>Woche 5</h1><p>Phase 2 · Kreuzband</p><div class="prog"><i></i></div><div class="pl"><span>Wochenziel</span><span>4 von 7 Tagen</span></div></div>
<div class="shadow" style="left:152px;top:352px;width:96px"></div>
<div class="orb boss" style="left:148px;top:262px;width:104px;height:104px"><svg width="48" height="48" viewBox="0 0 24 24" fill="#B8470F" stroke="#8A3A0C" stroke-width="1" stroke-linejoin="round"><path d="M12 2l3 6.5 7 .8-5.2 4.7 1.5 7L12 17.4 5.7 21l1.5-7L2 9.3l7-.8z"/></svg></div>
<div class="lbl" style="left:132px;top:376px">Return to Sport</div>
<div class="orb lock" style="left:268px;top:398px;width:62px;height:62px">{lock(26)}</div>
<div class="orb lock" style="left:66px;top:452px;width:50px;height:50px">{lock(22)}</div>
<div class="shadow" style="left:154px;top:636px;width:92px"></div>
<div class="orb cur" style="left:154px;top:548px;width:92px;height:92px"><svg width="40" height="40" viewBox="0 0 24 24" fill="#211B16"><path d="M6 3h2v18H6zM8 4h11l-3 4 3 4H8z"/></svg></div>
<div class="mn" style="left:222px;top:452px">{m}</div><span class="ph" style="left:250px;top:446px">PLATZHALTER</span>
<div class="orb done" style="left:50px;top:650px;width:56px;height:56px">{chk}</div>
<div class="orb done" style="left:260px;top:702px;width:56px;height:56px">{chk}</div>
<div class="veil"></div><div class="fab">{head}</div><div class="nav">{nv}</div>
<div style="position:absolute;z-index:6;left:0;right:0;top:204px;text-align:center"><span style="font:700 11px DMS;background:#211B16;color:#fff;border-radius:6px;padding:2px 8px;letter-spacing:.06em">{t['name'].upper()}</span></div></body></html>'''
    open(f'v2-ansatz3-{k}.html','w').write(html)
