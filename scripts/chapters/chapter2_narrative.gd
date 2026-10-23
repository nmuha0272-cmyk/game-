extends Node
## Chapter 2 story moments. Added by chapter.gd on the host.
## Right after the crash: Eli and Nora argue about the elevator falling
## (whose fault it is, and why they're really down here). Cole breaks it up;
## Walter is a little too calm about the cable (a clue for Chapter 4).

## Each line: [speaker, text, seconds on screen].
const CRASH_ARGUMENT := [
	["Nora", "Is everyone okay? ...Okay. Okay. We're alive.", 4.0],
	["Nora", "Great plan, Eli. 'Just take the elevator.' Now we're stuck at the bottom of a hole.", 5.0],
	["Eli", "Nobody made you get in. You wanted your story, remember?", 4.5],
	["Nora", "My SOURCE is down here. That's not a story, that's a person.", 4.5],
	["Eli", "So are Marcus and Jenna! They came here because of me. I'm not turning back.", 5.0],
	["Nora", "And if they're already dead? Are we all supposed to die looking for them?", 5.0],
	["Eli", "Don't. Don't you dare say that.", 3.5],
	["Cole", "ENOUGH. Both of you. Yelling is how that thing finds us.", 4.5],
	["Cole", "Eli, breathe. Nora, you've got a camera, not a vote on who we leave behind.", 5.0],
	["Nora", "...Fine. But that cable didn't just snap. Look at the end of it. It's cut clean.", 5.0],
	["Walter", "Old steel. Sixteen years of rust. These things happen.", 4.0],
	["Nora", "Rust doesn't cut in a straight line, Walter.", 4.0],
	["Cole", "We figure it out later. Right now we find a way out of this shaft. Together.", 5.0],
]

const STORY_KEY := "story_ch2_crash_argument"


func _ready() -> void:
	if not multiplayer.is_server():
		return
	# Plays once per chapter, from the very beginning only (not after a restart).
	if GameState.checkpoint_order > 0 or GameState.level_progress.has(STORY_KEY):
		return
	GameState.level_progress[STORY_KEY] = true
	# Give the chapter title a moment first.
	await get_tree().create_timer(5.0).timeout
	for line: Array in CRASH_ARGUMENT:
		if not is_inside_tree():
			return
		GameState.server_say(line[0], line[1], line[2])
		await get_tree().create_timer(float(line[2]) + 0.4).timeout
