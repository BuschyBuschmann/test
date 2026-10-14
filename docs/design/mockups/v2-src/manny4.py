# Vier eigene Manny-Varianten (Platzhalter-Skizzen)
import re
def mir(d):
    toks=re.findall(r'[A-Za-z]|-?\d+\.?\d*',d); out=[];n=[]
    for t in toks:
        if t.isalpha(): out.append(t)
        else:
            n.append(float(t))
            if len(n)==2: out.append(f'{140-n[0]:g} {n[1]:g}'); n=[]
    return ' '.join(out)
def pathglass(shapes,sc,tx,ty,c,sw,glint):
    return f'<g transform="translate({tx} {ty}) scale({sc})" stroke="{c}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round">{shapes}{glint}</g>'
def foot(x,y,r,c,sw,toes=3,w=19):
    return f'<g transform="translate({x} {y}) rotate({r})"><path d="M-{w} 0 h{2*w} q7 0 7 6 q0 6 -6 6 q-3 5 -8 1 q-3 5 -8 1 q-4 4 -8 -1 q-7 1 -9 -6 q-1 -7 0 -7z" fill="#FF9A2E" stroke="{c}" stroke-width="{sw}" stroke-linejoin="round"/></g>'
def eyes(e,c,sw,brow=True):
    (x1,x2,y,rx,ry)=e
    s=f'<ellipse cx="{x1}" cy="{y}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{c}" stroke-width="{sw}"/><ellipse cx="{x2}" cy="{y}" rx="{rx}" ry="{ry}" fill="#fff" stroke="{c}" stroke-width="{sw}"/><circle cx="{x1+2}" cy="{y+3}" r="{rx*.5:.1f}" fill="{c}"/><circle cx="{x2-2}" cy="{y+3}" r="{rx*.5:.1f}" fill="{c}"/><circle cx="{x1+3.5}" cy="{y+1}" r="1.5" fill="#fff"/><circle cx="{x2-0.5}" cy="{y+1}" r="1.5" fill="#fff"/>'
    if brow: s+=f'<path d="M{x1-rx-2} {y-ry-2} L{x1+rx} {y-ry-6} M{x2+rx+2} {y-ry-2} L{x2-rx} {y-ry-6}" stroke="{c}" stroke-width="3.2" stroke-linecap="round"/>'
    return s
def build(v,pose='standard',u='m'):
    c=v['c'];sw=v['sw'];stk=f'stroke="{c}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"'
    s=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-6 -4 152 194" width="152" height="194"><defs><clipPath id="{u}b"><path d="{v["body"]}"/></clipPath><clipPath id="{u}h"><path d="{v["head"]}"/></clipPath><clipPath id="{u}c"><path d="{v["belly"]}"/></clipPath></defs><ellipse cx="72" cy="178" rx="50" ry="5" fill="rgba(30,20,30,.28)"/><g transform="rotate({v["tilt"]} 72 176)">'
    for f in v['feet']: s+=foot(*f,c,sw)
    wl,wr=v['w'][pose]
    s+=f'<path d="{wl}" fill="{v["col"]}" {stk}/>'
    if pose!='troesten': s+=f'<path d="{wr}" fill="{v["col"]}" {stk}/>'
    s+=v.get('post_wings',lambda p:'')(pose)
    s+=f'<path d="{v["body"]}" fill="{v["col"]}" {stk}/><g clip-path="url(#{u}b)"><path d="{v["bshade"]}" fill="{v["dark"]}"/></g>'
    s+=f'<path d="{v["belly"]}" fill="#FFF1D8" {stk}/><g clip-path="url(#{u}c)"><path d="{v["cshade"]}" fill="#EAD5B4"/></g><path d="{v["belly"]}" fill="none" {stk}/>'
    if pose=='troesten': s+=f'<path d="{wr}" fill="{v["col"]}" {stk}/>'
    s+=f'<path d="{v["head"]}" fill="{v["col"]}" {stk}/><g clip-path="url(#{u}h)"><path d="{v["hshade"]}" fill="{v["dark"]}"/>{v.get("hl","")}</g>'
    if v.get('face'): s+=f'<path d="{v["face"]}" fill="#FFF1D8" {stk}/>'
    s+=f'<path d="{v["head"]}" fill="none" {stk}/>'+v.get('pre_glasses','')
    if pose=='troesten':
        s+=eyes(v['eyes'],c,sw*.7)+v['glasses'](*v['hand'])
    else: s+=v['glasses'](1,0,0)
    s+=v['beak']+v['mouth'][pose]+'</g>'
    if pose=='feier': s+='<path d="M124 14l3 7 7 1-5 5 1 7-6-4-6 4 1-7-5-5 7-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/><path d="M12 8l2 5 5 1-4 4 1 5-4-3-4 3 1-5-4-4 5-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/>'
    return s+'</svg>'
