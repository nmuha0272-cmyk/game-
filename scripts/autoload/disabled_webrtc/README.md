# WebRTC (internet play), switched off for now

These two scripts don't work in Godot 4.7 yet (wrong class names and API
calls), and the autoload is commented out in project.godot. The `.gdignore`
file in this folder makes Godot skip them, so they don't show errors in the
editor. To work on them again: fix them, move them back to
`scripts/autoload/`, delete `.gdignore`, and turn the autoload back on.
