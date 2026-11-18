# Playtest Logging System
# Records observations during playtesting sessions
# Usage: Add call to log_observation() at critical game moments

extends Node

var session_date := Time.get_date_string_from_system()

var observations := []  # Array of String
var player_count := 0
var session_start_ticks := 0

func start_session(count: int) -> void:
	player_count = count
	observations.clear()
	session_start_ticks = Time.get_ticks_msec()
	print("\n=== PLAYTEST SESSION START ===")
	print("Players: " + str(player_count))
	print("Date: " + session_date)

func end_session() -> void:
	var duration_ms := Time.get_ticks_msec() - session_start_ticks
	var duration_min := duration_ms / 1000.0 / 60.0
	print("\n=== PLAYTEST SESSION END ===")
	print("Duration: %.1f minutes" % duration_min)
	print("Players: " + str(player_count))
	print("Total observations: " + str(observations.size()))
	for obs in observations:
		print("  - " + obs)
	print("=== END ===\n")

func log_observation(observation: String, category: String) -> void:
	var entry := "[" + category + "] " + observation
	observations.append(entry)
	print("[PLAYTEST] " + entry)

func get_observations() -> Array:
	return observations