def hd(v,u='k',box='18 6 104 90'):
    return build(v,'standard',u).replace('viewBox="-6 -4 152 194" width="152" height="194"',f'viewBox="{box}" width="64" height="55"')
def sz(svg,w): return svg.replace('width="152" height="194"',f'width="{w}" height="{round(w*194/152)}"')
OR='#FF9A2E'
def mouth(d,fill='none',w=3,c='#0B1020'): return f'<path d="{d}" fill="{fill}" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
# ---------- A Lässig
def gA(sc,tx,ty):
    sh='<path d="M32 46 H68 L65 66 Q63 71 57 71 H40 Q33 71 32 64Z" fill="#0A0D18"/><path d="M76 46 H112 L111 64 Q110 71 103 71 H86 Q79 71 77 66Z" fill="#0A0D18"/><path d="M66 48 H78 M32 47 L24 44 M112 47 L120 44" fill="none"/>'
    gl='<path d="M42 49 L52 49 L46 68 L38 68Z" fill="#fff" opacity=".5" stroke="none"/><path d="M86 49 L96 49 L90 68 L82 68Z" fill="#fff" opacity=".5" stroke="none"/>'
    return pathglass(sh,sc,tx,ty,'#0B1020',4.8,gl)
A=dict(c='#0B1020',sw=4.8,col='#2A3A57',dark='#1B2640',tilt=-7,
 head="M72 14 C100 12 112 34 108 54 C104 74 84 84 64 82 C42 80 30 62 34 40 C38 22 54 15 72 14Z",
 body="M42 78 C26 102 18 128 26 150 C34 170 62 174 86 170 C110 166 124 150 120 124 C118 104 108 88 96 78Z",
 belly="M66 84 C92 84 106 112 104 138 C102 160 84 168 64 166 C44 164 34 150 36 128 C38 104 48 84 66 84Z",
 bshade="M98 76 C118 100 124 140 100 172 L130 172 L130 76Z",cshade="M92 88 C106 112 100 150 80 168 L112 168 L112 88Z",hshade="M96 12 C112 34 108 66 90 84 L124 84 L124 12Z",
 hl='<path d="M42 28 C48 20 58 16 68 16" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width="3.5" stroke-linecap="round"/>',
 feet=[(36,164,-12),(110,160,10)],
 w={'standard':("M38 96 C16 108 6 138 14 160 C28 154 40 132 44 108Z","M98 94 C124 104 136 130 130 152 C116 150 104 128 98 106Z"),
    'feier':("M38 98 C16 84 4 56 10 36 C22 40 38 62 44 88Z",mir("M38 98 C16 84 4 56 10 36 C22 40 38 62 44 88Z")),
    'troesten':("M38 96 C16 108 6 138 14 160 C28 154 40 132 44 108Z","M100 94 C114 112 98 138 70 130 C82 118 94 110 96 96Z")},
 glasses=gA,hand=(.42,-4,112),eyes=(50,92,60,9,10),
 beak='<path d="M58 70 Q70 64 82 70 Q80 82 70 84 Q60 82 58 70Z" fill="#FF9A2E" stroke="#0B1020" stroke-width="4.8" stroke-linejoin="round"/>',
 mouth={'standard':mouth("M50 82 Q70 100 92 82",'none',3.4),'feier':mouth("M50 82 Q70 108 92 82Z",'#B3261E',3.4),'troesten':mouth("M62 86 Q70 80 78 86",'none',3.4)})
# ---------- B Sportlich
def gB(sc,tx,ty):
    sh='<path d="M24 44 C48 36 92 36 116 44 C120 58 112 72 94 72 C80 72 76 62 70 62 C64 62 60 72 46 72 C28 72 20 58 24 44Z" fill="#0A0D18"/>'
    gl='<path d="M36 46 L50 44 L42 66 L32 64Z" fill="#fff" opacity=".45" stroke="none"/><path d="M84 44 L100 46 L96 64 L86 66Z" fill="#fff" opacity=".35" stroke="none"/>'
    return pathglass(sh,sc,tx,ty,'#0B1020',4.8,gl)
