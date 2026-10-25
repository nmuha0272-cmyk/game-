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
    }

    [Serializable]
    public class DoorData
    {
        public string name;
        public float[] p, r;
        public bool puzzle, locked;
    }

    [Serializable]
    public class LabelData
    {
        public float[] p, r, color;
        public string text;
        public float size;
        public bool billboard;
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
    }
}
