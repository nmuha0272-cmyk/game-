using System.Collections.Generic;
using UnityEngine;

// Pictures of items for the inventory, like Resident Evil 4's case: each
// item's model (a downloaded one from Asset Slots, or the stand-in shape) is
// photographed once by a little camera far below the level, in soft grey
// light, and the picture is kept. Long guns get a wide picture, and so on
// (the item's size in the case).
namespace Deepwell
{
    public class SZIcons : MonoBehaviour
    {
        static SZIcons _instance;
        static readonly Dictionary<string, Texture2D> Done = new Dictionary<string, Texture2D>();
        static readonly Queue<ItemData> Waiting = new Queue<ItemData>();
        static readonly HashSet<string> Queued = new HashSet<string>();
        const int CellPixels = 96;

        // The picture for an item (null until it's been taken; it's ready a frame later).
        public static Texture2D Get(ItemData d)
        {
            if (d == null) return null;
            if (Done.TryGetValue(d.id, out var tex)) return tex;
            if (Queued.Add(d.id))
            {
                Waiting.Enqueue(d);
                if (_instance == null) _instance = new GameObject("ItemIcons").AddComponent<SZIcons>();
            }
            return null;
        }

        Camera _cam;
        Light _key, _fill;
        Transform _stage;

        void Awake()
        {
            DontDestroyOnLoad(gameObject);
            transform.position = new Vector3(0f, -2000f, 0f);  // far from everything
            _stage = new GameObject("Stage").transform;
            _stage.SetParent(transform, false);
            _cam = new GameObject("IconCamera").AddComponent<Camera>();
            _cam.transform.SetParent(transform, false);
            _cam.orthographic = true;
            _cam.clearFlags = CameraClearFlags.SolidColor;
            _cam.backgroundColor = new Color(0f, 0f, 0f, 0f);
            _cam.nearClipPlane = 0.01f;
            _cam.farClipPlane = 20f;
            _cam.enabled = false;
            _key = MakeLight(new Vector3(-2f, 3f, -3f), 2.2f);
            _fill = MakeLight(new Vector3(3f, 1f, -2f), 1.0f);
        }

        Light MakeLight(Vector3 at, float strength)
        {
            var l = new GameObject("IconLight").AddComponent<Light>();
            l.transform.SetParent(transform, false);
            l.transform.localPosition = at;
            l.type = LightType.Point;
            l.range = 15f;
            l.intensity = strength;
            l.color = new Color(0.92f, 0.93f, 0.95f);
            return l;
        }

        void LateUpdate()
        {
            // One picture per frame, so nothing stutters.
            if (Waiting.Count == 0) return;
            var d = Waiting.Dequeue();
            Done[d.id] = Take(d);
        }

        Texture2D Take(ItemData d)
        {
            var size = SZInventory.SizeOf(d.id);
            int w = CellPixels * size.x, h = CellPixels * size.y;
            var holder = new GameObject("Item");
            holder.transform.SetParent(_stage, false);
            // Lay it on its side, pointing right, like in the case.
            holder.transform.localRotation = Quaternion.Euler(0f, 90f, 0f) * Quaternion.Euler(-12f, 0f, 0f);
            if (SZAssets.Spawn(SZAssets.SlotForItem(d.id), holder.transform, onGround: false) == null)
                SZItemLooks.Build(d, holder.transform);
            if (size.y > size.x && !d.id.StartsWith("weapon_")) holder.transform.localRotation = Quaternion.Euler(-20f, 25f, 0f);

            var renderers = holder.GetComponentsInChildren<Renderer>();
            var rt = RenderTexture.GetTemporary(w, h, 16, RenderTextureFormat.ARGB32);
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false) { name = "Icon " + d.id };
            if (renderers.Length > 0)
            {
                var b = renderers[0].bounds;
                foreach (var r in renderers) b.Encapsulate(r.bounds);
                float aspect = (float)w / h;
                _cam.aspect = aspect;
                _cam.orthographicSize = Mathf.Max(b.extents.y, b.extents.x / aspect) * 1.15f + 0.001f;
                _cam.transform.position = b.center - Vector3.forward * 5f;
                _cam.transform.rotation = Quaternion.identity;
                _key.transform.position = b.center + new Vector3(-2f, 3f, -3f);
                _fill.transform.position = b.center + new Vector3(3f, 1f, -2f);
                _cam.targetTexture = rt;
                var oldFog = RenderSettings.fog;
                RenderSettings.fog = false;
                _cam.Render();
                RenderSettings.fog = oldFog;
                var old = RenderTexture.active;
                RenderTexture.active = rt;
                tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
                tex.Apply();
                RenderTexture.active = old;
                _cam.targetTexture = null;
            }
            RenderTexture.ReleaseTemporary(rt);
            Destroy(holder);
            return tex;
        }
    }
}
