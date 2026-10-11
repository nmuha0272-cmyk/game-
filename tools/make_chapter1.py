"""Builds scenes/chapters/chapter_1/chapter_1.tscn (Chapter 1: The Surface).
Run from the project folder:  python3 tools/make_chapter1.py
Edit the room layouts here, not in the .tscn (it gets overwritten)."""
import math, os, random, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tscn import *
sc=Scene()
P=lambda k: sc.ext("PackedScene",k)
X=dict(
 hold=P("res://scenes/puzzles/hold_switch.tscn"), vent=P("res://scenes/puzzles/vent_cover.tscn"), fuse=P("res://scenes/puzzles/fuse_box.tscn"),
 console=P("res://scenes/puzzles/key_console.tscn"), keypad=P("res://scenes/puzzles/keypad.tscn"), lever=P("res://scenes/puzzles/lever.tscn"),
 button=P("res://scenes/puzzles/button.tscn"), lamp=P("res://scenes/puzzles/status_lamp.tscn"), clamp=P("res://scenes/puzzles/gate_clamp.tscn"),
 door=P("res://scenes/interactables/door.tscn"), gen=P("res://scenes/interactables/generator.tscn"), cab=P("res://scenes/interactables/filing_cabinet.tscn"),
 drag=P("res://scenes/interactables/evidence_drag_marks.tscn"), mphoto=P("res://scenes/interactables/evidence_monster_photo.tscn"),
 longman=P("res://scenes/monsters/long_man.tscn"), lfile=P("res://scenes/lore/lore_file.tscn"), lposter=P("res://scenes/lore/lore_poster.tscn"),
 lpersonal=P("res://scenes/lore/lore_personal.tscn"), lpaper=P("res://scenes/lore/lore_paper.tscn"), tape=P("res://scenes/lore/tape_machine.tscn"),
)
SC=lambda k: sc.ext("Script",k)
S_GATE=SC("res://scripts/puzzles/puzzle_gate.gd"); S_CODE=SC("res://scripts/puzzles/code_display.gd"); S_LIGHTS=SC("res://scripts/puzzles/puzzle_lights.gd")
S_MOVER=SC("res://scripts/puzzles/puzzle_mover.gd"); S_LORECHK=SC("res://scripts/puzzles/lore_check.gd"); S_LOCK=SC("res://scripts/interactables/door_lock.gd")
S_PSPAWN=SC("res://scripts/player/player_spawner.gd"); S_ISPAWN=SC("res://scripts/items/item_spawner.gd"); S_IPOINT=SC("res://scripts/items/item_spawn_point.gd")
S_NAV=SC("res://scripts/environment/bake_navigation_on_start.gd"); S_FLICK=SC("res://scripts/environment/flickering_light.gd"); S_PULSE=SC("res://scripts/environment/pulsing_light.gd")
S_RAND=SC("res://scripts/environment/random_ambient_sounds.gd"); S_TEAM=SC("res://scripts/game/team_monitor.gd"); S_CP=SC("res://scripts/game/checkpoint.gd")
S_CHAPTER=SC("res://scripts/chapters/chapter.gd"); S_STING=SC("res://scripts/chapters/stinger_trigger.gd"); S_CHASE=SC("res://scripts/chapters/chase_trigger.gd")
S_DRAIN=SC("res://scripts/chapters/flashlight_drain_trigger.gd"); S_ELEV=SC("res://scripts/chapters/elevator.gd")
S_CUT=SC("res://scripts/chapters/cutscene.gd"); S_SCARE=SC("res://scripts/chapters/scare_event.gd")
X.update(signal=P("res://scenes/puzzles/signal_light.tscn"), lmodel=P("res://assets/models/characters/long_man.glb"))
def shots(*items):
    """Cutscene shots: (from, look_from, to, look_to, seconds, caption)."""
    out=[]
    for a,la,b,lb,t,text in items:
        out.append("{"+f'"from": {v3(*a)}, "from_look": {v3(*la)}, "to": {v3(*b)}, "to_look": {v3(*lb)}, "time": {t}, "text": {S(text)}'+"}")
    return "["+", ".join(out)+"]"
A=lambda k: sc.ext("AudioStream","res://assets/audio/"+k)
WIND=A("wind_loop.wav"); DRONE=A("ambient_drone.wav"); DRIP=A("water_drip.wav"); CLANK=A("distant_clank.wav"); CREAK=A("metal_creak.wav")
STING=A("stinger.wav"); SNAP=A("cable_snap.wav"); HUM=A("elevator_hum.wav"); BUZZ=A("fluorescent_buzz.wav"); CREAKDOOR=A("door_creak.wav")
LORE=lambda k: sc.ext("Resource",f"res://lore/{k}.tres")

MAT=lambda k: ER(sc.ext("Material", f"res://assets/materials/{k}.tres"))
ROCK=MAT("terrain"); CONC=MAT("concrete_wall"); WALL=MAT("painted_wall"); WOOD=MAT("wood"); DWOOD=MAT("dark_wood")
METAL=MAT("rusty_metal"); RUST=METAL; FENCE=MAT("chainlink"); ROAD=MAT("asphalt"); FLOOR=MAT("concrete_floor"); LINO=MAT("lino_floor")
CINDER=MAT("cinder_block"); STONE=MAT("rock")
CAR=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.22,0.27,0.3), roughness="0.45", metallic="0.6"))
SCREEN=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.03,0.08,0.04), emission_enabled="true", emission=col(0.03,0.2,0.06), emission_energy_multiplier="1.0"))
BLACK=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.02,0.02,0.02), roughness="0.6"))
PAPER=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.75,0.72,0.62), roughness="0.95"))
BARK=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.12,0.09,0.07), roughness="1.0"))
NEEDLES=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.04,0.08,0.05), roughness="1.0"))
WHITE=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.7,0.7,0.68), roughness="0.5", metallic="0.3"))
night_sky=sc.sub("ShaderMaterial", shader=ER(sc.ext("Shader","res://assets/shaders/night_sky.gdshader")))
sky=sc.sub("Sky", sky_material=SR(night_sky))
env=sc.sub("Environment", background_mode="2", sky=SR(sky), ambient_light_source="2", ambient_light_color=col(0.18,0.22,0.28), ambient_light_energy="0.22",
           tonemap_mode="2", tonemap_exposure="1.25", ssao_enabled="true", glow_enabled="true", glow_intensity="1.0", glow_bloom="0.08", glow_hdr_threshold="0.9", volumetric_fog_enabled="true", volumetric_fog_density="0.022",
           volumetric_fog_albedo=col(0.7,0.75,0.8), volumetric_fog_length="45.0", adjustment_enabled="true", adjustment_contrast="1.15", adjustment_saturation="0.6")
navmesh=sc.sub("NavigationMesh", geometry_parsed_geometry_type="1", geometry_source_geometry_mode="1", geometry_source_group_name='&"chapter1_nav"', agent_height="2.0", agent_radius="0.5", agent_max_climb="0.25", filter_baking_aabb="AABB(0, -10, -100, 90, 6, 66)")

sc.node("Chapter1","Node3D",script=ER(S_CHAPTER))
sc.node("WorldEnvironment","WorldEnvironment",".",environment=SR(env))
sc.node("Moon","DirectionalLight3D",".",transform=xform((0,20,0),30,-35),light_color=col(0.55,0.65,0.9),light_energy="0.5",shadow_enabled="true",directional_shadow_max_distance="70.0")
for g in ["Exterior","Station","Underground","Puzzles","Lore","Lights","Sound","Triggers","Checkpoints","ItemSpawnPoints","Monsters"]:
    sc.node(g,"Node3D",".")

def B(name,parent,c,s,mt=CONC,collide=True,yaw=0,pitch=0,op=None):
    props=dict(transform=xform(c,yaw,pitch),size=v3(*s),material=mt)
    if collide: props["use_collision"]="true"
    if op is not None: props["operation"]=str(op)
    sc.node(name,"CSGBox3D",parent,**props)
def BX(name,parent,x1,x2,y1,y2,z1,z2,mt=CONC,collide=True):
    B(name,parent,((x1+x2)/2,(y1+y2)/2,(z1+z2)/2),(abs(x2-x1),abs(y2-y1),abs(z2-z1)),mt,collide)
def inst(key,name,parent,pos,yaw=0,np=None,**props):
    sc.node(name,None,parent,instance=X[key],node_paths=np,transform=xform(pos,yaw),**props); return f"{parent}/{name}"
MESH={}
def mesh(kind, **props):
    """One shared mesh resource per shape (so 20 identical bulbs = 1 mesh)."""
    key=(kind,tuple(sorted(props.items())))
    if key not in MESH: MESH[key]=SR(sc.sub(kind, **props))
    return MESH[key]
def mi(name,parent,pos,m,mat,yaw=0,pitch=0,roll=0,shadow=True):
    props=dict(transform=xform(pos,yaw,pitch,roll),mesh=m)
    props["surface_material_override/0"]=mat
    if not shadow: props["cast_shadow"]="0"
    sc.node(name,"MeshInstance3D",parent,**props)
def sxform(pos,yaw=0,scale=(1,1,1),pitch=0,roll=0):
    """Like xform, but scaled (scale is along the object's own x, y, z)."""
    t=xform(pos,yaw,pitch,roll); v=[float(x) for x in t[len("Transform3D("):-1].split(",")]
    for r in range(3):
        for c in range(3): v[r*3+c]*=scale[c]
    return "Transform3D("+", ".join(f"{x:g}" for x in v)+")"
def prop(name,parent,model,pos,yaw=0,scale=(1,1,1),mat=None,collide=None,roll=0):
    """A sculpted prop (tools/make_props.py) with a simple invisible collision shape.
    collide: ("box", size, center) or ("cyl", radius, height, center) in the prop's own space, or None."""
    sc.node(name,"StaticBody3D",parent,transform=xform(pos,yaw,0,roll))
    me=f"{parent}/{name}"
    m=ER(sc.ext("ArrayMesh",f"res://assets/models/prop_{model}.obj"))
    sc.node("Mesh","MeshInstance3D",me,transform=sxform((0,0,0),0,scale),mesh=m,**{"surface_material_override/0":mat or METAL})
    if collide:
        if collide[0]=="box":
            sh=sc.sub("BoxShape3D",size=v3(*collide[1])); c=collide[2]
        else:
            sh=sc.sub("CylinderShape3D",radius=str(collide[1]),height=str(collide[2])); c=collide[3]
        sc.node("CollisionShape3D","CollisionShape3D",me,transform=xform(c),shape=SR(sh))
def barrel(name,parent,x,y,z):
    prop(name,parent,"barrel",(x,y,z),random.uniform(0,360),collide=("cyl",0.32,0.9,(0,0.45,0)))
def crate(name,parent,x,y,z,size,yaw=0):
    prop(name,parent,"crate",(x,y+size/2,z),yaw,(size,size,size),WOOD,("box",(size,size,size),(0,0,0)))
