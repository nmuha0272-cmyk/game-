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
 locker=P("res://scenes/interactables/hiding_locker.tscn"), plate=P("res://scenes/puzzles/pressure_plate.tscn"),
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
S_DIALOGUE=SC("res://scripts/chapters/opening_dialogue.gd")
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
sc.node("OpeningDialogue","Node",".",script=ER(S_DIALOGUE))
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
# Rain over the outside (it stops at the station's roof).
rain_drop=sc.sub("QuadMesh", material=ER(sc.ext("Material","res://assets/materials/rain.tres")), size="Vector2(0.015, 0.45)")
sc.node("Rain","GPUParticles3D",E,transform=xform((0,24,12)),amount="6000",lifetime="1.4",preprocess="1.4",
        visibility_aabb="AABB(-50, -30, -60, 100, 32, 120)",process_material=ER(sc.ext("ParticleProcessMaterial","res://assets/materials/rain_process.tres")),
        draw_pass_1=SR(rain_drop))
def rain_stop(name,x1,x2,y1,y2,z1,z2):
    sc.node(name,"GPUParticlesCollisionBox3D",E,transform=xform(((x1+x2)/2,(y1+y2)/2,(z1+z2)/2)),size=v3(x2-x1,y2-y1,z2-z1))
# (the station's roof, except the hole over the west office)
rain_stop("RainRoofN",-18.65,12.15,0,12,-22.8,-8.5); rain_stop("RainRoofS",-18.65,12.15,0,12,-6.5,2.4)
rain_stop("RainRoofW",-18.65,-5.5,0,12,-8.5,-6.5); rain_stop("RainRoofE",-3.0,12.15,0,12,-8.5,-6.5)
rain_stop("RainGround",-55,55,-6,0,-50,72)  # (so it never falls into the rooms underground)
# Nasir's gray-box layout for a new building, kept hidden (and not solid) as a draft.
sc.node("NewBuildingDraft","Node3D",E,visible="false")
for n,c,sz,mt in [("StationExterior",(0,0,0),(50,10,30),ROAD),("Gate",(0,0,8),(8,6,2),METAL),("BuildingFootprint",(-20,0,-25),(40,10,35),CONC),
                  ("OfficeComputer",(-5,1,-10),(6,3,1),DWOOD),("OfficeKeypad",(15,1,-10),(4,3,1),DWOOD),("Corkboard",(-15,1,-20),(8,4,1),DWOOD),
                  ("FileDirectory",(10,1,-20),(6,3,1),DWOOD),("Stairwell",(-10,1,-35),(8,6,8),CONC),("TallyMarks",(-15,1.5,-38),(20,1,1),METAL),
                  ("TunnelEntrance",(-20,1,-50),(12,6,8),CONC),("VentCrawl",(-25,1,-60),(4,6,4),CONC),("GoliathArena",(-30,1,-70),(15,8,10),METAL),
                  ("ElevatorShaft",(-35,1,-85),(6,10,6),CONC),("FuseBox1",(-40,1,-80),(3,3,2),METAL),("FuseBox2",(-20,1,-85),(3,3,2),METAL),
                  ("DualKeyConsole",(-50,1,-90),(8,4,2),DWOOD),("ElevatorPanel",(-55,1,-95),(6,3,2),DWOOD),("HeightChart",(-35,2,-75),(2,15,1),DWOOD)]:
    B(n,E+"/NewBuildingDraft",c,sz,mt,collide=False)
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
    if -19.5<x<11.5 and -24<z<1: return True            # the station (and infirmary)
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
# (The old abandoned car outside the gate is gone: the team's car is parked by
# the main building now. Its dome light and the informant's notebook moved to it.)
light("CarDomeLight","Lights",(-5.1,1.75,9.0),color=(1,0.8,0.5),energy=0.15,rng=2.0,flicker=0.5,fixture=None)
inst("lpersonal","InformantNotebook","Lore",(-7.05,1.18,9.0),0,entry=ER(LORE("personal_journalist_notebook")))
item("battery",(-6,0.2,41))
# The team's own car (they drove here in it; the same car as the home screen).
# Parked on the road next to where everyone starts. At the start, Eli and Cole
# take the pistols out of its trunk (scripts/chapters/opening_dialogue.gd
# opens the TrunkLid). Built along its own Z (front at -Z, trunk at +Z),
# turned so the trunk points down the road (+X).
TC_PAINT=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.34,0.1,0.08), roughness="0.4", metallic="0.3"))
TC_TRIM=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.06,0.06,0.06), roughness="0.6"))
TC_CHROME=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.5,0.5,0.5), roughness="0.25", metallic="0.9"))
TC_GLASS=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.35,0.42,0.5,0.25), transparency="1", roughness="0.05"))
TC_SEAT=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.12,0.09,0.07), roughness="0.9"))
TC_HEAD=SR(sc.sub("StandardMaterial3D", albedo_color=col(1,1,0.9), emission_enabled="true", emission=col(1,0.95,0.8), emission_energy_multiplier="3.0"))
TC_TAIL=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.5,0.02,0.02), emission_enabled="true", emission=col(1,0.05,0.03), emission_energy_multiplier="2.0"))
TC="Exterior/TeamCar"
sc.node("TeamCar","StaticBody3D","Exterior",transform=xform((-5.5,0,9.0),90))  # by the main building
sc.node("CollisionShape3D","CollisionShape3D",TC,transform=xform((0,0.95,0.2)),shape=SR(sc.sub("BoxShape3D",size=v3(2.0,1.3,4.8))))
def tbox(name,size,pos,mat,parent=TC,pitch=0):
    mi(name,parent,pos,mesh("BoxMesh",size=v3(*size)),mat,pitch=pitch)
tbox("Body",(2.0,0.45,4.8),(0,0.55,0.2),TC_PAINT)
tbox("Hood",(2.0,0.35,1.5),(0,0.95,-1.55),TC_PAINT)
tbox("Trunk",(2.0,0.3,1.0),(0,0.925,2.1),TC_PAINT)
tbox("DoorL",(0.08,0.38,2.4),(-0.96,0.95,0.4),TC_PAINT); tbox("DoorR",(0.08,0.38,2.4),(0.96,0.95,0.4),TC_PAINT)
tbox("Bumper",(2.04,0.1,4.9),(0,0.3,0.2),TC_CHROME)
tbox("Roof",(1.86,0.06,2.1),(0,1.84,0.5),TC_PAINT)
for k,x in enumerate([-0.93,0.93]):
    tbox(f"PillarA{k}",(0.07,0.78,0.07),(x,1.47,-0.75),TC_TRIM,pitch=28)
    tbox(f"PillarB{k}",(0.07,0.72,0.07),(x,1.48,0.55),TC_TRIM)
    tbox(f"PillarC{k}",(0.07,0.78,0.07),(x,1.47,1.6),TC_TRIM,pitch=-25)
    tbox(f"Side{k}",(0.02,0.66,2.2),(x*1.02,1.47,0.45),TC_GLASS)
tbox("Windshield",(1.8,0.8,0.02),(0,1.47,-0.75),TC_GLASS,pitch=28)
tbox("RearWindow",(1.8,0.78,0.02),(0,1.47,1.63),TC_GLASS,pitch=-25)
tbox("SeatsFront",(1.4,0.6,0.55),(0,1.0,0.2),TC_SEAT); tbox("SeatBack",(1.8,0.75,0.6),(0,1.15,1.15),TC_SEAT)
for k,(x,z) in enumerate([(-0.95,-1.4),(0.95,-1.4),(-0.95,1.7),(0.95,1.7)]):
    mi(f"Wheel{k}",TC,(x,0.38,z),mesh("CylinderMesh",top_radius="0.38",bottom_radius="0.38",height="0.25",radial_segments="14",rings="1"),BLACK,roll=90)
for k,x in enumerate([-0.7,0.7]):
    tbox(f"Headlight{k}",(0.32,0.14,0.04),(x,0.9,-2.31),TC_HEAD)
    tbox(f"Taillight{k}",(0.3,0.1,0.04),(x,0.92,2.61),TC_TAIL)
# The trunk lid swings up around its front edge.
sc.node("TrunkLid","Node3D",TC,transform=xform((0,1.1,1.6)))
tbox("Lid",(2.0,0.05,1.0),(0,0,0.5),TC_PAINT,parent=TC+"/TrunkLid")
# Two pistols in the trunk.
for k,x in enumerate([-0.25,0.25]):
    tbox(f"TrunkPistol{k}",(0.05,0.035,0.2),(x,1.09,2.1),BLACK)
