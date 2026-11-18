# The sound for the Deep Static Games logo intro (7.6 s), plain Python.
import math, random, struct, sys, wave
SR = 44100; DUR = 7.6; N = int(SR * DUR)
random.seed(3)
out = [0.0] * N

def env(t, a, b, fade_in=0.05, fade_out=0.1):
    if t < a or t > b: return 0.0
    return min(1.0, (t - a) / fade_in if fade_in else 1, (b - t) / fade_out if fade_out else 1)

# hiss (static), smoothed a little so it isn't harsh
lp = 0.0
for i in range(N):
    t = i / SR
    amt = 0.0
    if t < 0.9: amt = math.sin(t / 0.9 * math.pi) * 0.45
    if 6.1 < t < 6.95: amt = max(amt, min(1, (t - 6.1) / 0.5) * 0.4)
    if amt:
        lp += (random.uniform(-1, 1) - lp) * 0.55
        out[i] += lp * amt

# low drone under everything
for i in range(int(0.9 * SR), int(6.6 * SR)):
    t = i / SR
    e = min(1, (t - 0.9) / 1.5) * min(1, (6.6 - t) / 0.4)
    out[i] += e * 0.16 * (math.sin(2 * math.pi * 55 * t) + 0.6 * math.sin(2 * math.pi * 82.4 * t + math.sin(t * 0.7)))

# thin electric whine while the signal draws
for i in range(int(0.9 * SR), int(2.2 * SR)):
    t = i / SR
    out[i] += env(t, 0.9, 2.2, 0.3, 0.2) * 0.05 * math.sin(2 * math.pi * (900 + 300 * (t - 0.9)) * t)

def beep(at, length=0.13, f=1000, vol=0.32):
    for i in range(int(at * SR), min(N, int((at + length) * SR))):
        t = i / SR - at
        out[i] += vol * math.sin(2 * math.pi * f * t) * min(1, t / 0.005) * min(1, (length - t) / 0.02)

def thump(at, vol=0.9, f=48):
    for i in range(int(at * SR), min(N, int((at + 0.6) * SR))):
        t = i / SR - at
        out[i] += vol * math.sin(2 * math.pi * f * t * (1 + 0.8 * math.exp(-t * 20))) * math.exp(-t * 7)

def crackle(at, length=0.08, vol=0.5):
    for i in range(int(at * SR), min(N, int((at + length) * SR))):
        if random.random() < 0.25:
            out[i] += random.uniform(-1, 1) * vol

# heartbeat: beep + "lub-dub"
for at, v in ((2.1, 1.0), (5.0, 0.8)):
    beep(at, vol=0.3 * v); thump(at, 0.9 * v); thump(at + 0.18, 0.55 * v, 42)
# ring drawing: a soft rising tone
for i in range(int(2.2 * SR), int(2.8 * SR)):
    t = i / SR
    out[i] += env(t, 2.2, 2.8, 0.1, 0.2) * 0.06 * math.sin(2 * math.pi * (300 + 500 * (t - 2.2)) * t)
# letters flickering on: little electric crackles
for k in range(14):
    crackle(2.9 + random.random() * 0.9, 0.03 + random.random() * 0.05, 0.25)
crackle(4.95, 0.15, 0.4); crackle(5.6, 0.1, 0.35)
# GAMES sliding out: a low whoosh
for i in range(int(3.9 * SR), int(4.6 * SR)):
    t = i / SR
    out[i] += env(t, 3.9, 4.6, 0.25, 0.4) * random.uniform(-1, 1) * 0.08
# flatline
beep(6.0, 0.7, 1000, 0.22)
for k in range(10): crackle(6.0 + random.random() * 0.6, 0.05, 0.4)
# old TV switching off: a falling whine, then a click
for i in range(int(6.6 * SR), int(7.0 * SR)):
    t = i / SR - 6.6
    out[i] += 0.18 * math.sin(2 * math.pi * (3000 - 6000 * t) * t) * (1 - t / 0.4)
crackle(6.95, 0.02, 0.8)

peak = max(abs(s) for s in out) or 1
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * 0.9)) * 32767)) for s in out))