def bandB(p):
    wb={'standard':"M10 130 L40 118 L42 132 L12 144Z",'feier':"M12 62 L42 74 L36 88 L8 76Z",'troesten':"M12 134 L40 122 L42 136 L14 148Z"}[p]
    return f'<path d="{wb}" fill="#FF7A2E" stroke="#0B1020" stroke-width="4" stroke-linejoin="round" transform="rotate(0)"/>'
B=dict(c='#0B1020',sw=4.8,col='#2A3A57',dark='#1B2640',tilt=6,
 head="M70 14 C94 14 104 30 104 48 C104 66 90 78 70 78 C50 78 36 66 36 48 C36 30 46 14 70 14Z",
 body="M34 80 C18 92 16 112 28 132 C36 148 44 164 56 172 L88 172 C100 164 108 148 114 132 C126 112 124 92 108 80Z",
 belly="M70 82 C92 84 100 108 96 134 C94 156 84 168 70 168 C56 168 46 156 44 134 C40 108 48 84 70 82Z",
 bshade="M100 80 C122 100 124 130 100 172 L130 172 L130 80Z",cshade="M90 90 C98 112 94 150 80 166 L108 166 L108 90Z",hshade="M92 14 C108 34 102 64 86 78 L120 78 L120 14Z",
 hl='<path d="M42 26 C48 19 56 16 64 16" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width="3.5" stroke-linecap="round"/>',
 pre_glasses='<path d="M36 28 C54 18 86 18 104 28 L104 38 C86 30 54 30 36 38Z" fill="#FF7A2E" stroke="#0B1020" stroke-width="4.8" stroke-linejoin="round"/>',
 post_wings=bandB,
 feet=[(34,152,-34),(108,168,6)],
 w={'standard':("M34 92 C12 100 4 126 8 150 C22 148 34 132 40 108Z","M104 90 C128 84 140 104 132 126 C120 130 110 114 102 104Z"),
    'feier':("M34 94 C12 80 2 54 10 36 C22 40 34 60 40 84Z",mir("M34 94 C12 80 2 54 10 36 C22 40 34 60 40 84Z")),
    'troesten':("M34 92 C12 100 4 126 8 150 C22 148 34 132 40 108Z","M102 92 C116 110 100 136 72 128 C84 116 94 108 98 94Z")},
 glasses=gB,hand=(.42,-2,118),eyes=(50,90,58,8,9),
 beak='<path d="M58 68 Q70 62 82 68 Q80 79 70 82 Q60 79 58 68Z" fill="#FF9A2E" stroke="#0B1020" stroke-width="4.8" stroke-linejoin="round"/>',
 mouth={'standard':mouth("M62 79 Q72 87 82 76",'none',3.2),'feier':mouth("M60 76 Q70 92 80 76Z",'#B3261E',3.2),'troesten':mouth("M62 80 Q70 75 78 80",'none',3.2)})
# ---------- C Niedlich-rund
def gC(sc,tx,ty):
    sh='<circle cx="46" cy="62" r="19" fill="#0A0D18"/><circle cx="94" cy="62" r="19" fill="#0A0D18"/><path d="M65 60 Q70 56 75 60" fill="none"/><path d="M27 58 L18 55 M113 58 L122 55" fill="none"/>'
    gl='<path d="M36 52 Q41 48 48 49" stroke="#fff" stroke-width="3.5" fill="none" opacity=".7"/><path d="M84 52 Q89 48 96 49" stroke="#fff" stroke-width="3.5" fill="none" opacity=".7"/>'
    return pathglass(sh,sc,tx,ty,'#16203A',3.8,gl)
