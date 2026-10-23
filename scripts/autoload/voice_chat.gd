extends Node
## Voice chat manager (autoload). Handles microphone capture, voice activity
## detection, and networked 3D voice playback.
## 
## Godot 4 doesn't have built-in voice chat, so we use AudioEffectCapture
## on a bus to get mic data, then send compressed audio packets over the network.

signal voice_data_ready(player_id: int, audio_data: Array, sample_rate: int)
signal noise_level_changed(player_id: int, level: float)  # 0.0..1.0

var _capture_effect: AudioEffectCapture
var _mic_bus_index := -1
var _sample_buffer: Array = []
var _buffer_timer: float = 0.0
var _send_interval := 0.05  # 20 packets/sec
var _enabled := true
var _push_to_talk := false
var _mic_sensitivity := 1.0
var _noise_gate_threshold := 0.01
var _vad_smoothing := 0.15
var _current_noise_level := 0.0

## Noise level tiers for monsters
const WHISPER_THRESHOLD := 0.15
const TALK_THRESHOLD := 0.35
const YELL_THRESHOLD := 0.65

const NOISE_RANGES := {
	"whisper": 4.0,
	"talk": 12.0,
	"yell": 25.0,
}


func _ready() -> void:
	_setup_microphone()
	set_process(true)


func _setup_microphone() -> void:
	# Find or create a microphone bus
	var audio_server = AudioServer
	var bus_count = audio_server.get_bus_count()
	
	# Look for existing "Microphone" bus
	for i in range(bus_count):
		if audio_server.get_bus_name(i) == "Microphone":
			_mic_bus_index = i
			break
	
	if _mic_bus_index == -1:
		# Create new bus at the end
		_mic_bus_index = bus_count
		audio_server.add_bus(_mic_bus_index)
		audio_server.set_bus_name(_mic_bus_index, "Microphone")
	
	# Add capture effect to the bus
	_capture_effect = AudioEffectCapture.new()
	_capture_effect.set_buffer_length(0.1)  # 100ms buffer
	audio_server.add_bus_effect(_mic_bus_index, _capture_effect)
	
	# Mute the bus so we don't hear ourselves locally
	audio_server.set_bus_volume_db(_mic_bus_index, -80.0)
	
	# Set bus to only receive from microphone (if available)
	# Note: Godot's audio input handling varies by platform


func _process(delta: float) -> void:
	if not _enabled or not NetworkManager.is_online():
		return
	
	_buffer_timer += delta
	if _buffer_timer >= _send_interval:
		_buffer_timer = 0.0
		_capture_and_send()


func _capture_and_send() -> void:
	if not _capture_effect:
		return
	
	var frames_available = _capture_effect.get_frames_available()
	if frames_available == 0:
		return
	
	# Get raw audio data
	var data = _capture_effect.get_buffer(frames_available)
	if data.size() == 0:
		return
	
	# Calculate RMS (volume) for VAD
	var rms = _calculate_rms(data)
	var noise_level = _apply_noise_gate(rms * _mic_sensitivity)
	
	# Smooth the noise level
	_current_noise_level = lerp(_current_noise_level, noise_level, _vad_smoothing)
	
	# Push-to-talk check
	var should_transmit = not _push_to_talk or Input.is_action_pressed("voice_chat")
	
	if should_transmit and _current_noise_level > _noise_gate_threshold:
		# Compress audio data (simple downsampling for now)
		var compressed = _compress_audio(data)
		
		# Send to other players
		var my_id = multiplayer.get_unique_id()
		_receive_voice.rpc_id(1, my_id, compressed, AudioServer.get_mix_rate())
		
		# Also send noise level to host for monster hearing
		if multiplayer.is_server():
			_broadcast_noise_level(my_id, _current_noise_level)
		else:
			_send_noise_level.rpc_id(1, my_id, _current_noise_level)
	
	# Nothing draws this on screen; listeners (monsters, tests) just watch it.
	noise_level_changed.emit(multiplayer.get_unique_id(), _current_noise_level)


func _calculate_rms(data: Array) -> float:
	# The capture buffer hands back stereo frames (one Vector2 per frame).
	var sum_sq := 0.0
	for frame in data:
		var v: Vector2 = frame
		sum_sq += (v.x * v.x + v.y * v.y) * 0.5
	return sqrt(sum_sq / maxf(data.size(), 1.0))


func _apply_noise_gate(rms: float) -> float:
	if rms < _noise_gate_threshold:
		return 0.0
	# Scale up to 0..1 range
	return min((rms - _noise_gate_threshold) / (1.0 - _noise_gate_threshold) * 2.0, 1.0)


func _compress_audio(data: Array) -> Array:
	# Simple compression: downsample by 2, quantize to 8-bit.
	# Each entry is a stereo frame (Vector2); fold it to one sample first.
	var compressed = []
	for i in range(0, data.size(), 2):
		var frame: Vector2 = data[i]
		var sample := clampf((frame.x + frame.y) * 0.5, -1.0, 1.0)
		compressed.append(int((sample + 1.0) * 127.5))
	return compressed


func _decompress_audio(data: Array) -> Array:
	var decompressed = []
	for byte in data:
		var sample = (byte / 127.5) - 1.0
		decompressed.append(sample)
		decompressed.append(sample)  # Duplicate for 2x upsample
	return decompressed


