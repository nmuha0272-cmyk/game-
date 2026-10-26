using System.Collections.Generic;
using UnityEngine;

// Builds Chapter 1 when the game starts: the level model (all the walls,
// rooms and props, exported from Godot), colliders, lights, signs, the moon,
// fog and ambient light. (Doors, items, notes and the Long Man are added by
// SZWorld.) Change the level in Godot
// (tools/make_chapter1.py), re-export (tools/export_for_unity.gd), and the
// Unity version matches.
namespace Deepwell
{
    public static class SZLevelBuilder
    {
        // How bright a Godot light is in Unity's built-in renderer (guessed: tune here).
        const float EnergyToIntensity = 1.6f;
        // Only this many lights cast shadows (shadowed point lights are expensive).
        const int MaxShadowLights = 12;

        // For the puzzles: the lights of each puzzle light group, and the parts of
        // each puzzle mover (a gate, a shutter), by puzzle piece number.
        public static readonly Dictionary<int, List<Light>> LightGroups = new Dictionary<int, List<Light>>();
        public static readonly Dictionary<int, List<Transform>> MoverParts = new Dictionary<int, List<Transform>>();
        // Level objects a downloaded asset can replace: "DESK_3" -> its parts.
        static readonly Dictionary<string, List<Transform>> SlotGroups = new Dictionary<string, List<Transform>>();

        static void AddMoverPart(int mover, Transform part)
        {
            if (mover < 0) return;
            if (!MoverParts.TryGetValue(mover, out var list)) MoverParts[mover] = list = new List<Transform>();
            list.Add(part);
        }

        public static SZLevelData Build(string chapter, Transform parent)
        {
            LightGroups.Clear();
            MoverParts.Clear();
            SlotGroups.Clear();
            var json = Resources.Load<TextAsset>($"Levels/{chapter}");
            if (json == null)
            {
                Debug.LogError($"Levels/{chapter}.json is missing from Assets/Resources. Re-export it from Godot.");
                return null;
            }
            var data = JsonUtility.FromJson<SZLevelData>(json.text);

            BuildGeometry(chapter, parent);
            BuildEnvironment(data, parent);
            BuildLights(data, parent);
            BuildLabels(data, parent);
            BuildColliders(data, parent);
            return data;
        }

        // The level model: anything named "COL_..." is solid.
        static void BuildGeometry(string chapter, Transform parent)
        {
            var prefab = Resources.Load<GameObject>($"Levels/{chapter}_level");
            if (prefab == null)
            {
                Debug.LogError($"Levels/{chapter}_level.glb didn't import. Is the glTFast package installed? (Window > Package Manager)");
                return;
            }
            var level = Object.Instantiate(prefab, parent);
            level.name = "LevelGeometry";
            SZGraphics.NotSoShiny(level, 0.12f);  // real metal (pipes, fences) keeps a little shine
            int solid = 0;
            foreach (var filter in level.GetComponentsInChildren<MeshFilter>())
            {
                // A model with several materials (like the ground and rock) is split into
                // child pieces, so check the piece's parents for the "COL_" name too.
                if (filter.sharedMesh != null && IsSolid(filter.transform, level.transform))
                {
                    var collider = filter.gameObject.AddComponent<MeshCollider>();
                    collider.sharedMesh = filter.sharedMesh;
                    solid++;
                }
            }
            // Parts of puzzle movers are named "...MOVER_<n>_...": they move when that puzzle is solved.
            foreach (Transform t in level.GetComponentsInChildren<Transform>())
            {
                var m = System.Text.RegularExpressions.Regex.Match(t.name, @"MOVER_(\d+)_");
                if (m.Success && (t.parent == null || !System.Text.RegularExpressions.Regex.IsMatch(t.parent.name, @"MOVER_\d+_")))
                    AddMoverPart(int.Parse(m.Groups[1].Value), t);
                var slot = System.Text.RegularExpressions.Regex.Match(t.name, @"SLOT_([A-Z]+_\d+)_");
                if (slot.Success && (t.parent == null || !t.parent.name.Contains("SLOT_")))
                {
                    if (!SlotGroups.TryGetValue(slot.Groups[1].Value, out var list)) SlotGroups[slot.Groups[1].Value] = list = new List<Transform>();
                    list.Add(t);
                }
            }
            ReplaceWithAssets(parent);
            if (solid == 0) Debug.LogError("Deepwell: no solid level parts were found, so you would fall through the floor.");
        }

