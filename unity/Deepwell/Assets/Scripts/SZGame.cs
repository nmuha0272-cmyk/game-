using System.Collections;
using UnityEngine;

// Starts everything. You don't need to set up a scene: press Play in any
// scene (even an empty one) and this builds the menu, then the chapter.
//   Menu: PLAY SOLO, HOST ONLINE, JOIN ONLINE, SETTINGS, QUIT.
//   Then pick your character (Eli, Cole, Nora or Walter).
//   In the game: Esc pauses, Tab shows your bag.
namespace Deepwell
{
    public class SZGame : MonoBehaviour
    {
        public static SZGame Instance { get; private set; }
        public static bool Paused { get; private set; }
        // Also true on the frame a note closes, so the same E press doesn't open it again.
        public static bool Reading => Instance != null && (Instance._readTitle != null || Instance._closedFrame == Time.frameCount);

        enum Mode { Menu, Characters, Join, Connecting, Loading, Settings, Playing, Paused }
        enum Plan { Solo, Host, Join }

        Mode _screen = Mode.Menu;
        Mode _settingsBack = Mode.Menu;
        Plan _plan;
        SZCharacter _character;
        string _playerName = "";
        string _address = "";
        string _status = "";
        SZWorld _world;

        string _say;
        float _sayUntil;
        string _readTitle, _readText;
        Vector2 _readScroll;
        int _openedFrame = -1, _closedFrame = -1;
        Camera _sceneCamera;
        float _hostHintUntil;

        GUIStyle _title, _sub, _button, _small, _prompt, _say2, _card, _cardTitle, _paperTitle, _paperText, _field;
        Texture2D _white;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Boot()
        {
            if (FindAnyObjectByType<SZGame>() == null)
                new GameObject("DeepwellGame").AddComponent<SZGame>();
        }

        void Awake()
        {
            Instance = this;
            SZGraphics.LoadQuality();
            SZPlayer.MouseSensitivity = PlayerPrefs.GetFloat("sz_mouse", 2f);
            SZPlayer.FlashlightBrightness = PlayerPrefs.GetFloat("sz_flashlight", 1f);
            AudioListener.volume = PlayerPrefs.GetFloat("sz_volume", 0.9f);
            _playerName = PlayerPrefs.GetString("sz_name", "");
            _address = PlayerPrefs.GetString("sz_address", "");
            var net = SZNet.Ensure();
            net.Joined += _ => StartCoroutine(StartChapter());
            net.Failed += reason =>
            {
                ShowMenu();
                _status = reason;
            };
        }

        void Start()
        {
            // The scene's own camera shows the menu; the player brings their own in the game.
            _sceneCamera = Camera.main;
            if (_sceneCamera != null)
            {
                _sceneCamera.clearFlags = CameraClearFlags.SolidColor;
                _sceneCamera.backgroundColor = Color.black;
            }
            ShowMenu();
        }

        // ---------------------------------------------------------------- what others call

        public void Say(string text, float seconds)
        {
            _say = text;
            _sayUntil = Time.time + seconds;
        }

        public void Read(string title, string text)
        {
            _readTitle = string.IsNullOrEmpty(title) ? "Note" : title;
            _readText = text;
            _readScroll = Vector2.zero;
            _openedFrame = Time.frameCount;
            SZAudio.Play2D("ping", 0.3f);
        }

        // ---------------------------------------------------------------- flow

        void ShowMenu()
        {
            if (_world) Destroy(_world.gameObject);
            _world = null;
            SZNet.Instance?.Stop();
            _screen = Mode.Menu;
            _readTitle = null;
            Paused = true;
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
            if (_sceneCamera != null) _sceneCamera.gameObject.SetActive(true);
        }

        void Go()
        {
            PlayerPrefs.SetString("sz_name", _playerName);
            _status = "";
            if (_plan == Plan.Solo)
            {
                StartCoroutine(StartChapter());
            }
            else if (_plan == Plan.Host)
            {
                if (SZNet.Instance.Host(out var error))
                {
                    _hostHintUntil = Time.time + 25f;
                    StartCoroutine(StartChapter());
                }
                else
                {
                    _status = error;
                    _screen = Mode.Menu;
                }
            }
            else
            {
                _screen = Mode.Join;
            }
        }

