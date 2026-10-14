# Eigener Manny (Platzhalter-Skizze, flacher Sticker-Stil). Erzeugt v2-manny-sticker.html und v2-ansatz4-abend.html
import re
C='#0B1020'
def mirror(d):  # spiegelt x -> 140-x fuer Pfade aus absoluten M/C/Z mit Zahlenpaaren
    toks=re.findall(r'[A-Za-z]|-?\d+\.?\d*',d); out=[];i=0;nums=[]
    for t in toks:
        if t.isalpha(): out.append(t)
        else:
            nums.append(float(t))
            if len(nums)==2: out.append(f'{140-nums[0]:g} {nums[1]:g}'); nums=[]
    return ' '.join(out)
def glasses(dy=0,sc=1,tx=0,ty=0,uid='g'):
    return f'''<g transform="translate({tx} {ty}) scale({sc}) translate(0 {dy})" stroke="{C}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round">
<path d="M24 62 L17 58 M116 62 L123 58" fill="none"/>
<rect x="23" y="55" width="42" height="25" rx="11" fill="#0A0D18"/><rect x="75" y="55" width="42" height="25" rx="11" fill="#0A0D18"/>
<path d="M65 61h10" fill="none"/>
<path d="M29 62 Q33 59 44 59" stroke="#3A4562" stroke-width="2" fill="none"/><path d="M81 62 Q85 59 96 59" stroke="#3A4562" stroke-width="2" fill="none"/>
<path d="M45 57 L55 57 L47 78 L38 78Z" fill="#fff" opacity=".5" stroke="none"/><path d="M97 57 L107 57 L99 78 L90 78Z" fill="#fff" opacity=".5" stroke="none"/></g>'''
def manny(pose='standard',u='m'):
    body="M70 14 C100 14 118 34 118 62 C118 70 120 78 122 92 C126 126 112 160 70 160 C28 160 14 126 18 92 C20 78 22 70 22 62 C22 34 40 14 70 14Z"
    belly="M70 66 C92 66 105 92 105 118 C105 146 91 156 70 156 C49 156 35 146 35 118 C35 92 48 66 70 66Z"
    if pose=='feier':
        wl="M27 88 C8 74 0 48 8 30 C19 35 30 56 36 78Z"; wr=mirror(wl)
    elif pose=='troesten':
        wl="M28 84 C10 96 6 120 14 132 C24 126 32 110 34 94Z"
        wr="M110 84 C122 102 104 124 76 116 C86 104 98 98 102 84Z"
    else:
        wl="M27 84 C8 94 4 120 12 132 C23 126 31 110 34 94Z"; wr="M113 82 C132 90 138 114 130 126 C119 122 110 106 106 92Z"
    s=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -4 148 184" width="148" height="184"><defs><clipPath id="{u}b"><path d="{body}"/></clipPath><clipPath id="{u}c"><path d="{belly}"/></clipPath></defs>'
    s+='<ellipse cx="70" cy="170" rx="46" ry="5" fill="rgba(30,20,30,.28)"/>'
    stk=f'stroke="{C}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"'
    # Fuesse mit drei runden Zehen
    foot=lambda x:f'<path d="M{x-14} 160 h28 q6 0 6 6 q0 5 -5 5 q-3 4 -7 1 q-3 4 -7 1 q-4 3 -7 -1 q-6 1 -8 -5 q-1 -7 0 -7z" fill="#FF9A2E" {stk}/>'
    s+=foot(46)+foot(94)
    s+=f'<path d="{wl}" fill="#27334D" {stk}/><path d="{wr}" fill="#27334D" {stk}/>' if pose!='troesten' else f'<path d="{wl}" fill="#27334D" {stk}/>'
    s+=f'<path d="{body}" fill="#2A3A57" {stk}/><g clip-path="url(#{u}b)"><path d="M92 10 C108 40 104 100 96 170 L150 170 L150 10Z" fill="#1B2640"/><path d="M30 20 C38 14 48 12 56 14" fill="none" stroke="#fff" stroke-opacity=".28" stroke-width="3.5" stroke-linecap="round"/></g>'
    s+=f'<path d="{body}" fill="none" {stk}/>'
    s+=f'<path d="{belly}" fill="#FFF1D8" {stk}/><g clip-path="url(#{u}c)"><path d="M92 70 C100 100 96 140 80 160 L110 160 L110 70Z" fill="#EAD5B4"/></g><path d="{belly}" fill="none" {stk}/>'
    if pose=='troesten': s+=f'<path d="{wr}" fill="#27334D" {stk}/>'
    # Stirnband
    s+=f'<path d="M23 46 C48 32 92 32 117 46 L115 57 C92 44 48 44 25 57Z" fill="#FF7A2E" {stk}/><path d="M60 38 L74 38 L72 50 L58 50Z" fill="#FFF1D8" opacity=".9" transform="translate(-4 0) skewX(-8)"/>'
    # Schnabel
    s+=f'<path d="M55 84 Q70 74 85 84 Q83 101 70 104 Q57 101 55 84Z" fill="#FF9A2E" {stk}/><path d="M60 92 Q70 99 80 92" fill="none" stroke="{C}" stroke-width="3" stroke-linecap="round"/>'
    if pose=='feier': s+=f'<path d="M60 93 Q70 109 80 93Z" fill="#B3261E" stroke="{C}" stroke-width="3" stroke-linejoin="round"/>'
    if pose=='troesten':
        s+=f'<ellipse cx="46" cy="66" rx="9" ry="10" fill="#fff" {stk}/><ellipse cx="94" cy="66" rx="9" ry="10" fill="#fff" {stk}/><circle cx="48" cy="69" r="4.5" fill="{C}"/><circle cx="92" cy="69" r="4.5" fill="{C}"/><circle cx="50" cy="67" r="1.5" fill="#fff"/><circle cx="94" cy="67" r="1.5" fill="#fff"/><path d="M36 54 L52 58 M104 54 L88 58" stroke="{C}" stroke-width="3.5" stroke-linecap="round"/>'
        s+=f'<path d="M62 96 Q70 91 78 96" fill="none" stroke="{C}" stroke-width="3" stroke-linecap="round"/>'
        s+=glasses(0,.42,-1,104,u)  # Brille in der Hand (links)
    else: s+=glasses()
    if pose=='feier': s+='<path d="M120 20l3 7 7 1-5 5 1 7-6-4-6 4 1-7-5-5 7-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/><path d="M14 18l2 5 5 1-4 4 1 5-4-3-4 3 1-5-4-4 5-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/>'
    return s+'</svg>'