# --- Network ---

@rpc("any_peer", "reliable")
func _receive_voice(sender_id: int, compressed_data: Array, sample_rate: int) -> void:
	if sender_id == multiplayer.get_unique_id():
		return  # Don't play own voice back
	
	var player = Player.find(get_tree(), sender_id)
	if not player or not is_instance_valid(player):
		return
	
	var decompressed = _decompress_audio(compressed_data)
	
	# Play from player's position in 3D
	_play_voice_3d(player, decompressed, sample_rate)


func _play_voice_3d(player: Player, audio_data: Array, sample_rate: int) -> void:
	# Create temporary AudioStreamPlayer3D at player's head
	var voice_player = AudioStreamPlayer3D.new()
	voice_player.position = player.global_position + Vector3(0, 1.6, 0)
	voice_player.unit_db = 0.0
	voice_player.max_distance = 20.0
	voice_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	voice_player.attenuation_filter_cutoff_hz = 5000.0  # Muffle at distance
	
	# Create stream from raw data
	var stream = AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	# Convert float array to byte array for 16-bit
	var byte_data = PackedByteArray()
	for sample in audio_data:
		var s16 = int(clamp(sample, -1.0, 1.0) * 32767)
		byte_data.append(s16 & 0xFF)
		byte_data.append((s16 >> 8) & 0xFF)
	stream.data = byte_data
	
	voice_player.stream = stream
	get_tree().root.add_child(voice_player)
	voice_player.play()
	
	# Clean up when done
	voice_player.finished.connect(func(): voice_player.queue_free())


@rpc("any_peer", "reliable")
func _send_noise_level(player_id: int, level: float) -> void:
	if multiplayer.is_server():
		_broadcast_noise_level(player_id, level)


func _broadcast_noise_level(player_id: int, level: float) -> void:
	# Send to all monsters for hearing
	_receive_noise_level.rpc(player_id, level)


@rpc("authority", "call_local", "reliable")
func _receive_noise_level(player_id: int, level: float) -> void:
	# Check voice mode for quiet sections
	var mode = GameState.voice_mode if GameState else "normal"
	var pulse = GameState.pulse_active if GameState else false
	
	# In whisper_only mode, only whisper is allowed
	if mode == "whisper_only":
		if level >= TALK_THRESHOLD:
			level = WHISPER_THRESHOLD * 0.9  # Clamp to whisper
	
	# In pulse_active mode (Ch 2 EM pulse), any voice triggers noise
	if pulse and mode == "pulse_active":
		# Voice during pulse = loud noise
		get_tree().call_group("monsters", "hear_noise", Player.find(get_tree(), player_id).global_position, 30.0)
		noise_level_changed.emit(player_id, level)
		return
	
	# In echo_mimic mode, voice creates noise AND marks position for Echo
	if mode == "echo_mimic" and level >= WHISPER_THRESHOLD:
		var player = Player.find(get_tree(), player_id)
		if player:
			get_tree().call_group("monsters", "hear_voice_position", player.global_position)
	
	# In warden_headset mode, walkie-talkie voice has extended range
	var walkie_multiplier = 1.0
	if mode == "warden_headset":
		walkie_multiplier = 3.0  # Warden hears walkie-talkies from 3x further
	
	# In dual_hunt mode, both Warden and Echo react (handled by monsters)
	var dual_hunt = (mode == "dual_hunt")
	
	# Determine noise tier and range
	var tier = "silent"
	var range = 0.0
	
	if level >= YELL_THRESHOLD:
		tier = "yell"
		range = NOISE_RANGES["yell"]
	elif level >= TALK_THRESHOLD:
		tier = "talk"
		range = NOISE_RANGES["talk"]
	elif level >= WHISPER_THRESHOLD:
		tier = "whisper"
		range = NOISE_RANGES["whisper"]
	
	# Find the player
	var player = Player.find(get_tree(), player_id)
	if not player:
		return
	
	# Apply mode multipliers
	if mode == "quiet":
		range *= 2.0  # 2x hearing in quiet zones
	elif mode == "dual_hunt":
		range *= 1.5  # 1.5x for dual hunt
	
	range *= walkie_multiplier
	
	# Send noise event to monsters
	if range > 0.0:
		get_tree().call_group("monsters", "hear_noise", player.global_position, range)
	
	# Tell the listeners how loud that player was (no on-screen meter).
	noise_level_changed.emit(player_id, level)


# --- Public API ---

func set_enabled(enabled: bool) -> void:
	_enabled = enabled


func set_push_to_talk(enabled: bool) -> void:
	_push_to_talk = enabled


func set_mic_sensitivity(value: float) -> void:
	_mic_sensitivity = clamp(value, 0.1, 10.0)


func set_noise_gate(value: float) -> void:
	_noise_gate_threshold = clamp(value, 0.0, 0.5)


func get_noise_tier() -> String:
	if _current_noise_level >= YELL_THRESHOLD:
		return "yell"
	elif _current_noise_level >= TALK_THRESHOLD:
		return "talk"
	elif _current_noise_level >= WHISPER_THRESHOLD:
		return "whisper"
	return "silent"


func get_noise_range() -> float:
	var tier = get_noise_tier()
	return NOISE_RANGES.get(tier, 0.0)