        IEnumerator StartChapter()
        {
            _screen = Mode.Loading;
            yield return null;  // draw "Loading..." first; building takes a few seconds
            yield return null;
            if (_sceneCamera != null) _sceneCamera.gameObject.SetActive(false);
            _world = SZWorld.Create("chapter1", _character, _playerName);
            if (_world.Local == null)
            {
                ShowMenu();
                _status = "The level didn't load. Check the Console for a red error.";
                yield break;
            }
            Say("CHAPTER 1  -  THE SURFACE", 4f);
            Resume();
        }

        void Resume()
        {
            _screen = Mode.Playing;
            Paused = false;
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        void Pause()
        {
            _screen = Mode.Paused;
            // Online the game keeps going (the others are still playing); solo it stops.
            Paused = true;
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        void Update()
        {
            Time.timeScale = _screen == Mode.Paused && !SZNet.Online ? 0f : 1f;
            if (_screen == Mode.Playing && Reading)
            {
                if ((SZInput.Down(SZKey.E) || SZInput.Down(SZKey.Escape)) && Time.frameCount != _openedFrame)
                {
                    _readTitle = null;
                    _closedFrame = Time.frameCount;
                }
                return;
            }
            if (!SZInput.Down(SZKey.Escape)) return;
            if (_screen == Mode.Playing) Pause();
            else if (_screen == Mode.Paused) Resume();
            else if (_screen == Mode.Settings) CloseSettings();
            else if (_screen == Mode.Characters || _screen == Mode.Join) _screen = Mode.Menu;
        }

        void CloseSettings()
        {
            PlayerPrefs.SetFloat("sz_mouse", SZPlayer.MouseSensitivity);
            PlayerPrefs.SetFloat("sz_flashlight", SZPlayer.FlashlightBrightness);
            PlayerPrefs.SetFloat("sz_volume", AudioListener.volume);
            PlayerPrefs.Save();
            _screen = _settingsBack;
        }

        // ---------------------------------------------------------------- drawing

        void Styles()
        {
            if (_title != null) return;
            _white = Texture2D.whiteTexture;
            _title = new GUIStyle(GUI.skin.label) { fontSize = 84, fontStyle = FontStyle.Bold };
            _title.normal.textColor = new Color(0.86f, 0.83f, 0.76f);
            _sub = new GUIStyle(GUI.skin.label) { fontSize = 17, fontStyle = FontStyle.Bold };
            _sub.normal.textColor = new Color(0.78f, 0.18f, 0.13f);
            _small = new GUIStyle(GUI.skin.label) { fontSize = 16, wordWrap = true };
            _small.normal.textColor = new Color(0.75f, 0.73f, 0.68f);
            _button = new GUIStyle(GUI.skin.button) { fontSize = 24, alignment = TextAnchor.MiddleLeft, padding = new RectOffset(22, 10, 6, 6) };
            _button.normal.background = Solid(new Color(0.06f, 0.06f, 0.07f, 0.92f));
            _button.hover.background = Solid(new Color(0.42f, 0.07f, 0.05f, 0.95f));
            _button.active.background = Solid(new Color(0.6f, 0.1f, 0.06f, 1f));
            _button.normal.textColor = new Color(0.85f, 0.82f, 0.75f);
            _button.hover.textColor = Color.white;
            _button.active.textColor = Color.white;
            _prompt = new GUIStyle(GUI.skin.label) { fontSize = 22, alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold };
            _prompt.normal.textColor = new Color(0.95f, 0.93f, 0.88f);
            _say2 = new GUIStyle(_prompt) { fontSize = 26, wordWrap = true };
            _card = new GUIStyle(GUI.skin.button) { fontSize = 15, alignment = TextAnchor.UpperLeft, wordWrap = true, padding = new RectOffset(14, 14, 54, 10) };
            _card.normal.background = Solid(new Color(0.07f, 0.07f, 0.08f, 0.95f));
            _card.hover.background = Solid(new Color(0.14f, 0.08f, 0.07f, 0.95f));
            _card.normal.textColor = new Color(0.72f, 0.7f, 0.65f);
            _card.hover.textColor = Color.white;
            _cardTitle = new GUIStyle(GUI.skin.label) { fontSize = 22, fontStyle = FontStyle.Bold };
            _paperTitle = new GUIStyle(GUI.skin.label) { fontSize = 28, fontStyle = FontStyle.Bold, wordWrap = true };
            _paperTitle.normal.textColor = new Color(0.15f, 0.12f, 0.1f);
            _paperText = new GUIStyle(GUI.skin.label) { fontSize = 19, wordWrap = true, richText = false };
            _paperText.normal.textColor = new Color(0.18f, 0.15f, 0.12f);
            _field = new GUIStyle(GUI.skin.textField) { fontSize = 24, padding = new RectOffset(12, 12, 8, 8) };
        }

        static Texture2D Solid(Color c)
        {
            var t = new Texture2D(1, 1);
            t.SetPixel(0, 0, c);
            t.Apply();
            return t;
        }

        void Box(Rect r, Color c)
        {
            var old = GUI.color;
            GUI.color = c;
            GUI.DrawTexture(r, _white);
            GUI.color = old;
        }

        void OnGUI()
        {
            Styles();
            switch (_screen)
            {
                case Mode.Menu: DrawMenu(); break;
                case Mode.Characters: DrawCharacters(); break;
                case Mode.Join: DrawJoin(); break;
                case Mode.Connecting: DrawBackdrop(); Center("Connecting..."); break;
                case Mode.Loading: DrawBackdrop(); Center("Loading Chapter 1..."); break;
                case Mode.Settings: if (_world == null) DrawBackdrop(); else Box(Full(), new Color(0, 0, 0, 0.75f)); DrawSettings(); break;
                case Mode.Paused: DrawHud(); DrawPause(); break;
                case Mode.Playing: DrawHud(); break;
            }
        }

        static Rect Full() => new Rect(0, 0, Screen.width, Screen.height);

        void DrawBackdrop()
        {
            Box(Full(), new Color(0.012f, 0.012f, 0.016f));
            // A slow red glow at the bottom, like an emergency light far away.
            float pulse = 0.05f + 0.03f * Mathf.Sin(Time.time * 1.3f);
            for (int i = 0; i < 12; i++)
                Box(new Rect(0, Screen.height * (0.6f + i * 0.035f), Screen.width, Screen.height * 0.035f),
                    new Color(0.5f, 0.04f, 0.02f, pulse * i / 12f));
        }

        void Center(string text)
        {
            GUI.Label(new Rect(0, Screen.height / 2f - 20, Screen.width, 40), text, _prompt);
        }

        void Title(float x, float y)
        {
            // The title shakes a little now and then.
            float shake = Random.value < 0.02f ? Random.Range(-3f, 3f) : 0f;
            GUI.Label(new Rect(x + shake, y, 900, 100), "DEEPWELL", _title);
            GUI.Label(new Rect(x + 6, y + 96, 900, 30), "LEVEL B  -  SEALED BY ORDER  -  1999", _sub);
        }

        void DrawMenu()
        {
            DrawBackdrop();
            float x = 90f, y = Screen.height * 0.18f;
            Title(x, y);
            y += 170f;
            if (GUI.Button(new Rect(x, y, 380, 54), "PLAY SOLO", _button)) { _plan = Plan.Solo; _screen = Mode.Characters; }
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "HOST ONLINE GAME", _button)) { _plan = Plan.Host; _screen = Mode.Characters; }
            if (GUI.Button(new Rect(x, y + 128, 380, 54), "JOIN ONLINE GAME", _button)) { _plan = Plan.Join; _screen = Mode.Characters; }
            if (GUI.Button(new Rect(x, y + 192, 380, 54), "SETTINGS", _button)) { _settingsBack = Mode.Menu; _screen = Mode.Settings; }
            if (GUI.Button(new Rect(x, y + 256, 380, 54), "QUIT", _button)) Application.Quit();
            if (!string.IsNullOrEmpty(_status))
                GUI.Label(new Rect(x, y + 330, 700, 60), _status, _sub);
            GUI.Label(new Rect(x, Screen.height - 50, Screen.width - 2 * x, 30),
                "Unity version: Chapter 1 with items, notes, the Long Man, abilities and online co-op (up to 4). Puzzles come next.", _small);
        }

