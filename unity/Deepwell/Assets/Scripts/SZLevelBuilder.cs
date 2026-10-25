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

        public static SZLevelData Build(string chapter, Transform parent)
        {
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
            foreach (var filter in level.GetComponentsInChildren<MeshFilter>())
            {
                if (filter.gameObject.name.StartsWith("COL_") && filter.sharedMesh != null)
                {
                    var collider = filter.gameObject.AddComponent<MeshCollider>();
                    collider.sharedMesh = filter.sharedMesh;
                }
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
            RenderSettings.reflectionIntensity = 0.35f;
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
                // Puzzle lights (a room's power) stay dark until puzzles exist (phase U3).
                if (l.starts_off) light.enabled = false;
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
