import math
def v3(x,y,z): return f"Vector3({x:g}, {y:g}, {z:g})"
def col(r,g,b,a=1): return f"Color({r:g}, {g:g}, {b:g}, {a:g})"
def xform(pos=(0,0,0), yaw=0.0, pitch=0.0, roll=0.0):
    # rotation order: yaw(Y) * pitch(X) * roll(Z)
    cy,sy=math.cos(math.radians(yaw)),math.sin(math.radians(yaw))
    cp,sp=math.cos(math.radians(pitch)),math.sin(math.radians(pitch))
    cr,sr=math.cos(math.radians(roll)),math.sin(math.radians(roll))
    Ry=[[cy,0,sy],[0,1,0],[-sy,0,cy]]; Rx=[[1,0,0],[0,cp,-sp],[0,sp,cp]]; Rz=[[cr,-sr,0],[sr,cr,0],[0,0,1]]
    mm=lambda A,B:[[sum(A[i][k]*B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    M=mm(Ry,mm(Rx,Rz))
    vals=[M[i][j] for i in range(3) for j in range(3)]
    vals=[0.0 if abs(x)<1e-9 else round(x,5) for x in vals]
    return "Transform3D(" + ", ".join(f"{x:g}" for x in vals) + f", {pos[0]:g}, {pos[1]:g}, {pos[2]:g})"
class Scene:
    def __init__(self): self.exts=[]; self.subs=[]; self.nodes=[]; self.n=0
    def ext(self, type_, path):
        for e in self.exts:
            if e[1]==path: return e[2]
        self.n+=1; i=f"{self.n}_x"; self.exts.append((type_,path,i)); return i
    def sub(self, type_, **props):
        self.n+=1; i=f"{type_}_{self.n}"; self.subs.append((type_,i,props)); return i
    def node(self, name, type_=None, parent=None, instance=None, node_paths=None, groups=None, **props):
        self.nodes.append((name,type_,parent,instance,node_paths,groups,props)); return (parent+"/" if parent and parent!="." else "")+name if parent else "."
    def write(self, path):
        out=[f"[gd_scene load_steps={len(self.exts)+len(self.subs)+1} format=3]\n"]
        for t,p,i in self.exts: out.append(f'[ext_resource type="{t}" path="{p}" id="{i}"]')
        if self.exts: out.append("")
        for t,i,props in self.subs:
            out.append(f'[sub_resource type="{t}" id="{i}"]')
            for k,v in props.items(): out.append(f"{k} = {v}")
            out.append("")
        for name,t,parent,inst,np,groups,props in self.nodes:
            h=f'[node name="{name}"'
            if t: h+=f' type="{t}"'
            if parent: h+=f' parent="{parent}"'
            if np: h+=' node_paths=PackedStringArray(' + ", ".join(f'"{x}"' for x in np) + ')'
            if groups: h+=' groups=[' + ", ".join(f'"{g}"' for g in groups) + ']'
            if inst: h+=f' instance=ExtResource("{inst}")'
            h+="]"; out.append(h)
            for k,v in props.items(): out.append(f"{k} = {v}")
            out.append("")
        open(path,"w").write("\n".join(out))
def ER(i): return f'ExtResource("{i}")'
def SR(i): return f'SubResource("{i}")'
def NP(p): return f'NodePath("{p}")'
def S(s): return '"' + s.replace('"','\\"') + '"'