        void DrawCharacters()
        {
            DrawBackdrop();
            float x = 90f, y = Screen.height * 0.1f;
            GUI.Label(new Rect(x, y, 900, 60), "WHO ARE YOU?", new GUIStyle(_title) { fontSize = 48 });
            GUI.Label(new Rect(x, y + 70, 200, 30), "Your name:", _small);
            _playerName = GUI.TextField(new Rect(x + 110, y + 62, 300, 44), _playerName, 16, _field);
            float w = Mathf.Min(300f, (Screen.width - 2 * x - 3 * 20f) / 4f), h = 260f;
            for (int i = 0; i < 4; i++)
            {
                var r = new Rect(x + i * (w + 20f), y + 140, w, h);
                var c = (SZCharacter)i;
                if (GUI.Button(r, SZCharacters.Abilities[i], _card))
                {
                    _character = c;
                    Go();
                }
                Box(new Rect(r.x, r.y, r.width, 5), SZCharacters.Colors[i]);
                _cardTitle.normal.textColor = SZCharacters.Colors[i];
                GUI.Label(new Rect(r.x + 14, r.y + 10, r.width, 30), SZCharacters.Names[i], _cardTitle);
                GUI.Label(new Rect(r.x + 14, r.y + 34, r.width, 20), SZCharacters.Roles[i].ToUpper(), _sub);
            }
            GUI.Label(new Rect(x, y + 140 + h + 20, 900, 30), "Click a character to start.   Esc = back", _small);
        }