        static bool IsSolid(Transform t, Transform root)
        {
            for (; t != null && t != root; t = t.parent)
                if (t.name.StartsWith("COL_")) return true;
            return false;
        }

        // Desks, computers and the team's car: if a downloaded asset is in that
        // slot (Deepwell > Asset Slots), it stands in their place. Their colliders
        // stay, so you still bump into them the same way.
        static void ReplaceWithAssets(Transform parent)
        {
            var done = new Dictionary<string, List<Bounds>>();
            foreach (var pair in SlotGroups)
            {
                var id = pair.Key.Substring(0, pair.Key.LastIndexOf('_')).ToLowerInvariant();
                if (!SZAssets.Has(id)) continue;
                var renderers = new List<Renderer>();
                foreach (var t in pair.Value) renderers.AddRange(t.GetComponentsInChildren<Renderer>());
                if (renderers.Count == 0) continue;
                var bounds = renderers[0].bounds;
                foreach (var r in renderers) bounds.Encapsulate(r.bounds);
                foreach (var r in renderers) r.enabled = false;
                // A monitor and its screen are two parts: only one asset for both.
                var grown = bounds;
                grown.Expand(0.2f);
                if (!done.TryGetValue(id, out var placed)) done[id] = placed = new List<Bounds>();
                if (placed.Exists(b => b.Intersects(grown))) continue;
                placed.Add(bounds);
                var facing = Quaternion.Euler(0f, pair.Value[0].eulerAngles.y, 0f);
                SZAssets.Replace(id, bounds, facing, parent);
            }
        }

        static void BuildEnvironment(SZLevelData data, Transform parent)
        {
            var env = data.environment;
            if (env != null)
            {
                // A little cold light from above, almost none from below: shapes read
                // in the dark without the flat "grey fog" look.
                var ambient = SZLevelData.C(env.ambient) * Mathf.Max(env.ambient_energy, 0.05f);
                RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
                RenderSettings.ambientSkyColor = ambient * 1.4f + new Color(0.006f, 0.008f, 0.014f);
                RenderSettings.ambientEquatorColor = ambient * 0.8f;
                RenderSettings.ambientGroundColor = ambient * 0.25f;
                RenderSettings.fog = env.fog;
                RenderSettings.fogMode = FogMode.ExponentialSquared;
                RenderSettings.fogDensity = Mathf.Clamp(env.fog_density * 2.5f, 0.005f, 0.08f);
                RenderSettings.fogColor = SZLevelData.C(env.fog_color) * 0.08f;
            }
            RenderSettings.skybox = null;

            if (data.moon != null && data.moon.r != null && data.moon.r.Length == 4)
            {
                var moon = new GameObject("Moon").AddComponent<Light>();
                moon.transform.SetParent(parent);
                moon.type = LightType.Directional;
                // Godot lights shine along their -Z, Unity lights along +Z.
                moon.transform.rotation = SZLevelData.Q(data.moon.r) * Quaternion.Euler(0f, 180f, 0f);
                moon.color = SZLevelData.C(data.moon.color);
                moon.intensity = data.moon.energy;
                moon.shadows = LightShadows.Soft;
                moon.shadowStrength = 0.85f;
            }
            SZGraphics.DarkReflections(new Color(0.02f, 0.025f, 0.035f));
        }

