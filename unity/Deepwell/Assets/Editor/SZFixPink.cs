using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

// Asset Store packs made for HDRP or URP (like "HDRP Lab Car" and "HDRP
// Terrain") have materials this project can't draw (it uses the built-in
// renderer), so they show up bright pink. This turns each one into a normal
// Standard material with the same picture, bumps and color.
// It runs by itself when you import a pack, and from Deepwell > Fix Pink Materials.
namespace Deepwell.EditorTools
{
    public static class SZFixPink
    {
        [MenuItem("Deepwell/Fix Pink Materials (HDRP or URP assets)")]
        public static void FixAll()
        {
            var paths = new List<string>();
            foreach (var guid in AssetDatabase.FindAssets("t:Material", new[] { "Assets" }))
                paths.Add(AssetDatabase.GUIDToAssetPath(guid));
            int n = Fix(paths);
            Debug.Log(n > 0 ? "Deepwell: fixed " + n + " pink materials." : "Deepwell: no pink materials found.");
        }

        public static int Fix(IEnumerable<string> paths)
        {
            var standard = Shader.Find("Standard");
            if (standard == null) return 0;
            int fixedCount = 0;
            foreach (var path in paths)
            {
                var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (mat == null || !NeedsFix(mat)) continue;
                Convert(mat, standard);
                EditorUtility.SetDirty(mat);
                fixedCount++;
            }
            if (fixedCount > 0)
            {
                AssetDatabase.SaveAssets();
                Debug.Log("Deepwell: " + fixedCount + " HDRP/URP materials changed to Standard so they aren't pink.");
            }
            return fixedCount;
        }

        static bool NeedsFix(Material m)
        {
            var sh = m.shader;
            if (sh == null || !sh.isSupported) return true;
            var name = sh.name;
            return name.StartsWith("HDRP/") || name.StartsWith("Universal Render Pipeline/") || name.StartsWith("Shader Graphs/")
                   || name.Contains("InternalErrorShader");
        }

        static void Convert(Material mat, Shader standard)
        {
            // The values the material had are still saved inside it, whatever its shader.
            var textures = new Dictionary<string, Texture>();
            var colors = new Dictionary<string, Color>();
            var floats = new Dictionary<string, float>();
            var so = new SerializedObject(mat);
            var saved = so.FindProperty("m_SavedProperties");
            if (saved != null)
            {
                Read(saved.FindPropertyRelative("m_TexEnvs"), e => textures[e.FindPropertyRelative("first").stringValue] =
                    e.FindPropertyRelative("second.m_Texture").objectReferenceValue as Texture);
                Read(saved.FindPropertyRelative("m_Colors"), e => colors[e.FindPropertyRelative("first").stringValue] =
                    e.FindPropertyRelative("second").colorValue);
                Read(saved.FindPropertyRelative("m_Floats"), e => floats[e.FindPropertyRelative("first").stringValue] =
                    e.FindPropertyRelative("second").floatValue);
            }

            // Ground (terrain) materials need the built-in terrain shader instead.
            var terrain = Shader.Find("Nature/Terrain/Standard");
            if (terrain != null && mat.shader != null && mat.shader.name.Contains("Terrain"))
            {
                mat.shader = terrain;
                return;
            }
            mat.shader = standard;
            mat.color = Pick(colors, Color.white, "_BaseColor", "_Color");
            var main = Pick(textures, null, "_BaseColorMap", "_BaseMap", "_MainTex", "_Albedo", "_AlbedoMap");
            mat.SetTexture("_MainTex", main);
            var normal = Pick(textures, null, "_NormalMap", "_BumpMap");
            mat.SetTexture("_BumpMap", normal);
            if (normal != null) mat.EnableKeyword("_NORMALMAP"); else mat.DisableKeyword("_NORMALMAP");
            var glow = Pick(textures, null, "_EmissiveColorMap", "_EmissionMap");
            var glowColor = Pick(colors, Color.black, "_EmissiveColor", "_EmissionColor");
            if (glow != null || glowColor.maxColorComponent > 0.01f)
            {
                mat.EnableKeyword("_EMISSION");
                mat.SetTexture("_EmissionMap", glow);
                mat.SetColor("_EmissionColor", glow != null && glowColor.maxColorComponent <= 0.01f ? Color.white : glowColor);
            }
            mat.SetFloat("_Metallic", Mathf.Min(Pick(floats, 0f, "_Metallic"), 0.3f));
            mat.SetFloat("_Glossiness", Mathf.Clamp(Pick(floats, 0.4f, "_Smoothness", "_Glossiness"), 0f, 0.6f));
            // See-through glass (car windows) stays see-through.
            if (Pick(floats, 0f, "_SurfaceType", "_Surface") > 0.5f || mat.color.a < 0.95f)
            {
                mat.SetFloat("_Mode", 3f);
                mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                mat.SetInt("_ZWrite", 0);
                mat.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                mat.renderQueue = 3000;
            }
        }

        static void Read(SerializedProperty list, System.Action<SerializedProperty> each)
        {
            if (list == null || !list.isArray) return;
            for (int i = 0; i < list.arraySize; i++) each(list.GetArrayElementAtIndex(i));
        }

        static T Pick<T>(Dictionary<string, T> values, T fallback, params string[] names)
        {
            foreach (var n in names)
                if (values.TryGetValue(n, out var v) && v != null) return v;
            return fallback;
        }
    }
}
