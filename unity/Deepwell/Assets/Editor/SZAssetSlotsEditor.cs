using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEngine;

// Puts downloaded assets where they belong, by themselves.
// When you import something (for example from the Unity Asset Store), every
// new prefab or model is checked by name: "Glock_17" goes in the PISTOL slot,
// "FirstAidKit" in MEDKIT, "Flashlight_01" in FLASHLIGHT, and so on. Only
// empty slots are filled, so nothing you picked yourself gets replaced.
// The Console says what went where.
//
// Deepwell > Asset Slots opens a window to see every slot, drag a different
// asset in, turn it, change its size, or clear it (back to the placeholder).
namespace Deepwell.EditorTools
{
    public class SZAssetSlotsAutoFill : AssetPostprocessor
    {
        static void OnPostprocessAllAssets(string[] imported, string[] deleted, string[] moved, string[] movedFrom)
        {
            // HDRP/URP materials would be pink in this project: make them normal ones.
            var materials = imported.Where(p => p.EndsWith(".mat", System.StringComparison.OrdinalIgnoreCase)).ToList();
            if (materials.Count > 0) EditorApplication.delayCall += () => SZFixPink.Fix(materials);
            var candidates = imported.Where(SZAssetSlotsTools.IsCandidate).ToList();
            if (candidates.Count == 0) return;
            // Wait until the import is finished before loading the new assets.
            EditorApplication.delayCall += () => SZAssetSlotsTools.AutoFill(candidates, quietIfNothing: true);
        }
    }

    public static class SZAssetSlotsTools
    {
        public const string SlotsPath = "Assets/Resources/SZAssetSlots.asset";

        // Our own files never go in a slot.
        static readonly string[] SkipFolders =
        {
            "Assets/Resources/Levels/", "Assets/Resources/Characters/", "Assets/Resources/Audio/",
            "Assets/Resources/Shaders/", "Assets/Resources/Textures/", "Assets/Scripts/", "Assets/Editor/", "Assets/Scenes/",
        };

        public static bool IsCandidate(string path)
        {
            var ext = Path.GetExtension(path).ToLowerInvariant();
            if (ext != ".prefab" && ext != ".fbx" && ext != ".obj" && ext != ".glb" && ext != ".gltf" && ext != ".blend") return false;
            return !SkipFolders.Any(f => path.StartsWith(f));
        }

        public static SZAssetSlots Load(bool create)
        {
            var slots = AssetDatabase.LoadAssetAtPath<SZAssetSlots>(SlotsPath);
            if (slots == null && create)
            {
                Directory.CreateDirectory("Assets/Resources");
                slots = ScriptableObject.CreateInstance<SZAssetSlots>();
                AssetDatabase.CreateAsset(slots, SlotsPath);
            }
            if (slots != null)
            {
                // Make sure every slot exists.
                foreach (var info in SZAssetSlots.Info)
                    if (slots.Find(info.id) == null) slots.slots.Add(new SZAssetSlots.Slot { id = info.id });
            }
            return slots;
        }

        // "Glock17_LowPoly" -> " glock 17 low poly ", so words can be matched whole.
        public static string Words(string name)
        {
            var sb = new StringBuilder(" ");
            char prev = ' ';
            foreach (var c in name)
            {
                bool split = (char.IsUpper(c) && char.IsLower(prev)) || (char.IsDigit(c) != char.IsDigit(prev) && char.IsLetterOrDigit(prev));
                if (split) sb.Append(' ');
                sb.Append(char.IsLetterOrDigit(c) ? char.ToLowerInvariant(c) : ' ');
                prev = c;
            }
            sb.Append(' ');
            return System.Text.RegularExpressions.Regex.Replace(sb.ToString(), " +", " ");
        }

        // Which slot an asset's file name fits (or null). Only the file name
        // counts: a "Magazine" inside a "Pistols" folder is not a pistol.
        public static string SlotFor(string path)
        {
            var text = Words(Path.GetFileNameWithoutExtension(path));
            foreach (var info in SZAssetSlots.Info)
                if (info.words.Any(w => text.Contains(" " + w + " ") || text.Contains(" " + w.Replace(" ", "") + " ")))
                {
                    // "car battery" must not land in "battery" or in "car".
                    if (info.id == "battery" && text.Contains(" car ")) continue;
                    if (info.id == "car" && text.Contains(" battery ")) continue;
                    return info.id;
                }
            return null;
        }

