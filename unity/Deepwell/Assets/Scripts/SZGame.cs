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

        enum Mode { Menu, Characters, Join, Connecting, Story, Arriving, Loading, Settings, Playing, Paused }
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

        // "PLAY AS ...": the newspaper story, then the car drives up to the station
        // (everyone gets out, Eli and Cole take the pistols from the trunk), then the chapter.
        void Confirm()
        {
            if (_menuScene.Selected < 0) return;
            _character = (SZCharacter)_menuScene.Selected;
            PlayerPrefs.SetString("sz_name", _playerName);
            _screen = Mode.Story;
            _storyPage = 0;
            _storyTime = 0f;
            _storySkip = 0f;
        }

        void Arrive()
        {
            _screen = Mode.Arriving;
            _menuScene.StartArrival(() => StartCoroutine(StartChapter()));
        }

        // ---------------------------------------------------------------- the newspaper (from Godot's opening_cutscene)

        int _storyPage;
        float _storyTime, _storySkip;
        static readonly float[] StoryPageTime = { 9f, 14f };

        const string NewsHeader = "The Blackwater Courier          October 12, 2015";
        const string NewsHeadline = "SEVENTH PERSON MISSING\nNEAR OLD WEATHER STATION";
        const string NewsArticle =
            "BLACKWATER COUNTY - Two college students have become the sixth and seventh people to vanish near the abandoned Blackwater Weather Station this year.\n\n" +
            "Marcus Bell, 21, and Jenna Park, 20, told friends they were going to film \"the creepiest place in the state\" for their channel. Their car was found Saturday at the end of the access road, keys still in the ignition.\n\n" +
            "They join five others missing since August, including reporter Daniel Marsh, who had been investigating the station's past.\n\n" +
            "The weather station was closed in 1999 after what officials called a gas leak. Eleven staff members died that night, including a married couple, Dr. Maria Reyes and Sgt. Daniel Reyes.\n\n" +
            "\"There is nothing out there but an empty building,\" a county spokesperson said. Search teams have not been allowed past the fence.\n\n" +
            "Continued on page A4...";
        const string NightText =
            "Eli Reyes read the article three times.\n\n" +
            "He was five years old in 1999, when his mom and dad drove to work at the weather station and never came home. \"A gas leak,\" they told him. Closed caskets.\n\n" +
            "Now Marcus and Jenna, his two best friends, had gone out there. For him. To find out what really happened to his parents.\n\n" +
            "And they had not come back.\n\n" +
            "Cole Brennan, the soldier who took Eli in when his parents died and raised him like his own son, said no. Then he said he was coming too.\n\n" +
            "Nora Vance, a reporter, had lost her source out there.\n\n" +
            "Walter Kessler said he used to work at the station. He said he knew the way in.\n\n" +
            "Seven people are missing. Four are going in after them.";

        void UpdateStory()
        {
            _storyTime += Time.unscaledDeltaTime;
            if (SZInput.Held(SZKey.Space)) _storySkip += Time.unscaledDeltaTime;
            else _storySkip = 0f;
            bool next = SZInput.Click || SZInput.Down(SZKey.Enter) || _storyTime > StoryPageTime[_storyPage];
            if (_storySkip >= 1f) _storyPage = StoryPageTime.Length;
            else if (next && _storyTime > 0.5f)
            {
                _storyPage++;
                _storyTime = 0f;
            }
            if (_storyPage >= StoryPageTime.Length) Arrive();
        }

        void DrawStory()
        {
            float fade = Mathf.Clamp01(_storyTime / 1.2f);
            Box(Full(), Color.black);
            var oldColor = GUI.color;
            GUI.color = new Color(1, 1, 1, fade);
            if (_storyPage == 0)
            {
                float w = Mathf.Min(760f, Screen.width - 60f), h = Mathf.Min(Screen.height - 60f, 640f);
                var r = new Rect(Screen.width / 2f - w / 2f, Screen.height / 2f - h / 2f, w, h);
                Box(r, new Color(0.86f, 0.83f, 0.74f));
                GUI.Label(new Rect(r.x + 36, r.y + 22, w - 72, 26), NewsHeader, new GUIStyle(_paperText) { fontSize = 16, fontStyle = FontStyle.Italic });
                Box(new Rect(r.x + 36, r.y + 52, w - 72, 2), new Color(0.2f, 0.17f, 0.14f));
                GUI.Label(new Rect(r.x + 36, r.y + 62, w - 72, 90), NewsHeadline, new GUIStyle(_paperTitle) { fontSize = 34, alignment = TextAnchor.UpperCenter });
                Box(new Rect(r.x + 36, r.y + 150, w - 72, 2), new Color(0.2f, 0.17f, 0.14f));
                GUI.Label(new Rect(r.x + 36, r.y + 164, w - 72, h - 180), NewsArticle, new GUIStyle(_paperText) { fontSize = 16 });
            }
            else
            {
                var title = new GUIStyle(_title) { fontSize = 30, alignment = TextAnchor.UpperCenter, fontStyle = FontStyle.Italic };
                GUI.Label(new Rect(0, Screen.height * 0.08f, Screen.width, 44), "That night...", title);
                var body = new GUIStyle(_small) { fontSize = 19, alignment = TextAnchor.UpperCenter };
                body.normal.textColor = new Color(0.85f, 0.83f, 0.78f);
                float w = Mathf.Min(820f, Screen.width - 80f);
                GUI.Label(new Rect(Screen.width / 2f - w / 2f, Screen.height * 0.08f + 64, w, Screen.height * 0.8f), NightText, body);
            }
            GUI.color = oldColor;
            GUI.Label(new Rect(0, Screen.height - 40, Screen.width - 24, 30),
                _storySkip > 0f ? "Skipping..." : "Click = next     Hold [SPACE] to skip", new GUIStyle(_small) { alignment = TextAnchor.UpperRight });
        }

        IEnumerator StartChapter()
        {
            _screen = Mode.Loading;
            yield return null;  // draw "Loading..." first; building takes a few seconds
            yield return null;
            if (_sceneCamera != null) _sceneCamera.gameObject.SetActive(false);
            if (_menuScene != null) Destroy(_menuScene.gameObject);
            _menuScene = null;
            _world = SZWorld.Create("chapter1", _character, _playerName);
            if (_world.Local == null)
            {
                ShowMenu();
                _status = "The level didn't load. Check the Console for a red error.";
                yield break;
            }
            // (The intro cutscene shows "CHAPTER 1 - THE SURFACE".)
            if (SZNet.IsHost) _hostHintUntil = Time.time + 25f;
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
            if (_screen == Mode.Arriving && (SZInput.Down(SZKey.Enter) || SZInput.Down(SZKey.Escape)))
                _menuScene.SkipArrival();
            if (_screen == Mode.Characters) CarKeys();
            else if (_screen == Mode.Story) UpdateStory();
            if (!SZInput.Down(SZKey.Escape)) return;
            if (_screen == Mode.Playing) Pause();
            else if (_screen == Mode.Paused) Resume();
            else if (_screen == Mode.Settings) CloseSettings();
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
                case Mode.Story: DrawStory(); break;
                case Mode.Arriving: DrawArriving(); break;
                case Mode.Loading: DrawBackdrop(); Center("Loading Chapter 1..."); break;
                case Mode.Settings: Box(Full(), new Color(0, 0, 0, 0.75f)); DrawSettings(); break;
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
            if (GUI.Button(new Rect(x, y, 380, 54), "PLAY SOLO", _button)) Go(Plan.Solo);
            if (GUI.Button(new Rect(x, y + 64, 380, 54), "HOST GAME", _button)) Go(Plan.Host);
            if (GUI.Button(new Rect(x, y + 128, 380, 54), "JOIN GAME", _button)) Go(Plan.Join);
            if (GUI.Button(new Rect(x, y + 192, 380, 54), "SETTINGS", _button)) { _settingsBack = Mode.Menu; _screen = Mode.Settings; }
            if (GUI.Button(new Rect(x, y + 256, 380, 54), "QUIT", _button)) Application.Quit();
            if (!string.IsNullOrEmpty(_status))
                GUI.Label(new Rect(x, y + 330, 700, 60), _status, _sub);
        }

        // Inside the car: cards at the bottom, the person you're looking at on the right.
        void DrawCharacters()
        {
            var scene = _menuScene;
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

        void DrawArriving()
        {
            var scene = _menuScene;
            if (scene == null) return;
            var c = _prompt.normal.textColor;
            var caption = new GUIStyle(_small) { fontSize = 22 };
            caption.normal.textColor = new Color(0.85f, 0.83f, 0.76f, scene.ArrivalText);
            GUI.Label(new Rect(88, 72, 900, 70), "BLACKWATER WEATHER STATION\nOCTOBER 14, 2015   03:52 AM", caption);
            DrawCaption(scene.Speaker, scene.Caption);
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
            if (SZCutscene.Playing)
            {
                DrawCutscene(SZCutscene.Current);
                return;
            }

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
            if (inv.HasGun)
                GUI.Label(new Rect(W - 520, y - 30, 500, 24), "PISTOL  " + inv.Clip + " / " + inv.Reserve + "    [Click] shoot  [R] reload",
                    new GUIStyle(_small) { alignment = TextAnchor.UpperRight });
            GUI.Label(new Rect(W - 520, y - 4, 500, 24), items, new GUIStyle(_small) { alignment = TextAnchor.UpperRight });
            string ability = SZCharacters.Abilities[(int)p.Character].Split(':')[0];
            if (p.AbilityCooldown > 0f) ability += "  (" + Mathf.CeilToInt(p.AbilityCooldown) + "s)";
            GUI.Label(new Rect(W - 520, y + 22, 500, 24), ability, new GUIStyle(_sub) { alignment = TextAnchor.UpperRight });

            if (SZNet.IsHost && Time.time < _hostHintUntil)
                Shadowed(new Rect(0, 16, W, 30), "You're hosting. Friends join with:  " + SZNet.LocalAddresses(), _prompt);

            if (SZInput.Held(SZKey.Tab) && _screen == Mode.Playing) DrawBag(inv);
        }

        // Black bars, the caption (with who's talking), and "hold Space to skip".
        void DrawCutscene(SZCutscene c)
        {
            float bar = Screen.height * 0.11f * c.Bars;
            Box(new Rect(0, 0, Screen.width, bar), Color.black);
            Box(new Rect(0, Screen.height - bar, Screen.width, bar), Color.black);
            DrawCaption(c.Speaker, c.Caption);
            var hint = new GUIStyle(_small) { alignment = TextAnchor.UpperRight, fontSize = 14 };
            GUI.Label(new Rect(0, Screen.height - 28, Screen.width - 20, 24),
                c.SkipHold > 0f ? "Skipping..." : "[SPACE] next     hold [SPACE] skip", hint);
        }

        void DrawCaption(string speaker, string text)
        {
            if (string.IsNullOrEmpty(text)) return;
            float y = Screen.height * 0.8f;
            if (!string.IsNullOrEmpty(speaker))
            {
                var who = new GUIStyle(_prompt) { fontSize = 18 };
                who.normal.textColor = new Color(0.91f, 0.69f, 0.29f);
                Shadowed(new Rect(0, y - 26, Screen.width, 26), speaker, who);
            }
            var line = new GUIStyle(_prompt) { fontSize = 22, wordWrap = true };
            Shadowed(new Rect(Screen.width * 0.15f, y, Screen.width * 0.7f, 70), text, line);
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
