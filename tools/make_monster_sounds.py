"""Makes two Long Man sounds from math: a bone/neck crack and a fast
skittering tap for when he crawls. Run: python3 tools/make_monster_sounds.py"""
import wave
import numpy as np

RATE = 44100
rng = np.random.default_rng(5)


def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    with wave.open(f"assets/audio/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print("made", name)


def click(length, decay, tone):
    t = np.arange(int(RATE * length)) / RATE
    noise = rng.standard_normal(len(t))
    body = np.sin(2 * np.pi * tone * t) * 0.6
    return (noise + body) * np.exp(-t * decay)


# Neck crack: a quick run of 5-7 sharp pops, like knuckles but bigger.
crack = np.zeros(int(RATE * 0.5))
pos = 0
for k in range(rng.integers(5, 8)):
    pop = click(0.03, 260, rng.uniform(900, 2200)) * rng.uniform(0.5, 1.0)
    pos += int(RATE * rng.uniform(0.015, 0.06))
    crack[pos:pos + len(pop)] += pop[:len(crack) - pos]
save("neck_crack", crack)

# Skitter: one light, dry tap of a fingernail/bone on concrete.
tap = click(0.06, 120, 3000) * 0.7 + click(0.06, 60, 400) * 0.5
save("skitter", tap)
