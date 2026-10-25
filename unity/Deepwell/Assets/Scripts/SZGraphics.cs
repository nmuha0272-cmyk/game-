using System.Collections.Generic;
using UnityEngine;

// How the game looks: quality presets (shadows, anti-aliasing, how many
// lights), the camera effect (SZPostEffect: glow, film look, grain,
// vignette) and simple materials for things the scripts build.
namespace Deepwell
{
    public static class SZGraphics
    {
        public static readonly string[] QualityNames = { "LOW", "MEDIUM", "HIGH" };
        public static int Quality { get; private set; } = 2;

        public static void SetQuality(int level)
        {
            Quality = Mathf.Clamp(level, 0, 2);
            PlayerPrefs.SetInt("sz_quality", Quality);
            QualitySettings.shadows = Quality == 0 ? ShadowQuality.HardOnly : ShadowQuality.All;
            QualitySettings.shadowResolution = Quality == 2 ? ShadowResolution.VeryHigh : Quality == 1 ? ShadowResolution.High : ShadowResolution.Medium;
            QualitySettings.shadowDistance = Quality == 2 ? 45f : Quality == 1 ? 30f : 18f;
            QualitySettings.shadowCascades = Quality == 0 ? 1 : 2;
            QualitySettings.pixelLightCount = Quality == 2 ? 12 : Quality == 1 ? 8 : 4;
            QualitySettings.antiAliasing = Quality == 2 ? 4 : Quality == 1 ? 2 : 0;
            QualitySettings.anisotropicFiltering = AnisotropicFiltering.ForceEnable;
            QualitySettings.softParticles = Quality > 0;
            QualitySettings.vSyncCount = 1;
            foreach (var fx in Object.FindObjectsByType<SZPostEffect>(FindObjectsSortMode.None))
                fx.enabled = Quality > 0;
        }

        public static void LoadQuality() => SetQuality(PlayerPrefs.GetInt("sz_quality", 2));

        // Sets up a player camera for the horror look.
        public static void SetupCamera(Camera cam)
        {
            cam.allowHDR = true;
            cam.allowMSAA = true;
            cam.renderingPath = RenderingPath.Forward;
            var fx = cam.gameObject.AddComponent<SZPostEffect>();
            fx.enabled = Quality > 0;
        }

        // Shiny surfaces reflect the sky by default, and Unity's default sky is bright
        // grey-blue, so everything looked silver. Reflect a near-black night instead.
        static Cubemap _darkSky;

        public static void DarkReflections(Color sky)
        {
            if (_darkSky == null)
            {
                _darkSky = new Cubemap(8, TextureFormat.RGBA32, false) { name = "DarkNight" };
                var pixels = new Color[64];
                for (int i = 0; i < pixels.Length; i++) pixels[i] = sky;
                foreach (CubemapFace face in new[] { CubemapFace.PositiveX, CubemapFace.NegativeX, CubemapFace.PositiveY,
                                                     CubemapFace.NegativeY, CubemapFace.PositiveZ, CubemapFace.NegativeZ })
                    _darkSky.SetPixels(pixels, face);
                _darkSky.Apply();
            }
            RenderSettings.defaultReflectionMode = UnityEngine.Rendering.DefaultReflectionMode.Custom;
#if UNITY_2022_1_OR_NEWER
            RenderSettings.customReflectionTexture = _darkSky;
#else
            RenderSettings.customReflection = _darkSky;
#endif
            RenderSettings.reflectionIntensity = 1f;
            DynamicGI.UpdateEnvironment();
        }

