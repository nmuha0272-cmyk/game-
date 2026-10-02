"""Makes roblox/sounds/*.ogg: the Long Man's sounds for the Roblox version
(Roblox needs them uploaded before a game can play them; see
roblox/HOW_TO_USE.txt). Also makes the heartbeat.
    pip install imageio-ffmpeg numpy
    python3 tools/make_roblox_sounds.py
"""
import os, subprocess, wave
import numpy as np
import imageio_ffmpeg

OUT = "roblox/sounds"
SOURCES = {"Scream": "monster_screech.wav", "Shriek": "monster_shriek.wav", "NeckCrack": "neck_crack.wav",
           "Skitter": "skitter.wav", "Breath": "monster_breath.wav", "Click": "monster_click.wav"}
os.makedirs(OUT, exist_ok=True)

# A heartbeat: two low thumps ("lub-dub"), about 100 beats a minute.
rate = 44100
t = np.arange(int(rate * 0.6)) / rate
def thump(start, freq, loud):
    x = np.clip(t - start, 0, None)
    return loud * np.sin(2 * np.pi * freq * x * (1 - 0.3 * x)) * np.exp(-x * 28) * (t >= start)
beat = thump(0.0, 55, 1.0) + thump(0.16, 48, 0.7)
beat = (beat / np.abs(beat).max() * 0.9 * 32767).astype(np.int16)
with wave.open(OUT + "/heartbeat.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(beat.tobytes())

ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
files = dict(SOURCES, Heartbeat=None)
for name, src in files.items():
    path = OUT + "/heartbeat.wav" if src is None else "assets/audio/" + src
    dst = f"{OUT}/LongMan_{name}.ogg"
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "5", dst], check=True)
    print("made", dst)
os.remove(OUT + "/heartbeat.wav")
