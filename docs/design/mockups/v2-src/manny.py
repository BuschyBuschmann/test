# Eigener Manny (Platzhalter-Skizze, flacher Sticker-Stil), Runde 5: Kopf und Körper als zwei Formen, leicht schräg.
import re
C='#0B1020'
def mirror(d):
    toks=re.findall(r'[A-Za-z]|-?\d+\.?\d*',d); out=[];nums=[]
    for t in toks:
        if t.isalpha(): out.append(t)
        else:
            nums.append(float(t))
            if len(nums)==2: out.append(f'{140-nums[0]:g} {nums[1]:g}'); nums=[]
    return ' '.join(out)
def glasses(sc=1,tx=0,ty=0):
    return f'''<g transform="translate({tx} {ty}) scale({sc})" stroke="{C}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round">
<path d="M30 56 L23 53 M110 56 L117 53" fill="none"/>
<rect x="29" y="49" width="38" height="23" rx="10" fill="#0A0D18"/><rect x="73" y="49" width="38" height="23" rx="10" fill="#0A0D18"/>
<path d="M67 55h6" fill="none"/>
<path d="M35 56 Q39 53 49 53" stroke="#3A4562" stroke-width="2" fill="none"/><path d="M79 56 Q83 53 93 53" stroke="#3A4562" stroke-width="2" fill="none"/>
<path d="M50 51 L59 51 L52 70 L44 70Z" fill="#fff" opacity=".5" stroke="none"/><path d="M94 51 L103 51 L96 70 L88 70Z" fill="#fff" opacity=".5" stroke="none"/></g>'''
def manny(pose='standard',u='m'):
    head="M70 12 C99 12 113 31 113 50 C113 68 95 83 70 83 C45 83 27 68 27 50 C27 31 41 12 70 12Z"
    body="M45 76 C30 96 17 122 21 148 C25 168 47 174 72 174 C101 174 119 166 121 144 C123 118 111 94 96 76Z"
    belly="M70 80 C95 80 109 110 109 138 C109 162 93 170 70 170 C47 170 31 162 31 138 C31 110 45 80 70 80Z"
    face="M38 60 C40 50 54 48 70 50 C86 48 100 50 102 60 C104 74 90 83 70 83 C50 83 36 74 38 60Z"
    if pose=='feier':
        wl="M36 98 C14 84 3 56 9 36 C22 40 36 62 42 86Z"; wr=mirror(wl)
    elif pose=='troesten':
        wl="M36 96 C14 108 5 136 13 156 C26 150 38 128 42 106Z"
        wr="M104 94 C116 112 100 138 72 130 C84 118 96 110 100 96Z"
    else:
        wl="M36 96 C14 108 5 136 13 158 C26 152 38 130 42 106Z"; wr="M104 94 C128 102 138 128 130 150 C118 146 108 126 100 106Z"
    stk=f'stroke="{C}" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round"'
    foot=lambda x,y,r:f'<g transform="translate({x} {y}) rotate({r})"><path d="M-19 0 h38 q7 0 7 6 q0 6 -6 6 q-3 5 -8 1 q-3 5 -8 1 q-4 4 -8 -1 q-7 1 -9 -6 q-1 -7 0 -7z" fill="#FF9A2E" {stk}/></g>'
    s=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-6 -4 152 194" width="152" height="194"><defs><clipPath id="{u}b"><path d="{body}"/></clipPath><clipPath id="{u}h"><path d="{head}"/></clipPath><clipPath id="{u}c"><path d="{belly}"/></clipPath></defs>'
    s+='<ellipse cx="72" cy="178" rx="56" ry="5" fill="rgba(30,20,30,.28)"/><g transform="rotate(-4 72 176)">'
    s+=foot(36,164,-10)+foot(108,166,10)
    s+=f'<path d="{wl}" fill="#27334D" {stk}/>'
    if pose!='troesten': s+=f'<path d="{wr}" fill="#27334D" {stk}/>'
    s+=f'<path d="{body}" fill="#2A3A57" {stk}/><g clip-path="url(#{u}b)"><path d="M98 70 C114 100 112 140 104 180 L150 180 L150 70Z" fill="#1B2640"/></g>'
    s+=f'<path d="{belly}" fill="#FFF1D8" {stk}/><g clip-path="url(#{u}c)"><path d="M94 84 C104 110 100 150 84 172 L115 172 L115 84Z" fill="#EAD5B4"/></g><path d="{belly}" fill="none" {stk}/>'
    if pose=='troesten': s+=f'<path d="{wr}" fill="#27334D" {stk}/>'
    s+=f'<path d="{head}" fill="#2A3A57" {stk}/><g clip-path="url(#{u}h)"><path d="M96 10 C112 30 112 60 100 84 L130 84 L130 10Z" fill="#1B2640"/><path d="M36 24 C44 17 54 14 62 14" fill="none" stroke="#fff" stroke-opacity=".28" stroke-width="3.5" stroke-linecap="round"/></g>'
    s+=f'<path d="{face}" fill="#FFF1D8" {stk}/><path d="{head}" fill="none" {stk}/>'
    s+=f'<path d="M26 36 C50 22 90 22 114 36 L113 47 C90 34 50 34 27 47Z" fill="#FF7A2E" {stk}/><path d="M58 29 L72 29 L70 41 L56 41Z" fill="#FFF1D8" opacity=".9" transform="skewX(-8) translate(5 0)"/>'
    if pose=='troesten':
        s+=f'<ellipse cx="50" cy="58" rx="9" ry="10" fill="#fff" {stk}/><ellipse cx="90" cy="58" rx="9" ry="10" fill="#fff" {stk}/><circle cx="52" cy="61" r="4.5" fill="{C}"/><circle cx="88" cy="61" r="4.5" fill="{C}"/><circle cx="54" cy="59" r="1.5" fill="#fff"/><circle cx="90" cy="59" r="1.5" fill="#fff"/><path d="M39 46 L55 50 M101 46 L85 50" stroke="{C}" stroke-width="3.5" stroke-linecap="round"/>'
        s+=glasses(.42,-2,116)
    else: s+=glasses()
    s+=f'<path d="M56 68 Q70 60 84 68 Q82 85 70 88 Q58 85 56 68Z" fill="#FF9A2E" {stk}/>'
    if pose=='troesten': s+=f'<path d="M62 79 Q70 74 78 79" fill="none" stroke="{C}" stroke-width="3" stroke-linecap="round"/>'
    elif pose=='feier': s+=f'<path d="M60 76 Q70 92 80 76Z" fill="#B3261E" stroke="{C}" stroke-width="3" stroke-linejoin="round"/>'
    else: s+=f'<path d="M61 76 Q70 83 79 76" fill="none" stroke="{C}" stroke-width="3" stroke-linecap="round"/>'
    s+='</g>'
    if pose=='feier': s+='<path d="M124 14l3 7 7 1-5 5 1 7-6-4-6 4 1-7-5-5 7-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/><path d="M12 8l2 5 5 1-4 4 1 5-4-3-4 3 1-5-4-4 5-1z" fill="#FFC23D" stroke="#0B1020" stroke-width="2.5" stroke-linejoin="round"/>'
    return s+'</svg>'
def head(u='h'):
    return manny('standard',u).replace('viewBox="-6 -4 152 194" width="152" height="194"','viewBox="18 6 104 90" width="64" height="55"')
def sized(svg,w):
    return svg.replace('width="152" height="194"',f'width="{w}" height="{round(w*194/152)}"')