def light(name,parent,pos,color=(0.8,1,0.88),energy=1.0,rng=7.0,flicker=None,pulse=False,shadow=True,fixture="auto"):
    """A light plus the thing it comes from: a caged bulb underground, a
    fluorescent tube indoors. Each gets its own glow material so it can
    flicker by itself."""
    if fixture=="auto":
        x,y,z=pos
        fixture="bulb" if y<-0.5 else ("tube" if -10<=x<=10 and -16<=z<=0 and y>2 else None)
    glow=None
    if fixture:
        glow=sc.sub("StandardMaterial3D", albedo_color=col(*color), emission_enabled="true", emission=col(*color),
                    emission_energy_multiplier="4.0" if fixture=="bulb" else "2.5")
    props=dict(transform=xform(pos),light_color=col(*color),light_energy=str(energy),shadow_enabled="true" if shadow else "false",omni_range=str(rng))
    if flicker is not None:
        props.update(script=ER(S_FLICK),brokenness=str(flicker))
        if glow: props["fixture_material"]=SR(glow)
    if pulse: props.update(script=ER(S_PULSE))
    sc.node(name,"OmniLight3D",parent,**props)
    me=f"{parent}/{name}"
    if fixture=="bulb":
        mi("Bulb",me,(0,0.08,0),mesh("SphereMesh",radius="0.06",height="0.12",radial_segments="12",rings="6"),SR(glow),shadow=False)
        mi("Cage",me,(0,0.08,0),mesh("CylinderMesh",top_radius="0.09",bottom_radius="0.09",height="0.2",radial_segments="8",rings="1"),FENCE,shadow=False)
        mi("Cable",me,(0,0.35,0),mesh("CylinderMesh",top_radius="0.01",bottom_radius="0.01",height="0.4",radial_segments="4",rings="1"),BLACK,shadow=False)
    elif fixture=="tube":
        mi("Housing",me,(0,0.17,0),mesh("BoxMesh",size=v3(1.3,0.06,0.28)),METAL,shadow=False)
        mi("Tube",me,(0,0.13,0),mesh("BoxMesh",size=v3(1.2,0.03,0.16)),SR(glow),shadow=False)
def item(iid,pos,lore=""):
    n=f"{iid}_{len(sc.nodes)}"
    props=dict(transform=xform(pos),script=ER(S_IPOINT),item_id=S(iid))
    if lore: props["lore_id"]=S(lore)
    sc.node(n,"Marker3D","ItemSpawnPoints",**props)
def label(name,parent,pos,yaw,text,size=0.004,font=32,color=(0.85,0.85,0.75),outline="4"):
    sc.node(name,"Label3D",parent,transform=xform(pos,yaw),pixel_size=str(size),text=S(text),font_size=str(font),modulate=col(*color),outline_size=outline)
def gate(name,parent,inputs,outputs,mode=0,latch=True,msg=""):
    sc.node(name,"Node",parent,node_paths=["inputs","outputs"],script=ER(S_GATE),
            inputs="["+", ".join(NP(i) for i in inputs)+"]",outputs="["+", ".join(NP(o) for o in outputs)+"]",
            mode=str(mode),latch="true" if latch else "false",solved_message=S(msg))
def area(name,parent,pos,size,script,np=None,**props):
    shp=sc.sub("BoxShape3D", size=v3(*size))
    sc.node(name,"Area3D",parent,node_paths=np,transform=xform(pos),script=ER(script),**props)
    sc.node("CollisionShape3D","CollisionShape3D",f"{parent}/{name}",shape=SR(shp))
    return f"{parent}/{name}"
def stinger(name,pos,size,msg="",script=None,np=None,**props):
    p=area(name,"Triggers",pos,size,script or S_STING,np=np,message=S(msg),**props)
    sc.node("Sound","AudioStreamPlayer",p,stream=ER(STING),volume_db="-4.0")
def checkpoint(name,order,pos,size,spawns):
    p=area(name,"Checkpoints",pos,size,S_CP,order=str(order))
    for k,(dx,dz) in enumerate(spawns):
        sc.node(f"Spawn{k+1}","Marker3D",p,transform=xform((dx,-size[1]/2,dz)))

# ============================================================ ROCK (ground + underground, carved)
sc.node("Rock","CSGCombiner3D","Underground",groups=["chapter1_nav"],use_collision="true")
R="Underground/Rock"
B("Mass",R,(32.5,-22.5,-20),(125,45,160),ROCK)
carves=[
 ("StairA",(9,-0.793,-20.6),(2,2.7,9.94),-26.57),("Landing",(9,-2.65,-26.0),(2,2.7,4.6),0),("StairB",(9,-5.355,-31.716),(2,2.7,10.4),-32),
 ("Junction",(9,-7.65,-40),(10,2.7,9.0),0),("DoorSlotD1",(9,-7.475,-45),(2,3.05,1.2),0),("TunnelT",(9,-7.65,-60.25),(4,2.7,29.5),0),
 ("AlcoveA1",(12.5,-7.65,-60),(3,2.7,4),0),("AlcoveA2",(5.5,-7.65,-65),(3,2.7,4),0),("CellOpening",(9,-7.65,-75.5),(2,2.7,1.2),0),("Cell",(9,-7,-81),(10,4,10),0),
 ("CrawlC1",(2.85,-8.375,-41),(2.7,1.25,1.0),0),("CrawlC2",(2,-8.375,-44.75),(1,1.25,8.5),0),("CrawlC3",(4.3,-8.375,-48.5),(5.6,1.25,1.0),0),
 ("TunnelE",(21,-7.65,-68),(20,2.7,2),0),("DoorSlotD2",(12,-7.475,-68),(0.6,3.05,2),0),("AlcoveA3",(20.5,-7.65,-71),(3,2.7,4),0),("DoorSlotD3",(30,-7.475,-68),(0.6,3.05,2),0),
 ("ElevatorRoom",(38,-7,-68),(16,4,18),0),("Shaft",(38,-25,-56),(4.4,40,6.4),0),
]
for n,c,s,p in carves:
    B(n,R,c,s,ROCK,collide=False,pitch=p,op=2)
# The sloped stair cuts dig a wedge below the next floor; fill it back in.
BX("LandingFill",R,8,10,-4.6,-4.0,-25.3,-23.6,ROCK); BX("JunctionFill",R,8,10,-9.8,-9.0,-36.4,-34.9,ROCK)

# ============================================================ ROOM 1: EXTERIOR
E="Exterior"
BX("Road",E,-22,22,0,0.02,36,42,ROAD,collide=False)
# Invisible walls where the forest gets too thick to walk through.
sc.node("ForestEdge","StaticBody3D",E)
for n,(x1,x2,z1,z2) in {"West":(-23,-22,-1,51),"East":(22,23,-1,51),"South":(-23,23,50,51),"NW":(-23,-15,-1,0),"NE":(15,23,-1,0)}.items():
    sh=sc.sub("BoxShape3D", size=v3(x2-x1,8,z2-z1))
    sc.node(n,"CollisionShape3D",E+"/ForestEdge",transform=xform(((x1+x2)/2,4,(z1+z2)/2)),shape=SR(sh))
# Ground beyond the edges of the level, so the world never just ends.
for n,(x1,x2,z1,z2) in {"OuterW":(-150,-30,-150,160),"OuterE":(95,180,-150,160),"OuterN":(-30,95,-150,-100),"OuterS":(-30,60,60,160)}.items():
    mi(n,E,((x1+x2)/2,0,(z1+z2)/2),mesh("PlaneMesh",size=f"Vector2({x2-x1}, {z2-z1})"),MAT("ground"))

# The forest: pine trees as MultiMeshes (one draw per tree part, not per tree).
random.seed(12)
def blocked(x,z):
    if -22.8<x<22.8 and -0.8<z<50.8: return True        # the play area
    if -11.5<x<11.5 and -24<z<1: return True            # the station
    if -30<x<95 and -100<z<60: return False              # on the big ground block
    return abs(x)>140 or z<-140 or z>150
trees=[]
while len(trees)<520:
    x=random.uniform(-110,120); z=random.uniform(-110,130)
    near=-35<x<65 and -60<z<85
    if blocked(x,z) or (not near and random.random()<0.6): continue
    if any((x-tx)**2+(z-tz)**2<5.0 for tx,tz,_,_ in trees): continue
    trees.append((x,z,random.uniform(0.75,1.5),random.uniform(0,math.tau)))
parts=[("Trunks",mesh("CylinderMesh",top_radius="0.12",bottom_radius="0.25",height="4.0",radial_segments="6",rings="1"),BARK,2.0),
       ("NeedlesLow",mesh("CylinderMesh",top_radius="0.0",bottom_radius="2.3",height="3.2",radial_segments="8",rings="1"),NEEDLES,3.4),
       ("NeedlesMid",mesh("CylinderMesh",top_radius="0.0",bottom_radius="1.8",height="2.8",radial_segments="8",rings="1"),NEEDLES,5.0),
       ("NeedlesTop",mesh("CylinderMesh",top_radius="0.0",bottom_radius="1.2",height="2.4",radial_segments="7",rings="1"),NEEDLES,6.6)]
sc.node("Forest","Node3D",E)
for name,m,mat,h in parts:
    buf=[]
    for x,z,sz,rot in trees:
        c,sn=math.cos(rot)*sz,math.sin(rot)*sz
        buf+= [c,0,sn,x, 0,sz,0,h*sz, -sn,0,c,z]
    mm=sc.sub("MultiMesh", transform_format="1", instance_count=str(len(trees)), mesh=m,
              buffer="PackedFloat32Array("+", ".join(f"{v:.3f}" for v in buf)+")")
    sc.node(name,"MultiMeshInstance3D",E+"/Forest",multimesh=SR(mm),material_override=mat)

# A concrete path from the gate to the door, and telephone poles by the road.
BX("Path",E,-1.2,1.2,0,0.02,0.3,21.8,FLOOR,collide=False)
for k,x in enumerate([-19,-5,9,21]):
    B(f"Pole{k}",E,(x,3.5,34.5),(0.25,7,0.25),DWOOD)
    B(f"PoleBar{k}",E,(x,6.5,34.5),(1.6,0.12,0.12),DWOOD,collide=False)
for k,(x1,x2) in enumerate([(-19,-5),(-5,9),(9,21)]):
    for dx in (-0.7,0.7):
        mi(f"Wire{k}_{dx}",E,((x1+x2)/2+dx*0,6.45,34.5+dx*0.0),mesh("BoxMesh",size=v3(x2-x1,0.02,0.02)),BLACK,shadow=False)
for n,(x1,x2,z1,z2) in {"FenceSouthW":(-15,-1.6,21.96,22.04),"FenceSouthE":(1.6,15,21.96,22.04),"FenceWest":(-15.04,-14.96,0,22),"FenceEast":(14.96,15.04,0,22),"FenceNW":(-15,-10,-0.04,0.04),"FenceNE":(10,15,-0.04,0.04)}.items():
    BX(n,E,x1,x2,0,3,z1,z2,FENCE)
for k,x in enumerate(x for x in range(-15,16,3) if abs(x) > 2):
    BX(f"PostS{k}",E,x-0.07,x+0.07,0,3.1,21.93,22.07,METAL)
