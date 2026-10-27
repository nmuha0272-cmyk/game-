using System.IO;
using Deepwell;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

// Sets the project up by itself the first time Unity opens it, so you can
// just press Play:
// - switches colors to Linear (needed for the horror camera look),
// - makes sure the shaders the game builds with get into a built game,
// - creates and opens the Deepwell scene (Assets/Scenes/Deepwell.unity),
// - copies the character models (Eli, Cole, Nora, Walter, the Long Man)
//   from the Godot project next door (../../assets/models/characters).
// Everything is also in the "Deepwell" menu at the top of Unity.
namespace Deepwell.EditorTools
{
    [InitializeOnLoad]
    public static class SZSetup
    {
        const string ScenePath = "Assets/Scenes/Deepwell.unity";
        const string ModelsFolder = "Assets/Resources/Characters";
        const string PropsFolder = "Assets/Resources/Props";
        static readonly string[] ModelFiles = { "eli.glb", "frank.glb", "journalist.glb", "engineer.glb", "long_man.glb" };
        // The uploads the game can show instead of placeholder shapes.
        // (rename -> keeps the slot finder happy: "keycard", "tape reel"...)
        static readonly string[][] PropFiles =
        {
            new[] { "fuse.glb", "fuse.glb" },
            new[] { "tape_reel.glb", "tape_reel.glb" },
            new[] { "control_panel.glb", "control_panel.glb" },
            new[] { "card_a.glb", "keycard.glb" },
        };
        const string DoneKey = "Deepwell.SetupDone.v2";

        static SZSetup()
        {
            EditorApplication.delayCall += () =>
            {
                if (EditorApplication.isPlayingOrWillChangePlaymode) return;
                // Models missing (first open, new machine, a deleted folder) -> copy
                // them again. This used to run only once per project, so a project
                // that lost its models stayed empty (the "models aren't showing" bug).
                if (AnyModelMissing()) CopyCharacterModels();
                if (EditorPrefs.GetBool(DoneKey + Application.dataPath, false)) return;
                EditorPrefs.SetBool(DoneKey + Application.dataPath, true);
                SetUpEverything();
            };
        }

        static bool AnyModelMissing()
        {
            foreach (var file in ModelFiles)
                if (!File.Exists(Path.Combine(ModelsFolder, file))) return true;
            foreach (var pair in PropFiles)
                if (File.Exists(Path.Combine(GodotAssets(), "props", pair[0])) && !File.Exists(Path.Combine(PropsFolder, pair[1])))
                    return true;
            return false;
        }

