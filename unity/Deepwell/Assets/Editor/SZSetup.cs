using System.IO;
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
        static readonly string[] ModelFiles = { "eli.glb", "frank.glb", "journalist.glb", "engineer.glb", "long_man.glb" };
        const string DoneKey = "Deepwell.SetupDone.v2";

        static SZSetup()
        {
            EditorApplication.delayCall += () =>
            {
                if (EditorApplication.isPlayingOrWillChangePlaymode) return;
                if (EditorPrefs.GetBool(DoneKey + Application.dataPath, false)) return;
                EditorPrefs.SetBool(DoneKey + Application.dataPath, true);
                SetUpEverything();
            };
        }

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

        [MenuItem("Deepwell/Copy Character Models from the Godot Project")]
        public static void CopyCharacterModels()
        {
            // Assets -> Deepwell -> unity -> the Godot project.
            var source = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "..", "..", "assets", "models", "characters"));
            if (!Directory.Exists(source))
            {
                Debug.Log("Deepwell: no Godot character models found at " + source +
                          ". People will look like simple stand-in figures. (Keep the unity folder inside the game folder to get the models.)");
                return;
            }
            Directory.CreateDirectory(ModelsFolder);
            int copied = 0;
            foreach (var file in ModelFiles)
            {
                var from = Path.Combine(source, file);
                var to = Path.Combine(ModelsFolder, file);
                if (!File.Exists(from) || File.Exists(to)) continue;
                File.Copy(from, to);
                copied++;
            }
            if (copied > 0)
            {
                Debug.Log("Deepwell: copied " + copied + " character models. Unity is importing them (this can take a minute).");
                AssetDatabase.Refresh();
            }
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
