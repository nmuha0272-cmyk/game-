DEEPWELL HOME SCREEN (Godot 4)

WHAT'S INSIDE (scenes/main_menu/)
  main_menu_car.tscn / .gd   The home screen: a car driving down a dark forest
                             road at night. Use this one as your main scene.
  main_menu.tscn / .gd       The title, buttons, and Join/Settings/Credits panels.
                             The car scene shows this on top of itself.
  menu_background.gdshader   The black-and-white Blackwater Station picture.
                             Only used if you open main_menu.tscn by itself.

SET UP
1. Copy the "scenes/main_menu" folder into your project's "scenes" folder.
2. Project > Project Settings > Application > Run > Main Scene:
   res://scenes/main_menu/main_menu_car.tscn
3. Press F5.

HOW IT WORKS
- Host Game or Join Game moves the camera into the back seat for character
  select. Eli drives, Cole sits next to him, Nora and Walter are in the back.
- Hover over a name card (or a character) and the camera glides to that
  character and shows what they can do. Click to choose, then "PLAY AS ...".
  Arrow keys + Enter work too (and a controller's d-pad + A). Esc goes back.
- After "PLAY AS ...", the camera moves behind the car and it drives up to the
  gate of the Blackwater Weather Station, stops, and fades to black, then
  opens the lobby. Press Enter or Esc to skip the drive.
- Host/Join call your NetworkManager autoload if it exists:
  host_game(port), join_game(ip, port), select_character(id).
- When a character is confirmed, the scene emits character_confirmed(id),
  sets GameState.chosen_character if a GameState autoload has that variable,
  and opens res://scenes/lobby/lobby.tscn if it exists.
- To lock a character another player picked, call
  set_character_taken("cole", true) on the car scene.

REAL MODELS
The characters are simple stand-in shapes for now. Save real models as:
  res://assets/models/characters/eli.glb
  res://assets/models/characters/cole.glb
  res://assets/models/characters/nora.glb
  res://assets/models/characters/walter.glb
and they will appear in their seats automatically (you may need to adjust
their position or size to sit right).

OPTIONAL SOUNDS (works without them)
  res://assets/audio/menu_ambience.ogg   (try a car engine / road rumble loop)
  res://assets/audio/ui_click.ogg

Settings are saved to user://settings.cfg.