        void DrawJoin()
        {
            DrawBackdrop();
            float x = 90f, y = Screen.height * 0.2f;
            GUI.Label(new Rect(x, y, 900, 60), "JOIN A FRIEND", new GUIStyle(_title) { fontSize = 48 });
            GUI.Label(new Rect(x, y + 80, 900, 50),
                "Type the IP address your friend sees on their screen after they press HOST.", _small);
            _address = GUI.TextField(new Rect(x, y + 130, 380, 48), _address, 64, _field);
            if (GUI.Button(new Rect(x, y + 195, 380, 54), "CONNECT", _button) && _address.Trim().Length > 0)
            {
                PlayerPrefs.SetString("sz_address", _address);
                _screen = Mode.Connecting;
                SZNet.Instance.Join(_address);
            }
            if (GUI.Button(new Rect(x, y + 259, 380, 54), "BACK", _button)) _screen = Mode.Menu;
            GUI.Label(new Rect(x, y + 335, 800, 80),
                "Same Wi-Fi: just type the IP.  Over the internet: the host forwards port 7777 (UDP), or you both use a free virtual-LAN app like Radmin VPN or ZeroTier.", _small);
        }

        void DrawSettings()
        {
            float x = 90f, y = Screen.height * 0.2f;
            GUI.Label(new Rect(x, y, 900, 60), "SETTINGS", new GUIStyle(_title) { fontSize = 48 });
            y += 90f;
            GUI.Label(new Rect(x, y, 260, 30), "Graphics", _small);
            for (int i = 0; i < 3; i++)
            {
                var label = (SZGraphics.Quality == i ? "> " : "") + SZGraphics.QualityNames[i];
                if (GUI.Button(new Rect(x + 260 + i * 130, y - 8, 120, 44), label, _button)) SZGraphics.SetQuality(i);
            }
            y += 60f;
            GUI.Label(new Rect(x, y, 260, 30), "Mouse speed: " + SZPlayer.MouseSensitivity.ToString("0.0"), _small);
            SZPlayer.MouseSensitivity = GUI.HorizontalSlider(new Rect(x + 260, y + 8, 380, 20), SZPlayer.MouseSensitivity, 0.3f, 6f);
            y += 50f;
            GUI.Label(new Rect(x, y, 260, 30), "Flashlight brightness: " + Mathf.RoundToInt(SZPlayer.FlashlightBrightness * 100) + "%", _small);
            SZPlayer.FlashlightBrightness = GUI.HorizontalSlider(new Rect(x + 260, y + 8, 380, 20), SZPlayer.FlashlightBrightness, 0.4f, 2f);
            y += 50f;
            GUI.Label(new Rect(x, y, 260, 30), "Volume: " + Mathf.RoundToInt(AudioListener.volume * 100) + "%", _small);
            AudioListener.volume = GUI.HorizontalSlider(new Rect(x + 260, y + 8, 380, 20), AudioListener.volume, 0f, 1f);
            y += 70f;
            if (GUI.Button(new Rect(x, y, 380, 54), "BACK", _button)) CloseSettings();
        }