        public static void AutoFill(IEnumerable<string> paths, bool quietIfNothing)
        {
            var slots = Load(create: true);
            var report = new List<string>();
            // Prefabs first: they usually come with their materials set up.
            foreach (var path in paths.OrderBy(p => p.EndsWith(".prefab") ? 0 : 1))
            {
                var id = SlotFor(path);
                if (id == null) continue;
                var slot = slots.Find(id);
                if (slot.prefab != null) continue;  // already filled (by you or earlier)
                var asset = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (asset == null || asset.GetComponentsInChildren<Renderer>(true).Length == 0) continue;
                slot.prefab = asset;
                slot.manual = false;
                report.Add(id.ToUpper() + " <- " + path);
            }
            if (report.Count > 0)
            {
                EditorUtility.SetDirty(slots);
                AssetDatabase.SaveAssets();
                Debug.Log("Deepwell: put downloaded assets in their slots:\n  " + string.Join("\n  ", report) +
                          "\n(Deepwell > Asset Slots to change any of them.)");
            }
            else if (!quietIfNothing)
            {
                Debug.Log("Deepwell: no new assets matched an empty slot.");
            }
        }

        public static void AutoFillWholeProject()
        {
            var paths = AssetDatabase.GetAllAssetPaths().Where(p => p.StartsWith("Assets/") && IsCandidate(p));
            AutoFill(paths, quietIfNothing: false);
        }
    }

    public class SZAssetSlotsWindow : EditorWindow
    {
        Vector2 _scroll;

        [MenuItem("Deepwell/Asset Slots (downloaded models)")]
        static void Open() => GetWindow<SZAssetSlotsWindow>("Deepwell Asset Slots");

        void OnGUI()
        {
            var slots = SZAssetSlotsTools.Load(create: true);
            EditorGUILayout.HelpBox(
                "Downloaded assets go in these slots by themselves (by their name). Drag a prefab or model onto a slot to pick one yourself. " +
                "Empty slots use the game's simple placeholder shapes. Turn = rotation if it faces the wrong way.", MessageType.Info);
            using (new EditorGUILayout.HorizontalScope())
            {
                if (GUILayout.Button("Find assets in my project now")) SZAssetSlotsTools.AutoFillWholeProject();
                if (GUILayout.Button("Clear all slots") &&
                    EditorUtility.DisplayDialog("Clear all slots?", "Every slot goes back to the placeholder shape.", "Clear", "Cancel"))
                {
                    foreach (var s in slots.slots) { s.prefab = null; s.manual = false; }
                    EditorUtility.SetDirty(slots);
                }
            }
            EditorGUILayout.Space();
            _scroll = EditorGUILayout.BeginScrollView(_scroll);
            foreach (var info in SZAssetSlots.Info)
            {
                var slot = slots.Find(info.id);
                using (new EditorGUILayout.HorizontalScope())
                {
                    EditorGUILayout.LabelField(info.label, GUILayout.Width(260));
                    EditorGUI.BeginChangeCheck();
                    var picked = (GameObject)EditorGUILayout.ObjectField(slot.prefab, typeof(GameObject), false);
                    if (EditorGUI.EndChangeCheck())
                    {
                        slot.prefab = picked;
                        slot.manual = picked != null;
                        EditorUtility.SetDirty(slots);
                    }
                    if (GUILayout.Button("Clear", GUILayout.Width(50)))
                    {
                        slot.prefab = null;
                        slot.manual = false;
                        EditorUtility.SetDirty(slots);
                    }
                }
                if (slot.prefab != null)
                {
                    EditorGUI.indentLevel++;
                    EditorGUI.BeginChangeCheck();
                    slot.rotation = EditorGUILayout.Vector3Field("Turn (degrees)", slot.rotation);
                    slot.sizeMultiplier = EditorGUILayout.Slider("Size", slot.sizeMultiplier, 0.2f, 3f);
                    if (EditorGUI.EndChangeCheck()) EditorUtility.SetDirty(slots);
                    EditorGUI.indentLevel--;
                }
            }
            EditorGUILayout.EndScrollView();
            if (GUI.changed) AssetDatabase.SaveAssets();
        }
    }
}
