extends CanvasLayer
## The camera "look" over the 3D view: dark corners, film grain, a little
## color fringing. When you're downed the edges go red and dark.
## It sits below the HUD and menus, so text stays sharp.

@onready var _material: ShaderMaterial = $Effect.material

var _hurt := 0.0


func _ready() -> void:
	layer = -1


func _process(delta: float) -> void:
	var me := Player.find(get_tree(), multiplayer.get_unique_id()) if multiplayer.has_multiplayer_peer() else null
	var target := 1.0 if (me and me.is_downed) else 0.0
	_hurt = move_toward(_hurt, target, delta * 1.5)
	_material.set_shader_parameter("hurt", _hurt)
	# Only during the game (no grain over the menus).
	visible = me != null