        void DrawPause()
        {
            Box(Full(), new Color(0, 0, 0, 0.7f));
            float x = 90f, y = Screen.height * 0.22f;
            GUI.Label(new Rect(x, y, 900, 90), "PAUSED", _title);
            if (SZNet.Online)
                GUI.Label(new Rect(x + 6, y + 92, 900, 30), SZNet.IsHost
                    ? "You're hosting. Friends join with:  " + SZNet.LocalAddresses()
                    : "Online game (the game keeps going while you're paused)", _sub);
            y += 140f;
            if (GUI.Button(new Rect(x, y, 380, 54), "RESUME", _button)) Resume();
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "SETTINGS", _button)) { _settingsBack = Mode.Paused; _screen = Mode.Settings; }
            if (GUI.Button(new Rect(x, y + 128, 380, 54), SZNet.Online ? "LEAVE GAME" : "BACK TO MENU", _button)) ShowMenu();
            if (GUI.Button(new Rect(x, y + 192, 380, 54), "QUIT", _button)) Application.Quit();
            GUI.Label(new Rect(x, y + 270, 900, 120),
                "WASD move   Mouse look   Shift sprint   Ctrl/C crouch   Space jump\n" +
                "F flashlight   E use / pick up   1 battery   2 flare   Q ability   Tab bag", _small);
        }

        void DrawHud()
        {
            if (_world == null || _world.Local == null) return;
            var p = _world.Local;
            float W = Screen.width, H = Screen.height;

            if (p.SenseUntil > Time.time) DrawSense(p);

            if (Reading && _screen == Mode.Playing)
            {
                DrawPaper();
                return;
            }

            // Crosshair and "[E] ..." prompt.
            Box(new Rect(W / 2f - 2, H / 2f - 2, 4, 4), new Color(1, 1, 1, 0.6f));
            if (p.Target != null) Shadowed(new Rect(0, H * 0.58f, W, 36), p.Target.Prompt, _prompt);
            if (p.AbilityPrompt != null) Shadowed(new Rect(0, H * 0.58f + 34, W, 36), p.AbilityPrompt, _prompt);
            if (p.AbilityProgress > 0f)
            {
                Box(new Rect(W / 2f - 100, H * 0.58f + 74, 200, 8), new Color(0, 0, 0, 0.6f));
                Box(new Rect(W / 2f - 100, H * 0.58f + 74, 200 * p.AbilityProgress, 8), new Color(0.9f, 0.7f, 0.2f));
            }

            if (Time.time < _sayUntil && !string.IsNullOrEmpty(_say))
            {
                var c = _say2.normal.textColor;
                c.a = Mathf.Clamp01((_sayUntil - Time.time) * 2f);
                _say2.normal.textColor = c;
                Shadowed(new Rect(W * 0.15f, H * 0.72f, W * 0.7f, 90), _say, _say2);
            }

            // Bottom left: flashlight battery and stamina.
            float x = 24f, y = H - 74f;
            GUI.Label(new Rect(x, y - 4, 140, 24), p.Flashlight.enabled ? "FLASHLIGHT  ON" : "FLASHLIGHT  [F]", _small);
            Bar(new Rect(x + 150, y + 4, 160, 10), p.Battery, p.Battery < 0.15f ? new Color(0.85f, 0.2f, 0.1f) : new Color(0.95f, 0.85f, 0.5f));
            GUI.Label(new Rect(x, y + 22, 140, 24), "STAMINA", _small);
            if (p.Stamina < 0.999f) Bar(new Rect(x + 150, y + 30, 160, 10), p.Stamina, new Color(0.6f, 0.75f, 0.9f));

            // Bottom right: items and ability.
            var inv = p.Inventory;
            string items = "[1] Batteries " + inv.Batteries + "     [2] Flares " + inv.Flares + "     Medkits " + inv.Medkits;
            GUI.Label(new Rect(W - 520, y - 4, 500, 24), items, new GUIStyle(_small) { alignment = TextAnchor.UpperRight });
            string ability = SZCharacters.Abilities[(int)p.Character].Split(':')[0];
            if (p.AbilityCooldown > 0f) ability += "  (" + Mathf.CeilToInt(p.AbilityCooldown) + "s)";
            GUI.Label(new Rect(W - 520, y + 22, 500, 24), ability, new GUIStyle(_sub) { alignment = TextAnchor.UpperRight });

            if (SZNet.IsHost && Time.time < _hostHintUntil)
                Shadowed(new Rect(0, 16, W, 30), "You're hosting. Friends join with:  " + SZNet.LocalAddresses(), _prompt);

            if (SZInput.Held(SZKey.Tab) && _screen == Mode.Playing) DrawBag(inv);
        }

        void DrawBag(SZInventory inv)
        {
            float w = 420f, h = 60f + 26f * Mathf.Max(inv.Bag.Count, 1);
            var r = new Rect(Screen.width / 2f - w / 2f, Screen.height * 0.2f, w, h);
            Box(r, new Color(0.03f, 0.03f, 0.04f, 0.92f));
            GUI.Label(new Rect(r.x + 16, r.y + 10, w, 30), "YOUR BAG", _sub);
            if (inv.Bag.Count == 0) GUI.Label(new Rect(r.x + 16, r.y + 40, w, 26), "(empty)", _small);
            for (int i = 0; i < inv.Bag.Count; i++)
                GUI.Label(new Rect(r.x + 16, r.y + 40 + i * 26, w - 32, 26), "- " + inv.Bag[i].name, _small);
        }

        void DrawPaper()
        {
            float w = Mathf.Min(720f, Screen.width - 60f), h = Screen.height * 0.8f;
            var r = new Rect(Screen.width / 2f - w / 2f, Screen.height * 0.1f, w, h);
            Box(Full(), new Color(0, 0, 0, 0.6f));
            Box(r, new Color(0.86f, 0.82f, 0.71f));
            GUI.Label(new Rect(r.x + 36, r.y + 26, w - 72, 70), _readTitle, _paperTitle);
            float textH = _paperText.CalcHeight(new GUIContent(_readText), w - 96);
            _readScroll = GUI.BeginScrollView(new Rect(r.x + 36, r.y + 100, w - 60, h - 150), _readScroll, new Rect(0, 0, w - 96, textH));
            GUI.Label(new Rect(0, 0, w - 96, textH), _readText, _paperText);
            GUI.EndScrollView();
            GUI.Label(new Rect(r.x, r.yMax - 40, w, 30), "[E] Close", new GUIStyle(_paperText) { alignment = TextAnchor.MiddleCenter, fontStyle = FontStyle.Bold });
        }

        // Eli's Sense: markers on the Long Man and on friends, even through walls.
        void DrawSense(SZPlayer p)
        {
            var cam = p.Camera;
            Box(Full(), new Color(0.1f, 0.15f, 0.4f, 0.08f));
            if (_world.Monster)
                Marker(cam, _world.Monster.transform.position + Vector3.up * 2.6f, "LONG MAN", new Color(1f, 0.2f, 0.15f));
            foreach (var r in _world.Remotes)
                Marker(cam, r.transform.position + Vector3.up * 2f, r.PlayerName, new Color(0.4f, 0.7f, 1f));
        }

        void Marker(Camera cam, Vector3 world, string label, Color color)
        {
            var s = cam.WorldToScreenPoint(world);
            if (s.z <= 0f) return;
            float dist = Vector3.Distance(cam.transform.position, world);
            var r = new Rect(s.x - 100, Screen.height - s.y - 30, 200, 26);
            Box(new Rect(s.x - 6, Screen.height - s.y - 6, 12, 12), color);
            var style = new GUIStyle(_prompt) { fontSize = 16 };
            style.normal.textColor = color;
            GUI.Label(r, label + "  " + Mathf.RoundToInt(dist) + "m", style);
        }

        void Bar(Rect r, float value, Color color)
        {
            Box(r, new Color(0, 0, 0, 0.6f));
            Box(new Rect(r.x, r.y, r.width * Mathf.Clamp01(value), r.height), color);
        }

        void Shadowed(Rect r, string text, GUIStyle style)
        {
            var c = style.normal.textColor;
            style.normal.textColor = new Color(0, 0, 0, c.a * 0.8f);
            GUI.Label(new Rect(r.x + 2, r.y + 2, r.width, r.height), text, style);
            style.normal.textColor = c;
            GUI.Label(r, text, style);
        }
    }
}