        // Imported models (the level, the characters) often say "metal" in their
        // files; Unity draws that as shiny chrome ("silver"). This turns it down
        // on the copies the game uses (the model files stay exactly as they are).
        public static void NotSoShiny(GameObject root, float maxMetal = 0.1f)
        {
            var done = new HashSet<Material>();
            foreach (var r in root.GetComponentsInChildren<Renderer>(true))
            {
                var mats = r.materials;  // copies, only for this game
                foreach (var m in mats)
                {
                    if (m == null || !done.Add(m)) continue;
                    foreach (var prop in new[] { "_Metallic", "metallicFactor" })
                        if (m.HasProperty(prop)) m.SetFloat(prop, Mathf.Min(m.GetFloat(prop), maxMetal));
                    if (m.HasProperty("_Glossiness")) m.SetFloat("_Glossiness", Mathf.Min(m.GetFloat("_Glossiness"), 0.5f));
                    if (m.HasProperty("_GlossMapScale")) m.SetFloat("_GlossMapScale", Mathf.Min(m.GetFloat("_GlossMapScale"), 0.5f));
                }
                r.materials = mats;
            }
        }

        // Store assets made for HDRP or URP show up pink here (this project uses
        // the built-in renderer). This swaps each pink material for a Standard
        // one with the same picture, bumps and color, so they look right.
        public static void FixPink(GameObject root)
        {
            var standard = Shader.Find("Standard");
            if (standard == null) return;
            var made = new Dictionary<Material, Material>();
            foreach (var r in root.GetComponentsInChildren<Renderer>(true))
            {
                var mats = r.sharedMaterials;
                bool changed = false;
                for (int i = 0; i < mats.Length; i++)
                {
                    var m = mats[i];
                    if (m == null || !NeedsFix(m)) continue;
                    if (m.shader != null && m.shader.name.Contains("Terrain")) continue;  // (ground: the editor fix handles it)
                    if (!made.TryGetValue(m, out var fixedMat)) made[m] = fixedMat = ToStandard(m, standard);
                    mats[i] = fixedMat;
                    changed = true;
                }
                if (changed) r.sharedMaterials = mats;
            }
        }

        static bool NeedsFix(Material m)
        {
            var sh = m.shader;
            if (sh == null || !sh.isSupported) return true;
            var name = sh.name;
            return name.StartsWith("HDRP/") || name.StartsWith("Universal Render Pipeline/") || name.StartsWith("Shader Graphs/")
                   || name.Contains("InternalErrorShader");
        }

        static Material ToStandard(Material old, Shader standard)
        {
            var names = new HashSet<string>();
            try { foreach (var n in old.GetTexturePropertyNames()) names.Add(n); } catch { }

            var mat = new Material(standard) { name = old.name + " (fixed)" };
            mat.color = Col(old, "_BaseColor", "_Color") ?? Color.white;
            var main = Tex(old, names, "_BaseColorMap", "_BaseMap", "_MainTex", "_Albedo", "_AlbedoMap");
            if (main != null) mat.mainTexture = main;
            var normal = Tex(old, names, "_NormalMap", "_BumpMap");
            if (normal != null)
            {
                mat.SetTexture("_BumpMap", normal);
                mat.EnableKeyword("_NORMALMAP");
            }
            var glow = Tex(old, names, "_EmissiveColorMap", "_EmissionMap");
            var glowColor = Col(old, "_EmissiveColor", "_EmissionColor");
            if (glow != null || (glowColor.HasValue && glowColor.Value.maxColorComponent > 0.01f))
            {
                mat.EnableKeyword("_EMISSION");
                if (glow != null) mat.SetTexture("_EmissionMap", glow);
                mat.SetColor("_EmissionColor", glowColor ?? Color.white);
            }
            mat.SetFloat("_Metallic", Mathf.Min(Num(old, "_Metallic") ?? 0f, 0.3f));
            mat.SetFloat("_Glossiness", Mathf.Clamp(Num(old, "_Smoothness", "_Glossiness") ?? 0.4f, 0f, 0.6f));
            // See-through glass (car windows): keep it see-through.
            bool clear = (Num(old, "_SurfaceType", "_Surface") ?? 0f) > 0.5f || mat.color.a < 0.95f;
            if (clear)
            {
                mat.SetFloat("_Mode", 3f);
                mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                mat.SetInt("_ZWrite", 0);
                mat.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                mat.renderQueue = 3000;
            }
            return mat;
        }

        static Texture Tex(Material m, HashSet<string> names, params string[] props)
        {
            foreach (var p in props)
                if (names.Contains(p))
                    try { var t = m.GetTexture(p); if (t != null) return t; } catch { }
            return null;
        }

