Put the car model for the opening here (the main menu, picking your
character, the drive). Name it ONE of these:
    volvo_s90.glb     audi_rs_q8.glb     car.glb
(.gltf and .fbx work too). It replaces the box car. If there are two,
car.glb wins, then volvo_s90, then audi_rs_q8.

It came as a Blender file? Open it in Blender, then
File > Export > glTF 2.0 (.glb), and save it here.

If it faces backwards, sits too high/low or is the wrong size, change
CAR_MODEL_TURN / CAR_MODEL_OFFSET / CAR_MODEL_LENGTH at the top of
scenes/main_menu/deepwell/main_menu_car.gd.