BX("GatePostL",E,-1.75,-1.55,0,3.1,21.9,22.1,METAL); BX("GatePostR",E,1.55,1.75,0,3.1,21.9,22.1,METAL)
# abandoned car + notebook
BX("CarBody",E,-11.1,-6.9,0.3,1.2,38.05,39.95,CAR); BX("CarCabin",E,-10.4,-8.2,1.2,1.9,38.15,39.85,CAR)
for k,(wx,wz) in enumerate([(-10.4,38),(-10.4,40),(-7.6,38),(-7.6,40)]):
    mi(f"Wheel{k}",E,(wx,0.35,wz),mesh("CylinderMesh",top_radius="0.35",bottom_radius="0.35",height="0.25",radial_segments="12",rings="1"),BLACK,pitch=90)
mi("Windshield",E,(-8.18,1.55,39),mesh("BoxMesh",size=v3(0.04,0.6,1.6)),BLACK,shadow=False)
light("CarDomeLight","Lights",(-9.3,1.75,39),color=(1,0.8,0.5),energy=0.15,rng=2.0,flicker=0.5,fixture=None)
inst("lpersonal","InformantNotebook","Lore",(-7.4,1.2,39),0,entry=ER(LORE("personal_journalist_notebook")))
item("battery",(-6,0.2,41))
# sign
BX("SignBoard",E,-5.2,-2.8,1.2,2.2,22.1,22.14,RUST)
label("SignText",E,(-4,1.7,22.16),0,"PROPERTY OF U.S. GOVERNMENT\nNO TRESPASSING\nBlackwater Weather Station",size=0.0035,font=36,color=(0.85,0.8,0.7),outline="0")
inst("drag","DragMarks","Lore",(0.6,0,26.5),8)
# yard
for n,(x1,x2,z1,z2) in {"ShedN":(8.5,11.5,10.5,10.65),"ShedS":(8.5,11.5,13.35,13.5),"ShedE":(11.35,11.5,10.5,13.5),
                        "ShedW1":(8.5,8.65,10.5,11.3),"ShedW2":(8.5,8.65,12.5,13.5)}.items():
    BX(n,E,x1,x2,0,2.5,z1,z2,WOOD)
BX("ShedLintel",E,8.5,8.65,2.05,2.5,11.3,12.5,WOOD)
BX("ShedFloor",E,8.65,11.35,0,0.03,10.65,13.35,DWOOD,collide=False)
BX("ShedRoof",E,8.3,11.7,2.5,2.65,10.3,13.7,METAL)
for k,(bx,bz) in enumerate([(7.8,10.6),(7.3,11.5),(12.2,14.2)]):
    barrel(f"Barrel{k}",E,bx,0,bz)
# The radar dome sits on a short drum ON the roof (it used to poke through the office ceiling).
B("RadarBase","Station",(-5,3.75,-9),(3.2,0.5,3.2),CONC,collide=False)
sc.node("RadarDome","CSGSphere3D","Station",transform=xform((-5,5.6,-9)),radius="2.2",radial_segments="16",rings="8",material=WHITE)
B("Mast","Station",(6,7.5,-4),(0.15,8,0.15),METAL,collide=False)
for k,y in enumerate([5,8,10.5]):
    B(f"MastBar{k}","Station",(6,y,-4),(1.4-k*0.35,0.06,0.06),METAL,collide=False)
light("MastWarning","Lights",(6,11.6,-4),color=(1,0.1,0.05),energy=0.8,rng=6,pulse=True,shadow=False,fixture="bulb")
item("crowbar",(8,0.2,15.5))
BX("LampPole",E,2.9,3.1,0,4.6,5.9,6.1,METAL)
light("YardLamp","Lights",(3,4.4,6.4),color=(1,0.85,0.6),energy=1.4,rng=12,flicker=0.25,fixture="bulb")
B("LampArm",E,(3,4.62,6.2),(0.08,0.08,0.5),METAL,collide=False)
sc.node("Gate","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((0,0,22)),script=ER(S_MOVER),open_offset=v3(0,1.15,0),move_time="0.9",sound=NP("Sound"))
gsh=sc.sub("BoxShape3D", size=v3(3.1,2.6,0.12)); gmesh=sc.sub("BoxMesh", size=v3(3.1,2.6,0.08))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/Gate",transform=xform((0,1.3,0)),shape=SR(gsh))
sc.node("Mesh","MeshInstance3D","Puzzles/Gate",transform=xform((0,1.3,0)),mesh=SR(gmesh),**{"surface_material_override/0":FENCE})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/Gate",stream=ER(CREAKDOOR),pitch_scale="0.6",unit_size="6.0")
inst("hold","GateLift","Puzzles",(-2.25,1.0,22.14),0,required_character="3",prompt_text=S("Lift the gate and hold it up (the others crawl under)"))
inst("clamp","GateJam","Puzzles",(2.25,1.0,21.86),180,np=["requires"],requires=NP("../GateLift"),requires_message=S("Someone has to lift the gate first."),prompt_text=S("Gate clamp"))
gate("GateLogic","Puzzles",["../GateLift","../GateJam"],["../Gate"],mode=1,latch=False,msg="")
gate("GateJammedMsg","Puzzles",["../GateJam"],[],msg="The crowbar jams the gate open.")
sc.node("Wind","AudioStreamPlayer3D","Sound",transform=xform((0,6,28)),stream=ER(WIND),volume_db="-2.0",unit_size="30.0",max_distance="70.0",autoplay="true")

# ============================================================ ROOM 2: STATION OFFICE
St="Station"
H=3.2; T=0.3
walls=[("FrontW",-10,-0.5,0,T),("FrontE",1.5,10,0,T),("BackW",-10,8,-16,T),("West",-10,-10,-16,0),("East",10,10,-16,0)]
BX("FrontW",St,-10,-0.5,0,H,-0.15,0.15,WALL); BX("FrontE",St,1.5,10,0,H,-0.15,0.15,WALL)
BX("BackWall",St,-10,8,0,H,-16.15,-15.85,WALL)
BX("WestWall",St,-10.15,-9.85,0,H,-16,0,WALL); BX("EastWall",St,9.85,10.15,0,H,-16,0,WALL)
BX("HallWestA",St,-1.15,-0.85,0,H,-16,-4,WALL); BX("HallWestB",St,-1.15,-0.85,0,H,-2.5,0,WALL)
BX("HallEastA",St,1.85,2.15,0,H,-16,-11,WALL); BX("HallEastB",St,1.85,2.15,0,H,-9,-3,WALL); BX("HallEastC",St,1.85,2.15,0,H,-1.5,0,WALL)
BX("DirectorWall",St,2,10,0,H,-6.3,-6.0,WALL)
BX("Roof",St,-10.3,10.3,H,H+0.3,-16.3,0.3,CONC)
BX("StairHouseW",St,7.7,8.0,0,3.0,-22.4,-16,WALL); BX("StairHouseE",St,10.0,10.3,0,3.0,-22.4,-16,WALL)
BX("StairHouseN",St,7.7,10.3,0,3.0,-22.7,-22.4,WALL); BX("StairHouseRoof",St,7.7,10.3,3.0,3.3,-22.7,-16,CONC)
# furniture
def desk(name,x1,x2,z1,z2):
    """An old office desk with drawers (things sit on top at y = 0.9).
    Long side along x: drawers face -z. Long side along z: turned to face +x."""
    w,d=x2-x1,z2-z1
    if w>=d: yaw,scale=0,(w,1,d/0.6)
    else: yaw,scale=90,(d,1,w/0.6)
    prop(name,St,"desk",((x1+x2)/2,0,(z1+z2)/2),yaw,scale,WOOD,("box",(scale[0]*1.0,0.9,0.6*scale[2]),(0,0.45,0)))
def chair(name,x,z,yaw,tipped=False):
    prop(name,St,"chair",(x,0.27 if tipped else 0,z),yaw,roll=80 if tipped else 0)
BX("OfficeFloor",St,-10,10,0,0.02,-16,0,LINO,collide=False)
desk("ComputerDesk",-9.4,-7.6,-13,-11); BX("Screen",St,-9.35,-9.25,0.95,1.6,-12.5,-11.5,SCREEN,collide=False)
BX("Monitor",St,-9.75,-9.3,0.9,1.65,-12.6,-11.4,BLACK)
desk("TapeDesk",-9.4,-7.6,-10.1,-8.7); desk("EngineerDesk",-4.8,-3.2,-11.4,-10.6)
desk("FileDesk",-5.8,-4.2,-5.4,-4.6); desk("DirectorDesk",5,7,-10.5,-9.5); desk("BreakTable",5.2,6.8,-3.6,-2.4)
chair("ChairEng",-4,-10,180); chair("ChairFile",-5,-4,0); chair("ChairDirector",6,-9,0); chair("ChairTipped",-7,-7,40,tipped=True)
chair("ChairBreak1",5.5,-4,0); chair("ChairBreak2",6.7,-2,200,tipped=True)
for k,z in enumerate([-2.2,-2.9,-3.6]):
    prop(f"Cabinet{k}",St,"cabinet",(-9.5,0,z),-90,collide=("box",(0.6,1.35,0.65),(0,0.675,0)))
BX("Bookshelf",St,2.2,2.6,0,2.0,-14.5,-12.5,DWOOD)
for k,y in enumerate([0.5,1.0,1.5]):
    BX(f"Books{k}",St,2.25,2.55,y,y+0.3,-14.4,-12.6+(-0.4 if k==1 else 0),CAR,collide=False)
random.seed(3)
for k in range(28):
    x=random.uniform(-9,9); z=random.uniform(-15.5,-0.5)
    if abs(x-0.5)<1.0 or abs(x-9)<1.2 and z<-14: continue  # keep the hall and the cabinet spot clear
    mi(f"Paper{k}",St,(x,0.025,z),mesh("PlaneMesh",size="Vector2(0.21, 0.29)"),PAPER,yaw=random.uniform(0,360),shadow=False)
# Boarded-up windows on the outside walls.
for k,(x,z,yaw) in enumerate([(-7,0.17,0),(-4,0.17,0),(5,0.17,0),(8,0.17,0),(-10.17,-4,90),(-10.17,-12,90),(10.17,-4,90),(10.17,-12,90)]):
    if k != 6:  # window 6 (break room, east) is a real opening: something looks in
        mi(f"Window{k}",St,(x,1.7,z),mesh("BoxMesh",size=v3(1.3,1.0,0.02)),BLACK,yaw=yaw,shadow=False)
    for j,roll in enumerate([25,-20]):
        mi(f"Board{k}_{j}",St,(x+(0.01 if yaw==0 else 0),1.7,z+(0.02 if yaw==0 else 0)),mesh("BoxMesh",size=v3(1.5,0.16,0.04)),DWOOD,yaw=yaw,roll=roll)
inst("door","FrontDoor",St,(-0.5,0,0),0)
# --- The outside of the station: a cold-war building that has rotted for years.
# All of it is just for looks (no collision), except the step and the AC units.
GRIME=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.06,0.05,0.035,0.55), transparency="1", roughness="1.0"))
RUSTSTREAK=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.28,0.12,0.05,0.45), transparency="1", roughness="1.0"))
SIGNLIGHT=SR(sc.sub("StandardMaterial3D", albedo_color=col(1,0.8,0.5), emission_enabled="true", emission=col(1,0.75,0.45), emission_energy_multiplier="3.0"))
def nb(name,x1,x2,y1,y2,z1,z2,mt=CONC): BX(name,St,x1,x2,y1,y2,z1,z2,mt,collide=False)
# Darker concrete base all the way round, and a thick roof edge (parapet).
nb("BaseFront",-10.25,10.25,0,0.45,0.15,0.3); nb("BaseWest",-10.3,-10.15,0,0.45,-16.3,0.3); nb("BaseEast",10.15,10.3,0,0.45,-16.3,0.3)
nb("BaseBack",-10.3,10.3,0,0.45,-16.3,-16.15)
for n,(x1,x2,z1,z2) in {"Front":(-10.4,10.4,0.2,0.4),"Back":(-10.4,10.4,-16.4,-16.2),"West":(-10.4,-10.2,-16.4,0.4),"East":(10.2,10.4,-16.4,0.4)}.items():
    nb("Parapet"+n,x1,x2,H+0.3,H+0.75,z1,z2)
    nb("Coping"+n,x1-0.05,x2+0.05,H+0.75,H+0.82,z1-0.05,z2+0.05,METAL)
