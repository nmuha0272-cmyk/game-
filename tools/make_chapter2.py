"""Builds scenes/chapters/chapter_2/chapter_2.tscn (Chapter 2: Level B).
Run from the project folder:  python3 tools/make_chapter2.py
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
S_CUT=SC("res://scripts/chapters/cutscene.gd")
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
X.update(locker=P("res://scenes/interactables/hiding_locker.tscn"), plate=P("res://scenes/puzzles/pressure_plate.tscn"),
         radio=P("res://scenes/puzzles/radio.tscn"))
S_FINAL=SC("res://scripts/chapters/final_chase.gd"); S_ESCAPE=SC("res://scripts/chapters/escape_zone.gd")
ALARM=A("monster_shriek.wav")
env=sc.sub("Environment", background_mode="1", background_color=col(0,0,0), ambient_light_source="2", ambient_light_color=col(0.16,0.18,0.2), ambient_light_energy="0.12",
           tonemap_mode="2", tonemap_exposure="1.25", ssao_enabled="true", glow_enabled="true", glow_intensity="1.0", glow_bloom="0.08", glow_hdr_threshold="0.9", volumetric_fog_enabled="true", volumetric_fog_density="0.03",
           volumetric_fog_albedo=col(0.6,0.65,0.6), volumetric_fog_length="30.0", adjustment_enabled="true", adjustment_contrast="1.15", adjustment_saturation="0.55")
navmesh=sc.sub("NavigationMesh", geometry_parsed_geometry_type="1", geometry_source_geometry_mode="1", geometry_source_group_name='&"chapter2_nav"', agent_height="2.0", agent_radius="0.5", agent_max_climb="0.25", filter_baking_aabb="AABB(-15, -1, -150, 60, 6, 155)")
sc.node("Chapter2","Node3D",script=ER(S_CHAPTER),title=S("CHAPTER 2\nLEVEL B"),flashlight_drain_at_start="true")
sc.node("WorldEnvironment","WorldEnvironment",".",environment=SR(env))
for g in ["Level","Puzzles","Lore","Lights","Sound","Triggers","Checkpoints","ItemSpawnPoints","Monsters"]:
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
        fixture="bulb"
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

U="Level"
def pipe(name,a,b,r=0.09,mat=None):
    """A straight pipe from point a to point b (along X or Z)."""
    (x1,y1,z1),(x2,y2,z2)=a,b
    length=abs(x2-x1)+abs(z2-z1)+abs(y2-y1)
    c=((x1+x2)/2,(y1+y2)/2,(z1+z2)/2)
    yaw,pitch,roll=(0,90,0) if abs(z2-z1)>0 else ((0,0,90) if abs(x2-x1)>0 else (0,0,0))
    mi(name,U,c,mesh("CylinderMesh",top_radius=f"{r}",bottom_radius=f"{r}",height=f"{length:.2f}",radial_segments="10",rings="1"),mat or METAL,yaw,pitch,roll)

# ============================================================ ROCK: everything is carved out of one block
sc.node("Rock","CSGCombiner3D","Level",groups=["chapter2_nav"],use_collision="true")
R="Level/Rock"
B("Mass",R,(15,2,-72),(64,8,158),ROCK)
ROOMS=[
 ("CrashSite",(0,1.75,-4),(12,3.5,12)),
 ("PlateDoorSlot",(0,1.4,-10.3),(2.4,2.8,1.0)),
 ("CorridorC1",(0,1.4,-20),(2.4,2.8,20)),
 ("LockerRoomDoor",(1.6,1.2,-20),(1.0,2.4,1.4)),("LockerRoom",(6,1.5,-20),(8,3,6)),
 ("RadioRoom",(-2,1.75,-35),(12,3.5,10)),
 ("BoothPassage",(4.5,1.2,-33),(1.2,2.4,1.2)),("SignalBooth",(7.5,1.5,-35),(5,3,6)),
 ("CorridorC2",(0,1.4,-46),(2,2.8,12)),("DormDoorSlot",(0,1.525,-52),(2,3.05,0.6)),
 ("DormHall",(0,1.75,-72.15),(4,3.5,39.7)),
 ("TunnelT1",(0,1.4,-102),(2.4,2.8,20)),("TunnelT2",(15,1.4,-112),(32.4,2.8,2.4)),("TunnelT3",(30,1.4,-124),(2.4,2.8,22)),
 ("LiftRoom",(30,1.75,-140),(8,3.5,10)),
]
DORM_Z=[-58,-67,-76,-85]
for zc in DORM_Z:
    for side in (-1,1):
        n="W" if side<0 else "E"
        ROOMS.append((f"Bunk{n}{zc}",(6.05*side,1.5,zc),(6.9,3,7)))
        ROOMS.append((f"BunkDoor{n}{zc}",(2.3*side,1.2,zc+2),(0.8,2.4,1.4)))
for n,c,sz in ROOMS:
    B(n,R,c,sz,ROCK,collide=False,op=2)
sc.node("NavProps","Node3D","Level",groups=["chapter2_nav"])
NP_="Level/NavProps"
L="Level"

# ============================================================ 1. THE CRASH SITE
# The elevator car lies wrecked against the wall. A heavy door only stays
# open while BOTH pressure plates are weighed down: players standing on
# them, or the two car batteries from the wreck.
for k,(c,s,yaw,pitch) in enumerate([((3,0.15,-0.5),(3.8,0.2,5.8),20,8),((4.6,1.4,-0.2),(0.12,2.6,5.6),20,8),((1.4,1.2,-0.9),(0.12,2.2,5.6),20,-6),
                                      ((3,2.5,0.9),(3.6,0.12,4.2),25,22),((2.5,1.4,-3.2),(3.6,2.6,0.1),20,15)]):
    B(f"Wreck{k}",NP_,c,s,METAL,yaw=yaw,pitch=pitch)
for k,x in enumerate([2.2,3.4,4.1]):
    B(f"Cable{k}",L,(x,2.6,-0.5+k*0.4),(0.04,1.8,0.04),BLACK,collide=False,pitch=10*k-10)
label("WreckSign",L,(1.25,1.6,-2.4),70,"LEVEL B\nSEALED BY ORDER",size=0.003,font=32,color=(1,0.4,0.25))
for k,(x,z,s) in enumerate([(-4.6,-8.4,0.7),(-5.2,0.8,0.9),(5,-8.6,0.6)]):
    crate(f"Rubble{k}",NP_,x,0,z,s,random.uniform(0,90))
item("car_battery",(3.4,0.3,0.4)); item("car_battery",(-5,0.2,-1.5)); item("battery",(-4.6,0.9,-8.4))
inst("plate","PlateWest","Puzzles",(-2.6,0,-7.6),0); inst("plate","PlateEast","Puzzles",(2.6,0,-7.6),0)
sc.node("PlateDoor","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((0,0,-10.3)),script=ER(S_MOVER),open_offset=v3(0,2.95,0),move_time="1.2",sound=NP("Sound"))
dsh=sc.sub("BoxShape3D", size=v3(2.4,2.8,0.3)); dmesh=sc.sub("BoxMesh", size=v3(2.4,2.8,0.3))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/PlateDoor",transform=xform((0,1.4,0)),shape=SR(dsh))
sc.node("Mesh","MeshInstance3D","Puzzles/PlateDoor",transform=xform((0,1.4,0)),mesh=SR(dmesh),**{"surface_material_override/0":RUST})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/PlateDoor",stream=ER(CREAK),pitch_scale="0.7",unit_size="6.0")
gate("PlateGate","Puzzles",["../PlateWest","../PlateEast"],["../PlateDoor"],mode=0,latch=False,msg="The heavy door grinds up... it only stays open while BOTH plates are held down.")
label("PlateHint",L,(0,2.3,-9.75),0,"BLAST DOOR B-1\nBOTH PLATES MUST BE WEIGHTED",size=0.003,font=32,color=(0.9,0.75,0.4))
light("CrashBulb1","Lights",(-3,3.2,-4),color=(1,0.8,0.55),energy=0.7,rng=8,flicker=0.6)
light("CrashSpark","Lights",(3,2.6,-1),color=(0.6,0.75,1),energy=0.5,rng=5,flicker=0.95,shadow=False)
stinger("CrashSting",(0,1.5,-5),(10,3,8),msg="The car fell the last few floors. Everyone's alive... somehow. The only way is the heavy door.")

# ============================================================ 2. CORRIDOR + STAFF LOCKER ROOM (learn to hide)
for k,z in enumerate([-21.4,-20.4,-19.4]):
    inst("locker",f"StaffLocker{k}","Puzzles",(9.55,0,z+0.45-0.45),-90)
label("LockerSign",L,(6,2.3,-22.95),0,"STAFF LOCKERS\nIF YOU HEAR IT: HIDE. DON'T LET IT SEE YOU.",size=0.003,font=32,color=(0.85,0.8,0.65))
item("battery",(3,0.2,-18)); item("walkie",(5,0.2,-22))
light("LockerBulb","Lights",(6,2.8,-20),energy=0.4,rng=6,flicker=0.5)
light("C1Bulb","Lights",(0,2.6,-16),energy=0.35,rng=6,flicker=0.8)
light("C1Bulb2","Lights",(0,2.6,-26),energy=0.3,rng=6,flicker=0.4)
stinger("LockerTip",(1.6,1.5,-20),(1.2,3,1.6),msg="Lockers: press E to hide inside, E to get out. It can't see or hear you in there... unless it SAW you get in.")
pipe("C1Pipe",(0.9,2.55,-11),(0.9,2.55,-29))

# ============================================================ 3. THE RADIO ROOM
# Tune the old radio to the emergency frequency. The frequency is on the
# chart in the signal booth next door, and it drifts: one player reads it
# out, another tunes. The broadcast gives the dormitory door code.
BX("RadioDesk",NP_,-5,-1,0,0.9,-39.9,-38.8,DWOOD)
inst("radio","Radio","Puzzles",(-3,0.9,-39.35),0,rotate_every="25.0")
sc.node("RadioChart","Label3D","Puzzles",node_paths=["source"],transform=xform((9.95,1.7,-35),-90),pixel_size="0.004",text=S(""),font_size="40",
        modulate=col(1,0.85,0.4),outline_size="0",script=ER(S_CODE),source=NP("../Radio"),template=S("EMERGENCY FREQUENCY\n%s\n(it drifts: check often)"))
gate("RadioGate","Puzzles",["../Radio"],[],msg="Through the static, a voice: \"...dormitory door code... I repeat...\" Someone chalks the numbers on the wall.")
sc.node("ChalkCode","Label3D","Puzzles",node_paths=["source","hidden_until"],transform=xform((-3,2.1,-39.95)),pixel_size="0.004",text=S(""),font_size="44",
        modulate=col(0.9,0.9,0.85),outline_size="0",script=ER(S_CODE),source=NP("../DormKeypad"),hidden_until=NP("../Radio"),
        hidden_text=S("(only static...)"),template=S("DORMITORY: %s"))
inst("lfile","RadioLog","Lore",(-1.6,0.9,-39.3),-10,entry=ER(LORE("file_radio_log")))
BX("MemoDesk",NP_,-7.9,-6.9,0,0.85,-34,-31.5,DWOOD)
inst("lfile","DirectorMemo","Lore",(-7.4,0.85,-32.6),80,entry=ER(LORE("file_director_memo")))
for k,(x,z) in enumerate([(-7.4,-38.5),(-7.4,-37.4)]):
    prop(f"RadioCabinet{k}",NP_,"cabinet",(x,0,z),90,collide=("box",(0.6,1.35,0.65),(0,0.675,0)))
light("RadioLamp","Lights",(-3,2.9,-37),color=(1,0.85,0.6),energy=0.6,rng=7,flicker=0.25)
light("BoothLamp","Lights",(7.5,2.6,-35),color=(0.8,0.9,1),energy=0.4,rng=5,flicker=0.5)
item("battery",(3.2,0.2,-31)); item("flare",(-7.5,0.2,-30.6))
checkpoint("RadioRoom",1,(0,1.5,-27),(2.4,3,2),[(-0.6,0),(0.6,0),(-0.6,1),(0.6,1)])

# ============================================================ 4. THE DORMITORY (hide and seek)
# The Long Man drops in when you enter. Find 3 FUSES in the bunk rooms while
# he hunts you, and put them in the fuse boxes by the blast door. Hide in
# the lockers when he comes.
inst("keypad","DormKeypad","Puzzles",(0.97,1.4,-50.5),-90)
inst("door","DormDoor","Puzzles",(-1,0,-52),0,puzzle_controlled="true")
gate("DormGate","Puzzles",["../DormKeypad"],["../DormDoor"],msg="The dormitory door unlocks. It's very quiet in there.")
label("DormSign",L,(0,2.75,-51.65),0,"DORMITORY - PHASE TWO VOLUNTEERS",size=0.003,font=32,color=(0.85,0.8,0.6))
BX("GuardDesk",NP_,1.0,1.95,0,0.9,-55.6,-54.4,METAL)
inst("lpersonal","GuardLogbook","Lore",(1.45,0.9,-55),-90,entry=ER(LORE("personal_guard_logbook")))
for i,zc in enumerate(DORM_Z):
    for side in (-1,1):
        n=("W" if side<0 else "E")+str(i+1)
        back=9.45*side
        # two bunk beds against the back wall
        for j,dz in enumerate([-1.6,1.4]):
            x1,x2=sorted([back-0.05*side, back-1.05*side])
            for y in (0.45,1.55):
                BX(f"Bed{n}_{j}_{y}",NP_,x1,x2,y,y+0.12,zc+dz-1.0,zc+dz+1.0,RUST)
                BX(f"Mattress{n}_{j}_{y}",L,x1+0.05,x2-0.05,y+0.12,y+0.25,zc+dz-0.95,zc+dz+0.95,PAPER,collide=False)
            for k,(lx,lz) in enumerate([(x1+0.05,zc+dz-0.95),(x2-0.05,zc+dz-0.95),(x1+0.05,zc+dz+0.95),(x2-0.05,zc+dz+0.95)]):
                BX(f"BedLeg{n}_{j}_{k}",L,lx-0.03,lx+0.03,0,1.7,lz-0.03,lz+0.03,RUST,collide=False)
        # a locker by the door wall
        inst("locker",f"Locker{n}","Puzzles",(3.25*side,0,zc-2.9),0)
        label(f"RoomNo{n}",L,(2.05*side,2.5,zc+2),90 if side<0 else -90,f"ROOM {n}",size=0.003,font=32,color=(0.7,0.65,0.55))
        light(f"RoomBulb{n}","Lights",(6*side,2.6,zc),color=(1,0.75,0.5),energy=0.25,rng=5,flicker=0.7 if (i+side)%2 else 0.95)
label("Bunk14",L,(9.4,2.0,-67+1.4),-90,"BUNK 14",size=0.003,font=32,color=(0.85,0.8,0.6))
inst("lpersonal","DogTag","Lore",(8.9,0.6,-67+1.4),-90,entry=ER(LORE("personal_son_dogtag")))
inst("lfile","IntakeLog","Lore",(-8.9,0.6,-58-1.6),90,entry=ER(LORE("file_levelb_intake")))
item("fuse",(-8.9,1.8,-67-1.6)); item("fuse",(8.0,0.2,-76+3.0)); item("fuse",(-4,0.2,-85-2.6))
item("battery",(8.9,0.6,-58+1.4)); item("flare",(-8.9,0.6,-76+1.4)); item("medkit",(7.5,0.2,-85-2.5))
for k,z in enumerate([-62.5,-71.5,-80.5]):
    inst("locker",f"HallLockerW{k}","Puzzles",(-1.6,0,z),90)
    inst("locker",f"HallLockerE{k}","Puzzles",(1.6,0,z),-90)
for k,z in enumerate([-56,-66,-76,-86]):
    light(f"HallRed{k}","Lights",(0,3.2,z),color=(1,0.12,0.06),energy=0.5,rng=7,pulse=True,shadow=False)
label("HallWriting",L,(-1.98,1.5,-75.5),90,"IT CHECKS THE LOCKERS\nIF IT SEES YOU GET IN",size=0.004,font=40,color=(0.55,0.08,0.06),outline="0")
# The blast door and its three fuse boxes.
sc.node("BlastDoor","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((0,0,-92.15)),script=ER(S_MOVER),open_offset=v3(0,3.6,0),move_time="3.0",sound=NP("Sound"))
bsh=sc.sub("BoxShape3D", size=v3(4,3.5,0.4)); bmesh=sc.sub("BoxMesh", size=v3(4,3.5,0.4))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/BlastDoor",transform=xform((0,1.75,0)),shape=SR(bsh))
sc.node("Mesh","MeshInstance3D","Puzzles/BlastDoor",transform=xform((0,1.75,0)),mesh=SR(bmesh),**{"surface_material_override/0":RUST})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/BlastDoor",stream=ER(CREAK),pitch_scale="0.5",unit_size="10.0")
label("BlastSign",L,(0,2.9,-91.9),0,"BLAST DOOR B-2\nPOWER: 3 FUSES",size=0.004,font=36,color=(1,0.5,0.3))
inst("fuse","BlastFuseA","Puzzles",(-1.95,1.3,-88.6),90); inst("fuse","BlastFuseB","Puzzles",(-1.95,1.3,-90.6),90)
inst("fuse","BlastFuseC","Puzzles",(1.95,1.3,-89.6),-90)
gate("BlastGate","Puzzles",["../BlastFuseA","../BlastFuseB","../BlastFuseC"],["../BlastDoor"],msg="The blast door grinds open... and every alarm in Level B goes off.")
checkpoint("Dormitory",2,(0,1.5,-54.5),(3.5,3,2),[(-1,0),(0,0),(1,0),(0,0.8)])

# ============================================================ 5. THE FINAL CHASE
# A long tunnel to the escape lift. Once every survivor is inside, the gate
# slams down behind them.
for k,(x,z,s) in enumerate([(0.6,-98,0.8),(-0.6,-104,0.9),(0.5,-109,0.7),(8,-111.6,0.8),(16,-112.5,0.9),(23,-111.5,0.8),(30.6,-118,0.8),(29.4,-125,0.9),(30.5,-131,0.7)]):
    crate(f"TunnelCrate{k}",NP_,x,0,z,s,random.uniform(0,40))
pipe("T1Pipe",(-1.0,2.5,-93),(-1.0,2.5,-111))
pipe("T2Pipe",(0,2.5,-111.1),(31,2.5,-111.1))
sc.node("AlarmLights","Node3D","Lights")
for k,(x,z) in enumerate([(0,-96),(0,-106),(6,-112),(16,-112),(26,-112),(30,-118),(30,-128),(0,-70),(0,-82)]):
    light(f"Alarm{k}","Lights/AlarmLights",(x,2.6,z),color=(1,0.05,0.02),energy=1.2,rng=9,pulse=True,shadow=False)
sc.node("ChaseBurst","Marker3D","Monsters",transform=xform((0,0,-64)))
sc.node("ChaseRestart","Marker3D","Monsters",transform=xform((0,0,-93.5)))
area("ChaseTrigger","Triggers",(0,1.4,-100),(2.4,2.8,2),S_STING,message=S(""))
sc.node("Sound","AudioStreamPlayer","Triggers/ChaseTrigger",stream=ER(STING),volume_db="-2.0")
sc.node("FinalChase","Node","Triggers",node_paths=["source","trigger","monster","burst_point","restart_point","alarm_lights"],script=ER(S_FINAL),
        source=NP("../../Puzzles/BlastGate"),trigger=NP("../ChaseTrigger"),monster=NP("../../Monsters/LongMan"),burst_point=NP("../../Monsters/ChaseBurst"),
        restart_point=NP("../../Monsters/ChaseRestart"),alarm_lights=NP("../../Lights/AlarmLights"))
checkpoint("BlastTunnel",3,(0,1.4,-96),(2.4,2.8,2),[(0,0),(0,-0.8),(0,0.8),(0,-1.6)])
# The escape lift.
BX("LiftFloor",NP_,26.2,33.8,0,0.05,-144.8,-136,METAL)
for k,(x1,x2,z1,z2) in enumerate([(26,26.15,-145,-136),(33.85,34,-145,-136),(26,34,-145,-144.85)]):
    BX(f"LiftCage{k}",L,x1,x2,0,3.4,z1,z2,FENCE,collide=False)
label("LiftSign",L,(30,2.9,-144.8),0,"ESCAPE LIFT - STAFF ONLY",size=0.004,font=40,color=(0.5,1,0.6))
light("LiftLight","Lights",(30,3.1,-140),color=(0.6,1,0.7),energy=0.9,rng=8)
sc.node("EscapeGate","AnimatableBody3D","Puzzles",node_paths=["sound"],transform=xform((30,2.9,-135.1)),script=ER(S_MOVER),open_offset=v3(0,-2.9,0),move_time="0.5",sound=NP("Sound"))
esh=sc.sub("BoxShape3D", size=v3(2.4,2.8,0.2)); emesh=sc.sub("BoxMesh", size=v3(2.4,2.8,0.15))
sc.node("CollisionShape3D","CollisionShape3D","Puzzles/EscapeGate",transform=xform((0,1.4,0)),shape=SR(esh))
sc.node("Mesh","MeshInstance3D","Puzzles/EscapeGate",transform=xform((0,1.4,0)),mesh=SR(emesh),**{"surface_material_override/0":FENCE})
sc.node("Sound","AudioStreamPlayer3D","Puzzles/EscapeGate",stream=ER(SNAP),unit_size="10.0")
area("EscapeZone","Triggers",(30,1.5,-140.8),(7.4,3,7.4),S_ESCAPE,np=["gate"],gate=NP("../../Puzzles/EscapeGate"))

# ============================================================ MONSTER, SOUND, SYSTEMS
sc.node("PatrolPoints","Node3D","Monsters")
for k,p in enumerate([(0,0,-60),(-6,0,-67),(0,0,-75),(6,0,-76),(0,0,-88),(-6,0,-85),(6,0,-58),(-6,0,-58),(6,0,-85)]):
    sc.node(f"Point{k+1}","Marker3D","Monsters/PatrolPoints",transform=xform(p))
sc.node("LongMan",None,"Monsters",instance=X["longman"],node_paths=["patrol_points"],transform=xform((0,0,-89),180),patrol_points=NP("../PatrolPoints"),start_delay="99999.0")
area("DormChase","Triggers",(0,1.5,-58.5),(4,3,1.5),S_CHASE,np=["monster"],monster=NP("../../Monsters/LongMan"),message=S("Something unfolds at the far end of the hall. FIND THE FUSES. HIDE."))
sc.node("Sound","AudioStreamPlayer","Triggers/DormChase",stream=ER(STING),volume_db="-2.0")
sc.node("Navigation","NavigationRegion3D",".",navigation_mesh=SR(navmesh),script=ER(S_NAV))
sc.node("Drone","AudioStreamPlayer3D","Sound",transform=xform((0,2,-60)),stream=ER(DRONE),volume_db="-4.0",unit_size="30.0",autoplay="true")
sc.node("LevelSounds","AudioStreamPlayer3D","Sound",transform=xform((0,2,-60)),unit_size="10.0",script=ER(S_RAND),
        sounds=f'Array[AudioStream]([{ER(DRIP)}, {ER(CLANK)}, {ER(CREAK)}, {ER(DRIP)}])',area_size=v3(20,2,120),min_delay="4.0",max_delay="9.0")
sc.node("Items","Node3D",".")
sc.node("ItemSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Items"),script=ER(S_ISPAWN),spawn_points=NP("../ItemSpawnPoints"))
sc.node("Players","Node3D",".")
sc.node("PlayerSpawner","MultiplayerSpawner",".",node_paths=["spawn_points"],spawn_path=NP("../Players"),script=ER(S_PSPAWN),spawn_points=NP("../SpawnPoints"))
sc.node("SpawnPoints","Node3D",".")
for k,(x,z) in enumerate([(-3.5,-2),(-2,-2),(-3.5,-0.5),(-2,-0.5)]):
    sc.node(f"Spawn{k+1}","Marker3D","SpawnPoints",transform=xform((x,0,z),0))
sc.node("TeamMonitor","Node",".",script=ER(S_TEAM))
sc.write("scenes/chapters/chapter_2/chapter_2.tscn")
print("chapter 2 written,", len(sc.nodes), "nodes")