        static void BuildLights(SZLevelData data, Transform parent)
        {
            var root = new GameObject("Lights").transform;
            root.SetParent(parent);
            int shadows = 0;
            foreach (var l in data.lights)
            {
                var go = new GameObject(l.spot ? "SpotLight" : "PointLight");
                go.transform.SetParent(root);
                go.transform.SetPositionAndRotation(SZLevelData.V(l.p), SZLevelData.Q(l.r) * Quaternion.Euler(0f, 180f, 0f));
                var light = go.AddComponent<Light>();
                light.type = l.spot ? LightType.Spot : LightType.Point;
                light.color = SZLevelData.C(l.color);
                light.intensity = l.energy * EnergyToIntensity;
                light.range = Mathf.Max(l.range, 0.5f);
                if (l.spot) light.spotAngle = Mathf.Clamp(l.angle * 2f, 1f, 179f);
                if (l.shadow && shadows < MaxShadowLights)
                {
                    light.shadows = LightShadows.Soft;
                    light.shadowBias = 0.03f;
                    light.shadowNormalBias = 0.3f;
                    shadows++;
                }
                light.renderMode = LightRenderMode.Auto;
                if (l.flicker >= 0f) go.AddComponent<SZFlicker>().brokenness = l.flicker;
                if (l.pulse) go.AddComponent<SZPulse>();
                // A puzzle's lights (a room's power) stay dark until it's solved.
                if (l.group >= 0)
                {
                    light.enabled = false;
                    if (!LightGroups.TryGetValue(l.group, out var group)) LightGroups[l.group] = group = new List<Light>();
                    group.Add(light);
                }
            }
        }

        static void BuildLabels(SZLevelData data, Transform parent)
        {
            var root = new GameObject("Signs").transform;
            root.SetParent(parent);
            var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            foreach (var l in data.labels)
            {
                if (string.IsNullOrWhiteSpace(l.text)) continue;
                var go = new GameObject("Sign");
                go.transform.SetParent(root);
                // Godot text faces +Z; Unity's TextMesh faces -Z.
                go.transform.SetPositionAndRotation(SZLevelData.V(l.p), SZLevelData.Q(l.r) * Quaternion.Euler(0f, 180f, 0f));
                var text = go.AddComponent<TextMesh>();
                text.text = l.text;
                text.font = font;
                text.fontSize = 64;
                // TextMesh letters are about characterSize * fontSize / 10 tall.
                text.characterSize = Mathf.Max(l.size, 0.01f) / (text.fontSize * 0.1f) * 0.9f;
                text.anchor = TextAnchor.MiddleCenter;
                text.alignment = TextAlignment.Center;
                text.color = SZLevelData.C(l.color);
                go.GetComponent<MeshRenderer>().sharedMaterial = font.material;
                if (l.billboard) go.AddComponent<SZBillboard>();
                if (l.source >= 0) go.AddComponent<SZCodeLabel>().Data = l;  // shows a puzzle's code
            }
        }

        // Invisible colliders for props (desks, cabinets, barrels...).
        static void BuildColliders(SZLevelData data, Transform parent)
        {
            var root = new GameObject("PropColliders").transform;
            root.SetParent(parent);
            foreach (var c in data.colliders)
            {
                var go = new GameObject("Collider");
                go.transform.SetParent(root);
                AddMoverPart(c.mover, go.transform);
                go.transform.SetPositionAndRotation(SZLevelData.V(c.p), SZLevelData.Q(c.r));
                if (c.box != null && c.box.Length == 3)
                {
                    go.AddComponent<BoxCollider>().size = new Vector3(c.box[0], c.box[1], c.box[2]);
                }
                else if (c.cylinder != null && c.cylinder.Length == 2)
                {
                    var capsule = go.AddComponent<CapsuleCollider>();
                    capsule.radius = c.cylinder[0];
                    capsule.height = Mathf.Max(c.cylinder[1], c.cylinder[0] * 2f);
                }
            }
        }
    }
}
