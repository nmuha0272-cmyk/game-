using UnityEngine;

// Starts everything. You don't need to set up a scene: press Play in any
// scene (even an empty one) and this builds the menu, then the chapter.
// Esc pauses (Resume / Back to menu / Quit).
namespace Deepwell
{
    public class SZGame : MonoBehaviour
    {
        public static bool Paused { get; private set; }

        enum Mode { Menu, Playing, Paused }
        Mode _screen = Mode.Menu;
        GameObject _world;
        SZPlayer _player;
        GUIStyle _title, _button, _small, _prompt;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Boot()
        {
            if (FindAnyObjectByType<SZGame>() == null)
                new GameObject("DeepwellGame").AddComponent<SZGame>();
        }

        void Start() => ShowMenu();

        void ShowMenu()
        {
            if (_world) Destroy(_world);
            _screen = Mode.Menu;
            Paused = true;
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        void StartChapter()
        {
            _world = new GameObject("Chapter1");
            var data = SZLevelBuilder.Build("chapter1", _world.transform);
            var spawn = data != null && data.spawns != null && data.spawns.Length > 0 ? data.spawns[0] : null;
            _player = SZPlayer.Spawn(spawn != null ? SZLevelData.V(spawn.p) : new Vector3(0f, 1f, 45f),
                                     spawn != null ? SZLevelData.Q(spawn.r) : Quaternion.identity);
            _player.transform.SetParent(_world.transform);
            Resume();
        }

        void Resume()
        {
            _screen = Mode.Playing;
            Paused = false;
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        void Update()
        {
            if (!Input.GetKeyDown(KeyCode.Escape)) return;
            if (_screen == Mode.Playing)
            {
                _screen = Mode.Paused;
                Paused = true;
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
            else if (_screen == Mode.Paused)
            {
                Resume();
            }
        }

        // ---------------------------------------------------------------- screens

        void Styles()
        {
            if (_title != null) return;
            _title = new GUIStyle(GUI.skin.label) { fontSize = 72, fontStyle = FontStyle.Bold };
            _title.normal.textColor = new Color(0.85f, 0.82f, 0.75f);
            _small = new GUIStyle(GUI.skin.label) { fontSize = 16 };
            _small.normal.textColor = new Color(0.75f, 0.2f, 0.15f);
            _button = new GUIStyle(GUI.skin.button) { fontSize = 26, alignment = TextAnchor.MiddleLeft };
            _prompt = new GUIStyle(GUI.skin.label) { fontSize = 22, alignment = TextAnchor.MiddleCenter };
            _prompt.normal.textColor = Color.white;
        }

        void OnGUI()
        {
            Styles();
            float x = 88f, y = Screen.height * 0.25f;
            if (_screen == Mode.Menu)
            {
                GUI.color = Color.white;
                GUI.DrawTexture(new Rect(0, 0, Screen.width, Screen.height), Texture2D.blackTexture);
                GUI.Label(new Rect(x, y, 900, 90), "DEEPWELL", _title);
                GUI.Label(new Rect(x + 4, y + 90, 900, 30), "LEVEL B  -  SEALED BY ORDER  -  1999", _small);
                if (GUI.Button(new Rect(x, y + 160, 360, 56), "  PLAY CHAPTER 1", _button)) StartChapter();
                if (GUI.Button(new Rect(x, y + 226, 360, 56), "  QUIT", _button)) Application.Quit();
                GUI.Label(new Rect(x, Screen.height - 60, 900, 30),
                    "UNITY VERSION - PHASE U1: walk the whole chapter. Online co-op comes in phase U2.", _small);
            }
            else if (_screen == Mode.Paused)
            {
                GUI.Label(new Rect(x, y, 900, 90), "PAUSED", _title);
                if (GUI.Button(new Rect(x, y + 110, 360, 56), "  RESUME", _button)) Resume();
                if (GUI.Button(new Rect(x, y + 176, 360, 56), "  BACK TO MENU", _button)) ShowMenu();
                if (GUI.Button(new Rect(x, y + 242, 360, 56), "  QUIT", _button)) Application.Quit();
            }
            else if (_player != null)
            {
                // Crosshair dot and the "[E] Open door" prompt.
                GUI.Label(new Rect(Screen.width / 2f - 10, Screen.height / 2f - 14, 20, 28), "·", _prompt);
                if (_player.Target != null)
                    GUI.Label(new Rect(0, Screen.height * 0.6f, Screen.width, 40), _player.Target.Prompt, _prompt);
                GUI.Label(new Rect(20, Screen.height - 40, 400, 30),
                    _player.Flashlight.enabled ? "[F] Flashlight ON" : "[F] Flashlight", _small);
            }
        }
    }
}
