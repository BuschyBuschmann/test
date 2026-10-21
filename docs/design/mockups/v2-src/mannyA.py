# Adapter: Manny Variante A "Lässig" (freigegeben, Platzhalter-Skizze) mit der API aus manny.py
from manny4 import build, hd, sz, A
def manny(pose='standard',u='m'): return build(A,pose,u)
def head(u='h'): return hd(A,u,'24 6 96 84')
def sized(svg,w): return sz(svg,w)