light("TeamCarDome","Lights",(-3.3,1.3,9.0),color=(1,0.85,0.6),energy=0.25,rng=2.5,shadow=False,fixture=None)
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
item("crowbar",(-2.8,0.2,9.8))  # by the trunk, for the jammed front door
item("crowbar",(8,0.2,15.5))   # (the yard one, for the gate)
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
# The roof has fallen in over the west office (HOLE): it's built in four pieces round the gap.
HOLE=(-5.5,-3.0,-8.5,-6.5)  # x1, x2, z1, z2
BX("RoofN",St,-10.3,10.3,H,H+0.3,-16.3,HOLE[2],CONC); BX("RoofS",St,-10.3,10.3,H,H+0.3,HOLE[3],0.3,CONC)
BX("RoofW",St,-10.3,HOLE[0],H,H+0.3,HOLE[2],HOLE[3],CONC); BX("RoofE",St,HOLE[1],10.3,H,H+0.3,HOLE[2],HOLE[3],CONC)
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
sc.node("Lock","Node",f"{St}/FrontDoor",script=ER(S_LOCK),kind="1")  # jammed: pry it with the crowbar from the trunk
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
# The station's own power. The lights start dead: restore the power (the
# terminal in the lobby and the breaker beside it) and the building wakes up.
sc.node("BuildingLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("OfficeLight","Puzzles/BuildingLights",(-5,3.0,-8),energy=0.9,rng=8,flicker=0.3); light("HallLight","Puzzles/BuildingLights",(0.5,3.0,-8),energy=0.6,rng=6,flicker=0.6)
light("DirectorLight","Puzzles/BuildingLights",(6,3.0,-11),energy=0.8,rng=6,flicker=0.15); light("BreakLight","Puzzles/BuildingLights",(6,3.0,-3),energy=0.6,rng=5,flicker=0.8)
sc.node("Buzz","AudioStreamPlayer3D","Sound",transform=xform((0,2.8,-8)),stream=ER(BUZZ),volume_db="-20.0",unit_size="3.0",autoplay="true")

# ------------------------------------------------------------ nobody has touched it in years
# The station is falling apart (a caved-in roof, rubble, ivy, mold, cobwebs,
# dead leaves blown in, water on the floor), but its emergency power still
# runs: exit signs, red emergency lamps, a humming vending machine, sparking
# cables and an old computer that still works. All of it is just for looks
# (no collision) except the fallen roof slab, the vending machine and the cage.
DEC="Station/Decay"; sc.node("Decay","Node3D",St)
def flat(c,a=1.0,rough=1.0,cull=False,metal=0.0,glow=None,glow_e=1.0):
    p=dict(albedo_color=col(*c,a),roughness=str(rough))
    if a<1: p["transparency"]="1"
    if cull: p["cull_mode"]="2"
    if metal: p["metallic"]=str(metal)
    if glow: p.update(emission_enabled="true",emission=col(*glow),emission_energy_multiplier=str(glow_e))
    return SR(sc.sub("StandardMaterial3D",**p))
IVY=flat((0.1,0.24,0.06),cull=True); IVY2=flat((0.17,0.32,0.08),cull=True); WEED=flat((0.22,0.3,0.09),cull=True)
MOLD=flat((0.03,0.05,0.02),0.55); WATERSTAIN=flat((0.12,0.09,0.05),0.4); COBWEB=flat((0.85,0.85,0.82),0.22,cull=True)
LEAF=flat((0.22,0.12,0.04),cull=True); LEAF2=flat((0.3,0.18,0.06),cull=True); DUST=flat((0.35,0.33,0.3),0.35)
PUDDLE=flat((0.02,0.025,0.03),0.85,rough=0.04,metal=0.3); RUBBLE=CONC; TILE=flat((0.62,0.6,0.55))
CRACK=flat((0.02,0.02,0.02),0.8); WIRE=flat((0.03,0.03,0.03)); COPPER=flat((0.55,0.3,0.12),metal=0.8,rough=0.4)
EXITGLOW=flat((0.1,0.9,0.3),glow=(0.15,1,0.35),glow_e=3.0); REDGLOW=flat((1,0.1,0.05),glow=(1,0.12,0.06),glow_e=4.0)
VEND=flat((0.5,0.08,0.06),rough=0.5,metal=0.3); VENDGLASS=flat((0.75,0.8,0.7),glow=(0.6,0.75,0.55),glow_e=0.8)
CRT=flat((0.6,0.57,0.5),rough=0.7); FLOPPY=flat((0.08,0.1,0.25),rough=0.6)
random.seed(77)
def quad(name,pos,w,h,mat,yaw=0,pitch=0,roll=0):
    mi(name,DEC,pos,mesh("QuadMesh",size=f"Vector2({w:g}, {h:g})"),mat,yaw=yaw,pitch=pitch,roll=roll,shadow=False)
def plane(name,pos,w,d,mat,yaw=0):
    mi(name,DEC,pos,mesh("PlaneMesh",size=f"Vector2({w:g}, {d:g})"),mat,yaw=yaw,shadow=False)
def chunk(name,pos,size,yaw=None,pitch=None):
    mi(name,DEC,pos,mesh("BoxMesh",size=v3(*size)),RUBBLE,yaw=random.uniform(0,360) if yaw is None else yaw,
       pitch=random.uniform(-25,25) if pitch is None else pitch,roll=random.uniform(-25,25))
# Lots of small leaves and grass blades are drawn as batches (MultiMesh), like the forest.
BATCH={}
def batch(kind,pos,size,yaw=0,pitch=0,roll=0):
    """One leaf/blade (a 1x1 quad scaled to size=(w,h)), turned yaw/pitch/roll degrees."""
    BATCH.setdefault(kind,[]).append((pos,size,yaw,pitch,roll))
def rot(yaw,pitch,roll):
    cy,sy=math.cos(math.radians(yaw)),math.sin(math.radians(yaw)); cp,sp=math.cos(math.radians(pitch)),math.sin(math.radians(pitch))
    cr,sr=math.cos(math.radians(roll)),math.sin(math.radians(roll))
    Y=[[cy,0,sy],[0,1,0],[-sy,0,cy]]; Xm=[[1,0,0],[0,cp,-sp],[0,sp,cp]]; Z=[[cr,-sr,0],[sr,cr,0],[0,0,1]]
    mul=lambda a,b: [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return mul(mul(Y,Xm),Z)
def emit_batches():
    quad1=mesh("QuadMesh",size="Vector2(1, 1)")
    for kind,mat in (("ivy",IVY),("ivy2",IVY2),("weed",WEED),("leaf",LEAF),("leaf2",LEAF2)):
        items=BATCH.get(kind,[])
        if not items: continue
        buf=[]
        for (x,y,z),(w,h),yw,pt,rl in items:
            m=rot(yw,pt,rl)
            buf+=[m[0][0]*w,m[0][1]*h,m[0][2],x, m[1][0]*w,m[1][1]*h,m[1][2],y, m[2][0]*w,m[2][1]*h,m[2][2],z]
        mm=sc.sub("MultiMesh", transform_format="1", instance_count=str(len(items)), mesh=quad1,
                  buffer="PackedFloat32Array("+", ".join(f"{v:.3f}" for v in buf)+")")
        sc.node("Leaves_"+kind,"MultiMeshInstance3D",DEC,multimesh=SR(mm),material_override=mat,cast_shadow="0")
def tuft(name,x,y,z,size=0.35):
    """A clump of weeds: thin grass blades leaning out."""
    for j in range(random.randint(5,9)):
        batch("weed" if j%3 else "ivy2",(x+random.uniform(-0.08,0.08),y+size*0.45,z+random.uniform(-0.08,0.08)),
              (random.uniform(0.04,0.07),size*random.uniform(0.6,1.0)),yaw=random.uniform(0,180),roll=random.uniform(-25,25))

# The caved-in roof: a broken slab leaning into the office, rubble, rebar, and the rain coming in.
hx,hz=(HOLE[0]+HOLE[1])/2,(HOLE[2]+HOLE[3])/2
B("FallenSlab",DEC,(hx-0.3,1.2,hz+0.3),(2.3,0.22,3.4),CONC,yaw=12,pitch=40)  # one end on the floor, one up at the hole
for k in range(16):
    r=random.uniform(0.15,0.45)
    chunk(f"Rubble{k}",(hx+random.uniform(-1.9,1.9),r*0.35,hz+random.uniform(-1.6,1.6)),(r,r*0.7,r*0.9))
for k in range(5):
    mi(f"Rebar{k}",DEC,(HOLE[0]+0.35*k+0.4,H+0.05,HOLE[2]+0.05),mesh("CylinderMesh",top_radius="0.012",bottom_radius="0.012",height="0.9",radial_segments="5",rings="1"),
       RUST,pitch=random.uniform(55,80),roll=random.uniform(-10,10),shadow=False)
plane("RoofPuddle",(hx+0.4,0.025,hz-0.2),2.6,2.0,PUDDLE,yaw=20)
plane("DrippingPuddle",(-1.5,0.024,-12.5),1.1,0.8,PUDDLE,yaw=-15)
for k in range(5):
    tuft(f"HoleWeed{k}",hx+random.uniform(-1.5,1.5),0.02,hz+random.uniform(-1.3,1.3),random.uniform(0.25,0.5))
# A small tree has grown up under the hole.
mi("SaplingTrunk",DEC,(hx+1.2,0.6,hz-0.9),mesh("CylinderMesh",top_radius="0.025",bottom_radius="0.045",height="1.2",radial_segments="6",rings="1"),BARK,roll=6)
for k in range(5):
    mi(f"SaplingLeaves{k}",DEC,(hx+1.2+random.uniform(-0.3,0.3),1.1+k*0.15,hz-0.9+random.uniform(-0.3,0.3)),
       mesh("SphereMesh",radius="0.3",height="0.4",radial_segments="8",rings="4"),IVY2,shadow=False)
# Moonlight falling through the hole.
sc.node("HoleMoonlight","SpotLight3D",DEC,transform=xform((hx,H+2.5,hz),0,-90),light_color=col(0.55,0.65,0.9),light_energy="2.2",
        spot_range="7.0",spot_angle="28.0",shadow_enabled="true")
sc.node("HoleRainSound","AudioStreamPlayer3D","Sound",transform=xform((hx,1.5,hz)),stream=ER(DRIP),volume_db="-6.0",unit_size="4.0",autoplay="true")

# Ceiling tiles that came down, and some still hanging by a corner.
for k in range(12):
    x=random.uniform(-9,9); z=random.uniform(-15,-0.8)
    if -1.2<x<2.2: continue  # keep the hall clear
    mi(f"FloorTile{k}",DEC,(x,0.03,z),mesh("BoxMesh",size=v3(0.6,0.02,0.6)),TILE,yaw=random.uniform(0,90),pitch=random.uniform(-6,6),shadow=False)
for k,(x,z) in enumerate([(-7.5,-3),(-2.5,-13.5),(4.5,-4.5),(0.5,-6),(7,-12)]):
    mi(f"HangingTile{k}",DEC,(x,H-0.45,z),mesh("BoxMesh",size=v3(0.6,0.02,0.6)),TILE,yaw=random.uniform(0,90),pitch=random.uniform(45,70),shadow=False)
# Cables hanging from the ceiling. Two of them still spark (the power works!).
for k,(x,z,spark) in enumerate([(-7.8,-5.5,False),(0.6,-10.5,True),(4,-2,False),(-2,-14,False),(6.5,-13.8,True)]):
    length=random.uniform(0.9,1.6)
    mi(f"Cable{k}",DEC,(x,H-length/2,z),mesh("CylinderMesh",top_radius="0.012",bottom_radius="0.012",height=f"{length:.2f}",radial_segments="5",rings="1"),
       WIRE,pitch=random.uniform(-12,12),roll=random.uniform(-12,12),shadow=False)
    mi(f"CableEnd{k}",DEC,(x,H-length,z),mesh("CylinderMesh",top_radius="0.016",bottom_radius="0.004",height="0.06",radial_segments="5",rings="1"),COPPER,shadow=False)
    if spark:
        light(f"Spark{k}",DEC,(x,H-length-0.05,z),color=(0.6,0.75,1),energy=1.4,rng=3.0,flicker=0.95,shadow=False,fixture=None)
# Cracks running across the walls.
for k,(x,y,z,yaw,length) in enumerate([(-6,2.2,0.16,0,1.6),(4.5,1.2,0.16,0,1.2),(-9.84,2.0,-7,90,2.0),(9.84,1.6,-13,-90,1.4),
                                       (-3,2.4,-15.84,180,1.8),(-0.84,1.4,-6,90,1.1),(1.84,2.2,-12.5,-90,1.3)]):
    for j in range(3):
        quad(f"Crack{k}_{j}",(x+(j*length/3-length/3 if yaw in (0,180) else 0),y-j*0.25,z+(0 if yaw in (0,180) else j*length/3-length/3)),
             length/3,0.03,CRACK,yaw=yaw,roll=random.uniform(-35,35))
# Mold creeping up from the floor and down from the ceiling, and water stains under the hole.
for k,(x,z,yaw) in enumerate([(-9.84,-14,90),(-9.84,-6,90),(9.84,-3,-90),(-4,-15.84,0),(5,-15.84,0),(-6,-0.16,180),(7,-0.16,180),(-0.84,-11,90)]):
    quad(f"MoldLow{k}",(x,0.4,z),random.uniform(1.0,2.2),0.8,MOLD,yaw=yaw)
    quad(f"MoldHigh{k}",(x+(0.3 if yaw in (0,180) else 0),H-0.35,z),random.uniform(0.8,1.6),0.7,MOLD,yaw=yaw)
for k,(x,z) in enumerate([(HOLE[0]+0.2,HOLE[2]-0.01),(HOLE[1]+0.4,HOLE[3]+0.01)]):
    quad(f"WaterStain{k}",(x,1.9,z),1.4,2.2,WATERSTAIN,yaw=0 if k else 180)
# Cobwebs in the corners.
for k,(x,z,yaw) in enumerate([(-9.6,-15.6,45),(9.6,-15.6,-45),(-9.6,-0.4,135),(9.6,-0.4,-135),(-1.25,-15.6,-45),(1.55,-0.4,45),(2.4,-6.6,45),(9.6,-6.6,-45)]):
    quad(f"Cobweb{k}",(x,H-0.35,z),0.9,0.7,COBWEB,yaw=yaw,pitch=-20)
# Dead leaves blown in under the front door, and dust everywhere.
for k in range(90):
    x=random.uniform(-2.5,3.5); z=random.uniform(-4.5,-0.3) if k<70 else random.uniform(-9,-6)
    batch("leaf" if k%2 else "leaf2",(x if k<70 else random.uniform(-6,-2.5),0.012+k*0.0001,z),(0.09,0.07),yaw=random.uniform(0,360),pitch=-90)
for k,(x,z,w,d) in enumerate([(-6,-12,3,2.5),(5,-12,3,3),(6,-1.5,2.5,1.5),(-7,-2,2,2.5)]):
    plane(f"Dust{k}",(x,0.021,z),w,d,DUST,yaw=random.uniform(0,40))
# A filing cabinet that fell over (the drawers spilled papers).
prop("FallenCabinet",DEC,"cabinet",(-8.2,0.33,-15.3),20,roll=90)
for k in range(6):
    mi(f"SpilledPaper{k}",DEC,(-7.4+random.uniform(-0.6,0.6),0.026,-14.8+random.uniform(-0.6,0.6)),mesh("PlaneMesh",size="Vector2(0.21, 0.29)"),PAPER,yaw=random.uniform(0,360),shadow=False)

# Outside: ivy climbing the walls, weeds along the bottom, a sagging gutter.
def ivy(name,x,z,yaw,height,width):
    """Ivy growing up a wall from the ground: a few woody stems, covered in small leaves."""
    along=(1,0) if yaw in (0,180) else (0,1)
    out=0.03*(1 if yaw==0 else -1 if yaw==180 else (1 if yaw==90 else -1))
    for st in range(3):
        sx=random.uniform(-width/3,width/3); lean=random.uniform(-14,14); h=height*random.uniform(0.7,1.0)
        mi(f"{name}Stem{st}",DEC,(x+along[0]*sx,h/2,z+along[1]*sx),mesh("CylinderMesh",top_radius="0.008",bottom_radius="0.02",height=f"{h:.2f}",radial_segments="4",rings="1"),
           BARK,yaw=yaw,roll=lean,shadow=False)
    for j in range(int(height*width*28)+10):
        y=random.uniform(0.05,height)**1.0; spread=width/2*(1.15-y/height*0.7)
        off=random.uniform(-spread,spread); size=random.uniform(0.1,0.2)
        pos=(x+along[0]*off+(out if yaw in (90,-90) else 0)*0, y, z+along[1]*off)
        pos=(pos[0]+(0 if yaw in (0,180) else out*random.uniform(0.3,1.5)),pos[1],pos[2]+(out*random.uniform(0.3,1.5) if yaw in (0,180) else 0))
        batch("ivy" if j%3 else "ivy2",pos,(size,size*0.9),yaw=yaw+random.uniform(-30,30),pitch=random.uniform(-25,25),roll=random.uniform(0,360))
for k,(x,z,yaw,h,w) in enumerate([(-8.6,0.34,0,3.6,2.4),(-4.6,0.34,0,2.2,1.4),(3.8,0.34,0,3.0,1.6),(8.2,0.34,0,3.8,2.2),
                                    (-10.42,-2,-90,3.4,2.6),(-10.42,-11,-90,3.8,3.0),(10.42,-6.5,90,2.8,2.0),(10.42,-14,90,3.6,2.2)]):
    ivy(f"Ivy{k}",x,z,yaw,h,w)
for k in range(26):
    side=random.choice(["front","west","east"])
    if side=="front": x,z=random.uniform(-10,10),random.uniform(0.45,0.9)
    elif side=="west": x,z=random.uniform(-10.9,-10.45),random.uniform(-16,0)
    else: x,z=random.uniform(10.45,10.9),random.uniform(-16,0)
    if -2<x<3 and side=="front": continue  # (not on the door step)
    tuft(f"BaseWeed{k}",x,0,z,random.uniform(0.25,0.6))
for k in range(18):
    x=random.uniform(-14,14); z=random.uniform(2,20)
    tuft(f"YardWeed{k}",x,0,z,random.uniform(0.2,0.45))
emit_batches()
mi("SaggingGutter",DEC,(-6.5,H+0.05,0.48),mesh("BoxMesh",size=v3(4.0,0.1,0.12)),METAL,roll=-14,shadow=False)

# Emergency power: still on after all these years.
for k,(x,z,yaw) in enumerate([(0.5,-0.2,180),(2.2,-10.0,90),(9,-15.75,0)]):
    mi(f"ExitSign{k}",DEC,(x,2.75,z),mesh("BoxMesh",size=v3(0.5,0.2,0.05)),EXITGLOW,yaw=yaw,shadow=False)
    label(f"ExitText{k}",DEC,(x+(0 if yaw in (0,180) else (0.03 if yaw==90 else -0.03)),2.75,z+(0.03 if yaw==0 else (-0.03 if yaw==180 else 0))),yaw,"EXIT",size=0.004,font=32,color=(0.9,1,0.9),outline="0")
light("ExitGlow",DEC,(0.5,2.6,-0.6),color=(0.2,1,0.4),energy=0.25,rng=3.0,shadow=False,fixture=None)
for k,(x,z,yaw) in enumerate([(-9.8,-9,90),(-0.85,-14.5,90),(9.8,-9,-90),(6,-0.2,180)]):
    mi(f"EmergencyLamp{k}",DEC,(x,2.6,z),mesh("BoxMesh",size=v3(0.35,0.15,0.12)),REDGLOW,yaw=yaw,shadow=False)
    light(f"EmergencyGlow{k}",DEC,(x+(0.3 if x<0 and yaw==90 else (-0.3 if x>0 and yaw==-90 else 0)),2.4,z+(-0.3 if yaw==180 else 0)),
          color=(1,0.15,0.08),energy=0.32,rng=4.5,flicker=0.1,shadow=False,fixture=None)
# The vending machine in the break room hums and glows.
BX("VendingMachine",St,8.6,9.6,0,1.9,-5.9,-5.15,METAL)
mi("VendingFront",DEC,(9.1,0.95,-5.14),mesh("BoxMesh",size=v3(1.0,1.9,0.02)),VEND,shadow=False)
mi("VendingWindow",DEC,(8.95,1.15,-5.12),mesh("BoxMesh",size=v3(0.6,1.1,0.02)),VENDGLASS,shadow=False)
light("VendingGlow",DEC,(9,1.2,-4.7),color=(0.75,0.9,0.7),energy=0.5,rng=3.0,flicker=0.05,shadow=False,fixture=None)
sc.node("VendingHum","AudioStreamPlayer3D","Sound",transform=xform((9,1,-5.3)),stream=ER(BUZZ),volume_db="-14.0",unit_size="2.5",autoplay="true")

# ------------------------------------------------------------ the floppy disk puzzle
# The director left a floppy disk on his desk. The old records computer in
# the office still works: put the disk in and it unlocks the supply cage.
item("floppy_disk",(6.3,0.93,-10.2))
desk("RecordsDesk",-2.9,-1.3,-15.5,-14.7)
BX("RecordsCRT",St,-2.45,-1.75,0.9,1.5,-15.45,-14.95,CRT)
BX("RecordsScreen",St,-2.38,-1.82,1.0,1.42,-14.96,-14.94,SCREEN,collide=False)
inst("clamp","RecordsDrive","Puzzles",(-1.55,1.05,-14.85),0,item_id=S("floppy_disk"),insert_time="1.0",engineer_insert_time="1.0",
     label_text=S("DISK DRIVE"),prompt_text=S("Disk drive"))
sc.node("RecordsText","Label3D","Puzzles",transform=xform((-2.1,1.22,-14.93)),pixel_size="0.0022",text=S("RECORDS v2.1\nINSERT DISK"),
        font_size="32",modulate=col(0.4,1,0.5),outline_size="0")
# The supply cage in the west office's back corner (chain-link, so you can see what's inside).
BX("CageSouth",St,-10,-7,0,H,-13.55,-13.45,FENCE)
BX("CageEastBack",St,-7.05,-6.95,0,H,-16,-15.6,FENCE)
BX("CageTop",St,-10,-7,2.98,3.02,-16,-13.5,FENCE,collide=False)
inst("door","SupplyCage","Puzzles",(-7,0,-13.6),90,puzzle_controlled="true")
gate("RecordsGate","Puzzles",["../RecordsDrive"],["../SupplyCage"],msg="The old computer reads the disk... SUPPLY CAGE: UNLOCKED.")
crate("CageCrate","Station",-9.4,0,-15.4,0.6)
item("battery",(-9.4,0.65,-15.4)); item("medkit",(-8.6,0.2,-15.5)); item("flare",(-8.0,0.2,-15.6)); item("battery",(-9.5,0.2,-14.3))

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
inst("door","ElevatorRoomDoor","Puzzles",(30,-9,-67),90,puzzle_controlled="true")
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
for k,(x,z) in enumerate([(13.1,-43.6),(13.3,-36.6),(12.6,-36.3),(39.7,-76.4),(40.4,-76.5),(30.7,-64.5)]):
    barrel(f"Barrel{k}",NPROP,x,-9,z)
for k,(x,z,sz,yaw) in enumerate([(4.8,-36.3,0.9,10),(31.0,-72.0,1.0,0),(31.1,-73.3,0.7,25),(36,-76.3,0.8,0)]):
    crate(f"Crate{k}",NPROP,x,-9,z,sz,yaw)
# The cell: a bed frame with straps, where Subject 7 was kept.
sc.node("CellBed","CSGBox3D",NPROP,transform=xform((12.6,-8.6,-83.5)),size=v3(1.0,0.12,2.1),use_collision="true",material=METAL)
for k,(dx,dz) in enumerate([(-0.45,-1.0),(0.45,-1.0),(-0.45,1.0),(0.45,1.0)]):
    B(f"CellBedLeg{k}",U,(12.6+dx,-8.8,-83.5+dz),(0.06,0.4,0.06),METAL,collide=False)
for k,dz in enumerate([-0.6,0.1,0.7]):
    mi(f"Strap{k}",U,(12.6,-8.52,-83.5+dz),mesh("BoxMesh",size=v3(1.06,0.03,0.1)),DWOOD,roll=0)
label("CellScratches",U,(13.95,-7.6,-81),-90,"LET ME OUT LET ME OUT\nLET ME OUT LET ME\nIT HURTS TO GROW",size=0.004,font=40,color=(0.5,0.45,0.4),outline="0")

# --- Somewhere to hide. These are the only real hiding spots in the tunnels,
# so a player who breaks line of sight has a chance to catch their breath.
# (TunnelLocker7 used to stand inside the airlock and blocked it.)
for k,spot in enumerate([(7.9,-80,90),(7.9,-56,90),(10.1,-49,-90),
                          (12.4,-59.2,0),(6.4,-66.2,0),(21.6,-69.8,180),
                          (44.3,-70,-90),None,(64.8,-70,90),(78.4,-88,90)]):
    if spot is None: continue
    x,z,yaw=spot
    inst("locker",f"TunnelLocker{k}",U,(x,-9,z),yaw)

# monster
sc.node("PatrolPoints","Node3D","Monsters")
for k,p in enumerate([(9,-9,-82),(9,-9,-72),(9,-9,-56),(5.5,-9,-65),(21,-9,-68),(38,-9,-68),(55,-9,-66),(72,-9,-66),(72,-9,-90),(18,-9,-52),(26,-9,-52)]):
    sc.node(f"Point{k+1}","Marker3D","Monsters/PatrolPoints",transform=xform(p))
# The Long Man and his chase (set to False to switch him off for testing).
LONG_MAN_ON=True
if LONG_MAN_ON:
  sc.node("LongMan",None,"Monsters",instance=X["longman"],node_paths=["patrol_points"],transform=xform((9,-9,-82),180),patrol_points=NP("../PatrolPoints"),start_delay="99999.0")
  inst("mphoto","Photo","Monsters/LongMan",(0,0,0),0)
sc.node("Navigation","NavigationRegion3D",".",navigation_mesh=SR(navmesh),script=ER(S_NAV))

stinger("TunnelsSting",(9,-7.5,-44),(9,3,5),msg="It's cold down here. Something smells like rust and old blood.")
# Cutscenes: the intro over the station, and Subject 7 rising in his cell.
sc.node("Cutscenes","Node",".")
sc.node("Intro","Node","Cutscenes",script=ER(S_CUT),play_on_start="true",shots=shots(
    ((-14,9,62),(0,2,-6),(-6,6.5,50),(0,2,-8),5.0,"1999. Site 12 was sealed... with people still inside."),
    ((-6.5,1.8,27),(-4,1.7,22),(-4.6,1.7,24.6),(-4,1.7,22),3.5,"Officially, it was only ever a weather station."),
    ((7,2.2,15),(-5,3.4,-9),(3,2.8,9),(-5,3.4,-9),4.0,"2015. Seven people are missing. Four are going in."),
    ((0.5,1.7,30),(0,1.4,22),(0.2,1.65,26),(0,1.3,22),2.5,"CHAPTER 1  -  THE SURFACE")))
if LONG_MAN_ON:
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
gate("ConsolesEnabled","Puzzles",["../PowerGate","../OverrideRead","../ElevatorKeySlot","../DormBreakers","../CommsGate"],[])
CONSOLE_NEEDS=S("Dead. It needs power, the override procedure (the Containment Order), the elevator key (in the Archive), the DORM WING's aux power, and the SURFACE RELAY (Comms, north of the Lab).")
inst("console","ConsoleWest","Puzzles",(31.5,-9,-61),90,np=["requires"],requires=NP("../ConsolesEnabled"),requires_message=CONSOLE_NEEDS)
inst("console","ConsoleEast","Puzzles",(44.5,-9,-75.5),-90,np=["requires"],requires=NP("../ConsolesEnabled"),requires_message=CONSOLE_NEEDS)
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
for n,c,sz in [("DoorSlotD4",(46.6,-7.475,-66),(1.4,3.05,2)),("TunnelLab",(55.5,-7.65,-66),(17,2.7,2)),
               ("SpecimenLab",(72,-7,-66),(16,4,16)),("ArchiveSlot",(72,-7.475,-74.65),(2,3.05,1.4)),
               ("ArchiveHall",(72,-7.65,-79.5),(2,2.7,9)),("Archive",(72,-7,-90),(14,4,12))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
inst("door","LabDoor","Puzzles",(47,-9,-65),90,puzzle_controlled="true")
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
# (off the junction) is sealed with a CARD READER: slot the yellow FACILITIES
# keycard to get in. The card sits with the fuel on the stairwell landing, on
# the way down - and the fuel tank is inside the power room, so anyone who
# missed them goes back up for it anyway. Fuel the generator, start it, then
# set the breakers to the wiring diagram on the wall. Power comes back on, and
# the shutter opens the way to the cell...
S_BREAKER=SC("res://scripts/puzzles/breaker_panel.gd"); S_SWITCH=SC("res://scripts/puzzles/breaker_switch.gd")
for n,c,sz in [("PowerDoorSlot",(14.3,-7.475,-42.5),(0.6,3.05,2)),("PowerHall",(15.5,-7.65,-42.5),(2.4,2.7,2)),("PowerRoom",(21,-7,-42),(9,4,10))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
inst("door","PowerRoomDoor","Puzzles",(14.3,-9,-41.5),90,puzzle_controlled="true")
label("PowerSign",U,(13.97,-6.75,-42.5),-90,"POWER ROOM",size=0.003,font=32,color=(0.95,0.8,0.3))
# The card reader: on the junction wall, just north of the door.
inst("fuse","PowerCardReader","Puzzles",(14.03,-7.6,-40.35),-90,item_id=S("keycard_yellow"),
     insert_time="3.0",engineer_insert_time="1.0",label_text=S("FACILITIES CARD"))
label("PowerCardSign",U,(13.97,-6.8,-40.35),-90,"FACILITIES CARD REQUIRED",size=0.0026,font=30,color=(0.95,0.8,0.3))
gate("PowerDoorGate","Puzzles",["../PowerCardReader"],["../PowerRoomDoor"],
     msg="The card reader chirps green... the POWER ROOM door unbolts.")
item("fuel_can",(8.6,-3.8,-25.4))
# The yellow keycard for the reader above, with the fuel on the landing.
item("keycard_yellow",(9.2,-3.9,-24.8))
item("battery",(10.6,0.85,12.0))
BX("ShedShelf",E,10.2,11.3,0.8,0.85,11.2,12.8,DWOOD)
light("ShedBulb","Lights",(10,2.3,12),color=(1,0.8,0.5),energy=0.5,rng=4,flicker=0.7)
stinger("ShedSting",(10,1.2,12),(2.6,2.4,2.6),msg="Something moves between the trees behind the shed. It's gone when you look.")
# Inside: generator, fuel tank, breaker panel, and the manual.
# The generator (it starts by itself once it has fuel: its light and hum come on).
BX("PowerGenBody",NPROP,18.0,20.0,-9,-7.9,-46.9,-45.5,METAL)
BX("PowerGenTop",U,18.3,19.7,-7.9,-7.6,-46.7,-45.7,RUST)
sc.node("GenRunning","Node3D","Puzzles",script=ER(S_LIGHTS))
light("PowerGenLamp","Puzzles/GenRunning",(19,-7,-45.2),color=(1,0.8,0.55),energy=0.8,rng=5)
sc.node("GenHum","AudioStreamPlayer3D","Puzzles/GenRunning",transform=xform((19,-8.4,-46.2)),stream=ER(A("generator_hum.wav")),unit_size="6.0")
inst("fuse","FuelTank","Puzzles",(21.2,-7.8,-46.95),0,item_id=S("fuel_can"),insert_time="3.0",engineer_insert_time="2.0",label_text=S("FUEL"))
gate("FuelGate","Puzzles",["../FuelTank"],["../GenRunning"],msg="The generator coughs... and starts. Now set the breakers to the diagram on the wall.")
sc.node("BreakerPanel","Node3D","Puzzles",node_paths=["powered_by"],transform=xform((25.45,-7.5,-41),-90),script=ER(S_BREAKER),powered_by=NP("../FuelGate"))
for k in range(3):
    sc.node(f"Switch{k+1}","StaticBody3D","Puzzles/BreakerPanel",transform=xform(((k-1)*0.32,0,0)),script=ER(S_SWITCH),number=str(k+1))
BX("BreakerBox",U,25.4,25.5,-8.05,-6.95,-41.9,-40.1,METAL,collide=False)
label("BreakerSign",U,(25.42,-6.75,-41),-90,"MAIN BREAKERS - SET THEM TO THE WIRING DIAGRAM",size=0.0028,font=32,color=(0.9,0.8,0.5))
sc.node("WiringDiagram","Label3D","Puzzles",node_paths=["source"],transform=xform((25.43,-7.55,-43.6),-90),pixel_size="0.0032",text=S(""),font_size="36",
        modulate=col(0.3,0.35,0.6),outline_size="0",script=ER(S_CODE),source=NP("../BreakerPanel"),template=S("WIRING DIAGRAM - POWER ROOM BREAKERS\n%s"))
mi("DiagramPaper",U,(25.44,-7.55,-43.6),mesh("BoxMesh",size=v3(1.7,0.6,0.01)),PAPER,yaw=-90,shadow=False)
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

# ============================================================ THE DARKROOM, THE FLOOD, AND THE VENTS
# 1. DARKROOM (behind the Power Room): once the power is back, develop the
#    last roll of film (the Journalist is fast, anyone else slow). The
#    photo shows the PUMP ROOM door code.
# 2. THE FLOOD: tunnel E is knee-deep in water. Wading is slow and every
#    splash is loud (the Long Man hears it). The elevator room door is held
#    shut by the water. In the pump room, set the 4 valves to the chart...
#    which hangs in the Long Man's empty CELL. Then the water drains.
# 3. THE VENTS: a long crawl-space from alcove A2 around the cell to the pump
#    room. Too small for him: the escape route when he's after you.
S_FLOOD=SC("res://scripts/environment/flood_water.gd")
WATER=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.05,0.06,0.06,0.75), transparency="1", roughness="0.03", metallic_specular="1.0"))
X.update(dark=P("res://scenes/puzzles/darkroom_table.tscn"))
for n,c,sz in [("DarkroomDoorSlot",(21,-7.475,-36),(2,3.05,2.2)),("Darkroom",(21,-7.25,-32.5),(6,3.5,5)),
               ("PumpDoorSlot",(20.5,-7.475,-73.5),(2,3.05,1.0)),("PumpRoom",(20.5,-7,-78),(8,4,8)),
               ("VentEntry",(3.15,-8.375,-66),(1.7,1.25,1.0)),("VentNS",(2.9,-8.375,-77.5),(1.2,1.25,23)),
               ("VentEW",(11.4,-8.375,-88.9),(18,1.25,1.2)),("VentUp",(20.5,-8.375,-85.5),(1.2,1.25,7.2))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
# --- the darkroom
inst("door","DarkroomDoor","Puzzles",(20,-9,-36),0)
label("DarkroomSign",U,(21,-6.75,-37.05),180,"DARKROOM",size=0.003,font=32,color=(1,0.4,0.3))
inst("dark","DarkroomTable","Puzzles",(21,-9,-31),180,np=["requires"],requires=NP("../PowerRestored"),requires_message=S("No power for the safelight. Restore the power first."))
light("Safelight","Lights",(21,-5.9,-32.5),color=(1,0.1,0.05),energy=0.6,rng=6,shadow=False)
BX("PhotoBoard",U,18.03,18.08,-8.2,-6.8,-34,-31,DWOOD,collide=False)
sc.node("PhotoCode","Label3D","Puzzles",node_paths=["source","hidden_until"],transform=xform((18.1,-7.5,-32.5),90),pixel_size="0.0032",text=S(""),font_size="40",
        modulate=col(0.85,0.82,0.75),outline_size="0",script=ER(S_CODE),source=NP("../PumpKeypad"),hidden_until=NP("../DarkroomTable"),
        hidden_text=S("(empty photo board)"),template=S("PHOTO: the pump room door.\nOn the keypad, in marker: %s"))
inst("lpaper","DarkroomNote","Lore",(23.95,-7.6,-32.5),-90,entry=ER(LORE("file_darkroom_note")))
for k,(x,z) in enumerate([(19,-34.5),(23,-34.5)]):
    BX(f"DarkShelf{k}",U,x-0.6,x+0.6,-9,-7.4,z-0.25,z+0.25,DWOOD)
# --- the flood: water in tunnel E and alcove A3 (it sinks away when drained)
sc.node("FloodWater","AnimatableBody3D","Puzzles",transform=xform((0,0,0)),script=ER(S_MOVER),open_offset=v3(0,-0.9,0),move_time="6.0")
for k,(c,size) in enumerate([((21,-8.3,-68),(17.4,2.0)),((20.5,-8.3,-71),(3.0,4.0))]):
    mi(f"Water{k}","Puzzles/FloodWater",c,mesh("PlaneMesh",size=f"Vector2({size[0]}, {size[1]})"),WATER,shadow=False)
p_=area("FloodArea","Triggers",(21,-8.5,-68),(17.4,1.2,2.0),S_FLOOD,np=["drained_by"],drained_by=NP("../../Puzzles/DrainGate"))
fsh=sc.sub("BoxShape3D", size=v3(3.0,1.2,4.0))
sc.node("Alcove","CollisionShape3D",p_,transform=xform((-0.5,0,-3)),shape=SR(fsh))
label("FloodSign",U,(29.97,-7.2,-68),-90,"DOOR HELD SHUT BY WATER PRESSURE\nDRAIN TUNNEL E (PUMP ROOM)",size=0.003,font=32,color=(1,0.6,0.3))
inst("lfile","FloodReport","Lore",(13,-8.4,-61.3),20,entry=ER(LORE("file_flood_report")))
# --- the pump room
inst("keypad","PumpKeypad","Puzzles",(21.97,-7.6,-72),-90)
inst("door","PumpDoor","Puzzles",(19.5,-9,-73.5),0,puzzle_controlled="true")
gate("PumpDoorGate","Puzzles",["../PumpKeypad"],["../PumpDoor"],msg="The pump room door unlocks.")
label("PumpSign",U,(20.5,-6.6,-73.0),0,"PUMP ROOM",size=0.003,font=32,color=(0.85,0.75,0.5))
sc.node("PumpPanel","Node3D","Puzzles",node_paths=["powered_by"],transform=xform((24.45,-7.5,-78),-90),script=ER(S_BREAKER),powered_by=NP("../PowerRestored"))
for k in range(4):
    sc.node(f"Switch{k+1}","StaticBody3D","Puzzles/PumpPanel",transform=xform(((k-1.5)*0.32,0,0)),script=ER(S_SWITCH),number=str(k+1))
BX("PumpBox",U,24.4,24.5,-8.05,-6.95,-78.8,-77.2,METAL,collide=False)
label("PumpPanelSign",U,(24.42,-6.75,-78),-90,"PUMP VALVES - SET TO THE DRAIN CHART\n(the chart is in CELL 7)",size=0.0028,font=32,color=(0.9,0.8,0.5))
for k,(x,z) in enumerate([(18,-80.5),(18,-77),(22.5,-80.8)]):
    sc.node(f"Pump{k}","CSGCylinder3D",U,transform=xform((x,-8.4,z)),radius="0.55",height="1.2",sides="14",use_collision="true",material=METAL)
pipe("PumpPipe",(16.6,-6.2,-81.5),(24.4,-6.2,-81.5),0.14)
light("PumpLight","Lights",(20.5,-5.7,-78),color=(0.8,0.9,1),energy=0.5,rng=7,flicker=0.6)
sc.node("DrainChart","Label3D","Puzzles",node_paths=["source"],transform=xform((9,-7.4,-85.93)),pixel_size="0.0034",text=S(""),font_size="40",
        modulate=col(0.75,0.7,0.6),outline_size="0",script=ER(S_CODE),source=NP("../PumpPanel"),template=S("DRAIN CHART - TUNNEL E PUMPS\n%s"))
gate("DrainGate","Puzzles",["../PumpPanel"],["../FloodWater","../ElevatorRoomDoor"],msg="The pumps roar. The water drains away... and the elevator room door swings open.")
# --- the vents: a long crawl from alcove A2, around the cell, to the pump room
label("VentSign",U,(4.03,-8.1,-66),90,"VENT - CROUCH (C)",size=0.0025,font=32,color=(0.8,0.75,0.6))
inst("lpersonal","VentNote","Lore",(2.9,-8.95,-80),0,entry=ER(LORE("personal_son_vent_note")))
light("VentGlow","Lights",(11,-7.9,-88.9),color=(0.6,0.7,0.6),energy=0.2,rng=4,shadow=False,fixture=None)
area("VentBangs","Triggers",(9,-8.4,-88.9),(2,1.2,1.2),S_SCARE,steps_from=v3(6,-6.3,-86),steps_to=v3(12,-6.3,-86),steps="6",sound=ER(CLANK),
     message=S("Something is pounding on the other side of the vent wall... but it can't get in."))
item("battery",(2.9,-8.9,-72)); item("flare",(16,-8.9,-88.9))

# ============================================================ THE INFIRMARY, THE AIRLOCK, AND THE GAS
# 1. INFIRMARY (a wing on the west side of the office): the medicine
#    cabinet's code is split over the 3 bed tags (one digit each). Inside:
#    2 gas masks and a med kit.
# 2. AIRLOCK (before the Lab Wing): two doors never open at once; press a
#    button and wait out the decontamination cycle.
# 3. GAS (the Lab Wing hall): poison gas. Someone in a gas mask runs through
#    and pulls the ventilation lever at the far end. Then it clears.
S_GAS=SC("res://scripts/environment/toxic_gas.gd"); S_AIRLOCK=SC("res://scripts/puzzles/airlock.gd")
# --- the infirmary wing (x -18..-10, z -12..-2)
sc.node("InfirmaryDoorHole","CSGBox3D","Station/WestWall",transform=xform((0,-0.4,2)),size=v3(0.6,2.4,2.0),operation="2")
for n,(x1,x2,z1,z2) in {"InfN":(-18.3,-10,-12.3,-12),"InfS":(-18.3,-10,-2,-1.7),"InfW":(-18.3,-18,-12.3,-1.7)}.items():
    BX(n,St,x1,x2,0,H,z1,z2,WALL)
BX("InfRoof",St,-18.3,-9.9,H,H+0.3,-12.3,-1.7,CONC)
BX("InfFloor",St,-18,-10,0,0.02,-12,-2,LINO,collide=False)
inst("door","InfirmaryDoor",St,(-10,0,-5),90)
label("InfSign",St,(-9.83,2.55,-6),90,"INFIRMARY",size=0.003,font=32,color=(0.85,0.85,0.75))
label("InfSignOut",St,(-18.33,2.2,-7),-90,"INFIRMARY",size=0.004,font=40,color=(0.7,0.7,0.6))
inst("keypad","MedKeypad","Puzzles",(-17.97,1.4,-9.2),90,code_length="3")
for k,z in enumerate([-10.8,-7.0,-3.2]):
    BX(f"InfBed{k}",St,-12.4,-10.6,0.45,0.6,z-0.5,z+0.5,WHITE)
    BX(f"InfMattress{k}",St,-12.35,-10.65,0.6,0.7,z-0.45,z+0.45,PAPER,collide=False)
    for j,(dx,dz) in enumerate([(-0.85,-0.45),(0.85,-0.45),(-0.85,0.45),(0.85,0.45)]):
        BX(f"InfBedLeg{k}_{j}",St,-11.5+dx-0.03,-11.5+dx+0.03,0,0.45,z+dz-0.03,z+dz+0.03,METAL,collide=False)
    mi(f"Curtain{k}",St,(-13.2,1.2,z),mesh("BoxMesh",size=v3(0.02,2.0,1.6)),SR(sc.sub("StandardMaterial3D", albedo_color=col(0.55,0.62,0.55,0.8), transparency="1", cull_mode="2")),shadow=False)
    sc.node(f"BedTag{k}","Label3D","Puzzles",node_paths=["source"],transform=xform((-10.58,0.9,z),90),pixel_size="0.003",text=S(""),font_size="36",
            modulate=col(0.25,0.2,0.15),outline_size="0",script=ER(S_CODE),source=NP("../MedKeypad"),digit=str(k),template=S(f"BED {k+1}\nTAG: %s"))
# the medicine cabinet (hollow, with a door that slides open)
for n,(x1,x2,y1,y2,z1,z2) in {"MedBack":(-18,-17.9,0,1.9,-11.5,-10.3),"MedTop":(-18,-17.4,1.85,1.9,-11.5,-10.3),"MedBottom":(-18,-17.4,0,0.05,-11.5,-10.3),
                               "MedSideN":(-18,-17.4,0,1.9,-11.5,-11.45),"MedSideS":(-18,-17.4,0,1.9,-10.35,-10.3),"MedShelf":(-17.9,-17.4,0.95,1.0,-11.45,-10.35)}.items():
    BX(n,St,x1,x2,y1,y2,z1,z2,WHITE)
sc.node("MedDoor","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((-17.38,0,-10.9)),script=ER(S_MOVER),open_offset=v3(0,0,1.25),move_time="0.7",sound=NP("Sound"))
mdsh=sc.sub("BoxShape3D", size=v3(0.05,1.9,1.2)); mdm=sc.sub("BoxMesh", size=v3(0.04,1.9,1.2))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/MedDoor",transform=xform((0,0.95,0)),shape=SR(mdsh))
sc.node("Mesh","MeshInstance3D","Puzzles/MedDoor",transform=xform((0,0.95,0)),mesh=SR(mdm),**{"surface_material_override/0":SR(sc.sub("StandardMaterial3D", albedo_color=col(0.7,0.8,0.75,0.5), transparency="1", roughness="0.1"))})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/MedDoor",stream=ER(CREAK),pitch_scale="1.7",unit_size="4.0")
gate("MedGate","Puzzles",["../MedKeypad"],["../MedDoor"],msg="The medicine cabinet unlocks: gas masks!")
label("MedLabel",St,(-17.36,2.05,-10.9),90,"MEDICINE - LOCKED\n(code: the bed tags, 1-2-3)",size=0.0028,font=32,color=(0.75,0.2,0.15))
item("gas_mask",(-17.65,1.05,-11.1)); item("gas_mask",(-17.65,1.05,-10.6)); item("medkit",(-17.65,0.1,-10.9))
inst("lfile","InfirmaryLog","Lore",(-14.5,0.9,-2.6),0,entry=ER(LORE("file_infirmary_log")))
BX("InfDesk",St,-15.4,-13.6,0,0.9,-2.9,-2.2,WOOD)
light("InfLight","Lights",(-14,3.0,-7),color=(0.85,0.95,1),energy=0.6,rng=8,flicker=0.5,fixture="tube")
stinger("InfSting",(-14,1.5,-7),(7,3,9),msg="It smells like old medicine. One of the curtains is moving... no wind in here.")
# --- the airlock (x 47..50 in the Lab Wing corridor)
B("AirlockInnerSlot",R,(50,-7.475,-66),(0.6,3.05,2),ROCK,collide=False,op=2)
inst("door","AirlockInnerDoor","Puzzles",(50,-9,-65),90,puzzle_controlled="true")
for n,pos,yaw in [("AirlockButtonOut",(45.95,-7.7,-64.6),-90),("AirlockButtonIn",(48.5,-7.7,-65.03),180),("AirlockButtonLab",(51.2,-7.7,-65.03),180)]:
    sc.node(n,None,"Puzzles",instance=X["button"],transform=xform(pos,yaw),active_time="1.0",prompt_text=S("Cycle the airlock"))
sc.node("AirlockMist","Node3D","Lights")
sc.node("Fog","FogVolume","Lights/AirlockMist",transform=xform((48.5,-7.65,-66)),size=v3(3,2.7,2),material=SR(sc.sub("FogMaterial", density="1.5", albedo=col(0.8,0.95,0.85))))
sc.node("AirlockHiss","AudioStreamPlayer3D","Sound",transform=xform((48.5,-7,-66)),stream=ER(A("flare_hiss.wav")),unit_size="6.0")
sc.node("Airlock","Node","Puzzles",node_paths=["outer_door","inner_door","buttons","hiss","mist"],script=ER(S_AIRLOCK),outer_door=NP("../LabDoor"),
        inner_door=NP("../AirlockInnerDoor"),buttons="["+", ".join(NP("../"+n) for n in ["AirlockButtonOut","AirlockButtonIn","AirlockButtonLab"])+"]",
        hiss=NP("../../Sound/AirlockHiss"),mist=NP("../../Lights/AirlockMist"))
label("AirlockSign",U,(46.05,-6.7,-66),90,"DECONTAMINATION AIRLOCK\nPRESS THE BUTTON - ONE DOOR AT A TIME",size=0.0028,font=32,color=(0.6,1,0.7))
# --- the gas in the Lab Wing hall, and the fan lever at the far end
sc.node("GasCloud","FogVolume","Lights",transform=xform((57.5,-7.65,-66)),size=v3(11,2.7,2),material=SR(sc.sub("FogMaterial", density="2.5", albedo=col(0.45,0.75,0.2), emission=col(0.05,0.12,0.02))))
area("LabGas","Triggers",(57.5,-7.65,-66),(11,2.7,2),S_GAS,np=["cleared_by","cloud"],cleared_by=NP("../../Puzzles/FanGate"),cloud=NP("../../Lights/GasCloud"),seconds_until_downed="3.5")
inst("lever","FanLever","Puzzles",(63.6,-7.7,-65.05),180,one_way="true",prompt_text=S("Pull the ventilation lever"))
gate("FanGate","Puzzles",["../FanLever"],[],msg="The fans roar to life. The gas clears out of the corridor.")
label("GasSign",U,(51.0,-6.85,-66.99),0,"TOXIC GAS - DO NOT ENTER WITHOUT A MASK\nMasks: station INFIRMARY. Fan lever: far end.",size=0.0028,font=32,color=(1,0.85,0.2))

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
# (the Lab Wing door no longer slams: it is now the airlock's outer door)
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
# Two lockers in the office, in case someone is chased back up the stairwell.
inst("locker","OfficeLocker0",St,(-9.4,0,-14.3),90)
inst("locker","OfficeLocker1",St,(9.4,0,-3.5),-90)
# --- Better looking rooms: the tunnels (puddles, cables, junction boxes, warning stripes)
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

# ============================================================ THE MAINTENANCE BYPASS (longer main tunnel)
# Section 3 of the main tunnel has caved in, so the way south now winds
# through the old maintenance bypass: three turns, failing fluorescent tubes
# with dark stretches between them, pipes, puddles, dripping water, a supply
# room (with a locker to hide in) and a shower room to search. It's all
# carved out of the same rock, so the Long Man's navigation covers it.
for n,c,s in [("BypassN",(14.95,-7.65,-57.6),(8.1,2.7,1.8)),        # east from the tunnel
              ("BypassE",(18.1,-7.65,-61.0),(1.8,2.7,8.6)),         # south
              ("BypassS",(14.95,-7.65,-64.4),(8.1,2.7,1.8)),        # back west to the tunnel
              ("SupplyDoorSlot",(19.3,-7.9,-61.0),(0.8,2.2,1.2)),
              ("SupplyRoom",(21.6,-7.65,-61.0),(4.0,2.7,3.2)),
              ("ShowerDoorSlot",(19.3,-7.9,-57.6),(0.8,2.2,1.2)),
              ("ShowerRoom",(21.4,-7.65,-57.65),(3.6,2.7,1.9))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
# the cave-in itself fills Section 3 of the main tunnel
BX("CaveIn",R,6.9,11.1,-9.1,-6.2,-63.3,-59.2,STONE)
for k,(x,y,z,r) in enumerate([(7.9,-8.6,-58.9,0.55),(9.4,-8.7,-58.8,0.45),(10.4,-8.5,-59.0,0.6),(8.6,-8.0,-59.05,0.5),
                              (8.0,-8.6,-63.55,0.5),(9.8,-8.7,-63.6,0.55),(10.6,-8.3,-63.4,0.45)]):
    mi(f"Rubble{k}",U,(x,y,z),mesh("SphereMesh",radius=f"{r}",height=f"{r*1.6:.2f}",radial_segments="7",rings="4"),STONE,yaw=random.uniform(0,90))
mi("BentBeam",U,(9,-7.2,-58.95),mesh("BoxMesh",size=v3(3.2,0.18,0.18)),RUST,roll=14)
label("CaveInSign",U,(9,-7.0,-58.75),0,"SECTION 3 CLOSED - CAVE-IN\nUSE MAINTENANCE BYPASS  ->",size=0.003,font=32,color=(0.95,0.75,0.2))
label("CaveInSignS",U,(9,-7.0,-63.85),180,"SECTION 3 CLOSED - CAVE-IN\n<-  USE MAINTENANCE BYPASS",size=0.003,font=32,color=(0.95,0.75,0.2))
# failing fluorescent tubes, far apart so there are dark stretches between
for k,(x,z) in enumerate([(13.2,-57.6),(18.1,-60.0),(16.2,-64.4),(21.6,-61.0)]):
    light(f"BypassTube{k}","Lights",(x,-6.5,z),color=(0.82,0.95,0.88),energy=0.55 if k<3 else 0.4,rng=3.6,flicker=[0.75,0.9,0.6,0.5][k],fixture="tube")
# pipes along the walls and ceiling
pipe("BypassPipeN1",(11.1,-6.75,-56.85),(18.9,-6.75,-56.85)); pipe("BypassPipeN2",(11.1,-7.05,-56.88),(18.9,-7.05,-56.88),0.05,BLACK)
pipe("BypassPipeE1",(18.85,-6.75,-64.4),(18.85,-6.75,-56.9)); pipe("BypassPipeE2",(17.3,-6.5,-65.2),(17.3,-6.5,-56.8),0.06)
pipe("BypassPipeS1",(11.1,-6.75,-65.15),(18.9,-6.75,-65.15)); pipe("BypassPipeS2",(11.1,-6.45,-64.4),(18.9,-6.45,-64.4),0.11,RUST)
for k,(x,z,w,d) in enumerate([(15.5,-57.7,1.6,1.2),(18.0,-62.5,1.2,2.2),(13.0,-64.3,1.8,1.1),(21.9,-57.6,1.4,1.0)]):
    mi(f"BypassPuddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,shadow=False)
sc.node("BypassDrips","AudioStreamPlayer3D","Sound",transform=xform((16,-7,-61)),unit_size="5.0",script=ER(S_RAND),
        sounds=f'Array[AudioStream]([{ER(DRIP)}, {ER(DRIP)}, {ER(DRIP)}, {ER(CREAK)}])',area_size=v3(8,1,8),min_delay="1.5",max_delay="4.0")
# supply room: a locker to hide in, shelves, batteries and a note
inst("locker","BypassLocker",U,(23.25,-9,-61.6),-90)
BX("SupplyShelf",NPROP,20.0,22.4,-9,-7.4,-62.55,-62.2,METAL)
for k,x in enumerate([20.4,21.0,21.8]):
    mi(f"SupplyBox{k}",U,(x,-8.05,-62.38),mesh("BoxMesh",size=v3(0.4,0.3,0.28)),DWOOD if k%2 else PAPER,yaw=random.uniform(-10,10))
item("battery",(20.6,-7.25,-62.38)); item("battery",(21.7,-8.85,-60.0))
inst("lfile","BypassScrawl","Lore",(22.0,-7.25,-62.38),0,entry=ER(LORE("file_bypass_scrawl")))
# shower room: a row of rusted shower heads, a drain, the cave-in notice
for k,x in enumerate([20.2,21.4,22.6]):
    pipe(f"ShowerHead{k}",(x,-6.9,-56.82),(x,-7.4,-56.82),0.04)
    mi(f"ShowerDrain{k}",U,(x,-8.99,-57.6),mesh("CylinderMesh",top_radius="0.08",bottom_radius="0.08",height="0.01",radial_segments="8",rings="1"),BLACK,shadow=False)
inst("lfile","CaveInNotice","Lore",(22.6,-8.9,-58.2),30,entry=ER(LORE("file_cavein_notice")))
item("ammo_9mm",(20.4,-8.9,-58.2))
light("ShowerGlow","Lights",(21.4,-6.6,-57.65),color=(0.6,0.8,0.7),energy=0.18,rng=3,flicker=0.95,shadow=False)
# the dripping stops...
area("BypassScare","Triggers",(18.1,-7.65,-61.5),(1.8,2.7,3),S_SCARE,steps_from=v3(15,-8.9,-64.4),steps_to=v3(12,-8.9,-64.4),steps="5",
     sound=ER(CREAK),message=S("The dripping stops."))

# ============================================================ THE ARMORY (deep in the tunnels)
# The old security armory is past the security shutter, at the end of a short
# hall off the maintenance bypass (behind a door). Everyone starts unarmed,
# so this is where the team finds guns and ammo, before the Long Man gets
# loose. (The stairs are just a dark junction now: no ambush there.)
OLIVE=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.22,0.25,0.14), roughness="0.7", metallic="0.3"))
BURLAP=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.42,0.36,0.24), roughness="1.0"))
GUNMETAL=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.06,0.06,0.06), roughness="0.4", metallic="0.8"))
for n,c,s in [("ArmoryHall",(21.7,-7.65,-64.4),(5.4,2.7,1.8)),
              ("ArmoryDoorSlot",(24.4,-7.475,-64.4),(0.6,3.05,2)),
              ("Armory",(27.05,-7.65,-61.6),(4.7,2.7,8.4))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
inst("door","ArmoryDoor","Puzzles",(24.4,-9,-63.4),90)
label("ArmorySign",U,(24.05,-6.55,-64.4),-90,"SECURITY ARMORY\nAUTHORISED PERSONNEL ONLY",size=0.0026,font=32,color=(0.95,0.8,0.3))
label("ArmoryArrow",U,(18.95,-7.2,-62.6),-90,"ARMORY",size=0.003,font=36,color=(0.95,0.8,0.3))
light("ArmoryHallTube","Lights",(22.2,-6.5,-64.4),color=(0.82,0.95,0.88),energy=0.4,rng=3.5,flicker=0.8,fixture="tube")
pipe("ArmoryHallPipe",(19.1,-6.75,-65.15),(24.0,-6.75,-65.15))
# furniture: weapon cabinet, table, gun rack, crates, a barrel
prop("WeaponCabinet",NPROP,"cabinet",(25.05,-9,-58.6),90,collide=("box",(0.6,1.35,0.65),(0,0.675,0)))
BX("ArmoryTable",NPROP,26.0,28.2,-9,-8.25,-62.0,-60.8,METAL)
BX("ArmoryRack",U,29.1,29.38,-9,-6.5,-64.8,-61.6,METAL,collide=False)
crate("ArmCrate0",NPROP,28.7,-9,-58.0,0.7,8); barrel("ArmBarrel0",NPROP,25.3,-9,-65.2)
light("ArmoryLight1","Lights",(27,-6.6,-59.5),color=(1,0.9,0.72),energy=0.9,rng=7,flicker=0.25)
light("ArmoryLight2","Lights",(27,-6.6,-64),color=(1,0.88,0.7),energy=0.7,rng=6,flicker=0.4)
light("ArmoryAlarm","Lights",(25.2,-6.6,-57.9),color=(1,0.1,0.05),energy=0.6,rng=5,pulse=True,shadow=False)
# sandbags along the north end
for k,(x,z) in enumerate([(25.6,-58.1),(26.4,-58.1),(27.2,-58.1),(26.0,-58.12),(26.8,-58.12)]):
    mi(f"Sandbag{k}",NPROP,(x,-8.82 if k<3 else -8.47,z),mesh("CapsuleMesh",radius="0.18",height="0.8",radial_segments="8",rings="2"),BURLAP,roll=90)
BX("SandbagWall",NPROP,25.2,27.6,-9,-8.3,-58.35,-57.85,BURLAP)
# wall rack of display rifles on the west wall
BX("RifleRackW",U,24.75,24.85,-8.3,-7.0,-61.6,-60.1,DWOOD,collide=False)
for k in range(4):
    z=-60.3-k*0.38
    mi(f"RackRifle{k}",U,(24.92,-7.65,z),mesh("BoxMesh",size=v3(0.05,1.05,0.09)),GUNMETAL,roll=6,shadow=False)
    mi(f"RackStock{k}",U,(24.92,-8.12,z),mesh("BoxMesh",size=v3(0.06,0.3,0.12)),DWOOD,shadow=False)
label("RackSign",U,(24.87,-6.85,-60.85),90,"RIFLES - SIGNED OUT",size=0.0025,font=28,color=(0.9,0.85,0.6))
# ammo cans on the table, a stack of ammo crates, a cleaning bench
for k,(x,z) in enumerate([(26.3,-61.7),(26.75,-61.75),(27.9,-61.1)]):
    mi(f"AmmoCan{k}",U,(x,-8.13,z),mesh("BoxMesh",size=v3(0.3,0.24,0.16)),OLIVE,yaw=random.uniform(-15,15))
for k in range(3):
    BX(f"AmmoCrateStack{k}",NPROP,28.5,29.2,-9+k*0.32,-8.7+k*0.32,-59.6,-59.1,OLIVE)
BX("CleanBench",NPROP,26.4,28.6,-9,-8.15,-65.75,-65.25,METAL)
mi("BenchRag",U,(27.0,-8.13,-65.5),mesh("BoxMesh",size=v3(0.3,0.01,0.2)),PAPER,yaw=20,shadow=False)
mi("BenchPistol",U,(27.7,-8.12,-65.5),mesh("BoxMesh",size=v3(0.22,0.04,0.14)),GUNMETAL,yaw=-30,shadow=False)
# paper target on the north wall, a map of Level B on the east wall
mi("TargetPaper",U,(27.9,-7.4,-57.43),mesh("BoxMesh",size=v3(0.6,0.8,0.01)),PAPER,shadow=False)
label("TargetRings",U,(27.9,-7.4,-57.45),180,"(  (  ( O )  )  )\n.  .   .",size=0.004,font=40,color=(0.1,0.1,0.1),outline="0")
mi("MapBoard",U,(29.37,-7.3,-60.2),mesh("BoxMesh",size=v3(0.02,0.9,1.3)),PAPER,shadow=False)
label("MapText",U,(29.35,-7.3,-60.2),-90,"LEVEL B\n[STAIRS]---[TUNNEL]---[CELL]\n     |       |\n [DORM]  [ARMORY]  [ELEVATOR]---[LAB]\n                       |\n                 [OBSERVATION]",size=0.0022,font=28,color=(0.15,0.15,0.4),outline="0")
# a dead security guard, and the sidearm he never got to use
BX("GuardTorso",U,27.4,28.0,-8.72,-8.34,-63.9,-62.8,BLACK,collide=False)
mi("GuardHead",U,(27.7,-8.55,-62.55),mesh("SphereMesh",radius="0.12",height="0.24",radial_segments="10",rings="5"),BLACK,shadow=False)
label("GuardNote",U,(27.7,-8.2,-63.3),0,"GUARD - KIA",size=0.0025,font=28,color=(0.6,0.5,0.45),outline="0")
inst("lfile","ArmorySignout","Lore",(27.4,-8.25,-61.1),-15,entry=ER(LORE("file_armory_signout")))
# the guns and ammo (spread out so several people can arm up)
item("weapon_shotgun",(29.0,-8.75,-64.2)); item("weapon_pistol",(29.0,-8.75,-63.2))
item("weapon_revolver",(29.0,-8.75,-62.3)); item("weapon_suppressed_9mm",(27.0,-8.15,-61.4))
item("ammo_12ga",(26.4,-8.15,-61.1)); item("ammo_9mm",(28.0,-8.15,-61.7))
item("ammo_9mm",(28.9,-8.85,-61.8)); item("ammo_38",(27.4,-8.05,-65.5))
item("ammo_308",(28.0,-8.05,-65.5)); item("medkit",(26.6,-8.05,-65.5))
item("ammo_12ga",(28.8,-7.9,-58.0)); item("flare",(25.9,-8.2,-58.1)); item("battery",(28.85,-7.95,-59.35))

# ============================================================ THE OBSERVATION WING (new co-op puzzle)
# Off the north side of the elevator room: a winding corridor to Observation
# Booth 2 and the Specimen Vault.
# THE PUZZLE (needs 2+ players):
#  - The booth door only stays open while someone stands on the PLATE in the
#    corridor outside (or for a few seconds after the button inside is
#    pressed, so nobody gets locked in).
#  - The vault code is shown ONLY on the booth monitor, and it changes every
#    minute. The keypad is around two corners, by the vault door.
#  So: one player holds the plate, one reads the code in the booth and calls
#  it out (or runs it over), and someone enters it at the vault.
for n,c,s in [("ObsDoorSlot",(44,-7.475,-59.3),(1.8,3.05,1.0)),
              ("ObsHallA",(44,-7.65,-53.6),(1.8,2.7,11.2)),
              ("ObsHallB",(48.55,-7.65,-48.9),(10.9,2.7,1.8)),
              ("ObsHallC",(53.1,-7.65,-44.45),(1.8,2.7,10.7)),
              ("BoothDoorSlot",(48,-7.475,-50.4),(2,3.05,1.2)),
              ("Booth",(48,-7.65,-53),(4,2.7,4)),
              ("VaultAnte",(53.5,-7.65,-38.5),(7,2.7,5)),
              ("VaultDoorSlot",(57.3,-7.475,-38.5),(0.6,3.05,2)),
              ("Vault",(60.3,-7.65,-38.3),(5.4,2.7,5.4))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
label("ObsSign",U,(44,-5.5,-59.05),180,"OBSERVATION WING\nBOOTH 2  /  SPECIMEN VAULT",size=0.003,font=32,color=(0.85,0.85,0.7))
for k,(x,z) in enumerate([(44,-56),(44,-50.5),(50.5,-48.9),(53.1,-45),(53.5,-38.5)]):
    light(f"ObsTube{k}","Lights",(x,-6.5,z),color=(0.85,0.95,0.9),energy=0.5,rng=4.5,flicker=[0.3,0.7,0.5,0.85,0.2][k],fixture="tube")
pipe("ObsPipeA",(44.75,-6.7,-58.8),(44.75,-6.7,-48.2)); pipe("ObsPipeB",(43.3,-6.7,-48.15),(53.8,-6.7,-48.15),0.06,BLACK)
pipe("ObsPipeC",(53.85,-6.6,-49.6),(53.85,-6.6,-40.1),0.08)
for k,(x,z,w,d) in enumerate([(44,-54,1.2,1.6),(51.5,-48.9,1.5,1.2),(53.1,-42.5,1.2,1.4)]):
    mi(f"ObsPuddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,shadow=False)
# the plate, the booth door, and the button inside
inst("plate","BoothPlate","Puzzles",(45.6,-9,-48.9),0,solo_linger="12.0")
label("PlateSign",U,(45.6,-7.0,-48.05),180,"TWO-MAN RULE\nSTAND ON THE PLATE TO HOLD THE BOOTH OPEN",size=0.0026,font=28,color=(0.95,0.8,0.3))
inst("door","BoothDoor","Puzzles",(47,-9,-50.4),0,puzzle_controlled="true")
sc.node("BoothExit",None,"Puzzles",instance=X["button"],transform=xform((49.4,-7.7,-51.03),180),active_time="3.0",prompt_text=S("Open the booth door"))
gate("BoothGate","Puzzles",["../BoothPlate","../BoothExit"],["../BoothDoor"],mode=1,latch=False)
# inside the booth: the monitor with the vault code, a desk, the log, a tape
BX("BoothDesk",NPROP,46.3,49.7,-9,-8.2,-54.9,-54.2,METAL)
mi("BoothMonitor",U,(48,-7.55,-54.5),mesh("BoxMesh",size=v3(0.9,0.6,0.5)),METAL,shadow=False)
mi("BoothScreen",U,(48,-7.55,-54.24),mesh("BoxMesh",size=v3(0.75,0.45,0.01)),SCREEN,shadow=False)
sc.node("VaultCodeScreen","Label3D","Puzzles",node_paths=["source"],transform=xform((48,-7.55,-54.22)),pixel_size="0.0022",text=S(""),font_size="40",
        modulate=col(0.4,1,0.5),outline_size="0",script=ER(S_CODE),source=NP("../VaultKeypad"),template=S("VAULT CODE\n%s\n(changes every minute)"))
inst("lfile","ObservationLog","Lore",(46.9,-8.2,-54.5),15,entry=ER(LORE("file_observation_log")))
inst("tape","TapeMachine3","Puzzles",(49.2,-8.2,-54.55),0)
light("BoothLight","Lights",(48,-6.5,-52.5),color=(0.7,0.9,1),energy=0.45,rng=4,flicker=0.25,fixture="tube")
# the "glass": a dark window looking at nothing... and a hand print on it
mi("BoothWindow",U,(46.03,-7.4,-53),mesh("BoxMesh",size=v3(0.02,0.9,2.2)),BLACK,shadow=False)
label("HandPrint",U,(46.06,-7.3,-53.3),90,"( ' ' ' ' )\n  \\    /",size=0.004,font=40,color=(0.35,0.4,0.35),outline="0")
# the vault antechamber: keypad, benches, the reel tape
inst("keypad","VaultKeypad","Puzzles",(56.97,-7.6,-40.3),-90,rotate_every="60.0")
inst("door","VaultDoor","Puzzles",(57.3,-9,-37.5),90,puzzle_controlled="true")
gate("VaultGate","Puzzles",["../VaultKeypad"],["../VaultDoor","../VaultLights"],msg="The vault door unbolts with a heavy CLUNK.")
label("VaultSign",U,(56.95,-6.7,-38.5),-90,"SPECIMEN VAULT\nCODE FROM BOOTH 2 ONLY",size=0.003,font=32,color=(0.9,0.35,0.3))
BX("AnteBench",NPROP,50.2,52.6,-9,-8.55,-40.7,-40.25,DWOOD)
item("reel_tape",(51.2,-8.45,-40.45),"tape_vault_guard")
light("AnteLight","Lights",(53.5,-6.6,-37),color=(1,0.85,0.6),energy=0.35,rng=5,flicker=0.6)
# the vault: shelves of glowing specimen jars, the manifest, the badge, loot
sc.node("VaultLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("VaultLight","Puzzles/VaultLights",(60.3,-6.6,-38.3),color=(0.6,1,0.7),energy=0.7,rng=7)
JAR=SR(sc.sub("StandardMaterial3D", albedo_color=col(0.4,0.9,0.5,0.55), transparency="1", emission_enabled="true", emission=col(0.15,0.5,0.2), emission_energy_multiplier="1.5"))
for side,z in [("N",-35.95),("S",-40.65)]:
    BX(f"VaultShelf{side}",NPROP,58.2,62.6,-9,-7.0,z-0.25,z+0.25,METAL)
    for k in range(6):
        mi(f"Jar{side}{k}",U,(58.6+k*0.7,-7.55 if k%2 else -8.35,z),mesh("CylinderMesh",top_radius="0.12",bottom_radius="0.12",height="0.32",radial_segments="10",rings="1"),JAR,shadow=False)
inst("lfile","VaultManifest","Lore",(62.4,-8.4,-38.3),-80,entry=ER(LORE("file_vault_manifest")))
BX("VaultTable",NPROP,61.6,62.8,-9,-8.4,-39.0,-37.6,METAL)
inst("lpersonal","InformantBadge","Lore",(62.0,-8.4,-37.9),20,entry=ER(LORE("personal_journalist_badge")))
item("medkit",(59.0,-8.8,-38.3)); item("ammo_9mm",(59.8,-8.8,-37.3)); item("ammo_12ga",(60.6,-8.8,-39.3)); item("battery",(62.2,-8.35,-38.8))
# the Long Man can wander up here too once he's loose
for k,p in enumerate([(44,-9,-54),(50,-9,-48.9),(53.1,-9,-44)]):
    sc.node(f"ObsPoint{k+1}","Marker3D","Monsters/PatrolPoints",transform=xform(p))
area("BoothScare","Triggers",(48,-7.65,-53),(3.6,2.7,3.6),S_SCARE,steps_from=v3(44,-6.3,-53),steps_to=v3(44,-6.3,-57),steps="4",
     sound=ER(A("monster_breath.wav")),message=S("Something taps on the glass. Four times."))

# ============================================================ THE COMMS ROOM (required)
# North of the Specimen Lab. The elevator override must be AUTHORISED by the
# surface relay, so the consoles now also need the relay. Tune the radio to
# the emergency band: the live frequency is only on the chart in the antenna
# room (out of sight of the radio) and it drifts, so one player reads it out
# while another tunes.
X.update(radio=P("res://scenes/puzzles/radio.tscn"))
for n,c,s in [("CommsSlot",(76,-7.475,-58.2),(1.8,3.05,1.0)),
              ("CommsHallN",(76,-7.65,-51.1),(1.8,2.7,14.4)),
              ("CommsHallW",(73.9,-7.65,-50.8),(6.0,2.7,1.8)),
              ("RadioRoom",(67.75,-7.65,-49.5),(6.5,2.7,9.0)),
              ("AntennaRoom",(76.5,-7.65,-40.5),(7.0,2.7,7.0))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
label("CommsSign",U,(76,-5.6,-58.05),180,"COMMUNICATIONS\nSURFACE RELAY",size=0.003,font=32,color=(0.85,0.85,0.7))
for k,(x,z) in enumerate([(76,-55),(76,-46.5),(73,-50.8),(67.75,-49.5),(76.5,-40.5)]):
    light(f"CommsTube{k}","Lights",(x,-6.5,z),color=(0.85,0.95,0.9),energy=0.5,rng=4.5,flicker=[0.6,0.85,0.4,0.3,0.7][k],fixture="tube")
pipe("CommsPipe1",(76.85,-6.7,-57.8),(76.85,-6.7,-44.2)); pipe("CommsPipe2",(71.1,-6.75,-50.0),(75.1,-6.75,-50.0),0.06,BLACK)
for k,(x,z,w,d) in enumerate([(76,-52,1.2,1.8),(68.5,-46,1.6,1.2)]):
    mi(f"CommsPuddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,shadow=False)
# the radio room: the radio on its desk, racks of dead equipment, the log, a tape machine
BX("RadioDesk",NPROP,65.9,69.6,-9,-8.1,-53.95,-53.2,DWOOD)
inst("radio","CommsRadio","Puzzles",(67.75,-8.1,-53.6),0,rotate_every="25.0")
for k,z in enumerate([-51.5,-48.5,-45.5]):
    BX(f"CommsRack{k}",NPROP,64.55,65.3,-9,-6.9,z-1.1,z+1.1,METAL)
    for j in range(5):
        mi(f"RackLamp{k}_{j}",U,(65.32,-7.2-j*0.3,z-0.6+j*0.3),mesh("BoxMesh",size=v3(0.01,0.05,0.05)),SCREEN,shadow=False)
inst("lfile","CommsLog","Lore",(69.1,-8.1,-53.5),-15,entry=ER(LORE("file_comms_log")))
inst("tape","TapeMachine4","Puzzles",(66.3,-8.1,-53.5),0)
item("battery",(70.4,-8.9,-45.0))
sc.node("RelayLights","Node3D","Puzzles",script=ER(S_LIGHTS))
light("RelayLamp","Puzzles/RelayLights",(67.75,-6.7,-53.3),color=(0.3,1,0.4),energy=0.8,rng=5,shadow=False,fixture=None)
gate("CommsGate","Puzzles",["../CommsRadio"],["../RelayLights"],msg="Through the static: \"...Level B, elevator override AUTHORISED.\" The consoles will accept it now.")
# the antenna room: the live frequency chart, the transcript, a reel tape
BX("AntennaMast",NPROP,78.6,79.0,-9,-6.3,-38.6,-38.2,METAL)
for k in range(4):
    mi(f"AntennaRung{k}",U,(78.8,-8.4+k*0.55,-38.4),mesh("BoxMesh",size=v3(0.9,0.04,0.04)),METAL,shadow=False)
mi("ChartPaper",U,(76.0,-7.4,-37.04),mesh("BoxMesh",size=v3(1.8,0.9,0.01)),PAPER,shadow=False)
sc.node("FrequencyChart","Label3D","Puzzles",node_paths=["source"],transform=xform((76.0,-7.4,-37.06),180),pixel_size="0.0035",text=S(""),font_size="40",
        modulate=col(0.2,0.2,0.45),outline_size="0",script=ER(S_CODE),source=NP("../CommsRadio"),template=S("RELAY BAND - LIVE\n%s\n(it drifts: keep calling it out)"))
inst("lpersonal","LastCall","Lore",(74.2,-8.9,-37.6),40,entry=ER(LORE("personal_guard_last_call")))
item("reel_tape",(78.0,-8.85,-43.2),"tape_relay_test"); item("flare",(73.7,-8.9,-43.4))
area("AntennaScare","Triggers",(76.5,-7.65,-41),(6,2.7,5),S_SCARE,steps_from=v3(76,-6.3,-56),steps_to=v3(76,-6.3,-46),steps="5",
     sound=ER(A("monster_breath.wav")),message=S("The radio in the other room crackles... and someone whispers your names."))
sc.node("CommsNeedSign","Label3D",U,transform=xform((31.5,-6.4,-59.05),180),pixel_size="0.0028",text=S("CONSOLES NEED THE SURFACE RELAY\n(COMMS - NORTH OF THE LAB)"),font_size="32",modulate=col(1,0.8,0.4))
checkpoint("Comms",7,(76,-7.5,-55),(1.8,3,2),[(0,-0.6),(0,0.6),(0,-1.2),(0,1.2)])

# ============================================================ THE BOILER ROOM (optional, two valves)
# Off the south wall of the elevator room. Venting the boilers needs BOTH
# relief valves held open at the same time: one by the boilers, one in the
# gauge room down the other corridor. Then the pressure cage opens (loot).
for n,c,s in [("BoilerSlot",(42.5,-7.475,-77.3),(1.8,3.05,1.0)),
              ("BoilerHall1",(42.5,-7.65,-80.5),(1.8,2.7,7.2)),
              ("BoilerHall2",(37.7,-7.65,-84.9),(11.4,2.7,1.8)),
              ("GaugeHall",(32.9,-7.65,-88.9),(1.8,2.7,6.2)),
              ("GaugeRoom",(29.25,-7.65,-91),(5.5,2.7,5)),
              ("BoilerDoorSlot",(41.4,-7.475,-86.3),(1.8,3.05,1.4)),
              ("BoilerRoom",(43,-7,-92),(10,4,10)),
              ("BoilerCage",(46,-7.65,-98.4),(3,2.7,2.8))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
label("BoilerSign",U,(42.5,-5.6,-76.95),0,"BOILER ROOM\nDANGER - HIGH PRESSURE",size=0.003,font=32,color=(1,0.6,0.3))
for k,(x,z) in enumerate([(42.5,-80),(37,-84.9),(32.9,-89),(29.25,-91)]):
    light(f"BoilerTube{k}","Lights",(x,-6.5,z),color=(0.9,0.85,0.7),energy=0.45,rng=4,flicker=[0.7,0.5,0.9,0.4][k],fixture="tube")
light("BoilerGlow","Lights",(43,-6.0,-92),color=(1,0.45,0.2),energy=0.9,rng=9,flicker=0.3)
pipe("BoilerPipeH1",(43.25,-6.7,-77.8),(43.25,-6.7,-84.2)); pipe("BoilerPipeH2",(32.2,-6.7,-84.15),(43.2,-6.7,-84.15),0.12,RUST)
pipe("GaugePipe",(33.65,-6.75,-86),(33.65,-6.75,-91.8),0.06,BLACK)
for k,(x,z,w,d) in enumerate([(42.5,-82,1.2,1.8),(35,-84.9,1.8,1.2),(32.9,-91,1.2,1.4),(44,-89,2,1.6)]):
    mi(f"BoilerPuddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,shadow=False)
# two big boilers with pipes to the ceiling
for k,z in enumerate([-90.3,-94.6]):
    sc.node(f"Boiler{k}","CSGCylinder3D",NPROP,transform=xform((40.4,-7.6,z)),radius="1.15",height="2.8",sides="16",use_collision="true",material=RUST)
    pipe(f"BoilerStack{k}",(40.4,-6.2,z),(40.4,-5.0,z),0.2)
label("BoilerPlateLabel",U,(41.57,-7.6,-94.6),90,"B-2",size=0.004,font=40,color=(0.8,0.7,0.4))
inst("lpersonal","BoilerPlate","Lore",(41.7,-8.9,-93.4),90,entry=ER(LORE("personal_engineer_boiler_plate")))
# steam, hiss and knocking
sc.node("BoilerSteam","FogVolume","Lights",transform=xform((40.4,-7.4,-92.4)),size=v3(3,2.5,7),material=SR(sc.sub("FogMaterial", density="0.6", albedo=col(0.85,0.85,0.85))))
sc.node("BoilerHiss","AudioStreamPlayer3D","Sound",transform=xform((40.4,-7.5,-92.4)),stream=ER(A("flare_hiss.wav")),volume_db="-8.0",unit_size="5.0",autoplay="true")
sc.node("BoilerKnocks","AudioStreamPlayer3D","Sound",transform=xform((43,-7,-92)),unit_size="7.0",script=ER(S_RAND),
        sounds=f'Array[AudioStream]([{ER(CLANK)}, {ER(CLANK)}, {ER(CREAK)}, {ER(DRIP)}])',area_size=v3(9,2,9),min_delay="3.0",max_delay="7.0")
# the two relief valves
inst("hold","ValveBoiler","Puzzles",(38.05,-8.0,-92.4),90,prompt_text=S("Hold the relief valve open"))
inst("hold","ValveGauge","Puzzles",(26.55,-8.0,-91),90,prompt_text=S("Hold the relief valve open"))
label("ValveSignA",U,(38.05,-7.3,-92.4),90,"RELIEF VALVE A\nHOLD WITH VALVE B",size=0.0025,font=28,color=(0.95,0.8,0.3))
label("ValveSignB",U,(26.55,-7.3,-91),90,"RELIEF VALVE B\nHOLD WITH VALVE A",size=0.0025,font=28,color=(0.95,0.8,0.3))
for k in range(3):
    mi(f"Gauge{k}",U,(29.25-1+k,-7.2,-88.53),mesh("CylinderMesh",top_radius="0.16",bottom_radius="0.16",height="0.05",radial_segments="12",rings="1"),WHITE,pitch=90,shadow=False)
label("GaugeText",U,(29.25,-7.75,-88.55),180,"BOILER A    BOILER B    MAIN\n  DANGER      DANGER     DANGER",size=0.0022,font=28,color=(0.8,0.2,0.15),outline="0")
inst("lfile","BoilerLog","Lore",(30.8,-8.9,-92.8),-30,entry=ER(LORE("file_boiler_log")))
# the pressure cage with the loot
sc.node("PressureCage","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((46,-9,-97)),script=ER(S_MOVER),open_offset=v3(0,2.6,0),move_time="2.5",sound=NP("Sound"))
cgsh=sc.sub("BoxShape3D", size=v3(3,2.7,0.12)); cgm=sc.sub("BoxMesh", size=v3(3,2.7,0.05))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/PressureCage",transform=xform((0,1.35,0)),shape=SR(cgsh))
sc.node("Mesh","MeshInstance3D","Puzzles/PressureCage",transform=xform((0,1.35,0)),mesh=SR(cgm),**{"surface_material_override/0":FENCE})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/PressureCage",stream=ER(CREAK),pitch_scale="0.7",unit_size="10.0")
gate("BoilerVent","Puzzles",["../ValveBoiler","../ValveGauge"],["../PressureCage"],msg="Both valves scream... the boilers vent with a roar, and the pressure cage unlocks.")
item("medkit",(45.2,-8.9,-98.8)); item("ammo_12ga",(46.0,-8.9,-99.2)); item("ammo_9mm",(46.8,-8.9,-98.8)); item("battery",(46.4,-8.9,-98.0))
inst("locker","BoilerLocker",U,(47.25,-9,-89),-90)
area("BoilerScare","Triggers",(43,-7.65,-90),(6,2.7,4),S_SCARE,steps_from=v3(44,-5.2,-95),steps_to=v3(42,-5.2,-88),steps="4",
     sound=ER(CLANK),message=S("Four knocks inside the boiler. Then four more."))

# ============================================================ THE MORGUE (optional, find the code)
# Off the east wall of the elevator room. The cold room code is split over
# four toe tags: two in the morgue, one in the hall, one on a body bag in the
# boiler room. Find them all, then enter the code by the cold room door.
for n,c,s in [("MorgueHall",(48.95,-7.65,-72.5),(6.1,2.7,1.8)),
              ("MorgueHallS",(51.1,-7.65,-75.85),(1.8,2.7,8.5)),
              ("Morgue",(55,-7.65,-84),(12,2.7,8)),
              ("ColdDoorSlot",(57,-7.475,-88.5),(2,3.05,1.0)),
              ("ColdRoom",(57,-7.65,-92),(7,2.7,6))]:
    B(n,R,c,s,ROCK,collide=False,op=2)
label("MorgueSign",U,(45.95,-5.6,-72.5),-90,"MORGUE  /  COLD STORAGE",size=0.003,font=32,color=(0.75,0.85,0.9))
for k,(x,z) in enumerate([(48.5,-72.5),(51.1,-77),(52.5,-84),(58,-84),(57,-92)]):
    light(f"MorgueTube{k}","Lights",(x,-6.5,z),color=(0.75,0.9,1),energy=0.45,rng=4.5,flicker=[0.5,0.9,0.3,0.6,0.4][k],fixture="tube")
pipe("MorguePipe",(46.1,-6.7,-71.75),(51.9,-6.7,-71.75),0.06,BLACK); pipe("MorguePipeS",(51.85,-6.7,-72.5),(51.85,-6.7,-79.8))
for k,(x,z,w,d) in enumerate([(51.1,-75,1.2,1.6),(55.5,-86,1.8,1.2)]):
    mi(f"MorguePuddle{k}",U,(x,-8.985,z),mesh("PlaneMesh",size=f"Vector2({w}, {d})"),WATER,shadow=False)
sc.node("ColdKeypad",None,"Puzzles",instance=X["keypad"],transform=xform((58.6,-7.6,-87.97),0))
inst("door","ColdDoor","Puzzles",(56,-9,-88.5),0,puzzle_controlled="true")
gate("ColdGate","Puzzles",["../ColdKeypad"],["../ColdDoor"],msg="The cold room door unseals with a hiss of freezing air.")
label("ColdSign",U,(57,-6.6,-87.95),0,"COLD STORAGE\nCODE: ALL FOUR TOE TAGS, IN ORDER",size=0.0026,font=28,color=(0.75,0.85,0.95))
# the drawer wall and two autopsy tables
BX("DrawerWall",NPROP,60.4,61.0,-9,-6.4,-87.5,-80.5,METAL)
for k in range(9):
    r,c=k//3,k%3
    label(f"DrawerNo{k}",U,(60.38,-7.0-r*0.8,-86.5+c*2.2),-90,str(k+1),size=0.004,font=40,color=(0.8,0.8,0.75))
for k,x in enumerate([53.5,57.0]):
    BX(f"AutopsyTable{k}",NPROP,x-0.5,x+0.5,-9,-8.1,-85.0,-83.0,WHITE)
    BX(f"Sheet{k}",U,x-0.42,x+0.42,-8.1,-7.85,-84.9,-83.2,PAPER,collide=False)
inst("locker","MorgueLocker",U,(49.35,-9,-86),90)
inst("lfile","MorgueLedger","Lore",(57.5,-8.1,-83.0),15,entry=ER(LORE("file_morgue_ledger")))
item("flare",(50.0,-8.9,-81.0))
# the four toe tags (each shows one digit of the cold room code)
TAG=[((53.5,-7.83,-83.15),0,"Puzzles"),((60.36,-7.4,-83.2),-90,"Puzzles"),((50.23,-7.6,-77.5),90,"Puzzles"),((44.6,-8.6,-89.6),0,"Puzzles")]
BX("BodyBag",U,44.0,45.2,-9,-8.75,-90.6,-89.8,BLACK,collide=False)
for k,(pos,yaw,par) in enumerate(TAG):
    sc.node(f"ToeTag{k}","Label3D",par,node_paths=["source"],transform=xform(pos,yaw),pixel_size="0.0022",text=S(""),font_size="32",
            modulate=col(0.3,0.25,0.2),outline_size="0",script=ER(S_CODE),source=NP("../ColdKeypad"),digit=str(k),template=S(f"TOE TAG {k+1} of 4\\n%s"))
    mi(f"TagCard{k}",U,pos,mesh("BoxMesh",size=v3(0.22,0.12,0.005)),PAPER,yaw=yaw,shadow=False)
# the cold room: the bracelet, loot
BX("ColdShelf",NPROP,54.0,60.0,-9,-7.2,-94.9,-94.4,METAL)
for k in range(5):
    mi(f"ColdBox{k}",U,(54.6+k*1.2,-7.9,-94.65),mesh("BoxMesh",size=v3(0.5,0.3,0.35)),WHITE,shadow=False)
inst("lpersonal","Bracelet","Lore",(57,-8.9,-91.5),20,entry=ER(LORE("personal_son_bracelet")))
item("medkit",(55,-8.9,-92.5)); item("battery",(59,-8.9,-92.5)); item("ammo_38",(56.2,-7.1,-94.65)); item("ammo_308",(58.0,-7.1,-94.65))
sc.node("ColdMist","FogVolume","Lights",transform=xform((57,-8.4,-92)),size=v3(6.5,1.2,5.5),material=SR(sc.sub("FogMaterial", density="0.4", albedo=col(0.8,0.9,1))))
area("MorgueScare","Triggers",(55,-7.65,-82),(8,2.7,3),S_SCARE,steps_from=v3(60.5,-7.4,-86.5),steps_to=v3(60.5,-7.4,-81.5),steps="3",
     sound=ER(CLANK),message=S("Somewhere behind you, a drawer slides open by itself."))
# the Long Man can come looking in all three
for k,p in enumerate([(51.1,-9,-76),(55,-9,-84),(43,-9,-90),(37,-9,-84.9),(76,-9,-50),(67.75,-9,-49)]):
    sc.node(f"NewPoint{k+1}","Marker3D","Monsters/PatrolPoints",transform=xform(p))

# ============================================================ CHECKPOINTS, SPAWNS, SYSTEMS
checkpoint("Yard",1,(0,1.5,7.5),(8,3,4),[(-1.5,0),(1.5,0),(-1.5,1.5),(1.5,1.5)])
checkpoint("Tunnels",2,(9,-7.5,-38),(8,3,4),[(-1.5,1),(0,1),(1.5,1),(0,2)])
checkpoint("Shutter",3,(9,-7.5,-52.5),(4,3,2),[(-1,0),(0,0),(1,0),(0,0.8)])
checkpoint("ElevatorApproach",5,(18,-7.5,-68),(4,3,2),[(-1.5,0),(0,0),(1.5,0),(3,0)])
checkpoint("LabWing",6,(65.5,-7.5,-66),(2,3,2),[(-1.5,0),(0,0),(1.5,0),(3,0)])
sc.node("Items","Node3D",".")
sc.node("ItemSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Items"),script=ER(S_ISPAWN),spawn_points=NP("../ItemSpawnPoints"))
sc.node("Players","Node3D",".")
sc.node("PlayerSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Players"),script=ER(S_PSPAWN),spawn_points=NP("../SpawnPoints"))
sc.node("SpawnPoints","Node3D",".")
for k,(x,z) in enumerate([(-1.5,7.5),(1.5,7.5),(-1.5,9),(1.5,9)]):  # by the front door
    sc.node(f"Spawn{k+1}","Marker3D","SpawnPoints",transform=xform((x,0,z),0))
sc.node("TeamMonitor","Node",".",script=ER(S_TEAM))

# Real steps down the hidden stairwell. The carved ramp is still what you walk
# on (so movement and the Long Man's navigation stay smooth); these boxes just
# sit on it so it looks like a proper staircase.
def stairs(name,z_hi,y_hi,z_lo,y_lo,steps=16,width=1.9,thick=0.6):
    for i in range(steps):
        t0=i/float(steps); t1=(i+1)/float(steps)
        z0=z_hi+(z_lo-z_hi)*t0; z1=z_hi+(z_lo-z_hi)*t1
        top=y_hi+(y_lo-y_hi)*t0
        mi(f"{name}Step{i}","Underground",(9,top-thick/2,(z0+z1)/2),
           mesh("BoxMesh",size=v3(width,thick,abs(z1-z0)+0.02)),ROCK)
stairs("StairA",-15.55,0.22,-24.44,-4.22)
stairs("StairB",-26.59,-3.74,-35.41,-9.26)

# ============================================================ ENTRANCE POWER
# Right inside the front door: an old terminal and a breaker. Get the power
# back on and the station's lights (BuildingLights, above) come to life.
X["term"]=P("res://scenes/puzzles/terminal.tscn"); X["brk"]=P("res://scenes/puzzles/breaker.tscn")
inst("term","Terminal","Puzzles",(-0.85,0,-1.2),90)
inst("brk","Breaker","Puzzles",(1.83,1.4,-1.2),-90)
gate("EntrancePower","Puzzles",["../Terminal","../Breaker"],["../BuildingLights"],msg="The building shudders and the lights come on.")

# ============================================================ THE DORM WING (longer chapter)
# A billet wing off the main tunnel (east side, just past the security
# shutter). It has its own aux breaker bank: throw the lever in the back
# room, then set the five breakers to the card pinned in the bunk room. The
# elevator consoles refuse an override while the dorm is dead, so this wing
# is now part of the critical path.
for n,c,sz in [("DormSlot",(12.5,-7.65,-52),(5,2.7,2)),
               ("DormBunks",(18,-7.65,-52),(9,2.7,8)),
               ("DormLink",(23.5,-7.65,-52),(4,2.7,2)),
               ("DormUtility",(26,-7.65,-52),(6,2.7,8))]:
    B(n,R,c,sz,ROCK,collide=False,op=2)
label("DormSign",U,(10.9,-6.9,-55),-90,"DORM WING\nAUX POWER  ->",size=0.003,font=32,color=(0.85,0.8,0.6))
# eight metal bunks, two rows deep, most of them stripped
for k,(x,z) in enumerate([(15.6,-54.6),(15.6,-49.4),(21.0,-54.6),(21.0,-49.4)]):
    BX(f"DormBed{k}",U,x-0.9,x+0.9,-9,-8.4,z-0.95,z+0.95,METAL)
    BX(f"DormBedMat{k}",U,x-0.85,x+0.85,-8.4,-8.3,z-0.85,z+0.85,PAPER,collide=False)
    BX(f"DormBedPost{k}",U,x-0.92,x-0.84,-9,-6.9,z-0.97,z-0.89,METAL,collide=False)
    BX(f"DormBedPost2{k}",U,x+0.84,x+0.92,-9,-6.9,z-0.97,z-0.89,METAL,collide=False)
# One hiding locker in the dorm's utility room. (Two more used to stand in
# the middle of the dorm's narrow passages and blocked the way in.)
inst("locker","DormLocker2",U,(24.2,-9,-55),0)
inst("lfile","DormLog","Lore",(16.5,-8.4,-50.4),0,entry=ER(LORE("file_dorm_log")))
inst("lfile","DormScrawl","Lore",(19.5,-8.4,-53.4),180,entry=ER(LORE("personal_dorm_scrawl")))
item("battery",(20.4,-8.9,-50.0)); item("flare",(24.4,-8.9,-52))
light("DormBunkLight",U,(18,-6.7,-52),energy=0.55,rng=7,flicker=0.55)
# the wiring card (the aux breaker sequence) pinned to the bunk-room wall
sc.node("DormWiring","Label3D","Puzzles",node_paths=["source"],transform=xform((18,-7.4,-48.1),180),pixel_size="0.0032",text=S(""),font_size="36",
        modulate=col(0.3,0.35,0.6),outline_size="0",script=ER(S_CODE),source=NP("../DormBreakers"),template=S("AUX POWER - DORM BREAKERS\n%s"))
mi("DormWiringPaper",U,(18,-7.4,-48.05),mesh("BoxMesh",size=v3(2.6,0.7,0.01)),PAPER,shadow=False)
# the aux power room: the lever that wakes the bank, and the 5 breakers
inst("lever","DormPowerLever","Puzzles",(26,-7.7,-55.9),0,one_way="true",prompt_text=S("Throw the dorm's aux power"))
sc.node("DormBreakers","Node3D","Puzzles",node_paths=["powered_by"],transform=xform((28.95,-7.5,-52),-90),script=ER(S_BREAKER),powered_by=NP("../DormPowerLever"))
for k in range(5):
    sc.node(f"Switch{k+1}","StaticBody3D","Puzzles/DormBreakers",transform=xform(((k-2)*0.32,0,0)),script=ER(S_SWITCH),number=str(k+1))
BX("DormBreakerBox",U,28.9,29.0,-8.05,-6.95,-52.9,-51.1,METAL,collide=False)
label("DormBreakerSign",U,(28.92,-6.8,-52),-90,"DORM AUX BREAKERS\nSET TO THE CARD (BUNK ROOM)",size=0.0028,font=32,color=(0.9,0.8,0.5))
light("DormUtilLight",U,(26,-6.7,-52),energy=0.5,rng=7,flicker=0.35)
sc.node("DormDrone","AudioStreamPlayer3D","Sound",transform=xform((22,-7,-52)),stream=ER(DRONE),volume_db="-12.0",unit_size="14.0",autoplay="true")
area("DormScare","Triggers",(18,-7.65,-52),(9,2.7,8),S_SCARE,steps_from=v3(15,-8.9,-49),steps_to=v3(21,-8.9,-55),steps="6",
     sound=ER(CLANK),message=S("Slow footsteps cross the dorm... but you are the only one down here."))
sc.node("ElevatorAuxSign","Label3D",U,transform=xform((34,-6.6,-59.1),180),pixel_size="0.0028",text=S("CONSOLES NEED AUX POWER\n(DORM WING)"),font_size="32",modulate=col(1,0.8,0.4))
# declared last so its box-shape subresource doesn't renumber the stairs' meshes
checkpoint("Dorm",4,(15,-7.5,-52),(6,3,4),[(-2,0),(0,0),(2,0),(0,1)])

# Why the team came: the "MISSING" poster on the station's front wall (seven
# people, two of them Eli's friends), and the friends' camera on the stairwell
# landing (they got this far).
inst("lpaper","MissingPoster","Lore",(3.85,1.5,0.23),0,entry=ER(LORE("file_missing_seven")))
inst("lpersonal","FriendsCamera","Lore",(9.65,-3.95,-25.7),200,entry=ER(LORE("personal_son_friends_camera")))

# pack upgrades: a pouch out by the informant's car, a backpack on the stairwell landing
item("pouch",(-6.8,0.2,41)); item("backpack",(7.6,-3.8,-24))

sc.write("scenes/chapters/chapter_1/chapter_1.tscn")
print("chapter 1 written,", len(sc.nodes), "nodes")
