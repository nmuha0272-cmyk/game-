extends NavigationRegion3D
## Builds the map of walkable floor that monsters use to find their way,
## when the level starts (host only, since only the host moves monsters).
## Anything in the "navigation_geometry" group counts as floor or walls.
## Doors and movable furniture are left out on purpose: monsters deal with
## those themselves.


func _ready() -> void:
	if not multiplayer.is_server():
		return
	# CSG boxes build their collision shapes a moment after loading, so wait
	# one physics frame first or the map comes out empty.
	await get_tree().physics_frame
	bake_navigation_mesh(false)
