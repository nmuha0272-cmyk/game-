using UnityEditor;
using UnityEngine;

// See the level in the Unity editor without pressing Play:
// Deepwell > Show Level in Scene builds Chapter 1 into the Scene view (the
// level, the lights, the items), with your downloaded assets (Deepwell >
// Asset Slots) where the game puts them. Change a slot's asset, Turn or Size
// and the preview updates by itself, so you can see it right away.
//
// The preview is only for looking: it's never saved into the scene, and it
// goes away while the game is playing (the game builds its own level).
namespace Deepwell.EditorTools
{
    [InitializeOnLoad]
    public static class SZPreview
    {
        const string RootName = "Deepwell Level Preview (only in the editor)";
        const string ShownKey = "Deepwell.PreviewShown";

        static SZPreview()
        {
            EditorApplication.playModeStateChanged += state =>
            {
                // Not in the game: the game builds its own level.
                if (state == PlayModeStateChange.ExitingEditMode) Clear();
                else if (state == PlayModeStateChange.EnteredEditMode && Shown) EditorApplication.delayCall += Build;
            };
            // (After scripts reload, put it back if it was showing.)
            EditorApplication.delayCall += () =>
            {
                if (Shown && !EditorApplication.isPlayingOrWillChangePlaymode && Find() == null) Build();
            };
        }

        static bool Shown
        {
            get => EditorPrefs.GetBool(ShownKey + Application.dataPath, false);
            set => EditorPrefs.SetBool(ShownKey + Application.dataPath, value);
        }

        [MenuItem("Deepwell/Show Level in Scene (preview)", false, 0)]
        public static void Show()
        {
            Shown = true;
            Build();
            // Look at the start: the front of the station, where the team parks.
            var view = SceneView.lastActiveSceneView;
            if (view != null)
            {
                view.pivot = new Vector3(0f, 1.5f, 3f);
                view.rotation = Quaternion.Euler(18f, 160f, 0f);
                view.size = 14f;
                view.Repaint();
            }
        }

        [MenuItem("Deepwell/Hide Level Preview", false, 1)]
        public static void Hide()
        {
            Shown = false;
            Clear();
        }

        // The Asset Slots window calls this when you change something. It waits
        // until you stop changing things for a moment (dragging a slider), then rebuilds.
        static double _rebuildAt = -1;

        public static void RefreshIfShown()
        {
            if (!Shown || EditorApplication.isPlayingOrWillChangePlaymode) return;
            if (_rebuildAt < 0) EditorApplication.update += WaitThenBuild;
            _rebuildAt = EditorApplication.timeSinceStartup + 0.7;
        }

        static void WaitThenBuild()
        {
            if (EditorApplication.timeSinceStartup < _rebuildAt) return;
            EditorApplication.update -= WaitThenBuild;
            _rebuildAt = -1;
            if (Shown && !EditorApplication.isPlayingOrWillChangePlaymode) Build();
        }

        static GameObject Find()
        {
            foreach (var go in Resources.FindObjectsOfTypeAll<GameObject>())
                if (go.name == RootName && go.scene.IsValid()) return go;
            return null;
        }

        static void Clear()
        {
            GameObject old;
            while ((old = Find()) != null) Object.DestroyImmediate(old);
        }

        static void Build()
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) return;
            Clear();
            var json = Resources.Load<TextAsset>("Levels/chapter1");
            if (json == null)
            {
                Debug.LogWarning("Deepwell: Levels/chapter1 is missing from Assets/Resources, so there's nothing to show.");
                return;
            }
            var data = JsonUtility.FromJson<SZLevelData>(json.text);
            var root = new GameObject(RootName) { hideFlags = HideFlags.DontSave };
            try
            {
                SZLevelBuilder.PreviewGeometry("chapter1", root.transform);
                AddLights(data, root.transform);
                AddItems(data, root.transform);
            }
            catch (System.Exception e)
            {
                Debug.LogWarning("Deepwell: part of the preview didn't build (" + e.Message + ").");
            }
            // Nothing in it is saved or selectable by accident.
            foreach (var t in root.GetComponentsInChildren<Transform>(true)) t.gameObject.hideFlags = HideFlags.DontSave;
            SceneView.RepaintAll();
        }

        static void AddLights(SZLevelData data, Transform root)
        {
            if (data.lights == null) return;
            var group = new GameObject("Lights").transform;
            group.SetParent(root, false);
            foreach (var l in data.lights)
            {
                var go = new GameObject("Light");
                go.transform.SetParent(group, false);
                go.transform.SetPositionAndRotation(SZLevelData.V(l.p), SZLevelData.Q(l.r));
                var light = go.AddComponent<Light>();
                light.type = l.spot ? LightType.Spot : LightType.Point;
                light.color = SZLevelData.C(l.color);
                light.intensity = l.energy * 1.5f;
                light.range = l.range;
                if (l.spot) light.spotAngle = l.angle * 2f;
            }
        }

        static void AddItems(SZLevelData data, Transform root)
        {
            if (data.items == null) return;
            var group = new GameObject("Items").transform;
            group.SetParent(root, false);
            foreach (var d in data.items)
            {
                var go = new GameObject("Item " + d.id);
                go.transform.SetParent(group, false);
                go.transform.position = SZLevelData.V(d.p);
                if (SZAssets.Spawn(SZAssets.SlotForItem(d.id), go.transform, onGround: true) == null)
                    SZItemLooks.Build(d, go.transform);
            }
        }
    }
}