        static Color? Col(Material m, params string[] props)
        {
            foreach (var p in props)
                try { if (m.HasProperty(p)) return m.GetColor(p); } catch { }
            return null;
        }

        static float? Num(Material m, params string[] props)
        {
            foreach (var p in props)
                try { if (m.HasProperty(p)) return m.GetFloat(p); } catch { }
            return null;
        }

        // A plain lit material (works in the built-in renderer).
        public static Material Lit(Color color, float smoothness = 0.3f, Color? glow = null)
        {
            var mat = new Material(Shader.Find("Standard"));
            mat.color = color;
            mat.SetFloat("_Glossiness", smoothness);
            if (glow.HasValue)
            {
                mat.EnableKeyword("_EMISSION");
                mat.SetColor("_EmissionColor", glow.Value);
                mat.globalIlluminationFlags = MaterialGlobalIlluminationFlags.RealtimeEmissive;
            }
            return mat;
        }
    }

    // The camera effect. Other scripts can flash the screen or show damage.
    [RequireComponent(typeof(Camera))]
    public class SZPostEffect : MonoBehaviour
    {
        public float exposure = 1.25f;
        public float bloomStrength = 0.9f;
        public float bloomThreshold = 0.85f;
        public float vignette = 0.75f;
        public float grain = 0.06f;
        public float fringe = 0.004f;
        public float saturation = 0.92f;
        public Color tint = new Color(0.98f, 0.98f, 1.0f);

        // 0..1, fade by themselves.
        public static float Flash, Damage;

        Material _mat;
        static readonly int MainTex = Shader.PropertyToID("_MainTex");

        void OnEnable()
        {
            var shader = Resources.Load<Shader>("Shaders/SZHorrorPost");
            if (shader == null || !shader.isSupported)
            {
                Debug.LogWarning("Deepwell: the camera effect shader didn't load, so it's off.");
                enabled = false;
                return;
            }
            _mat = new Material(shader) { hideFlags = HideFlags.HideAndDontSave };
        }

        void OnDisable()
        {
            if (_mat) Destroy(_mat);
            _mat = null;
        }

        void Update()
        {
            Flash = Mathf.MoveTowards(Flash, 0f, Time.unscaledDeltaTime * 2.5f);
            Damage = Mathf.MoveTowards(Damage, 0f, Time.unscaledDeltaTime * 0.5f);
        }

        void OnRenderImage(RenderTexture src, RenderTexture dst)
        {
            if (_mat == null)
            {
                Graphics.Blit(src, dst);
                return;
            }
            // Bloom: the bright parts at quarter size, blurred a few times.
            int w = Mathf.Max(src.width / 4, 1), h = Mathf.Max(src.height / 4, 1);
            var format = src.format;
            var a = RenderTexture.GetTemporary(w, h, 0, format);
            var b = RenderTexture.GetTemporary(w, h, 0, format);
            _mat.SetFloat("_BloomThreshold", bloomThreshold);
            Graphics.Blit(src, a, _mat, 1);
            for (int i = 0; i < 3; i++)
            {
                Graphics.Blit(a, b, _mat, 2);
                Graphics.Blit(b, a, _mat, 2);
            }

            _mat.SetTexture("_BloomTex", a);
            _mat.SetFloat("_Exposure", exposure);
            _mat.SetFloat("_BloomStrength", bloomStrength);
            _mat.SetFloat("_Vignette", vignette);
            _mat.SetFloat("_Grain", grain);
            _mat.SetFloat("_Fringe", fringe);
            _mat.SetFloat("_Saturation", saturation);
            _mat.SetColor("_Tint", tint);
            _mat.SetFloat("_Seed", Random.value * 100f);
            _mat.SetFloat("_Flash", Flash);
            _mat.SetFloat("_Damage", Damage);
            Graphics.Blit(src, dst, _mat, 0);

            RenderTexture.ReleaseTemporary(a);
            RenderTexture.ReleaseTemporary(b);
        }
    }
}