# Concrete pillars that stick out of the walls, so the walls aren't flat.
for k,x in enumerate([-10,-6,-2.4,3.4,6,10]):
    nb(f"PillarF{k}",x-0.22,x+0.22,0,H+0.75,0.1,0.32)
for side,x in (("W",-10.32),("E",10.32)):
    for k,z in enumerate([-16,-8,0]):
        nb(f"Pillar{side}{k}",x-0.12,x+0.12,0,H+0.75,z-0.22,z+0.22)
# Entrance: a concrete roof on two steel posts, a step, a caged lamp, and the station's sign.
nb("CanopySlab",-1.9,2.9,2.75,2.95,0.15,2.2)
nb("CanopyEdge",-1.95,2.95,2.6,2.75,2.05,2.25,METAL)
for k,x in enumerate([-1.7,2.7]):
    nb(f"CanopyPost{k}",x-0.06,x+0.06,0,2.75,2.0,2.12,METAL)
BX("DoorStep",St,-1.4,2.4,0,0.06,0.15,1.4,FLOOR,collide=False)
nb("SignPlate",-1.6,2.6,2.98,3.55,2.05,2.12,RUST)
label("StationName",St,(0.5,3.27,2.13),0,"BLACKWATER WEATHER STATION 7",size=0.0042,font=40,color=(0.85,0.82,0.7),outline="0")
label("StationNumber",St,(5,2.6,0.33),0,"BLDG 7-A  ·  RESTRICTED",size=0.0035,font=32,color=(0.6,0.58,0.5),outline="0")
mi("EntranceBulb",St,(0.5,2.6,1.2),mesh("SphereMesh",radius="0.08",height="0.16",radial_segments="8",rings="4"),SIGNLIGHT,shadow=False)
light("EntranceLamp","Lights",(0.5,2.45,1.3),color=(1,0.78,0.5),energy=1.1,rng=7,flicker=0.55,fixture=None)
# Window frames and sills around the boarded windows.
for k,(x,z,yaw) in enumerate([(-7,0.17,0),(-4,0.17,0),(5,0.17,0),(8,0.17,0),(-10.17,-4,90),(-10.17,-12,90),(10.17,-4,90),(10.17,-12,90)]):
    out=1 if (yaw==0 or x>0) else -1
    for j,(dx,dy,w,h) in enumerate([(0,0.58,1.5,0.1),(0,-0.58,1.6,0.12),(-0.7,0,0.1,1.2),(0.7,0,0.1,1.2)]):
        if yaw==0: pos=(x+dx,1.7+dy,0.2)
        else: pos=(x+out*0.05,1.7+dy,z+dx)
        mi(f"WinFrame{k}_{j}",St,pos,mesh("BoxMesh",size=v3(w,h,0.08)),METAL,yaw=yaw,shadow=False)
    # A rust streak running down from each window sill.
    if yaw==0: pos=(x+0.2,0.85,0.18)
    else: pos=(x+out*0.02,0.85,z-0.2)
    mi(f"WinStreak{k}",St,pos,mesh("QuadMesh",size="Vector2(0.35, 1.5)"),RUSTSTREAK,yaw=yaw if yaw==0 else (90 if out>0 else -90),shadow=False)
# Dirt where rain runs off the roof and up from the ground.
for k,(x,w) in enumerate([(-8.5,2.5),(-3.5,1.4),(4.2,1.8),(8.6,2.2)]):
    mi(f"RoofGrime{k}",St,(x,H-0.1,0.181),mesh("QuadMesh",size=f"Vector2({w}, 1.1)"),GRIME,shadow=False)
mi("GroundGrimeFront",St,(0,0.6,0.32),mesh("QuadMesh",size="Vector2(20.4, 0.5)"),GRIME,shadow=False)
# Drainpipes at the front corners.
for k,x in enumerate([-9.7,9.7]):
    mi(f"Drainpipe{k}",St,(x,(H+0.6)/2,0.42),mesh("CylinderMesh",top_radius="0.06",bottom_radius="0.06",height=str(H+0.6),radial_segments="8",rings="1"),METAL,shadow=False)
    mi(f"DrainShoe{k}",St,(x,0.12,0.55),mesh("BoxMesh",size=v3(0.14,0.12,0.3)),METAL,shadow=False)
    mi(f"DrainStain{k}",St,(x,0.02,0.85),mesh("PlaneMesh",size="Vector2(0.7, 0.9)"),GRIME,shadow=False)
# An electric meter and a cable running up the east side, and an old fuel tank.
nb("MeterBox",10.32,10.5,1.1,1.8,-2.2,-1.6,METAL)
nb("Conduit",10.33,10.4,1.8,H+0.7,-1.95,-1.85,METAL)
mi("FuelTank",St,(11.4,1.0,-10),mesh("CylinderMesh",top_radius="0.6",bottom_radius="0.6",height="2.6",radial_segments="14",rings="1"),RUST,pitch=90)
for k,z in enumerate([-11,-9]):
    nb(f"TankLeg{k}",11.0,11.8,0,0.45,z-0.06,z+0.06,METAL)
nb("FuelPipe",10.32,10.85,1.3,1.38,-10.04,-9.96,METAL)
# Rooftop: humming air units, vents, a dead satellite dish and aerials.
for k,(x,z) in enumerate([(-8,-3),(2.5,-12.5)]):
    BX(f"ACUnit{k}",St,x-0.8,x+0.8,H+0.3,H+1.3,z-0.6,z+0.6,METAL)
    mi(f"ACFan{k}",St,(x,H+1.32,z),mesh("CylinderMesh",top_radius="0.45",bottom_radius="0.45",height="0.04",radial_segments="16",rings="1"),BLACK,shadow=False)
for k,(x,z) in enumerate([(-2,-6),(4,-2.5),(-6,-14)]):
    mi(f"RoofVent{k}",St,(x,H+0.65,z),mesh("CylinderMesh",top_radius="0.18",bottom_radius="0.18",height="0.7",radial_segments="10",rings="1"),METAL,shadow=False)
    mi(f"RoofVentCap{k}",St,(x,H+1.05,z),mesh("CylinderMesh",top_radius="0.05",bottom_radius="0.3",height="0.15",radial_segments="10",rings="1"),METAL,shadow=False)
mi("DishPost",St,(8,H+0.9,-13),mesh("CylinderMesh",top_radius="0.06",bottom_radius="0.08",height="1.2",radial_segments="8",rings="1"),METAL,shadow=False)
mi("Dish",St,(8,H+1.6,-12.8),mesh("CylinderMesh",top_radius="0.75",bottom_radius="0.15",height="0.3",radial_segments="18",rings="1"),WHITE,pitch=-60,roll=15)
for k,(x,z,h) in enumerate([(-9,-15,3.0),(-8.6,-15.2,2.2)]):
    mi(f"Aerial{k}",St,(x,H+0.3+h/2,z),mesh("CylinderMesh",top_radius="0.02",bottom_radius="0.03",height=str(h),radial_segments="6",rings="1"),METAL,shadow=False)
