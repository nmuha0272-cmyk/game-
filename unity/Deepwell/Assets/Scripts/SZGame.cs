using System.Collections;
using UnityEngine;

// Starts everything. You don't need to set up a scene: press Play in any
// scene (even an empty one) and this builds the menu, then the chapter.
//   Home screen (SZMenuScene): the car on the forest road, with PLAY SOLO,
//   HOST GAME, JOIN GAME, SETTINGS, QUIT.
//   Then the camera moves into the car to pick your character (Eli, Cole,
//   Nora or Walter), and the car drives up to the station.
//   In the game: Esc pauses, Tab shows your bag.
namespace Deepwell
{
    public class SZGame : MonoBehaviour
    {
        public static SZGame Instance { get; private set; }
        public static bool Paused { get; private set; }
        // Also true on the frame a note closes, so the same E press doesn't open it again.
        public static bool Reading => Instance != null && (Instance._readTitle != null || Instance._closedFrame == Time.frameCount);

        enum Mode { Menu, Characters, Join, Connecting, Talk, Arriving, Loading, Settings, Playing, Paused }
        enum Plan { Solo, Host, Join }

        Mode _screen = Mode.Menu;
        Mode _settingsBack = Mode.Menu;
        Plan _plan;
        SZCharacter _character;
        string _playerName = "";
        string _address = "";
        string _status = "";
        SZWorld _world;
        SZMenuScene _menuScene;

        string _say;
        float _sayUntil;
        string _readTitle, _readText;
        Vector2 _readScroll;
        int _openedFrame = -1, _closedFrame = -1;
        Camera _sceneCamera;
        float _hostHintUntil;
        float _unhoverAt = -1f;

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
            Subtitles = PlayerPrefs.GetInt("sz_subtitles", 1) == 1;
            BigSubtitles = PlayerPrefs.GetInt("sz_big_subtitles", 0) == 1;
            _playerName = PlayerPrefs.GetString("sz_name", "");
            _address = PlayerPrefs.GetString("sz_address", "");
            var net = SZNet.Ensure();
            net.Joined += _ => EnterCar();
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
            if (_sceneCamera != null) _sceneCamera.gameObject.SetActive(false);
            if (_menuScene == null) _menuScene = SZMenuScene.Create();
            _menuScene.BackToMenu();
        }

        // A menu button: Solo and Host go straight into the car; Join asks for the IP first.
        void Go(Plan plan)
        {
            _plan = plan;
            _status = "";
            if (plan == Plan.Solo)
            {
                EnterCar();
            }
            else if (plan == Plan.Host)
            {
                if (SZNet.Instance.Host(out var error))
                {
                    _hostHintUntil = Time.time + 25f;
                    EnterCar();
                }
                else
                {
                    _status = error;
                }
            }
            else
            {
                _screen = Mode.Join;
            }
        }

        // The camera moves into the back seat to pick a character.
        void EnterCar()
        {
            _screen = Mode.Characters;
            _menuScene.EnterSelect();
            _menuScene.Selected = (int)_character;
        }

        void LeaveCar()
        {
            SZNet.Instance.Stop();
            _screen = Mode.Menu;
            _menuScene.BackToMenu();
        }

        // "PLAY AS ...": the team talks in the car while Eli drives, then the car
        // drives up to the station, then the chapter (and the trunk scene there).
        void Confirm()
        {
            if (_menuScene.Selected < 0) return;
            _character = (SZCharacter)_menuScene.Selected;
            PlayerPrefs.SetString("sz_name", _playerName);
            _screen = Mode.Talk;
            _menuScene.StartTalk(Arrive);
        }

        void Arrive()
        {
            _screen = Mode.Arriving;
            _menuScene.StartArrival(() => StartCoroutine(StartChapter()));
        }


        // save: start from a saved game. skipIntro: a friend reloading with the host.
        IEnumerator StartChapter(SZSaveData save = null, bool skipIntro = false)
        {
            _screen = Mode.Loading;
            _readTitle = null;
            _panel = null;
            _invOpen = false;
            _invPicked = null;
            if (_world) Destroy(_world.gameObject);  // (loading during a game: the old one goes first)
            _world = null;
            yield return null;  // draw "Loading..." first; building takes a few seconds
            yield return null;
            if (_sceneCamera != null) _sceneCamera.gameObject.SetActive(false);
            if (_menuScene != null) Destroy(_menuScene.gameObject);
            _menuScene = null;
            if (save != null)
            {
                _character = save.character;
                if (!string.IsNullOrEmpty(save.name)) _playerName = save.name;
            }
            string problem = null;
            try
            {
                _world = SZWorld.Create(save != null ? save.chapter : "chapter1", _character, _playerName, save, skipIntro);
            }
            catch (System.Exception e)
            {
                Debug.LogException(e);
                problem = e.GetType().Name + ": " + e.Message;
            }
            if (problem != null || _world == null || _world.Local == null)
            {
                ShowMenu();
                _status = "THE LEVEL DIDN'T LOAD.  " + (problem ?? "Levels/chapter1 is missing from Assets/Resources.") +
                          "\n(Send a picture of this, or of the red lines in Window > General > Console.)";
                yield break;
            }
            // (The intro cutscene shows "CHAPTER 1 - THE SURFACE".)
            if (SZNet.IsHost) _hostHintUntil = Time.time + 25f;
            Resume();
            if (save != null) Say("Game loaded", 2.5f);
        }

        // ---------------------------------------------------------------- saving

