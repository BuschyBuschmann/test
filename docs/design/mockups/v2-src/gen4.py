import re
from manny import *
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
<div class="big">{sized(manny('standard','a'),330)}</div>
<div class="row"><div class="c">{sized(manny('standard','b'),170)}Standard</div><div class="c">{sized(manny('feier','c'),170)}Feier</div><div class="c">{sized(manny('troesten','d'),170)}Trösten (Brille ab)</div></div>
<div class="cap">Kopf als Knopf</div>
<div class="btns"><div class="b" style="width:80px;height:80px">{head('k1').replace('width="64" height="55"','width="70" height="60"')}</div><div class="b" style="width:56px;height:56px">{head('k2').replace('width="64" height="55"','width="50" height="43"')}</div><div class="b" style="width:40px;height:40px">{head('k3').replace('width="64" height="55"','width="36" height="31"')}</div></div>
</body></html>'''
open('v2-manny-sticker.html','w').write(sheet)
a=open('v2-ansatz3-abend.html').read()
a=re.sub(r'(<div class="mn" style="left:222px;top:452px">).*?(</div><span class="ph")',lambda m:m.group(1)+sized(manny('standard','p'),132)+m.group(2),a,flags=re.S)
a=a.replace('class="mn" style="left:222px;top:452px"','class="mn" style="left:218px;top:462px"').replace('style="left:250px;top:446px">PLATZHALTER','style="left:236px;top:452px">PLATZHALTER')
a=re.sub(r'(<div class="fab">).*?(</div><div class="nav">)',lambda m:m.group(1)+head('f').replace('width="64" height="55"','width="52" height="45"')+m.group(2),a,flags=re.S)
open('v2-ansatz4-abend.html','w').write(a)