C=dict(c='#16203A',sw=3.8,col='#34476B',dark='#26365A',tilt=-3,
 head="M70 14 C104 14 126 38 126 64 C126 90 104 106 70 106 C36 106 14 90 14 64 C14 38 36 14 70 14Z",
 body="M44 100 C32 116 32 140 40 156 C50 170 90 170 100 156 C108 140 108 116 96 100Z",
 belly="M70 106 C90 106 96 124 94 142 C92 156 82 163 70 163 C58 163 48 156 46 142 C44 124 50 106 70 106Z",
 bshade="M98 100 C112 120 110 150 98 166 L124 166 L124 100Z",cshade="M88 112 C96 126 94 148 82 160 L104 160 L104 112Z",hshade="M104 16 C124 38 124 80 98 104 L134 104 L134 16Z",
 hl='<path d="M34 34 C42 24 54 19 66 18" fill="none" stroke="#fff" stroke-opacity=".3" stroke-width="4" stroke-linecap="round"/>',
 face="M24 78 C28 98 50 104 70 104 C90 104 112 98 116 78 C102 90 86 86 70 88 C54 86 38 90 24 78Z",
 pre_glasses='<path d="M64 14 C60 4 70 0 72 8 M72 12 C74 2 84 4 80 14" fill="none" stroke="#16203A" stroke-width="3.8" stroke-linecap="round"/><ellipse cx="22" cy="86" rx="8" ry="5" fill="#FF8F6B" opacity=".55"/><ellipse cx="118" cy="86" rx="8" ry="5" fill="#FF8F6B" opacity=".55"/>',
 feet=[(48,164,-6),(94,164,6)],
 w={'standard':("M44 112 C30 118 24 136 30 148 C40 146 46 132 48 120Z",mir("M44 112 C30 118 24 136 30 148 C40 146 46 132 48 120Z")),
    'feier':("M44 110 C26 98 18 78 22 62 C34 66 44 82 48 100Z",mir("M44 110 C26 98 18 78 22 62 C34 66 44 82 48 100Z")),
    'troesten':("M44 112 C30 118 24 136 30 148 C40 146 46 132 48 120Z","M98 112 C106 128 94 146 74 142 C82 134 90 128 94 114Z")},
 glasses=gC,hand=(.4,-2,128),eyes=(46,94,64,12,13),
 beak='<path d="M62 76 Q70 70 78 76 Q77 85 70 87 Q63 85 62 76Z" fill="#FF9A2E" stroke="#16203A" stroke-width="3.8" stroke-linejoin="round"/>',
 mouth={'standard':mouth("M62 92 Q70 98 78 92",'none',3,'#16203A'),'feier':mouth("M60 90 Q70 106 80 90Z",'#B3261E',3,'#16203A'),'troesten':mouth("M63 94 Q70 89 77 94",'none',3,'#16203A')})
# ---------- D Modern-minimal
def gD(sc,tx,ty):
    sh='<path d="M26 32 H114 Q118 32 118 38 V46 Q118 58 104 58 H84 Q74 58 70 50 Q66 58 56 58 H36 Q22 58 22 46 V38 Q22 32 26 32Z" fill="#0A0D18"/>'
    gl='<path d="M32 38 H62" stroke="#fff" stroke-width="3" opacity=".55" fill="none"/><path d="M84 38 H108" stroke="#fff" stroke-width="3" opacity=".55" fill="none"/>'
    return pathglass(sh,sc,tx,ty,'#0B1020',2.6,gl)
D=dict(c='#0B1020',sw=2.6,col='#2B3956',dark='#2B3956',tilt=0,
 head="M70 6 C90 6 106 22 106 42 C106 62 90 78 70 78 C50 78 34 62 34 42 C34 22 50 6 70 6Z",
 body="M42 70 H98 Q116 70 116 88 V140 Q116 172 70 172 Q24 172 24 140 V88 Q24 70 42 70Z",
 belly="M70 84 C92 84 100 104 100 128 C100 152 88 162 70 162 C52 162 40 152 40 128 C40 104 48 84 70 84Z",
 bshade="M0 0Z",cshade="M0 0Z",hshade="M0 0Z",
 hl='<path d="M44 16 C54 10 66 8 76 8 L76 22 C62 22 50 28 42 38Z" fill="#fff" opacity=".14"/>',
 feet=[(44,166,0),(98,166,0)],
 w={'standard':("M26 92 Q8 100 8 124 Q8 140 22 138 Q30 120 28 104Z",mir("M26 92 Q8 100 8 124 Q8 140 22 138 Q30 120 28 104Z")),
    'feier':("M26 92 Q6 80 4 54 Q18 50 28 70Z",mir("M26 92 Q6 80 4 54 Q18 50 28 70Z")),
    'troesten':("M26 92 Q8 100 8 124 Q8 140 22 138 Q30 120 28 104Z","M104 92 Q116 112 98 130 Q84 128 78 122 Q92 112 96 92Z")},
 glasses=gD,hand=(.42,-2,112),eyes=(52,88,42,7,8),
 beak='<path d="M60 52 H80 Q80 66 70 68 Q60 66 60 52Z" fill="#FF9A2E" stroke="#0B1020" stroke-width="2.6" stroke-linejoin="round"/>',
 mouth={'standard':mouth("M62 70 Q70 76 78 70",'none',2.6),'feier':mouth("M60 68 Q70 84 80 68Z",'#B3261E',2.6),'troesten':mouth("M63 72 Q70 67 77 72",'none',2.6)})
V=[('A','Lässig',A),('B','Sportlich',B),('C','Niedlich-rund',C),('D','Modern-minimal',D)]