        // The menu's CONTINUE: straight into the saved game (solo, or hosting so friends can join).
        void Continue(bool host)
        {
            var save = SZSave.LoadGame();
            if (save == null)
            {
                _status = "The save couldn't be read. Start a new game.";
                return;
            }
            _plan = host ? Plan.Host : Plan.Solo;
            _status = "";
            if (host && !SZNet.Instance.Host(out var error))
            {
                _status = error;
                return;
            }
            StartCoroutine(StartChapter(save));
        }

        // F5 (or SAVE GAME in the pause menu).
        void QuickSave()
        {
            if (_world == null || _world.Local == null) return;
            if (SZNet.IsClient) { Say("Only the host can save the game.", 2.5f); return; }
            if (SZCutscene.Playing) { Say("You can't save during a cutscene.", 2f); return; }
            Say(SZSave.SaveGame(_world) ? "Game saved" : "The game couldn't be saved.", 2.5f);
            SZAudio.Play2D("ping", 0.4f);
        }

        // F9 (or LOAD LAST SAVE): everyone goes back to the save together.
        void QuickLoad()
        {
            if (SZNet.IsClient) { Say("Only the host can load the game.", 2.5f); return; }
            var save = SZSave.LoadGame();
            if (save == null) { Say("There's no save yet. Press F5 to save.", 2.5f); return; }
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("LOAD"));
            StartCoroutine(StartChapter(save));
        }

        // A friend's computer: the host loaded a save. Rebuild, then the host's
        // summary puts the chapter (and your own saved place) back.
        public void ReloadWithHost()
        {
            StartCoroutine(StartChapter(null, true));
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
            if (_screen == Mode.Playing && _panel != null)
            {
                if (SZInput.Down(SZKey.Escape)) ClosePanel();
                return;
            }
            if (_screen == Mode.Playing && !SZCutscene.Playing && SZInput.Down(SZKey.Tab)) ToggleInventory();
            if (_invOpen && (_screen != Mode.Playing || SZInput.Down(SZKey.Escape)))
            {
                if (_screen == Mode.Playing) ToggleInventory();
                else _invOpen = false;
                return;
            }
            if (_screen == Mode.Arriving && (SZInput.Down(SZKey.Enter) || SZInput.Down(SZKey.Escape)))
                _menuScene.SkipArrival();
            if (_screen == Mode.Characters) CarKeys();
            if (_screen == Mode.Playing && SZInput.Down(SZKey.QuickSave)) QuickSave();
            if (_screen == Mode.Playing && !SZCutscene.Playing && SZInput.Down(SZKey.QuickLoad)) { QuickLoad(); return; }

            if (!SZInput.Down(SZKey.Escape)) return;
            if (_screen == Mode.Playing) Pause();
            else if (_screen == Mode.Paused) Resume();
            else if (_screen == Mode.Settings && !_waitingFor.HasValue)
            {
                if (_controlsOpen) _controlsOpen = false; else CloseSettings();
            }
            else if (_screen == Mode.Characters) LeaveCar();
            else if (_screen == Mode.Join) _screen = Mode.Menu;
        }

        // Choosing in the car: click a person, or arrow keys + Enter (like Godot).
        void CarKeys()
        {
            bool typing = GUIUtility.keyboardControl != 0;  // typing a name: arrows and Enter belong to the text box
            int step = typing ? 0 : SZInput.Down(SZKey.Right) ? 1 : SZInput.Down(SZKey.Left) ? -1 : 0;
            if (step != 0)
            {
                int current = _menuScene.Hovered >= 0 ? _menuScene.Hovered : Mathf.Max(_menuScene.Selected, 0);
                int next = (current + step + 4) % 4;
                _menuScene.Hovered = next;
                _menuScene.Selected = next;
            }
            if (SZInput.Click)
            {
                int who = _menuScene.CharacterAt(SZInput.MousePosition);
                if (who >= 0)
                {
                    _menuScene.Selected = who;
                    _menuScene.Hovered = who;
                }
            }
            if (SZInput.Down(SZKey.Enter) && !typing) Confirm();
        }

        void CloseSettings()
        {
            PlayerPrefs.SetInt("sz_subtitles", Subtitles ? 1 : 0);
            PlayerPrefs.SetInt("sz_big_subtitles", BigSubtitles ? 1 : 0);
            _controlsOpen = false;
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
                case Mode.Connecting: DrawShade(); Center("Connecting..."); break;
                case Mode.Talk: DrawTalk(); break;
                case Mode.Arriving: DrawArriving(); break;
                case Mode.Loading: DrawBackdrop(); Center("Loading Chapter 1..."); break;
                case Mode.Settings:
                    Box(Full(), new Color(0, 0, 0, 0.75f));
                    if (_controlsOpen) DrawControls(); else DrawSettings();
                    break;
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

        // Dark on the left so the menu text is easy to read over the car scene (like Godot).
        void DrawShade()
        {
            for (int i = 0; i < 16; i++)
                Box(new Rect(i * Screen.width * 0.04f, 0, Screen.width * 0.04f, Screen.height), new Color(0, 0, 0, 0.85f * (1f - i / 16f)));
        }

        void DrawMenu()
        {
            DrawShade();
            // The security camera look from the Godot menu.
            GUI.Label(new Rect(24, 16, 600, 24), "CAM 03  //  BLACKWATER STATION  //  EXTERIOR", _small);
            var rec = new GUIStyle(_small) { alignment = TextAnchor.UpperRight };
            rec.normal.textColor = Time.time % 1.2f < 0.7f ? new Color(0.85f, 0.2f, 0.15f) : new Color(0.4f, 0.4f, 0.38f);
            GUI.Label(new Rect(Screen.width - 424, 16, 400, 24), "\u25CF REC   10-14-2015   03:47:12", rec);

            float x = 88f, y = Screen.height * 0.2f;
            GUI.Label(new Rect(x + 4, y - 26, 600, 24), "U.S. GOVERNMENT PROPERTY  //  CLASSIFIED", _sub);
            Title(x, y);
            y += 170f;
            if (SZSave.Exists)
            {
                if (GUI.Button(new Rect(x, y, 380, 54), "CONTINUE", _button)) Continue(false);
                if (GUI.Button(new Rect(x + 390, y, 260, 54), "CONTINUE + HOST", _button)) Continue(true);
                y += 64f;
            }
            if (GUI.Button(new Rect(x, y, 380, 54), SZSave.Exists ? "NEW GAME (SOLO)" : "PLAY SOLO", _button)) Go(Plan.Solo);
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "HOST GAME", _button)) Go(Plan.Host);
            if (GUI.Button(new Rect(x, y + 128, 380, 54), "JOIN GAME", _button)) Go(Plan.Join);
            if (GUI.Button(new Rect(x, y + 192, 380, 54), "SETTINGS", _button)) { _settingsBack = Mode.Menu; _screen = Mode.Settings; }
            if (GUI.Button(new Rect(x, y + 256, 380, 54), "QUIT", _button)) Application.Quit();
            if (!string.IsNullOrEmpty(_status))
                GUI.Label(new Rect(x, y + 330, Screen.width - x - 40, 120), _status, new GUIStyle(_sub) { wordWrap = true });
        }

        // Inside the car: cards at the bottom, the person you're looking at on the right.
        void DrawCharacters()
        {
            var scene = _menuScene;
            if (scene.MirrorShot) return;  // looking at their face in the rear-view mirror
            float W = Screen.width, H = Screen.height;
            GUI.Label(new Rect(88, 56, 900, 50), "CHOOSE YOUR CHARACTER", new GUIStyle(_title) { fontSize = 34 });
            GUI.Label(new Rect(90, 104, 1000, 24), "POINT AT A NAME TO MEET THEM.  CLICK TO CHOOSE.  ARROW KEYS + ENTER ALSO WORK.", _small);
            GUI.Label(new Rect(90, 138, 120, 30), "YOUR NAME", _small);
            _playerName = GUI.TextField(new Rect(200, 132, 260, 36), _playerName, 16, new GUIStyle(_field) { fontSize = 18 });

            // Info panel (who you're looking at, or who you picked).
            int show = scene.Hovered >= 0 ? scene.Hovered : scene.Selected;
            if (show >= 0)
            {
                var panel = new Rect(W - 520, H * 0.5f - 210, 480, 330);
                Box(panel, new Color(0.03f, 0.035f, 0.035f, 0.88f));
                float py = panel.y + 18;
                GUI.Label(new Rect(panel.x + 22, py, 440, 44), SZCharacters.Names[show].ToUpper(), new GUIStyle(_title) { fontSize = 34 });
                var role = new GUIStyle(_sub);
                role.normal.textColor = new Color(0.91f, 0.69f, 0.29f);
                GUI.Label(new Rect(panel.x + 22, py + 46, 440, 24), SZCharacters.Roles[show].ToUpper(), role);
                var body = new GUIStyle(_small) { fontSize = 16 };
                GUI.Label(new Rect(panel.x + 22, py + 78, 440, 80), SZCharacters.About[show], body);
                GUI.Label(new Rect(panel.x + 22, py + 160, 440, 70), SZCharacters.Abilities[show], body);
                var quote = new GUIStyle(body);
                quote.normal.textColor = new Color(0.48f, 0.47f, 0.42f);
                GUI.Label(new Rect(panel.x + 22, py + 240, 440, 50), SZCharacters.Quotes[show], quote);
            }

            // The four name cards.
            float cw = Mathf.Min(250f, (W - 180f) / 4f - 12f), ch = 84f;
            float cx = W / 2f - (cw * 4 + 36f) / 2f, cy = H - ch - 96f;
            int hoveredCard = -1;
            for (int i = 0; i < 4; i++)
            {
                var r = new Rect(cx + i * (cw + 12f), cy, cw, ch);
                if (r.Contains(Event.current.mousePosition)) hoveredCard = i;
                bool picked = scene.Selected == i;
                Box(r, picked ? new Color(0.12f, 0.11f, 0.08f, 0.95f) : new Color(0.03f, 0.035f, 0.035f, 0.88f));
                if (picked || hoveredCard == i) Box(new Rect(r.x, r.yMax - 3, r.width, 3), new Color(0.91f, 0.69f, 0.29f));
                _cardTitle.normal.textColor = picked ? new Color(0.91f, 0.69f, 0.29f) : new Color(0.85f, 0.83f, 0.76f);
                GUI.Label(new Rect(r.x + 16, r.y + 14, r.width, 30), SZCharacters.Names[i].Split(' ')[0].ToUpper(), _cardTitle);
                GUI.Label(new Rect(r.x + 16, r.y + 46, r.width, 24), SZCharacters.Roles[i].ToUpper(), _small);
                if (GUI.Button(r, GUIContent.none, GUIStyle.none)) scene.Selected = i;
            }
            // Pointing at a card moves the camera to that person (wait a moment before moving back).
            if (Event.current.type == EventType.Repaint)
            {
                if (hoveredCard >= 0)
                {
                    scene.Hovered = hoveredCard;
                    _unhoverAt = -1f;
                }
                else if (scene.Hovered >= 0 && _unhoverAt < 0f) _unhoverAt = Time.unscaledTime + 0.35f;
                if (_unhoverAt > 0f && Time.unscaledTime > _unhoverAt && hoveredCard < 0)
                {
                    scene.Hovered = -1;
                    _unhoverAt = -1f;
                }
            }

            if (GUI.Button(new Rect(88, H - 78, 200, 50), "BACK", _button)) LeaveCar();
            if (scene.Selected >= 0 &&
                GUI.Button(new Rect(W - 408, H - 78, 320, 50), "PLAY AS " + SZCharacters.Names[scene.Selected].Split(' ')[0].ToUpper(), _button))
                Confirm();
            if (SZNet.IsHost)
                GUI.Label(new Rect(300, H - 64, 700, 30), "Hosting. Friends join with:  " + SZNet.LocalAddresses(), _small);
        }

        // The car conversation: black bars, who is talking, and the subtitle.
        void DrawTalk()
        {
            var scene = _menuScene;
            if (scene == null) return;
            float bar = Screen.height * 0.1f;
            Box(new Rect(0, 0, Screen.width, bar), Color.black);
            Box(new Rect(0, Screen.height - bar, Screen.width, bar), Color.black);
            DrawCaption(scene.Speaker, scene.Caption);
            var hint = new GUIStyle(_small) { alignment = TextAnchor.UpperRight, fontSize = 14 };
            GUI.Label(new Rect(0, Screen.height - 28, Screen.width - 20, 24),
                scene.SkipHold > 0f ? "Skipping..." : "[SPACE] next     hold [SPACE] skip", hint);
        }

        void DrawArriving()
        {
            var scene = _menuScene;
            if (scene == null) return;
            var c = _prompt.normal.textColor;
            var caption = new GUIStyle(_small) { fontSize = 22 };
            caption.normal.textColor = new Color(0.85f, 0.83f, 0.76f, scene.ArrivalText);
            GUI.Label(new Rect(88, 72, 900, 70), "BLACKWATER WEATHER STATION\nOCTOBER 14, 2015   03:52 AM", caption);
            GUI.Label(new Rect(88, Screen.height - 50, 600, 30), "Enter = skip", _small);
            if (scene.Fade > 0f) Box(Full(), new Color(0, 0, 0, scene.Fade));
            _prompt.normal.textColor = c;
        }

        void DrawJoin()
        {
            DrawShade();
            float x = 88f, y = Screen.height * 0.2f;
            GUI.Label(new Rect(x, y, 900, 60), "JOIN GAME", new GUIStyle(_title) { fontSize = 48 });
            GUI.Label(new Rect(x, y + 80, 900, 50), "HOST IP ADDRESS  (your friend sees it on their screen after they press HOST GAME)", _small);
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
            y += 50f;
            GUI.Label(new Rect(x, y, 260, 30), "Subtitles", _small);
            if (GUI.Button(new Rect(x + 260, y - 8, 120, 44), Subtitles ? "> ON" : "ON", _button)) Subtitles = true;
            if (GUI.Button(new Rect(x + 390, y - 8, 120, 44), Subtitles ? "OFF" : "> OFF", _button)) Subtitles = false;
            y += 50f;
            GUI.Label(new Rect(x, y, 260, 30), "Subtitle size", _small);
            if (GUI.Button(new Rect(x + 260, y - 8, 120, 44), BigSubtitles ? "NORMAL" : "> NORMAL", _button)) BigSubtitles = false;
            if (GUI.Button(new Rect(x + 390, y - 8, 120, 44), BigSubtitles ? "> LARGE" : "LARGE", _button)) BigSubtitles = true;
            y += 70f;
            if (GUI.Button(new Rect(x, y, 380, 54), "CONTROLS (CHANGE KEYS)", _button)) { _controlsOpen = true; _waitingFor = null; }
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "BACK", _button)) CloseSettings();
        }

        // ---------------------------------------------------------------- subtitles

        public static bool Subtitles = true, BigSubtitles;

        // ---------------------------------------------------------------- changing the keys

        bool _controlsOpen;
        SZKey? _waitingFor;

        void DrawControls()
        {
            float x = 90f, y = Screen.height * 0.08f;
            GUI.Label(new Rect(x, y, 900, 60), "CONTROLS", new GUIStyle(_title) { fontSize = 48 });
            GUI.Label(new Rect(x, y + 62, 900, 26), "Click a key, then press the new key (or a mouse button). Esc = cancel.", _small);
            y += 100f;
            // Two columns, so every key fits on the screen.
            float top = y, bottom = y;
            for (int i = 0; i < SZInput.Changeable.Length; i++)
            {
                var k = SZInput.Changeable[i];
                float cx = x + (i < 8 ? 0f : 560f), cy = top + (i % 8) * 44f;
                GUI.Label(new Rect(cx, cy + 8, 260, 30), SZInput.ActionName(k), _small);
                string shown = _waitingFor == k ? "press a key..." : SZInput.KeyName(SZInput.KeyFor(k));
                if (GUI.Button(new Rect(cx + 270, cy, 260, 40), shown, _button)) _waitingFor = k;
                bottom = Mathf.Max(bottom, cy + 44f);
            }
            y = bottom;
            GUI.Label(new Rect(x, y + 4, 900, 50),
                "Always the same: arrow keys move, Ctrl crouches, 1-4 pick an item, left click uses it, Esc pauses.", _small);
            y += 50f;
            if (GUI.Button(new Rect(x, y, 260, 50), "RESET TO DEFAULTS", _button)) SZInput.ResetKeys();
            if (GUI.Button(new Rect(x + 270, y, 260, 50), "BACK", _button)) { _controlsOpen = false; _waitingFor = null; }

            // The next key press (or mouse button) becomes the new key.
            var e = Event.current;
            if (_waitingFor.HasValue)
            {
                if (e.type == EventType.KeyDown && e.keyCode != KeyCode.None)
                {
                    if (e.keyCode != KeyCode.Escape) SZInput.SetKey(_waitingFor.Value, e.keyCode);
                    _waitingFor = null;
                    e.Use();
                }
                else if (e.type == EventType.MouseDown && e.button > 0)
                {
                    SZInput.SetKey(_waitingFor.Value, KeyCode.Mouse0 + e.button);
                    _waitingFor = null;
                    e.Use();
                }
            }
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
            if (!SZNet.IsClient)
            {
                if (GUI.Button(new Rect(x + 390, y, 260, 54), "SAVE GAME", _button)) { Resume(); QuickSave(); }
                if (GUI.Button(new Rect(x + 390, y + 64, 260, 54), "LOAD LAST SAVE", _button) && SZSave.Exists) { Resume(); QuickLoad(); }
            }
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "SETTINGS", _button)) { _settingsBack = Mode.Paused; _screen = Mode.Settings; }
            if (GUI.Button(new Rect(x, y + 128, 380, 54), SZNet.Online ? "LEAVE GAME" : "BACK TO MENU", _button)) ShowMenu();
            if (GUI.Button(new Rect(x, y + 192, 380, 54), "QUIT", _button)) Application.Quit();
            GUI.Label(new Rect(x, y + 270, 900, 120),
                "WASD move   Mouse look   Shift sprint   Ctrl/C crouch   Space jump\n" +
                "F flashlight   E use / pick up (hold E for some)   1-4 pick an item   Click use it   R reload\n" +
                "G drop   Tab inventory   Q ability   F5 quick save   F9 quick load\n(change keys in Settings > Controls)", _small);
        }

        void DrawHud()
        {
            if (_world == null || _world.Local == null) return;
            var p = _world.Local;
            float W = Screen.width, H = Screen.height;
            if (SZCutscene.Playing)
            {
                DrawCutscene(SZCutscene.Current);
                return;
            }

            if (p.HidingIn != null) DrawLockerView();
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
            float progress = Mathf.Max(p.AbilityProgress, p.HoldProgress);
            if (progress > 0f)
            {
                Box(new Rect(W / 2f - 100, H * 0.58f + 74, 200, 8), new Color(0, 0, 0, 0.6f));
                Box(new Rect(W / 2f - 100, H * 0.58f + 74, 200 * progress, 8), new Color(0.9f, 0.7f, 0.2f));
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

            // Bottom middle: the 4 quick slots (1-4). Bottom right: ability.
            var inv = p.Inventory;
            DrawHotbar(inv);
            string ability = SZCharacters.Abilities[(int)p.Character].Split(':')[0];
            if (p.AbilityCooldown > 0f) ability += "  (" + Mathf.CeilToInt(p.AbilityCooldown) + "s)";
            GUI.Label(new Rect(W - 520, y + 22, 500, 24), ability, new GUIStyle(_sub) { alignment = TextAnchor.UpperRight });

            if (SZNet.IsHost && Time.time < _hostHintUntil)
                Shadowed(new Rect(0, 16, W, 30), "You're hosting. Friends join with:  " + SZNet.LocalAddresses(), _prompt);

            if (_invOpen && _screen == Mode.Playing) DrawInventory(p);
            if (_endingAt > 0f) DrawEnding();
            if (_panel != null && _screen == Mode.Playing) _panel.Draw(this);
        }

        // Black bars, the caption (with who's talking), and "hold Space to skip".
        void DrawCutscene(SZCutscene c)
        {
            float bar = Screen.height * 0.11f * c.Bars;
            Box(new Rect(0, 0, Screen.width, bar), Color.black);
            Box(new Rect(0, Screen.height - bar, Screen.width, bar), Color.black);
            if (c.ShowPhoto) DrawPhoto();
            DrawCaption(c.Speaker, c.Caption);
            var hint = new GUIStyle(_small) { alignment = TextAnchor.UpperRight, fontSize = 14 };
            GUI.Label(new Rect(0, Screen.height - 28, Screen.width - 20, 24),
                c.SkipHold > 0f ? "Skipping..." : "[SPACE] next     hold [SPACE] skip", hint);
        }

        // Eli's old photo of him with his mom and dad (Resources/Textures/eli_family_photo.png).
        Texture2D _photo;

        void DrawPhoto()
        {
            if (_photo == null) _photo = Resources.Load<Texture2D>("Textures/eli_family_photo");
            if (_photo == null) return;
            float h = Screen.height * 0.6f, w = h * _photo.width / Mathf.Max(_photo.height, 1);
            var r = new Rect(Screen.width / 2f - w / 2f, Screen.height * 0.42f - h / 2f, w, h);
            var m = GUI.matrix;
            GUIUtility.RotateAroundPivot(-3f, r.center);
            GUI.DrawTexture(r, _photo, ScaleMode.ScaleToFit);
            GUI.matrix = m;
        }

        void DrawCaption(string speaker, string text)
        {
            if (string.IsNullOrEmpty(text) || !Subtitles) return;
            float y = Screen.height * (BigSubtitles ? 0.76f : 0.8f);
            if (!string.IsNullOrEmpty(speaker))
            {
                var who = new GUIStyle(_prompt) { fontSize = BigSubtitles ? 24 : 18 };
                who.normal.textColor = new Color(0.91f, 0.69f, 0.29f);
                Shadowed(new Rect(0, y - 26, Screen.width, 26), speaker, who);
            }
            var line = new GUIStyle(_prompt) { fontSize = BigSubtitles ? 30 : 22, wordWrap = true };
            Shadowed(new Rect(Screen.width * 0.12f, y, Screen.width * 0.76f, BigSubtitles ? 110 : 70), text, line);
        }

        // Inside a locker: dark, except a few slits in the door to peek through.
        void DrawLockerView()
        {
            float W = Screen.width, H = Screen.height;
            float top = H * 0.36f, slit = H * 0.035f, gap = H * 0.05f;
            Box(new Rect(0, 0, W, top), new Color(0.01f, 0.01f, 0.01f, 0.97f));
            for (int i = 0; i < 4; i++)
            {
                float y = top + slit + i * (slit + gap);
                Box(new Rect(0, y - gap, W, gap), new Color(0.01f, 0.01f, 0.01f, 0.97f));
            }
            float bottom = top + slit + 4 * (slit + gap) - gap;
            Box(new Rect(0, bottom, W, H - bottom), new Color(0.01f, 0.01f, 0.01f, 0.97f));
            Box(new Rect(0, 0, W * 0.18f, H), new Color(0.01f, 0.01f, 0.01f, 0.97f));
            Box(new Rect(W * 0.82f, 0, W * 0.18f, H), new Color(0.01f, 0.01f, 0.01f, 0.97f));
            Shadowed(new Rect(0, H - 60, W, 30), "Hiding. Stay quiet...", _prompt);
        }

        // ---------------------------------------------------------------- inventory (the case)

        // Tab opens the case, like Resident Evil 4: every item takes up space by
        // its size. Click an item to pick it up, move it (R turns it), click to put
        // it down. Point at an item and press 1-4 to put it on that number key.
        bool _invOpen;
        SZItem _invPicked, _invHover;
        bool _pickedTurned;
        int _pickedFromX, _pickedFromY;
        bool _pickedFromTurned;
        public static bool InventoryOpen => Instance != null && Instance._invOpen;

        static readonly Color CaseBack = new Color(0.06f, 0.06f, 0.065f, 0.97f);
        static readonly Color CellColor = new Color(0.13f, 0.13f, 0.14f, 1f);
        static readonly Color CellLine = new Color(0.26f, 0.26f, 0.27f, 1f);
        static readonly Color ItemBack = new Color(0.2f, 0.2f, 0.21f, 1f);
        static readonly Color CountGreen = new Color(0.55f, 0.95f, 0.6f);
        static readonly Color CountRed = new Color(0.95f, 0.25f, 0.2f);

        void ToggleInventory()
        {
            if (_invOpen) CancelMove();
            _invOpen = !_invOpen;
            Cursor.lockState = _invOpen ? CursorLockMode.None : CursorLockMode.Locked;
            Cursor.visible = _invOpen;
        }

        void CancelMove()
        {
            if (_invPicked == null) return;
            _world?.Local?.Inventory.MoveTo(_invPicked, _pickedFromX, _pickedFromY, _pickedFromTurned);
            _invPicked = null;
        }

        // The 4 number keys at the bottom of the screen.
        void DrawHotbar(SZInventory inv)
        {
            float size = 72f, gap = 8f;
            float x0 = Screen.width / 2f - (size * 4 + gap * 3) / 2f, y = Screen.height - size - 18f;
            for (int i = 0; i < 4; i++)
            {
                var r = new Rect(x0 + i * (size + gap), y, size, size);
                var it = inv.Hotkeys[i];
                if (it != null && !inv.Items.Contains(it)) it = null;
                Box(r, i == inv.Selected ? new Color(0.3f, 0.26f, 0.15f, 0.95f) : new Color(0.06f, 0.06f, 0.07f, 0.85f));
                Box(new Rect(r.x, r.yMax - 2, r.width, 2), i == inv.Selected ? new Color(0.95f, 0.75f, 0.3f) : CellLine);
                GUI.Label(new Rect(r.x + 4, r.y + 2, 20, 18), (i + 1).ToString(), new GUIStyle(_small) { fontSize = 12 });
                if (it == null) continue;
                var icon = SZIcons.Get(it.data);
                if (icon) GUI.DrawTexture(new Rect(r.x + 6, r.y + 10, r.width - 12, r.height - 22), icon, ScaleMode.ScaleToFit);
                DrawCount(r, it, inv, 13);
            }
            var held = inv.Held;
            if (held != null)
            {
                string line = held.data.name + (held.IsGun ? "   " + held.clip + " / " + inv.Count(SZInventory.AmmoFor(held.Id)) + "   [Click] shoot  [R] reload" : "   [Click] use   [G] drop");
                Shadowed(new Rect(0, y - 26, Screen.width, 24), line, new GUIStyle(_small) { alignment = TextAnchor.MiddleCenter });
            }
        }

        // The number in the corner: how many (green), or bullets in a gun (red when empty).
        void DrawCount(Rect r, SZItem it, SZInventory inv, int fontSize)
        {
            string text = null;
            var color = CountGreen;
            if (it.IsGun)
            {
                text = it.clip.ToString();
                if (it.clip == 0) color = CountRed;
            }
            else if (SZInventory.StackMax(it.Id) > 1) text = it.count.ToString();
            if (text == null) return;
            var style = new GUIStyle(_small) { fontSize = fontSize, fontStyle = FontStyle.Bold, alignment = TextAnchor.LowerRight };
            style.normal.textColor = color;
            Shadowed(new Rect(r.x, r.y, r.width - 5, r.height - 3), text, style);
        }

        void DrawInventory(SZPlayer p)
        {
            var inv = p.Inventory;
            var e = Event.current;
            Box(Full(), new Color(0, 0, 0, 0.65f));
            float cell = Mathf.Min(64f, (Screen.height * 0.7f) / SZInventory.MaxRows, (Screen.width - 420f) / SZInventory.Cols);
            float gw = cell * SZInventory.Cols;
            float gx = Mathf.Max(30f, Screen.width / 2f - (gw + 340f) / 2f), gy = Screen.height / 2f - (cell * SZInventory.MaxRows) / 2f + 20f;
            Box(new Rect(gx - 14, gy - 54, gw + 28, cell * SZInventory.MaxRows + 90), CaseBack);
            GUI.Label(new Rect(gx, gy - 48, 400, 40), "INVENTORY", new GUIStyle(_title) { fontSize = 28 });

            // The grid (rows you haven't unlocked yet are dark).
            for (int y = 0; y < SZInventory.MaxRows; y++)
                for (int x = 0; x < SZInventory.Cols; x++)
                {
                    var r = new Rect(gx + x * cell, gy + y * cell, cell, cell);
                    Box(r, CellLine);
                    Box(new Rect(r.x + 1, r.y + 1, r.width - 2, r.height - 2), y < inv.Rows ? CellColor : new Color(0.03f, 0.03f, 0.03f));
                }
            if (inv.Rows < SZInventory.MaxRows)
                GUI.Label(new Rect(gx, gy + inv.Rows * cell + 4, gw, 24), "(a pouch or backpack makes the case bigger)", new GUIStyle(_small) { fontSize = 13 });

            // Which cell the mouse is over.
            int mx = Mathf.FloorToInt((e.mousePosition.x - gx) / cell), my = Mathf.FloorToInt((e.mousePosition.y - gy) / cell);
            bool inGrid = mx >= 0 && my >= 0 && mx < SZInventory.Cols && my < inv.Rows;
            if (e.type == EventType.Repaint || e.type == EventType.MouseMove) _invHover = inGrid ? inv.At(mx, my) : null;

            // The items.
            foreach (var it in inv.Items)
            {
                if (it == _invPicked) continue;
                var r = new Rect(gx + it.x * cell + 2, gy + it.y * cell + 2, it.W * cell - 4, it.H * cell - 4);
                DrawItem(r, it, inv, it == _invHover);
            }

            // The item you're moving follows the mouse (green = fits, red = doesn't).
            if (_invPicked != null)
            {
                int w = _pickedTurned ? SZInventory.SizeOf(_invPicked.Id).y : SZInventory.SizeOf(_invPicked.Id).x;
                int h = _pickedTurned ? SZInventory.SizeOf(_invPicked.Id).x : SZInventory.SizeOf(_invPicked.Id).y;
                int px = mx - (w - 1) / 2, py = my - (h - 1) / 2;
                bool fits = inv.Fits(px, py, w, h, _invPicked);
                var r = new Rect(gx + px * cell + 2, gy + py * cell + 2, w * cell - 4, h * cell - 4);
                Box(r, fits ? new Color(0.2f, 0.6f, 0.25f, 0.45f) : new Color(0.7f, 0.15f, 0.1f, 0.45f));
                bool was = _invPicked.turned;
                _invPicked.turned = _pickedTurned;
                DrawItem(r, _invPicked, inv, true);
                _invPicked.turned = was;
                if (e.type == EventType.MouseDown && e.button == 0)
                {
                    if (fits && inv.MoveTo(_invPicked, px, py, _pickedTurned))
                    {
                        _invPicked = null;
                        SZAudio.Play2D("repair_click", 0.3f);
                    }
                    e.Use();
                }
                else if (e.type == EventType.MouseDown && e.button == 1)
                {
                    CancelMove();
                    e.Use();
                }
                else if (e.type == EventType.KeyDown && e.keyCode == KeyCode.R)
                {
                    _pickedTurned = !_pickedTurned;
                    e.Use();
                }
            }
            else if (e.type == EventType.MouseDown && e.button == 0 && _invHover != null)
            {
                // Pick it up to move it.
                _invPicked = _invHover;
                _pickedFromX = _invPicked.x;
                _pickedFromY = _invPicked.y;
                _pickedFromTurned = _invPicked.turned;
                _pickedTurned = _invPicked.turned;
                e.Use();
            }

            // 1-4 while pointing at an item: put it on that number key.
            if (e.type == EventType.KeyDown && _invHover != null && e.keyCode >= KeyCode.Alpha1 && e.keyCode <= KeyCode.Alpha4)
            {
                inv.SetHotkey(e.keyCode - KeyCode.Alpha1, _invHover);
                SZAudio.Play2D("repair_click", 0.3f);
                e.Use();
            }

            // The item you're pointing at (or moving): what it is, and what you can do.
            var info = new Rect(gx + gw + 30, gy - 54, 300, cell * SZInventory.MaxRows + 90);
            Box(info, CaseBack);
            var shown = _invPicked ?? _invHover ?? _invLast;
            if (shown != null && !inv.Items.Contains(shown)) shown = null;
            if (_invHover != null) _invLast = _invHover;
            if (shown == null)
            {
                GUI.Label(new Rect(info.x + 16, info.y + 20, 270, 80), "Point at an item to see it.", _small);
            }
            else
            {
                GUI.Label(new Rect(info.x + 16, info.y + 16, 270, 60), shown.data.name.ToUpper(), new GUIStyle(_title) { fontSize = 22, wordWrap = true });
                var icon = SZIcons.Get(shown.data);
                if (icon) GUI.DrawTexture(new Rect(info.x + 16, info.y + 76, 268, 120), icon, ScaleMode.ScaleToFit);
                string details = shown.data.hint;
                if (shown.IsGun) details = "Loaded: " + shown.clip + " / " + SZInventory.ClipSize(shown.Id) + "   Ammo: " + inv.Count(SZInventory.AmmoFor(shown.Id)) + "\n" + details;
                else if (SZInventory.StackMax(shown.Id) > 1) details = "You have " + shown.count + ".\n" + details;
                GUI.Label(new Rect(info.x + 16, info.y + 206, 270, 150), details, new GUIStyle(_small) { wordWrap = true });
                if (_invPicked == null)
                {
                    if (GUI.Button(new Rect(info.x + 16, info.yMax - 130, 268, 50), "USE", _button)) p.UseItem(shown);
                    if (GUI.Button(new Rect(info.x + 16, info.yMax - 70, 268, 50), "DROP", _button)) { p.Drop(shown); _invLast = null; }
                }
            }
            GUI.Label(new Rect(gx, gy + SZInventory.MaxRows * cell + 8, gw + 320, 24),
                _invPicked != null ? "Click to put it down   R = turn it   Right click = cancel"
                                   : "Click an item to move it   1-4 = put it on a number key   Tab = close",
                new GUIStyle(_small) { fontSize = 13 });
        }

        SZItem _invLast;

        void DrawItem(Rect r, SZItem it, SZInventory inv, bool highlight)
        {
            Box(r, highlight ? new Color(0.3f, 0.3f, 0.32f, 1f) : ItemBack);
            var icon = SZIcons.Get(it.data);
            if (icon)
            {
                // A long gun standing up: turn its picture too.
                if (it.turned)
                {
                    var m = GUI.matrix;
                    GUIUtility.RotateAroundPivot(90f, r.center);
                    var turned = new Rect(r.center.x - r.height / 2f, r.center.y - r.width / 2f, r.height, r.width);
                    GUI.DrawTexture(new Rect(turned.x + 4, turned.y + 4, turned.width - 8, turned.height - 8), icon, ScaleMode.ScaleToFit);
                    GUI.matrix = m;
                }
                else GUI.DrawTexture(new Rect(r.x + 4, r.y + 4, r.width - 8, r.height - 8), icon, ScaleMode.ScaleToFit);
            }
            else
            {
                GUI.Label(r, it.data.name, new GUIStyle(_small) { fontSize = 11, alignment = TextAnchor.MiddleCenter, wordWrap = true });
            }
            int key = System.Array.IndexOf(inv.Hotkeys, it);
            if (key >= 0)
            {
                Box(new Rect(r.x + 3, r.y + 3, 16, 16), new Color(0.85f, 0.85f, 0.85f, 0.9f));
                var badge = new GUIStyle(_small) { fontSize = 11, fontStyle = FontStyle.Bold, alignment = TextAnchor.MiddleCenter };
                badge.normal.textColor = Color.black;
                GUI.Label(new Rect(r.x + 3, r.y + 3, 16, 16), (key + 1).ToString(), badge);
            }
            DrawCount(r, it, inv, 15);
        }

        // ---------------------------------------------------------------- puzzle screens (keypad, terminal)

        // A puzzle that shows its own screen (SZPuzzles: the keypad buttons,
        // the terminal's grid). The mouse is free while it's open.
        public interface IPanel
        {
            void Draw(SZGame game);
        }

        IPanel _panel;
        public static bool PanelOpen => Instance != null && Instance._panel != null;

        public void OpenPanel(IPanel panel)
        {
            _panel = panel;
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        public void ClosePanel()
        {
            _panel = null;
            if (_screen == Mode.Playing)
            {
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
            }
        }

        // ---------------------------------------------------------------- the end of the chapter

        float _endingAt = -1f;

        public void ShowEnding()
        {
            if (_endingAt > 0f) return;
            _endingAt = Time.time;
            _invOpen = false;
            _panel = null;
            StartCoroutine(Ending());
        }

        IEnumerator Ending()
        {
            Say("The elevator shudders and starts down...", 3f);
            yield return new WaitForSeconds(3.5f);
            SZAudio.Play2D("cable_snap", 1f);
            SZPostEffect.Flash = 0.5f;
            Say("SNAP!", 1.5f);
            yield return new WaitForSeconds(1.5f);
            Paused = true;
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        void DrawEnding()
        {
            float k = Mathf.Clamp01((Time.time - _endingAt - 4.5f) / 1.5f);
            if (k <= 0f) return;
            Box(Full(), new Color(0, 0, 0, k));
            var c = GUI.color;
            GUI.color = new Color(1, 1, 1, k);
            GUI.Label(new Rect(0, Screen.height * 0.3f, Screen.width, 90), "END OF CHAPTER 1", new GUIStyle(_title) { fontSize = 60, alignment = TextAnchor.MiddleCenter });
            GUI.Label(new Rect(0, Screen.height * 0.3f + 90, Screen.width, 40), "THE SURFACE", new GUIStyle(_sub) { fontSize = 22, alignment = TextAnchor.MiddleCenter });
            GUI.Label(new Rect(0, Screen.height * 0.3f + 140, Screen.width, 40), "Chapter 2 comes to the Unity version next.", new GUIStyle(_small) { alignment = TextAnchor.MiddleCenter });
            if (k >= 1f && GUI.Button(new Rect(Screen.width / 2f - 190, Screen.height * 0.3f + 200, 380, 54), "BACK TO MENU", _button))
            {
                _endingAt = -1f;
                ShowMenu();
            }
            GUI.color = c;
        }

        // Styles the puzzle screens can use.
        public GUIStyle ButtonStyle => _button;
        public GUIStyle TitleStyle => _title;
        public GUIStyle SmallStyle => _small;
        public void Fill(Rect r, Color c) => Box(r, c);

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
