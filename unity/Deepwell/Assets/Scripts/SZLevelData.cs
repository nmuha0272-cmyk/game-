using System;
using UnityEngine;

// The data side of a chapter, read from Resources/Levels/chapter1.json.
// It's written by the Godot project (tools/export_for_unity.gd), already in
// Unity's coordinates: positions are [x, y, z], rotations are quaternions
// [x, y, z, w], colors are [r, g, b, a].
namespace Deepwell
{
    [Serializable]
    public class SZLevelData
    {
        public LightData[] lights;
        public DoorData[] doors;
        public LabelData[] labels;
        public SpawnData[] spawns;
        public ColliderData[] colliders;
        public ItemData[] items;
        public LoreData[] lore;
        public LoreData[] lore_book;
        public CheckpointData[] checkpoints;
        public TriggerData[] triggers;
        public MonsterData monster;
        public CutsceneData[] cutscenes;
        public DialogueLine[] dialogue;
        public SpawnData team_car;
        public PuzzleData[] puzzles;
        public SpawnData[] lockers;   // lockers to hide in (door faces +Z)
        public MoonData moon;
        public EnvironmentData environment;

        public static Vector3 V(float[] a) => a != null && a.Length >= 3 ? new Vector3(a[0], a[1], a[2]) : Vector3.zero;
        public static Quaternion Q(float[] a) => a != null && a.Length >= 4 ? new Quaternion(a[0], a[1], a[2], a[3]) : Quaternion.identity;
        public static Color C(float[] a) => a != null && a.Length >= 3 ? new Color(a[0], a[1], a[2], a.Length >= 4 ? a[3] : 1f) : Color.white;
    }

    [Serializable]
    public class LightData
    {
        public float[] p, r, color;
        public float energy, range, angle, flicker;
        public bool shadow, spot, pulse, starts_off;
        public int group = -1;  // a puzzle's light group: dark until it's solved
    }

    [Serializable]
    public class DoorData
    {
        public string name;
        public float[] p, r;
        public bool puzzle, locked;
        public string @lock;       // "keycard_green" / "keycard_yellow" / "keycard_red" / "jammed" / ""
        public int id = -1;        // its puzzle piece (doors a puzzle opens)
    }

    [Serializable]
    public class LabelData
    {
        public float[] p, r, color;
        public string text;
        public float size;
        public bool billboard;
        // A code display: shows a puzzle's code once hidden_until is solved.
        public int source = -1, hidden_until = -1, digit = -1;
        public string template, hidden_text;
    }

    [Serializable]
    public class SpawnData
    {
        public float[] p, r;
    }

    [Serializable]
    public class ColliderData
    {
        public float[] p, r, box, cylinder;
        public int mover = -1;  // moves with this puzzle mover (a gate, a shutter)
    }

    [Serializable]
    public class MoonData
    {
        public float[] r, color;
        public float energy;
    }

    [Serializable]
    public class EnvironmentData
    {
        public float[] ambient, fog_color;
        public float ambient_energy, fog_density;
        public bool fog;
    }

    [Serializable]
    public class ItemData
    {
        public string id, name, hint, lore;
        public float[] p, color;
    }

    [Serializable]
    public class LoreData
    {
        public string id, title, text, kind;
        public float[] p, r;
    }

    [Serializable]
    public class CheckpointData
    {
        public string name;
        public int order;
        public float[] p, r, size;
        public SpawnPoint[] spawns;
    }

    // A point written as {"p": [x, y, z]} (JsonUtility can't read arrays of arrays).
    [Serializable]
    public class SpawnPoint
    {
        public float[] p;
    }

    [Serializable]
    public class TriggerData
    {
        public string message;
        public bool chase;
        public float[] p, r, size;
    }

    [Serializable]
    public class MonsterData
    {
        public float[] p, r;
        public float patrol_speed, investigate_speed, chase_speed, catch_distance, catch_cooldown;
        public SpawnPoint[] patrol;
    }

    [Serializable]
    public class CutsceneData
    {
        public string name;
        public bool play_on_start;
        public ShotData[] shots;
    }

    // The camera glides from "from" (looking at "from_look") to "to" (looking at "to_look").
    [Serializable]
    public class ShotData
    {
        public float[] from, from_look, to, to_look;
        public float time;
        public string text;
    }

    [Serializable]
    public class DialogueLine
    {
        public string who, text;
        public bool trunk, pistols, photo;  // the trunk scene at the team's car
    }

    // One puzzle piece from the Godot level: a lever, keypad, fuse box, gate
    // (the logic that wires pieces together), door, light group, mover...
    [Serializable]
    public class PuzzleData
    {
        public string id, kind, name;
        public int parent = -1;
        public float[] p, r, size;
        public bool has_code;
        public ParamData[] @params;

        public ParamData Get(string key) => @params == null ? null : Array.Find(@params, x => x.k == key);
        public string S(string key, string fallback = "") { var x = Get(key); return x != null && !string.IsNullOrEmpty(x.s) ? x.s : fallback; }
        public float N(string key, float fallback = 0f) { var x = Get(key); return x != null ? x.n : fallback; }
        public bool B(string key) => Get(key)?.b ?? false;
        public int[] Refs(string key) => Get(key)?.refs ?? new int[0];
        public bool Has3D => p != null && p.Length == 3;
        public int Ref(string key) { var r = Refs(key); return r.Length > 0 ? r[0] : -1; }
        public float[] V(string key) => Get(key)?.v;
    }

    // One setting: s = text, n = number, b = yes/no, refs = pieces it points at, v = vector/color.
    [Serializable]
    public class ParamData
    {
        public string k, s;
        public float n;
        public bool b;
        public int[] refs;
        public float[] v;
    }
}
