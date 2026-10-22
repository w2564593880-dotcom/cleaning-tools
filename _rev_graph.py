import os,re,sys
root="main.tex"
seen=[]
def walk(p, depth=0):
    p=p.replace("/",os.sep)
    if not os.path.exists(p):
        print("  "*depth+"[MISSING] "+p); return
    if p in seen: 
        print("  "*depth+"[AGAIN] "+p); return
    seen.append(p)
    print("  "*depth+p)
    txt=open(p,encoding="utf-8",errors="replace").read()
    for m in re.finditer(r'^[^%]*\\(?:input|include)\{([^}]*)\}', txt, re.M):
        f=m.group(1)
        if not f.endswith(".tex"): f+=".tex"
        # resolve relative to cwd (LaTeX resolves from root dir)
        walk(os.path.normpath(f), depth+1)
walk(root)
print("\nTOTAL files:",len(seen))