# Barbed wire along the top of the fence (arms leaning out, three strands).
for n,(x1,x2,z1,z2) in {"S1":(-15,-1.6,22,22),"S2":(1.6,15,22,22),"W":(-15,-15,0,22),"E":(15,15,0,22)}.items():
    length=max(abs(x2-x1),abs(z2-z1)); along_x=abs(x2-x1)>0
    lean=(0,0.25) if along_x else ((-0.25,0) if x1<0 else (0.25,0))
    for j in range(3):
        y=3.15+j*0.14; dx,dz=lean[0]*(j+1)/3,lean[1]*(j+1)/3
        mi(f"Barb{n}{j}",E,((x1+x2)/2+dx,y,(z1+z2)/2+dz),mesh("BoxMesh",size=v3(length if along_x else 0.015,0.015,0.015 if along_x else length)),METAL,shadow=False)
    steps=int(length//3)+1
    for j in range(steps):
        t=j/max(steps-1,1); x=x1+(x2-x1)*t; z=z1+(z2-z1)*t
        mi(f"BarbArm{n}{j}",E,(x+lean[0]/2,3.3,z+lean[1]/2),mesh("BoxMesh",size=v3(0.03,0.5,0.03)),METAL,
           pitch=(-30 if along_x else 0),roll=(0 if along_x else (30 if x1<0 else -30)),shadow=False)
# split code
inst("tape","TapeMachine","Puzzles",(-8.5,0.9,-9.4),90,required_lore=S("tape_welcome"))
inst("keypad","OfficeKeypad","Puzzles",(1.83,1.4,-8.0),-90)
inst("hold","MonitorPower","Puzzles",(1.83,1.3,-7.0),-90,prompt_text=S("Hold the monitor power switch ON"))
gate("ComputerBoot","Puzzles",["../TapeMachine","../MonitorPower"],[],latch=False)
sc.node("Monitor","Label3D","Puzzles",node_paths=["source","hidden_until"],transform=xform((-9.22,1.28,-12),90),pixel_size="0.004",
        text=S(""),font_size="48",modulate=col(0.4,1,0.5),outline_size="0",script=ER(S_CODE),source=NP("../OfficeKeypad"),hidden_until=NP("../ComputerBoot"),
        hidden_text=S("VOICE LOCKED / NO POWER"),template=S("DIRECTOR'S TERMINAL\nDOOR CODE: %s"))
inst("door","DirectorDoor","Puzzles",(2,0,-9),90,puzzle_controlled="true")
gate("OfficeGate","Puzzles",["../OfficeKeypad"],["../DirectorDoor"],msg="The director's office unlocks.")
inst("cab","FilingCabinet","Puzzles",(9.0,0,-15.25),0)
inst("door","StairDoor","Puzzles",(8,0,-16),0)
sc.node("Lock","Node","Puzzles/StairDoor",script=ER(S_LOCK))
# lore + gear
inst("lfile","StaffDirectory","Lore",(-5,0.9,-5),20,entry=ER(LORE("file_staff_directory")))
inst("lpersonal","EngineerNameplate","Lore",(-4,0.9,-11),0,entry=ER(LORE("personal_engineer_nameplate")))
inst("lpaper","Corkboard","Lore",(9.84,1.6,-9),-90,entry=ER(LORE("file_corkboard")))
item("reel_tape",(-6.5,0.2,-14.8),"tape_welcome"); item("walkie",(-2.5,0.2,-1.0)); item("walkie",(8.5,0.2,-7.0))
item("battery",(6,1.0,-3.2)); item("flare",(6.5,1.0,-2.8))
light("OfficeLight","Lights",(-5,3.0,-8),energy=0.9,rng=8,flicker=0.3); light("HallLight","Lights",(0.5,3.0,-8),energy=0.6,rng=6,flicker=0.6)
light("DirectorLight","Lights",(6,3.0,-11),energy=0.8,rng=6,flicker=0.15); light("BreakLight","Lights",(6,3.0,-3),energy=0.6,rng=5,flicker=0.8)
sc.node("Buzz","AudioStreamPlayer3D","Sound",transform=xform((0,2.8,-8)),stream=ER(BUZZ),volume_db="-20.0",unit_size="3.0",autoplay="true")

# ============================================================ ROOM 3: HIDDEN STAIRWELL
label("TallyMarks","Underground",(8.05,-2.7,-25.5),90,"\n".join(["|||| " * 9]*9),size=0.003,font=32,color=(0.75,0.72,0.65),outline="0")
inst("lposter","Poster","Lore",(9.95,-2.4,-25.0),-90,entry=ER(LORE("file_poster_stronger")))
inst("lpersonal","GuardRoster","Lore",(9.75,-4,-24.2),-60,entry=ER(LORE("personal_guard_roster")))
item("battery",(8.25,-3.8,-24.0)); item("battery",(8.25,-3.8,-24.4)); item("flare",(9.75,-3.8,-26.9))
light("DyingBulb","Lights",(9,-1.6,-25.5),color=(1,0.85,0.6),energy=0.6,rng=5,flicker=0.85)
area("FlashlightDrain","Triggers",(9,1.4,-18.5),(2.2,3,3),S_DRAIN)

# ============================================================ ROOM 4: MAINTENANCE TUNNELS
inst("vent","VentCover","Puzzles",(4.05,-9,-41),90)
inst("door","BoltedDoor","Puzzles",(8,-9,-45),0,puzzle_controlled="true")
inst("lever","DoorBolt","Puzzles",(10.6,-7.7,-45.55),180,one_way="true",prompt_text=S("Slide the door bolt open"))
gate("BoltGate","Puzzles",["../DoorBolt"],["../BoltedDoor"],msg="The bolted door swings open.")
label("JunctionHint","Underground",(9,-7.3,-44.4),0,"BOLTED FROM THE OTHER SIDE",size=0.003,font=32,color=(0.85,0.7,0.5))
item("fuse",(9.2,-8.8,-55)); item("medkit",(12.8,-8.8,-59.5))
BX("CrateA1",Underground:="Underground",12.5,13.5,-9,-8.4,-61.8,-60.8,WOOD)
inst("lpersonal","VolunteerID","Lore",(13,-8.4,-61.3),0,entry=ER(LORE("personal_son_volunteer_id")))
BX("CrateA2","Underground",4.6,5.6,-9,-8.4,-64.5,-63.5,WOOD)
inst("lfile","Subject7Log","Lore",(5.1,-8.4,-64),0,entry=ER(LORE("file_subject7_log")))
BX("Locker","Underground",4.0,4.5,-9,-7.0,-66.6,-65.6,METAL)
inst("lpaper","CrayonDrawing","Lore",(4.53,-7.8,-66.1),90,entry=ER(LORE("personal_son_drawing")))
chart="HEIGHT\n----- WK 31 ^^ past the ceiling ^^\n----- WK 23   9 ft 2\n----- WK 14   7 ft 11\n----- WK 6    6 ft 9\n----- WK 1    6 ft 0"
label("HeightChart","Underground",(10.95,-7.5,-52),-90,chart,size=0.003,font=32,color=(0.8,0.1,0.08),outline="0")
inst("door","TunnelDoor","Puzzles",(12,-9,-67),90,puzzle_controlled="true")
light("TunnelLight1","Lights",(9,-6.6,-52),energy=0.6,rng=6,flicker=0.5); light("TunnelLight2","Lights",(9,-6.6,-66),energy=0.5,rng=6,flicker=0.9)
light("JunctionRed","Lights",(9,-6.7,-40),color=(1,0.08,0.04),energy=1.2,rng=8,pulse=True)
light("CellGlow","Lights",(9,-5.6,-81),color=(0.3,0.6,0.4),energy=0.15,rng=6,shadow=False)
item("fuse",(20.5,-8.8,-72)); light("AlcoveA3Light","Lights",(20.5,-6.7,-71),energy=0.4,rng=4,flicker=0.7)
light("ELight1","Lights",(16,-6.6,-68),energy=0.5,rng=6,flicker=0.5); light("ELight2","Lights",(25,-6.6,-68),energy=0.5,rng=6,flicker=0.7)
inst("door","ElevatorRoomDoor","Puzzles",(30,-9,-67),90)
sc.node("Drone","AudioStreamPlayer3D","Sound",transform=xform((15,-7,-58)),stream=ER(DRONE),volume_db="-6.0",unit_size="25.0",autoplay="true")
sc.node("TunnelSounds","AudioStreamPlayer3D","Sound",transform=xform((20,-7.5,-60)),unit_size="8.0",script=ER(S_RAND),
        sounds=f'Array[AudioStream]([{ER(DRIP)}, {ER(DRIP)}, {ER(CLANK)}, {ER(CREAK)}])',area_size=v3(40,2,50),min_delay="4.0",max_delay="10.0")

# --- Dressing the tunnels: pipes, cables, junk. Props that block the way are
# in the "chapter1_nav" group so the Long Man walks around them.
U="Underground"
sc.node("NavProps","Node3D",U,groups=["chapter1_nav"])
NPROP=U+"/NavProps"
def pipe(name,a,b,r=0.09,mat=None):
    """A straight pipe from point a to point b (along X or Z)."""
    (x1,y1,z1),(x2,y2,z2)=a,b
    length=abs(x2-x1)+abs(z2-z1)+abs(y2-y1)
    c=((x1+x2)/2,(y1+y2)/2,(z1+z2)/2)
    yaw,pitch,roll=(0,90,0) if abs(z2-z1)>0 else ((0,0,90) if abs(x2-x1)>0 else (0,0,0))
    mi(name,U,c,mesh("CylinderMesh",top_radius=f"{r}",bottom_radius=f"{r}",height=f"{length:.2f}",radial_segments="10",rings="1"),mat or METAL,yaw,pitch,roll)
pipe("PipeT1",(7.25,-6.75,-74.5),(7.25,-6.75,-46)); pipe("PipeT2",(7.3,-7.1,-74.5),(7.3,-7.1,-46),0.06)
pipe("PipeT3",(10.78,-6.6,-74.5),(10.78,-6.6,-46),0.05,BLACK)
pipe("PipeE1",(14.5,-6.75,-67.25),(28,-6.75,-67.25)); pipe("PipeE2",(14.5,-7.05,-67.2),(28,-7.05,-67.2),0.05,BLACK)
pipe("PipeJ1",(4.25,-6.7,-44.3),(13.8,-6.7,-44.3))
pipe("PipeRoom1",(30.3,-5.6,-76.6),(45.7,-5.6,-76.6),0.14); pipe("PipeRoom2",(30.3,-5.3,-59.4),(45.7,-5.3,-59.4),0.1)
for k,(x,z) in enumerate([(13.1,-43.6),(13.3,-36.6),(12.6,-36.3),(41.8,-76.4),(42.5,-76.5),(30.7,-64.5)]):
    barrel(f"Barrel{k}",NPROP,x,-9,z)
for k,(x,z,sz,yaw) in enumerate([(4.8,-36.3,0.9,10),(45.1,-66.2,1.0,0),(45.2,-64.9,0.7,25),(36,-76.3,0.8,0)]):
    crate(f"Crate{k}",NPROP,x,-9,z,sz,yaw)
# The cell: a bed frame with straps, where Subject 7 was kept.
sc.node("CellBed","CSGBox3D",NPROP,transform=xform((12.6,-8.6,-83.5)),size=v3(1.0,0.12,2.1),use_collision="true",material=METAL)
for k,(dx,dz) in enumerate([(-0.45,-1.0),(0.45,-1.0),(-0.45,1.0),(0.45,1.0)]):
    B(f"CellBedLeg{k}",U,(12.6+dx,-8.8,-83.5+dz),(0.06,0.4,0.06),METAL,collide=False)
for k,dz in enumerate([-0.6,0.1,0.7]):
    mi(f"Strap{k}",U,(12.6,-8.52,-83.5+dz),mesh("BoxMesh",size=v3(1.06,0.03,0.1)),DWOOD,roll=0)
label("CellScratches",U,(13.95,-7.6,-81),-90,"LET ME OUT LET ME OUT\nLET ME OUT LET ME\nIT HURTS TO GROW",size=0.004,font=40,color=(0.5,0.45,0.4),outline="0")

# monster
sc.node("PatrolPoints","Node3D","Monsters")
for k,p in enumerate([(9,-9,-82),(9,-9,-72),(9,-9,-56),(5.5,-9,-65),(21,-9,-68),(38,-9,-68),(55,-9,-66),(72,-9,-66),(72,-9,-90)]):
    sc.node(f"Point{k+1}","Marker3D","Monsters/PatrolPoints",transform=xform(p))
sc.node("LongMan",None,"Monsters",instance=X["longman"],node_paths=["patrol_points"],transform=xform((9,-9,-82),180),patrol_points=NP("../PatrolPoints"),start_delay="99999.0")
inst("mphoto","Photo","Monsters/LongMan",(0,0,0),0)
sc.node("Navigation","NavigationRegion3D",".",navigation_mesh=SR(navmesh),script=ER(S_NAV))

stinger("TunnelsSting",(9,-7.5,-38),(9,3,5),msg="It's cold down here. Something smells like rust and old blood.")
# Cutscenes: the intro over the station, and Subject 7 rising in his cell.
sc.node("Cutscenes","Node",".")
sc.node("Intro","Node","Cutscenes",script=ER(S_CUT),play_on_start="true",shots=shots(
    ((-14,9,62),(0,2,-6),(-6,6.5,50),(0,2,-8),5.0,"1999. Site 12 was sealed... with people still inside."),
    ((-6.5,1.8,27),(-4,1.7,22),(-4.6,1.7,24.6),(-4,1.7,22),3.5,"Officially, it was only ever a weather station."),
    ((7,2.2,15),(-5,3.4,-9),(3,2.8,9),(-5,3.4,-9),4.0,"2015. Four strangers came looking for answers."),
    ((0.5,1.7,30),(0,1.4,22),(0.2,1.65,26),(0,1.3,22),2.5,"CHAPTER 1  -  THE SURFACE")))
sc.node("Reveal","Node","Cutscenes",script=ER(S_CUT),shots=shots(
    ((9.4,-7.7,-73.2),(9,-6.9,-82),(9.15,-7.6,-75.2),(9,-6.7,-82),1.8,"SUBJECT 7"),
    ((9.25,-6.35,-80.1),(9,-6.45,-81.7),(9.08,-6.42,-80.7),(9,-6.45,-81.7),1.6,"")))
stinger("ChaseTrigger",(9,-7.5,-67),(4,3,4),msg="RUN!",script=S_CHASE,np=["monster","cutscene"],monster=NP("../../Monsters/LongMan"),cutscene=NP("../../Cutscenes/Reveal"))

# ============================================================ ROOM 5: ELEVATOR ROOM
sc.node("RoomLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("Bright1","Puzzles/RoomLights",(34,-5.6,-64),energy=1.2,rng=10); light("Bright2","Puzzles/RoomLights",(42,-5.6,-72),energy=1.2,rng=10)
light("ElevatorRed","Lights",(38,-5.6,-68),color=(1,0.08,0.04),energy=1.0,rng=12,pulse=True)
inst("gen","Generator","Puzzles",(32.5,-9,-75.8),0,np=["lamp"],lamp=NP("../GeneratorLamp"))
light("GeneratorLamp","Puzzles",(32.5,-7,-74.8),color=(1,0.8,0.55),energy=0.8,rng=4)
inst("fuse","FuseBoxEast","Puzzles",(45.95,-7.6,-70),-90); inst("fuse","FuseBoxWest","Puzzles",(30.05,-7.6,-73),90)
inst("lamp","PowerLamp","Puzzles",(38,-5.4,-59.2),0)
gate("PowerGate","Puzzles",["../Generator","../FuseBoxEast","../FuseBoxWest"],["../RoomLights","../PowerLamp"],msg="Power restored. The elevator panel flickers on.")
sc.node("OverrideRead","Node","Puzzles",script=ER(S_LORECHK),lore_id=S("file_containment_order"))
gate("ConsolesEnabled","Puzzles",["../PowerGate","../OverrideRead","../ElevatorKeySlot"],[])
inst("console","ConsoleWest","Puzzles",(31.5,-9,-61),90,np=["requires"],requires=NP("../ConsolesEnabled"),requires_message=S("Dead. It needs power, the override procedure (the Containment Order), and the elevator key (in the Archive)."))
inst("console","ConsoleEast","Puzzles",(44.5,-9,-75.5),-90,np=["requires"],requires=NP("../ConsolesEnabled"),requires_message=S("Dead. It needs power, the override procedure (the Containment Order), and the elevator key (in the Archive)."))
gate("DualKey","Puzzles",["../ConsoleWest","../ConsoleEast"],[],msg="Override accepted. Everyone into the elevator!")
BX("ControlDesk","Underground",39,41,-9,-8.1,-74.4,-73.6,METAL)
inst("lfile","ContainmentOrder","Lore",(40,-8.1,-74),-10,entry=ER(LORE("file_containment_order")))
inst("lpaper","Blueprint","Lore",(36.5,-7.2,-76.95),0,entry=ER(LORE("personal_engineer_blueprint")))
BX("TapeTable","Underground",43.4,44.6,-9,-8.1,-63,-62,WOOD)
inst("tape","TapeMachine2","Puzzles",(44,-8.1,-62.5),-90)
item("reel_tape",(43,-8.8,-61),"tape_final_recording")
# the elevator car
EL="Puzzles/Elevator"
sc.node("Elevator","AnimatableBody3D","Puzzles",node_paths=["powered_by"],transform=xform((38,-9,-56)),script=ER(S_ELEV),powered_by=NP("../DualKey"))
for n,(c,s) in {"Floor":((0,-0.1,0),(3.8,0.2,5.8)),"WallW":((-1.9,1.5,0),(0.1,3,5.8)),"WallE":((1.9,1.5,0),(0.1,3,5.8)),"WallBack":((0,1.5,2.9),(3.8,3,0.1)),"Ceiling":((0,3.05,0),(3.8,0.1,5.8))}.items():
    sh=sc.sub("BoxShape3D", size=v3(*s)); me=sc.sub("BoxMesh", size=v3(*s))
    sc.node(n+"Shape","CollisionShape3D",EL,transform=xform(c),shape=SR(sh))
    sc.node(n,"MeshInstance3D",EL,transform=xform(c),mesh=SR(me),**{"surface_material_override/0":METAL})
sc.node("Gate","AnimatableBody3D",EL,transform=xform((3.8,0,-2.95)))
gsh2=sc.sub("BoxShape3D", size=v3(3.8,3,0.08)); gm2=sc.sub("BoxMesh", size=v3(3.8,3,0.06))
sc.node("CollisionShape3D","CollisionShape3D",EL+"/Gate",transform=xform((0,1.5,0)),shape=SR(gsh2))
sc.node("Mesh","MeshInstance3D",EL+"/Gate",transform=xform((0,1.5,0)),mesh=SR(gm2),**{"surface_material_override/0":FENCE})
ish=sc.sub("BoxShape3D", size=v3(3.6,2.6,5.4))
sc.node("Inside","Area3D",EL,transform=xform((0,1.3,0.1)))
sc.node("CollisionShape3D","CollisionShape3D",EL+"/Inside",shape=SR(ish))
sc.node("DescendButton",None,EL,instance=X["button"],transform=xform((1.84,1.3,-1.5),-90),active_time="1.0",prompt_text=S("Descend"))
sc.node("Panel","Label3D",EL,transform=xform((0,2.3,2.84),180),pixel_size="0.004",text=S("LEVEL B - SEALED BY ORDER"),font_size="36",modulate=col(1,0.4,0.25))
sc.node("Lights","Node3D",EL)
sc.node("CarLight","OmniLight3D",EL+"/Lights",transform=xform((0,2.7,0)),light_color=col(1,0.9,0.7),light_energy="0.9",omni_range="5.0")
sc.node("Hum","AudioStreamPlayer3D",EL,transform=xform((0,1.5,0)),stream=ER(HUM),volume_db="-6.0")
sc.node("Snap","AudioStreamPlayer",EL,stream=ER(SNAP),volume_db="2.0")
stinger("ElevatorSting",(38,-7.5,-66),(10,3,8),msg="The elevator. The only way down.")

# ============================================================ ROOM 6: THE LAB WING (longer chapter)
# From the elevator room, a long corridor east to the Specimen Lab. Pull the
# lab's power lever and its monitor shows the Archive door code; one player
# reads it out, another types it on the keypad. The Archive (a maze of
# shelves) holds the ELEVATOR KEY, which the elevator now needs.
GLASS=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.6,0.8,0.7,0.25), transparency="1", roughness="0.05", metallic_specular="1.0"))
GOO=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.15,0.4,0.2,0.55), transparency="1", emission_enabled="true", emission=col(0.1,0.5,0.2), emission_energy_multiplier="0.6"))
for n,c,sz in [("DoorSlotD4",(47,-7.475,-66),(0.6,3.05,2)),("TunnelLab",(55.5,-7.65,-66),(17,2.7,2)),
               ("SpecimenLab",(72,-7,-66),(16,4,16)),("ArchiveSlot",(72,-7.475,-75),(2,3.05,0.6)),
               ("ArchiveHall",(72,-7.65,-79.5),(2,2.7,9)),("Archive",(72,-7,-90),(14,4,12))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
inst("door","LabDoor","Puzzles",(47,-9,-65),90)
label("LabSign",U,(46.1,-6.9,-66),90,"LAB WING  ->\nAUTHORISED STAFF ONLY",size=0.003,font=32,color=(0.85,0.8,0.6))
light("LabHall1","Lights",(51,-6.6,-66),energy=0.35,rng=5,flicker=0.85)
light("LabHall2","Lights",(59,-6.6,-66),energy=0.3,rng=5,flicker=0.95)
for k,x in enumerate([50,54.5,58,61.5]):
    pipe(f"LabPipe{k}",(x,-6.45,-65.2),(x+2.6,-6.45,-65.2)) if k%2==0 else None
# The Specimen Lab: six growth tanks (three with something still inside).
for k,(x,z) in enumerate([(66.5,-60.5),(70,-60.5),(73.5,-60.5),(66.5,-71.5),(70,-71.5),(73.5,-71.5)]):
    sc.node(f"TankBase{k}","CSGCylinder3D",U,transform=xform((x,-8.8,z)),radius="0.75",height="0.4",sides="16",use_collision="true",material=METAL)
    sc.node(f"TankGlass{k}","CSGCylinder3D",U,transform=xform((x,-7.5,z)),radius="0.65",height="2.2",sides="16",use_collision="true",material=GLASS)
    sc.node(f"TankTop{k}","CSGCylinder3D",U,transform=xform((x,-6.25,z)),radius="0.75",height="0.3",sides="16",material=METAL)
    if k in (0,4):
        sc.node(f"TankGoo{k}","CSGCylinder3D",U,transform=xform((x,-7.7,z)),radius="0.6",height="1.8",sides="16",material=GOO)
        mi(f"TankBody{k}",U,(x,-7.5,z),mesh("CapsuleMesh",radius="0.22",height="1.6"),BLACK,shadow=False)
        light(f"TankGlow{k}","Lights",(x,-7.2,z),color=(0.3,1,0.45),energy=0.35,rng=3.5,shadow=False,fixture=None)
    if k == 2:
        label(f"TankCrack{k}",U,(x,-7.4,z+0.67),0,"6",size=0.006,font=48,color=(0.7,0.65,0.5))
for k,(x1,x2,z1,z2) in enumerate([(76,79.4,-63,-62),(76,79.4,-70,-69),(64.6,68,-66.5,-65.5)]):
    BX(f"LabBench{k}",U,x1,x2,-9,-8.1,z1,z2,METAL)
BX("LabDesk",U,78.4,79.6,-9,-8.1,-67,-65,DWOOD)
BX("LabMonitorCase",U,79.3,79.75,-8.1,-7.3,-66.45,-65.55,BLACK)
BX("LabScreen",U,79.25,79.3,-8.0,-7.4,-66.35,-65.65,SCREEN,collide=False)
inst("lfile","SpecimenNotes","Lore",(77.5,-8.1,-62.5),15,entry=ER(LORE("file_specimen_notes")))
item("battery",(65.5,-8.8,-58.8)); item("flare",(78.8,-8.8,-73)); item("walkie",(66,-8.1,-66))
label("LabWallWriting",U,(64.05,-7.4,-63),90,"HE IS NOT GONE\nHE IS IN THE WALLS",size=0.0045,font=40,color=(0.55,0.5,0.45),outline="0")
sc.node("LabLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("LabBright1","Puzzles/LabLights",(68,-5.6,-66),energy=1.0,rng=10)
light("LabBright2","Puzzles/LabLights",(76,-5.6,-66),energy=1.0,rng=10)
light("LabDim","Lights",(72,-5.8,-66),color=(0.9,0.3,0.2),energy=0.25,rng=8,flicker=0.7)
inst("lever","LabPower","Puzzles",(66,-7.7,-58.1),180,one_way="true",prompt_text=S("Pull the lab's power lever"))
gate("LabPowerGate","Puzzles",["../LabPower"],["../LabLights"],msg="The lab lights buzz on. The monitor by the desk wakes up.")
inst("keypad","ArchiveKeypad","Puzzles",(73.6,-7.6,-73.97),0)
sc.node("LabMonitor","Label3D","Puzzles",node_paths=["source","hidden_until"],transform=xform((79.22,-7.7,-66),-90),pixel_size="0.004",
        text=S(""),font_size="40",modulate=col(0.4,1,0.5),outline_size="0",script=ER(S_CODE),source=NP("../ArchiveKeypad"),hidden_until=NP("../LabPower"),
        hidden_text=S("NO POWER"),template=S("ARCHIVE DOOR\nCODE: %s"))
inst("door","ArchiveDoor","Puzzles",(71,-9,-75),0,puzzle_controlled="true")
gate("ArchiveGate","Puzzles",["../ArchiveKeypad"],["../ArchiveDoor"],msg="The Archive door unlocks.")
# The Archive: rows of shelves like a maze, and the elevator key at the back.
for r,(z,gaps) in enumerate([(-86.5,[(70.5,72.5)]),(-89.5,[(66,68),(76,78)]),(-92.5,[(71,73)])]):
    x=65.2; edges=[(a,b) for a,b in gaps]
    segs=[]; cur=65.2
    for a,b in edges:
        segs.append((cur,a)); cur=b
    segs.append((cur,78.8))
    for k,(a,b) in enumerate(segs):
        if b-a > 0.3:
            BX(f"Shelf{r}_{k}",U,a,b,-9,-6.9,z-0.3,z+0.3,DWOOD)
            for j,y in enumerate([-8.4,-7.7,-7.1]):
                BX(f"Files{r}_{k}_{j}",U,a+0.1,b-0.1,y,y+0.3,z-0.25,z+0.25,PAPER,collide=False)
BX("KeyDesk",U,71,73,-9,-8.1,-95.6,-94.6,DWOOD)
item("keycard_red",(72,-8.0,-95.1))
inst("lpersonal","FatherLetter","Lore",(71.4,-8.1,-95),10,entry=ER(LORE("personal_son_father_letter")))
label("Cabinet14",U,(78.9,-7.4,-94),-90,"CABINET 14\nVOLUNTEERS 10-14",size=0.003,font=32,color=(0.8,0.75,0.6))
light("ArchiveLight1","Lights",(68,-6.6,-88),energy=0.3,rng=6,flicker=0.9)
light("ArchiveLight2","Lights",(75,-6.6,-94),energy=0.35,rng=5,flicker=0.6)
stinger("ArchiveSting",(72,-7.5,-84),(4,3,2),msg="Rows and rows of files. Something is breathing between the shelves.")
# The elevator key goes in a slot by the elevator.
inst("fuse","ElevatorKeySlot","Puzzles",(33.5,-7.6,-59.05),180,item_id=S("keycard_red"),insert_time="1.0",engineer_insert_time="1.0",label_text=S("ELEVATOR KEY"))

# ============================================================ THE POWER ROOM (before you meet the Long Man)
# The tunnel is blocked by a security shutter with no power. The Power Room
# (off the junction) needs a yellow keycard; the spare card and the fuel are
# in the yard shed. Fuel the generator, start it, then set the breakers to
# the wiring diagram in the director's office. Power comes back on, and the
# shutter opens the way to the cell...
S_BREAKER=SC("res://scripts/puzzles/breaker_panel.gd"); S_SWITCH=SC("res://scripts/puzzles/breaker_switch.gd")
for n,c,sz in [("PowerDoorSlot",(14.3,-7.475,-42.5),(0.6,3.05,2)),("PowerHall",(15.5,-7.65,-42.5),(2.4,2.7,2)),("PowerRoom",(21,-7,-42),(9,4,10))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
inst("door","PowerRoomDoor","Puzzles",(14.3,-9,-41.5),90)
sc.node("Lock","Node","Puzzles/PowerRoomDoor",script=ER(S_LOCK),keycard_color=S("yellow"))
label("PowerSign",U,(13.97,-6.75,-42.5),-90,"POWER ROOM - YELLOW CARD ONLY",size=0.003,font=32,color=(0.95,0.8,0.3))
label("PowerSpare",U,(13.97,-7.25,-42.5),-90,"spare card + generator fuel:\nYARD SHED",size=0.0028,font=32,color=(0.75,0.7,0.6),outline="0")
item("keycard_yellow",(10.6,0.85,12.0)); item("fuel_can",(9.4,0.25,12.8))
BX("ShedShelf",E,10.2,11.3,0.8,0.85,11.2,12.8,DWOOD)
light("ShedBulb","Lights",(10,2.3,12),color=(1,0.8,0.5),energy=0.5,rng=4,flicker=0.7)
stinger("ShedSting",(10,1.2,12),(2.6,2.4,2.6),msg="Something moves between the trees behind the shed. It's gone when you look.")
# Inside: generator, fuel tank, breaker panel, and the manual.
inst("gen","PowerGenerator","Puzzles",(19,-9,-46.2),0,np=["lamp"],lamp=NP("../PowerGenLamp"))
light("PowerGenLamp","Puzzles",(19,-7,-45.2),color=(1,0.8,0.55),energy=0.8,rng=5)
inst("fuse","FuelTank","Puzzles",(21.2,-7.8,-46.95),0,item_id=S("fuel_can"),insert_time="3.0",engineer_insert_time="2.0",label_text=S("FUEL"))
gate("FuelGate","Puzzles",["../PowerGenerator","../FuelTank"],[],msg="The generator coughs... and starts. Now the breakers.")
sc.node("BreakerPanel","Node3D","Puzzles",node_paths=["powered_by"],transform=xform((25.45,-7.5,-41),-90),script=ER(S_BREAKER),powered_by=NP("../FuelGate"))
for k in range(5):
    sc.node(f"Switch{k+1}","StaticBody3D","Puzzles/BreakerPanel",transform=xform(((k-2)*0.32,0,0)),script=ER(S_SWITCH),number=str(k+1))
BX("BreakerBox",U,25.4,25.5,-8.05,-6.95,-41.9,-40.1,METAL,collide=False)
label("BreakerSign",U,(25.42,-6.75,-41),-90,"MAIN BREAKERS - SET TO THE WIRING DIAGRAM\n(the diagram is in the Director's office)",size=0.0028,font=32,color=(0.9,0.8,0.5))
sc.node("WiringDiagram","Label3D","Puzzles",node_paths=["source"],transform=xform((5,1.9,-6.32),180),pixel_size="0.0032",text=S(""),font_size="36",
        modulate=col(0.3,0.35,0.6),outline_size="0",script=ER(S_CODE),source=NP("../BreakerPanel"),template=S("WIRING DIAGRAM - POWER ROOM BREAKERS\n%s"))
mi("DiagramPaper",St,(5,1.9,-6.31),mesh("BoxMesh",size=v3(2.6,0.7,0.01)),PAPER,shadow=False)
sc.node("PowerRoomLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("PowerBright1","Puzzles/PowerRoomLights",(19,-5.6,-42),energy=1.0,rng=9)
light("PowerBright2","Puzzles/PowerRoomLights",(9,-6.6,-48),energy=0.9,rng=8)
light("PowerEmergency","Lights",(21,-5.8,-38),color=(1,0.1,0.05),energy=0.4,rng=8,pulse=True,shadow=False)
inst("lfile","PowerManual","Lore",(17.4,-8.1,-38),20,entry=ER(LORE("file_power_manual")))
BX("ManualDesk",U,16.9,18.1,-9,-8.1,-38.6,-37.4,DWOOD)
for k,(x,z) in enumerate([(24.5,-37.8),(24.5,-38.8),(17.2,-46.4)]):
    barrel(f"PowerBarrel{k}",NPROP,x,-9,z)
pipe("PowerPipe1",(16.6,-5.5,-37.4),(25.4,-5.5,-37.4),0.12); pipe("PowerPipe2",(16.6,-5.8,-46.6),(25.4,-5.8,-46.6),0.08,BLACK)
# The security shutter blocking the tunnel until the power is back.
sc.node("TunnelShutter","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((9,-9,-50.5)),script=ER(S_MOVER),open_offset=v3(0,2.75,0),move_time="3.0",sound=NP("Sound"))
shsh=sc.sub("BoxShape3D", size=v3(4,2.7,0.3)); shm=sc.sub("BoxMesh", size=v3(4,2.7,0.25))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/TunnelShutter",transform=xform((0,1.35,0)),shape=SR(shsh))
sc.node("Mesh","MeshInstance3D","Puzzles/TunnelShutter",transform=xform((0,1.35,0)),mesh=SR(shm),**{"surface_material_override/0":RUST})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/TunnelShutter",stream=ER(CREAK),pitch_scale="0.5",unit_size="12.0")
label("ShutterSign",U,(9,-7.4,-50.3),0,"SECURITY SHUTTER\nNO POWER - RESTART IN THE POWER ROOM",size=0.0032,font=36,color=(1,0.55,0.3))
gate("PowerRestored","Puzzles",["../FuelGate","../BreakerPanel"],["../PowerRoomLights","../TunnelShutter"],msg="POWER RESTORED. The lights hum on... and the security shutter rumbles open.")

# ============================================================ MORE PUZZLES, SCARES, DETAIL AND STORY
# --- Puzzle: the director's SAFE (the green keycard is inside). Its code is
# scribbled on the break room wall, so someone reads it out.
for n,(x1,x2,y1,y2,z1,z2) in {"SafeBack":(9.75,9.85,0,0.9,-8.7,-7.7),"SafeTop":(9.1,9.85,0.82,0.9,-8.7,-7.7),"SafeBottom":(9.1,9.85,0,0.08,-8.7,-7.7),
                               "SafeSideN":(9.1,9.85,0,0.9,-8.7,-8.62),"SafeSideS":(9.1,9.85,0,0.9,-7.78,-7.7)}.items():
    BX(n,St,x1,x2,y1,y2,z1,z2,METAL)
sc.node("SafeDoor","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((9.1,0,-8.2)),script=ER(S_MOVER),open_offset=v3(0,0,0.9),move_time="0.7",sound=NP("Sound"))
sfsh=sc.sub("BoxShape3D", size=v3(0.06,0.9,1.0)); sfm=sc.sub("BoxMesh", size=v3(0.06,0.9,1.0))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/SafeDoor",transform=xform((0,0.45,0)),shape=SR(sfsh))
sc.node("Mesh","MeshInstance3D","Puzzles/SafeDoor",transform=xform((0,0.45,0)),mesh=SR(sfm),**{"surface_material_override/0":METAL})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/SafeDoor",stream=ER(CREAK),pitch_scale="1.6",unit_size="4.0")
item("keycard_green",(9.45,0.2,-8.2))
inst("keypad","SafeKeypad","Puzzles",(9.83,1.25,-8.2),-90)
gate("SafeGate","Puzzles",["../SafeKeypad"],["../SafeDoor"],msg="Click. The director's safe swings open.")
label("SafeLabel",St,(9.83,1.62,-8.2),-90,"DIRECTOR'S SAFE",size=0.003,font=32,color=(0.8,0.75,0.6))
sc.node("SafeScribble","Label3D","Puzzles",node_paths=["source"],transform=xform((7.6,1.25,-0.17),180),pixel_size="0.0035",text=S(""),font_size="40",
        modulate=col(0.55,0.5,0.45),outline_size="0",script=ER(S_CODE),source=NP("../SafeKeypad"),template=S("dir. safe - %s\n(don't forget AGAIN)"))
# --- Puzzle: the tunnel door code blinks in MORSE CODE from a signal lamp in
# alcove A1. The translation chart hangs in the junction, far away: one
# player watches the blinks, another reads the chart.
inst("keypad","TunnelKeypad","Puzzles",(10.97,-7.6,-65.6),-90)
gate("TunnelGate","Puzzles",["../TunnelKeypad"],["../TunnelDoor"],msg="The tunnel door unlocks.")
inst("signal","SignalLamp","Puzzles",(13.9,-7.3,-60),-90,np=["source"],source=NP("../TunnelKeypad"))
label("SignalSign",U,(13.95,-6.75,-60),-90,"DOOR E-2 CODE (SIGNAL)",size=0.003,font=32,color=(0.85,0.75,0.5))
morse="MORSE CODE\n1  . - - - -     6  - . . . .\n2  . . - - -     7  - - . . .\n3  . . . - -     8  - - - . .\n4  . . . . -     9  - - - - .\n5  . . . . .     0  - - - - -\nshort = .   long = -"
label("MorseChart",U,(13.95,-7.4,-38),-90,morse,size=0.0032,font=36,color=(0.9,0.85,0.7),outline="0")
BX("MorseBoard",U,13.97,14.0,-8.35,-6.45,-39.6,-36.4,DWOOD,collide=False)
label("TunnelDoorSign",U,(10.97,-7.0,-65.6),-90,"DOOR E-2: CODE FROM SIGNAL LAMP",size=0.0028,font=32,color=(0.85,0.7,0.5))
# --- Scares
# A real hole in the break room's east wall, behind the boards, so you can see out.
sc.node("WindowHole","CSGBox3D","Station/EastWall",transform=xform((0,0.1,4)),size=v3(0.8,1.0,1.3),operation="2")
sc.node("WindowFace",None,"Triggers",instance=X["lmodel"],transform=sxform((10.85,-1.0,-4),-90,(2.8,2.8,2.8)))
area("FaceAtWindow","Triggers",(6,1.5,-2.6),(6,3,4),S_SCARE,np=["show_node"],show_node=NP("../WindowFace"),show_time="0.7",sound=ER(STING),
     message=S("...was something looking in the window?"))
area("TunnelBlackout","Triggers",(9,-7.65,-55),(4,2.7,2),S_SCARE,np=["lights"],lights="["+", ".join(NP("../../Lights/"+n) for n in ["TunnelLight1","TunnelLight2","JunctionRed"])+"]",
     dark_time="4.0",sound=ER(A("monster_breath.wav")),sound_volume_db="4.0",message=S("The lights die. Something is breathing in the dark..."))
area("RoofSteps","Triggers",(6,1.5,-11),(7,3,8),S_SCARE,steps_from=v3(3,3.7,-14),steps_to=v3(9,3.7,-8),steps="7",message=S("Heavy footsteps... on the roof?"))
area("LabDoorSlam","Triggers",(52,-7.65,-66),(2,2.7,2),S_SCARE,np=["door"],door=NP("../../Puzzles/LabDoor"),sound=ER(SNAP),message=S("BANG. The door slams shut behind you."))
# --- More story
inst("lfile","WeatherMemo","Lore",(-4.4,0.9,-5),-15,entry=ER(LORE("file_weather_cover")))
inst("lpersonal","TwoSoldiers","Lore",(6.3,0.9,-3.0),30,entry=ER(LORE("personal_son_photo")))
inst("lfile","SecurityLog","Lore",(5.5,-8.4,-37.5),0,entry=ER(LORE("file_security_log")))
BX("SecurityDesk",U,4.6,6.4,-9,-8.4,-38.1,-36.9,METAL)
BX("SecurityMonitor",U,5.2,5.9,-8.4,-7.9,-38.05,-37.7,BLACK)
BX("SecurityScreen",U,5.25,5.85,-8.35,-7.95,-37.7,-37.68,SCREEN,collide=False)
item("reel_tape",(77.6,-8.0,-69.5),"tape_kowalski_warning")
# --- Better looking rooms: the office
for k in range(9):
    x=-9.5+k*2.4
    mi(f"CeilStripX{k}",St,(x,3.18,-8),mesh("BoxMesh",size=v3(0.04,0.02,16)),METAL,shadow=False)
for k in range(7):
    z=-15+k*2.4
    mi(f"CeilStripZ{k}",St,(0,3.18,z),mesh("BoxMesh",size=v3(20,0.02,0.04)),METAL,shadow=False)
POSTER=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.62,0.58,0.45), roughness="1.0"))
for k,(pos,yaw,text) in enumerate([((-9.83,1.8,-6.5),90,"REPORT ALL\nWEATHER ANOMALIES\nTO THE DIRECTOR"),((-1.17,1.8,-13),-90,"LOOSE LIPS\nSINK SHIPS"),
                                     ((9.83,1.9,-12.5),-90,"PROJECT IRONWOOD\nSTRONGER TOGETHER")]):
    mi(f"PosterBack{k}",St,pos,mesh("BoxMesh",size=v3(0.9,1.1,0.01)),POSTER,yaw=yaw,shadow=False)
    dx,dz=((0.01,0) if yaw==90 else (-0.01,0))
    label(f"PosterText{k}",St,(pos[0]+dx,pos[1],pos[2]+dz),yaw,text,size=0.0028,font=32,color=(0.2,0.15,0.1),outline="0")
mi("Clock",St,(-1.15,2.55,-6),mesh("CylinderMesh",top_radius="0.18",bottom_radius="0.18",height="0.04",radial_segments="16",rings="1"),WHITE,yaw=-90,pitch=90,shadow=False)
label("ClockHands",St,(-1.12,2.55,-6),-90,"3:17",size=0.003,font=32,color=(0.1,0.1,0.1),outline="0")
for k,y in enumerate([0.0,0.45]):
    mi(f"Cooler{k}",St,(-9.5,y+0.4,-0.8),mesh("CylinderMesh",top_radius="0.17",bottom_radius="0.2",height="0.8" if k==0 else "0.5",radial_segments="12",rings="1"),WHITE if k==0 else SR(sc.sub("StandardMaterial3D", albedo_color=col(0.5,0.65,0.8,0.5), transparency="1", roughness="0.1")),shadow=False)
for k,(x,z) in enumerate([(-8.6,-15.5),(-8.0,-15.5),(-8.3,-15.5)]):
    crate(f"FileBox{k}",St,x,0.4*(k==2),z,0.4,random.uniform(-10,10))
# --- Better looking rooms: the tunnels (puddles, cables, junction boxes, warning stripes)
WATER=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.05,0.06,0.06,0.75), transparency="1", roughness="0.03", metallic_specular="1.0"))
for k,(x,z,w,d) in enumerate([(8.5,-50,1.8,2.6),(9.6,-58,1.2,1.6),(9,-70.5,2.2,1.4),(20,-68.2,3,1.2),(36,-72,2.5,2),(55,-66,3,1.4),(70,-63,2,2.5)]):
    mi(f"Puddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,yaw=random.uniform(0,40),shadow=False)
for k,(x,z) in enumerate([(7.1,-48),(10.9,-54),(7.1,-63),(10.9,-72)]):
    BX(f"JunctionBox{k}",U,x-0.08 if x<9 else x-0.02,x+0.02 if x<9 else x+0.08,-7.9,-7.4,z-0.25,z+0.25,METAL,collide=False)
    mi(f"DropCable{k}",U,(x,-6.9,z),mesh("CylinderMesh",top_radius="0.015",bottom_radius="0.015",height="1.0",radial_segments="4",rings="1"),BLACK,shadow=False)
STRIPE=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.85,0.7,0.1), roughness="0.8"))
for k,(c,yaw) in enumerate([((11.0,-6.3,-68),90),((30.0,-6.0,-68),90),((47.0,-6.25,-66),90),((72,-6.25,-74.7),0)]):
    for j in range(4):
        off=(j-1.5)*0.45
        pos=(c[0],c[1],c[2]+off) if yaw==90 else (c[0]+off,c[1],c[2])
        mi(f"Stripe{k}_{j}",U,pos,mesh("BoxMesh",size=v3(0.22,0.12,0.03)),STRIPE,yaw=yaw,roll=35,shadow=False)
