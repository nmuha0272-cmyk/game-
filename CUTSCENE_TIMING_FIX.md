# Cutscene Timing Fix

## Changes Made

The opening cutscene now plays **after** character selection instead of at game startup.

### Flow Before:
1. Game starts → Opening cutscene plays
2. Cutscene finishes → Main menu appears
3. Join/Host → Lobby → Pick characters
4. Press Start → Game begins

### Flow After:
1. Game starts → Main menu appears immediately
2. Join/Host → Lobby → Pick characters
3. Press Start → **Opening cutscene plays**
4. Cutscene finishes → Game begins

## Files Modified

### `scripts/main.gd`
- Removed cutscene auto-play on startup
- Main menu now shows immediately in `_ready()`
- When `game_started` signal fires, the cutscene plays before loading the level
- After cutscene finishes, the level loads (host only, then synced to all players)

### `scripts/ui/opening_cutscene.gd`
- Added `play_cutscene()` method to trigger playback manually
- Cutscene starts hidden instead of auto-playing
- Input handling only works when cutscene is visible

### `scenes/main_menu/opening_cutscene.tscn`
- Set `visible = false` on the root Control node

## Multiplayer Behavior

The cutscene plays for **all players** simultaneously because:
- `GameState._start_game()` is an RPC with `call_local` 
- The `game_started` signal fires on every client
- Each client's `main.gd` responds by showing and playing the cutscene
- After the cutscene, only the host loads the level (standard behavior)

## Testing

To test:
1. Start the game → Main menu should appear immediately
2. Host a game or play solo
3. Pick a character in the lobby
4. Press Start
5. The cutscene should play
6. After cutscene (or skip with Space), the game level should load
