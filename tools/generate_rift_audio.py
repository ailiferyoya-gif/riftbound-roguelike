import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(17)


def tone(buf, start, duration, start_hz, end_hz, amp, kind="sine", attack=0.006, release=0.12):
    first = int(start * SAMPLE_RATE)
    count = max(1, int(duration * SAMPLE_RATE))
    for index in range(count):
        pos = index / SAMPLE_RATE
        t = index / max(1, count - 1)
        phase = 2 * math.pi * (start_hz * pos + (end_hz - start_hz) * pos * pos / (2 * duration))
        if kind == "saw":
            value = 2 * ((phase / (2 * math.pi)) % 1.0) - 1
        elif kind == "triangle":
            value = 2 * abs(2 * ((phase / (2 * math.pi)) % 1.0) - 1) - 1
        else:
            value = math.sin(phase)
        fade_in = min(1.0, pos / attack) if attack else 1.0
        fade_out = min(1.0, max(0.0, duration - pos) / release) if release else 1.0
        buf[first + index] += value * amp * fade_in * fade_out


def noise(buf, start, duration, amp, color="white"):
    first = int(start * SAMPLE_RATE)
    count = max(1, int(duration * SAMPLE_RATE))
    previous = 0.0
    for index in range(count):
        pos = index / SAMPLE_RATE
        sample = random.uniform(-1.0, 1.0)
        if color == "dark":
            sample = previous * 0.82 + sample * 0.18
            previous = sample
        fade_in = min(1.0, pos / 0.002)
        fade_out = min(1.0, max(0.0, duration - pos) / 0.08)
        buf[first + index] += sample * amp * fade_in * fade_out


def write(name, duration, build):
    buf = [0.0] * int(duration * SAMPLE_RATE)
    build(buf)
    peak = max(0.001, max(abs(sample) for sample in buf))
    scale = min(0.92 / peak, 1.0)
    path = os.path.join(ROOT, name + ".wav")
    with wave.open(path, "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(SAMPLE_RATE)
        audio.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, sample * scale)) * 32767)) for sample in buf))


write("rift-click", 0.14, lambda b: (tone(b, 0, 0.11, 930, 1480, 0.22, "triangle", 0.002, 0.06), noise(b, 0, 0.035, 0.08)))


def build_attack(b):
    tone(b, 0, 0.31, 180, 72, 0.35, "saw", 0.002, 0.14)
    tone(b, 0.018, 0.19, 260, 920, 0.25, "triangle", 0.002, 0.08)
    noise(b, 0.018, 0.095, 0.24)
    tone(b, 0.055, 0.16, 1100, 250, 0.16, "saw", 0.002, 0.1)


write("rift-attack", 0.36, build_attack)


def build_skill(b):
    tone(b, 0, 0.62, 180, 740, 0.22, "triangle", 0.02, 0.22)
    tone(b, 0.06, 0.56, 360, 1180, 0.18, "sine", 0.04, 0.2)
    tone(b, 0.18, 0.42, 880, 1760, 0.13, "sine", 0.01, 0.22)
    tone(b, 0.34, 0.3, 1320, 1980, 0.1, "triangle", 0.01, 0.18)
    noise(b, 0.02, 0.34, 0.035, "dark")


write("rift-skill", 0.78, build_skill)


def build_guard(b):
    tone(b, 0, 0.38, 92, 58, 0.28, "sine", 0.002, 0.2)
    tone(b, 0.01, 0.34, 480, 820, 0.2, "triangle", 0.01, 0.2)
    tone(b, 0.08, 0.28, 980, 620, 0.13, "sine", 0.01, 0.18)


write("rift-guard", 0.48, build_guard)


def build_heal(b):
    for offset, hz in ((0.0, 330), (0.13, 495), (0.26, 660), (0.39, 990)):
        tone(b, offset, 0.34, hz, hz * 1.015, 0.16, "sine", 0.012, 0.22)
    tone(b, 0.08, 0.68, 260, 1040, 0.09, "triangle", 0.02, 0.3)
    noise(b, 0.08, 0.46, 0.028, "dark")


write("rift-heal", 0.9, build_heal)


def build_enemy(b):
    tone(b, 0, 0.34, 150, 42, 0.34, "saw", 0.002, 0.16)
    tone(b, 0.02, 0.28, 310, 78, 0.17, "triangle", 0.002, 0.12)
    noise(b, 0.0, 0.16, 0.2, "dark")
    tone(b, 0.12, 0.16, 620, 180, 0.12, "saw", 0.002, 0.1)


write("rift-enemy", 0.42, build_enemy)


def build_reward(b):
    for offset, hz in ((0.0, 660), (0.12, 880), (0.24, 1320)):
        tone(b, offset, 0.22, hz, hz * 1.04, 0.2, "sine", 0.002, 0.15)
    tone(b, 0.29, 0.32, 1760, 880, 0.1, "triangle", 0.002, 0.2)


write("rift-reward", 0.68, build_reward)


def build_victory(b):
    for offset, hz in ((0.0, 392), (0.18, 494), (0.36, 587), (0.54, 784), (0.72, 988)):
        tone(b, offset, 0.38, hz, hz * 1.01, 0.16, "sine", 0.008, 0.28)
    tone(b, 0.35, 0.75, 196, 392, 0.08, "triangle", 0.03, 0.4)


write("rift-victory", 1.24, build_victory)


def build_defeat(b):
    tone(b, 0, 0.78, 260, 62, 0.32, "triangle", 0.008, 0.35)
    tone(b, 0.05, 0.62, 130, 38, 0.22, "saw", 0.004, 0.32)
    noise(b, 0.08, 0.44, 0.08, "dark")


write("rift-defeat", 1.0, build_defeat)

print("generated", len(os.listdir(ROOT)), "Riftbound sound effects in", ROOT)