# --- Better looking rooms: the lab
for k,(x,z) in enumerate([(77.4,-62.2),(77.0,-69.3)]):
    mi(f"Microscope{k}",U,(x,-7.9,z),mesh("CylinderMesh",top_radius="0.03",bottom_radius="0.08",height="0.4",radial_segments="8",rings="1"),BLACK,shadow=False)
for k,z in enumerate([-60.5,-71.5]):
    BX(f"LabTerminal{k}",U,79.5,79.9,-9,-7.4,z-0.4,z+0.4,METAL)
    BX(f"LabTerminalScreen{k}",U,79.47,79.5,-8.0,-7.6,z-0.3,z+0.3,SCREEN,collide=False)
for k,(x,z) in enumerate([(65.5,-68),(78.5,-73)]):
    mi(f"IVPole{k}",U,(x,-8.05,z),mesh("CylinderMesh",top_radius="0.02",bottom_radius="0.02",height="1.9",radial_segments="6",rings="1"),METAL,shadow=False)
    mi(f"IVBag{k}",U,(x+0.08,-7.25,z),mesh("BoxMesh",size=v3(0.04,0.22,0.14)),SR(sc.sub("StandardMaterial3D", albedo_color=col(0.8,0.75,0.6,0.6), transparency="1")),shadow=False)