def head(u='h'):
    return manny('standard',u).replace('viewBox="-4 -4 148 184" width="148" height="184"','viewBox="8 8 124 106" width="64" height="55"')
tag='<span class="ph">PLATZHALTER · eigene Skizze</span>'
sheet=f'''<!doctype html><html lang="de"><meta charset="utf-8"><style>
@font-face{{font-family:DMS;src:url("../../../../app/assets/fonts/DMSans[opsz,wght].ttf");font-weight:100 1000}}
body{{margin:0;width:780px;height:920px;background:linear-gradient(180deg,#F2B58C,#E8A68A 12%,#DCCFC4 45%,#F7F2EB);font-family:DMS,sans-serif;color:#211B16;position:relative}}
.big{{position:absolute;left:230px;top:70px;filter:drop-shadow(0 12px 14px rgba(60,30,20,.3))}}
.row{{position:absolute;left:30px;right:30px;top:520px;display:flex;justify-content:space-around}}
.c{{text-align:center;font-weight:700;font-size:16px}}.c svg{{display:block;margin:0 auto 6px;filter:drop-shadow(0 8px 8px rgba(60,30,20,.25))}}
.ph{{position:absolute;left:50%;transform:translateX(-50%);top:22px;font:700 12px DMS;background:#211B16;color:#fff;border-radius:7px;padding:4px 10px;letter-spacing:.04em;white-space:nowrap}}
.btns{{position:absolute;left:0;right:0;top:806px;display:flex;justify-content:center;gap:28px;align-items:center}}
.b{{border-radius:50%;background:rgba(255,255,255,.5);border:1px solid rgba(255,255,255,.8);box-shadow:0 10px 24px -8px rgba(30,20,30,.4),inset 0 1px 0 #fff;display:grid;place-items:center;overflow:hidden}}
.cap{{position:absolute;left:0;right:0;top:782px;text-align:center;font-weight:700;font-size:14px}}
</style><body>{tag}
<div class="big">{manny('standard','a').replace('width="148" height="184"','width="320" height="397"')}</div>
<div class="row"><div class="c">{manny('standard','b').replace('width="148" height="184"','width="170" height="211"')}Standard</div><div class="c">{manny('feier','c').replace('width="148" height="184"','width="170" height="211"')}Feier</div><div class="c">{manny('troesten','d').replace('width="148" height="184"','width="170" height="211"')}Trösten (Brille ab)</div></div>
<div class="cap">Kopf als Knopf</div>
<div class="btns"><div class="b" style="width:80px;height:80px">{head('k1').replace('width="64" height="55"','width="70" height="60"')}</div><div class="b" style="width:56px;height:56px">{head('k2').replace('width="64" height="55"','width="50" height="43"')}</div><div class="b" style="width:40px;height:40px">{head('k3').replace('width="64" height="55"','width="36" height="31"')}</div></div>
</body></html>'''
open('v2-manny-sticker.html','w').write(sheet)
a=open('v2-ansatz3-abend.html').read()
a=re.sub(r'(<div class="mn" style="left:222px;top:452px">).*?(</div><span class="ph")',lambda m:m.group(1)+manny('standard','p').replace('width="148" height="184"','width="128" height="159"')+m.group(2),a,flags=re.S)
a=a.replace('class="mn" style="left:222px;top:452px"','class="mn" style="left:218px;top:462px"').replace('style="left:250px;top:446px">PLATZHALTER','style="left:236px;top:452px">PLATZHALTER')
a=re.sub(r'(<div class="fab">).*?(</div><div class="nav">)',lambda m:m.group(1)+head('f').replace('width="64" height="55"','width="52" height="45"')+m.group(2),a,flags=re.S)
open('v2-ansatz4-abend.html','w').write(a)