        // Assets -> Deepwell -> unity -> the Godot project.
        static string GodotAssets() => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "..", "assets", "models"));

        [MenuItem("Deepwell/Set Up Project (run this if something looks wrong)")]
        public static void SetUpEverything()
        {
            SetGraphicsSettings();
            CopyCharacterModels();
            MakeScene();
            Debug.Log("Deepwell: project set up. Press the Play button at the top to start the game.");
        }

        [MenuItem("Deepwell/Open the Deepwell Scene")]
        public static void OpenScene()
        {
            if (File.Exists(ScenePath) && EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
                EditorSceneManager.OpenScene(ScenePath);
        }

        static void SetGraphicsSettings()
        {
            if (PlayerSettings.colorSpace != ColorSpace.Linear)
                PlayerSettings.colorSpace = ColorSpace.Linear;

            // Shaders the scripts look up by name need to be "always included" for a built game.
            var settings = AssetDatabase.LoadAssetAtPath<Object>("ProjectSettings/GraphicsSettings.asset");
            var standard = Shader.Find("Standard");
            if (settings == null || standard == null) return;
            var so = new SerializedObject(settings);
            var list = so.FindProperty("m_AlwaysIncludedShaders");
            if (list == null) return;
            for (int i = 0; i < list.arraySize; i++)
                if (list.GetArrayElementAtIndex(i).objectReferenceValue == standard) return;
            list.InsertArrayElementAtIndex(list.arraySize);
            list.GetArrayElementAtIndex(list.arraySize - 1).objectReferenceValue = standard;
            so.ApplyModifiedProperties();
        }

        [MenuItem("Deepwell/Copy Models from the Godot Project")]
        public static void CopyCharacterModels()
        {
            var source = Path.Combine(GodotAssets(), "characters");
            var props = Path.Combine(GodotAssets(), "props");
            if (!Directory.Exists(source) && !Directory.Exists(props))
            {
                Debug.Log("Deepwell: no Godot models found at " + GodotAssets() +
                          ". People will look like simple stand-in figures. (Keep the unity folder inside the game folder to get the models.)");
                return;
            }
            Directory.CreateDirectory(ModelsFolder);
            Directory.CreateDirectory(PropsFolder);
            int copied = 0;
            foreach (var file in ModelFiles)
            {
                var from = Path.Combine(source, file);
                var to = Path.Combine(ModelsFolder, file);
                if (!File.Exists(from) || File.Exists(to)) continue;
                File.Copy(from, to);
                copied++;
            }
            foreach (var pair in PropFiles)
            {
                var from = Path.Combine(props, pair[0]);
                var to = Path.Combine(PropsFolder, pair[1]);
                if (!File.Exists(from) || File.Exists(to)) continue;
                File.Copy(from, to);
                copied++;
            }
            if (copied > 0)
            {
                Debug.Log("Deepwell: copied " + copied + " models. Unity is importing them (this can take a minute).");
                AssetDatabase.Refresh();
            }
        }

        // A quick answer to "why isn't it showing?": what's in the folders, and
        // which asset slots have a model and which still use the placeholder.
        [MenuItem("Deepwell/Check Models and Assets")]
        public static void CheckModelsAndAssets()
        {
            var report = new System.Text.StringBuilder("Deepwell models and assets:\n");
            foreach (var file in ModelFiles)
                report.Append("  character ").Append(file).Append(File.Exists(Path.Combine(ModelsFolder, file)) ? "  OK\n" : "  MISSING\n");
            foreach (var pair in PropFiles)
                report.Append("  prop ").Append(pair[1]).Append(File.Exists(Path.Combine(PropsFolder, pair[1])) ? "  OK\n" : "  missing (placeholder is used)\n");
            var slots = SZAssetSlotsTools.Load(create: false);
            if (slots != null)
            {
                int filled = 0;
                foreach (var slot in slots.slots) if (slot.prefab != null) filled++;
                report.Append("  asset slots filled: ").Append(filled).Append(" / ").Append(slots.slots.Count).Append('\n');
                foreach (var info in SZAssetSlots.Info)
                {
                    var slot = slots.Find(info.id);
                    report.Append("    ").Append(info.label).Append(": ")
                          .Append(slot != null && slot.prefab != null ? slot.prefab.name : "placeholder").Append('\n');
                }
            }
            Debug.Log(report.ToString());
        }

        static void MakeScene()
        {
            if (!File.Exists(ScenePath))
            {
                if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
                Directory.CreateDirectory(Path.GetDirectoryName(ScenePath));
                // An almost empty scene: a camera for the menu. The game builds everything else when you press Play.
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                var cam = new GameObject("Main Camera");
                cam.tag = "MainCamera";
                var camera = cam.AddComponent<Camera>();
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = Color.black;
                cam.AddComponent<AudioListener>();
                EditorSceneManager.SaveScene(scene, ScenePath);
            }
            else if (EditorSceneManager.GetActiveScene().path != ScenePath)
            {
                if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
                EditorSceneManager.OpenScene(ScenePath);
            }
            // Put it first in File > Build Profiles so a built game starts with it.
            var scenes = EditorBuildSettings.scenes;
            foreach (var s in scenes)
                if (s.path == ScenePath) return;
            var list = new System.Collections.Generic.List<EditorBuildSettingsScene> { new EditorBuildSettingsScene(ScenePath, true) };
            list.AddRange(scenes);
            EditorBuildSettings.scenes = list.ToArray();
        }
    }
}