label("LabChart",U,(64.05,-7.2,-69),90,"GROWTH CHART - SUBJECT 7\nWK 1   6 ft 0\nWK 14  7 ft 11\nWK 31  ???",size=0.0032,font=36,color=(0.85,0.8,0.65))

# ============================================================ CHECKPOINTS, SPAWNS, SYSTEMS
checkpoint("Yard",1,(0,1.5,17),(8,3,4),[(-1.5,0),(0,0),(1.5,0),(0,1.5)])
checkpoint("Tunnels",2,(9,-7.5,-38),(8,3,4),[(-1.5,1),(0,1),(1.5,1),(0,2)])
checkpoint("Shutter",3,(9,-7.5,-52.5),(4,3,2),[(-1,0),(0,0),(1,0),(0,0.8)])
checkpoint("ElevatorApproach",4,(18,-7.5,-68),(4,3,2),[(-1.5,0),(0,0),(1.5,0),(3,0)])
checkpoint("LabWing",5,(55,-7.5,-66),(4,3,2),[(-1.5,0),(0,0),(1.5,0),(3,0)])
sc.node("Items","Node3D",".")
sc.node("ItemSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Items"),script=ER(S_ISPAWN),spawn_points=NP("../ItemSpawnPoints"))
sc.node("Players","Node3D",".")
sc.node("PlayerSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Players"),script=ER(S_PSPAWN),spawn_points=NP("../SpawnPoints"))
sc.node("SpawnPoints","Node3D",".")
for k,(x,z) in enumerate([(-1.5,45),(1.5,45),(-1.5,46.5),(1.5,46.5)]):
    sc.node(f"Spawn{k+1}","Marker3D","SpawnPoints",transform=xform((x,0,z),0))
sc.node("TeamMonitor","Node",".",script=ER(S_TEAM))
sc.write("scenes/chapters/chapter_1/chapter_1.tscn")
print("chapter 1 written,", len(sc.nodes), "nodes")
