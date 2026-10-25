using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

// The Deepwell home screen, the same as the Godot one
// (scenes/main_menu/deepwell/main_menu_car.gd): a car driving down a dark
// forest road at night.
//   MENU:     the camera watches the car from outside (SZGame draws the
//             title and buttons on top).
//   SELECT:   the camera moves into the back seat. Eli drives, Cole sits next
//             to him, Nora and Walter are in the back. Pointing at a
//             character's card moves the camera to them; picking one shows
//             their face in the rear-view mirror.
//   TALK:     after PLAY AS, the team talks while Eli drives (with subtitles):
//             "Uncle Cole, why is there a journalist and an old man in the car?"
//   ARRIVING: the camera moves behind the car, it drives up to the gate of
//             the Blackwater Weather Station, stops, and fades to black.
//             (The trunk scene happens in the level, at the real station.)
// Godot positions are copied with X flipped (Unity is left-handed).
namespace Deepwell
{
    public class SZMenuScene : MonoBehaviour
    {
        public enum State { Menu, Select, Talk, Arriving }

        public State Mode { get; private set; } = State.Menu;
        public int Hovered = -1;   // character the camera looks at (-1 = none)
        public int Selected = -1;  // character clicked
        public float Fade { get; private set; }       // 0..1 black at the end of the drive
        public float ArrivalText { get; private set; } // 0..1 the "BLACKWATER WEATHER STATION" caption
        public Camera Camera { get; private set; }
        // The car conversation's subtitle (who is talking, and the line).
        public string Speaker { get; private set; }
        public string Caption { get; private set; }
        public float SkipHold { get; private set; }
        // Looking into the rear-view mirror right now (the menu hides its cards).
        public bool MirrorShot => Mode == State.Select && Time.time < _mirrorShotUntil;

        // What the team says on the way (after you pick your character).
        static readonly string[,] Talk =
        {
            { "ELI", "So... Uncle Cole. Why is there a journalist and an old man in the car?" },
            { "COLE", "Eli, they're here because—" },
            { "NORA", "I can speak for myself, thanks. Nora Vance. My source went missing out here a month ago, and I'm going to find out why." },
            { "WALTER", "Walter Kessler. I worked at that station, a long time ago. I know the way in." },
            { "COLE", "They want the same thing we do, kid. We find Marcus and Jenna, and we get out." },
            { "ELI", "...Okay. Okay." },
        };
        static readonly int[] TalkWho = { 0, 1, 2, 3, 1, 0 };
        int _line = -1;
        float _lineTime, _lineLength;
        Action _onTalkDone;

        // The rear-view mirror: a little camera at the mirror looking at whoever you picked.
        Camera _mirrorCam;
        RenderTexture _mirrorTexture;
        float _mirrorShotUntil;
        int _lastSelected = -1;
        static readonly Vector3 MirrorPos = G(0f, 1.62f, -0.6f);

        const float DriveSpeed = 17f;
        const float StationStartZ = -75f, StationStopZ = -9f, RoadLength = 160f;

        // Godot's camera spots (X is flipped by G()).
        static readonly Vector3 MenuCamPos = G(-4.2f, 1.35f, -6.0f), MenuCamTarget = G(-1.4f, 0.95f, 0.4f);
        static readonly Vector3 ArriveCamPos = G(-2.4f, 2.6f, 7.0f), ArriveCamTarget = G(0.6f, 1.6f, -14.0f);
        static readonly Vector3 BackseatCamPos = G(0f, 1.5f, 1.18f), BackseatCamTarget = G(0f, 1.32f, -3f);
        // Per character (Eli, Cole, Nora, Walter): seat, side camera, side look-at, stand-in color and size.
        static readonly Vector3[] Seats = { G(-0.38f, 0f, -0.1f), G(0.38f, 0f, -0.1f), G(-0.55f, 0.08f, 1.02f), G(0.55f, 0.08f, 1.02f) };
        static readonly Vector3[] SideCams = { G(0.3f, 1.52f, -0.66f), G(-0.3f, 1.52f, -0.66f), G(0.08f, 1.52f, 0.38f), G(-0.08f, 1.52f, 0.38f) };
        static readonly Vector3[] SideLooks = { G(-0.38f, 1.4f, -0.05f), G(0.38f, 1.42f, -0.05f), G(-0.55f, 1.4f, 1.02f), G(0.55f, 1.4f, 1.02f) };
        static readonly Color[] StandInColors = { new Color(0.38f, 0.23f, 0.12f), new Color(0.29f, 0.32f, 0.19f), new Color(0.7f, 0.58f, 0.4f), new Color(0.13f, 0.17f, 0.32f) };
        static readonly float[] Sizes = { 1f, 1.12f, 0.95f, 0.97f };

        static Vector3 G(float x, float y, float z) => new Vector3(-x, y, z);

        Transform _car, _station;
        readonly List<Transform> _scrollers = new List<Transform>();
        readonly List<Transform> _trees = new List<Transform>();
        readonly Transform[] _figures = new Transform[4];
        float _time, _speed = DriveSpeed, _stoppedAt = -1f;
        Action _onArrived;
        bool _arrivedCalled;
        AudioSource _engine;

        public static SZMenuScene Create()
        {
            var go = new GameObject("MenuScene");
            var scene = go.AddComponent<SZMenuScene>();
            scene.Build();
            return scene;
        }

        void Build()
        {
            BuildEnvironment();
            BuildRoadAndForest();
            BuildStation();
            BuildCar();
            for (int i = 0; i < 4; i++) BuildCharacter(i);
            BuildMirror();

            var cam = new GameObject("MenuCamera");
            cam.transform.SetParent(transform);
            Camera = cam.AddComponent<Camera>();
            Camera.fieldOfView = 55f;
            Camera.nearClipPlane = 0.05f;
            Camera.farClipPlane = 300f;
            Camera.clearFlags = CameraClearFlags.SolidColor;
            Camera.backgroundColor = new Color(0.015f, 0.02f, 0.03f);
            cam.AddComponent<AudioListener>();
            cam.tag = "MainCamera";
            SZGraphics.SetupCamera(Camera);
            cam.transform.SetPositionAndRotation(MenuCamPos, Quaternion.LookRotation(MenuCamTarget - MenuCamPos));

            // A low road rumble (the generator hum, slowed down).
            _engine = SZAudio.Attach(cam, "generator_hum", 0.25f, 1000f, loop: true);
            _engine.spatialBlend = 0f;
            _engine.pitch = 0.55f;
        }

        // ---------------------------------------------------------------- what SZGame calls

        public void EnterSelect()
        {
            Mode = State.Select;
            Hovered = -1;
        }

        public void BackToMenu()
        {
            Mode = State.Menu;
            Hovered = -1;
        }

        // After PLAY AS: the team talks while Eli drives, then the drive to the gate.
        public void StartTalk(Action done)
        {
            Mode = State.Talk;
            Hovered = -1;
            _onTalkDone = done;
            NextLine();
        }

        void NextLine()
        {
            _line++;
            if (_line >= Talk.GetLength(0))
            {
                Speaker = Caption = null;
                var done = _onTalkDone;
                _onTalkDone = null;
                done?.Invoke();
                return;
            }
            Speaker = Talk[_line, 0];
            Caption = Talk[_line, 1];
            _lineTime = 0f;
            _lineLength = Mathf.Clamp(Caption.Length / 15f, 1.6f, 7f);  // reading time
        }

        void UpdateTalk(float dt)
        {
            // Tap Space (or click) for the next line, hold Space to skip the talk.
            if (SZInput.Held(SZKey.Space)) SkipHold += dt;
            else
            {
                if (SkipHold > 0f && SkipHold < 0.35f) _lineTime = _lineLength;
                SkipHold = 0f;
            }
            if (SZInput.Click) _lineTime = _lineLength;
            if (SkipHold >= 1f)
            {
                SkipHold = 0f;
                _line = Talk.GetLength(0) - 1;
                _lineTime = _lineLength;
            }
            _lineTime += dt;
            if (_lineTime >= _lineLength) NextLine();
        }

        public void StartArrival(Action onArrived)
        {
            Mode = State.Arriving;
            Hovered = -1;
            _onArrived = onArrived;
            _station.localPosition = new Vector3(_station.localPosition.x, 0f, StationStartZ);
            _station.gameObject.SetActive(true);
        }

        // Skip the drive and the cutscene (Enter or Esc).
        public void SkipArrival()
        {
            if (Mode != State.Arriving) return;
            if (_stoppedAt < 0f || Time.time - _stoppedAt < FadeAt) _stoppedAt = Time.time - FadeAt;
            _speed = 0f;
        }

        const float FadeAt = 2f;  // seconds after the car stops

        // The character under the mouse in the 3D car (or -1).
        public int CharacterAt(Vector2 screenPoint)
        {
            var ray = Camera.ScreenPointToRay(screenPoint);
            if (Physics.Raycast(ray, out var hit, 20f, ~0, QueryTriggerInteraction.Collide))
                for (int i = 0; i < 4; i++)
                    if (_figures[i] != null && hit.collider.transform.IsChildOf(_figures[i])) return i;
            return -1;
        }

        // ---------------------------------------------------------------- every frame

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            _time += dt;
            if (Mode == State.Arriving) UpdateArrival(dt);
            if (Mode == State.Talk) UpdateTalk(dt);
            UpdateMirror();

            // Move the world toward the camera so the car looks like it's driving.
            foreach (var node in _scrollers)
            {
                var p = node.localPosition;
                p.z += _speed * dt;
                if (p.z > 30f)
                {
                    p.z -= RoadLength;
                    if (_trees.Contains(node)) p.x = Mathf.Sign(p.x + 0.9f) * Random.Range(5.5f, 20f) - 0.9f;
                }
                node.localPosition = p;
            }

            // Bumpy road: the car bobs and sways a little.
            float shake = _speed / DriveSpeed;
            _car.localPosition = new Vector3(0f, (Mathf.Sin(_time * 9f) * 0.008f + Mathf.Sin(_time * 2.3f) * 0.012f) * shake, 0f);
            _car.localRotation = Quaternion.Euler(Mathf.Sin(_time * 3.1f) * 0.17f * shake, 0f, -Mathf.Sin(_time * 1.7f) * 0.34f * shake);
            for (int i = 0; i < 4; i++)
            {
                var f = _figures[i];
                var p = f.localPosition;
                p.y = Seats[i].y + Mathf.Sin(_time * 1.6f + Seats[i].x * 3f) * 0.006f;
                f.localPosition = p;
            }
            if (_engine) _engine.pitch = 0.35f + 0.2f * shake;

            // Glide the camera toward where it should be right now.
            var pos = MenuCamPos + new Vector3(-Mathf.Sin(_time * 0.21f) * 0.35f, Mathf.Sin(_time * 0.33f) * 0.08f, 0f);
            var look = MenuCamTarget;
            if (Mode == State.Arriving)
            {
                pos = ArriveCamPos;
                look = ArriveCamTarget;
            }
            else if (Mode == State.Talk && _line >= 0 && _line < TalkWho.Length)
            {
                // The camera goes to whoever is talking.
                pos = SideCams[TalkWho[_line]];
                look = SideLooks[TalkWho[_line]];
                pos += new Vector3(Mathf.Sin(_time * 0.6f) * 0.012f, Mathf.Sin(_time * 0.9f) * 0.01f, 0f);
            }
            else if (Mode == State.Select)
            {
                pos = Hovered >= 0 ? SideCams[Hovered] : BackseatCamPos;
                look = Hovered >= 0 ? SideLooks[Hovered] : BackseatCamTarget;
                // Just picked someone: look into the rear-view mirror at them.
                if (Time.time < _mirrorShotUntil)
                {
                    pos = MirrorPos + G(0.02f, -0.06f, 0.55f);
                    look = MirrorPos + new Vector3(0f, 0.07f, 0f);  // the mirror sits low, below the info panel
                }
                pos += new Vector3(Mathf.Sin(_time * 0.6f) * 0.012f, Mathf.Sin(_time * 0.9f) * 0.01f, 0f);  // road bumps
            }
            Camera.fieldOfView = Mathf.Lerp(Camera.fieldOfView, Mode == State.Select && Time.time < _mirrorShotUntil ? 28f : 55f, dt * 4f);
            float k = 1f - Mathf.Exp(-4f * dt);
            var t = Camera.transform;
            t.position = Vector3.Lerp(t.position, pos, k);
            t.rotation = Quaternion.Slerp(t.rotation, Quaternion.LookRotation(look - pos), k);

            // Name tags over the characters while choosing.
            for (int i = 0; i < 4; i++)
            {
                var tag = _figures[i].Find("NameTag");
                if (tag) tag.gameObject.SetActive(Mode == State.Select && (Hovered == i || Selected == i));
            }
        }

        // ---------------------------------------------------------------- rear-view mirror

        void BuildMirror()
        {
            var mirror = new GameObject("RearViewMirror").transform;
            mirror.SetParent(_car, false);
            mirror.localPosition = MirrorPos;
            Box(mirror, new Vector3(0.3f, 0.1f, 0.03f), Vector3.zero, Mat(new Color(0.04f, 0.04f, 0.04f)));
            Box(mirror, new Vector3(0.02f, 0.12f, 0.02f), new Vector3(0f, 0.1f, 0f), Mat(new Color(0.04f, 0.04f, 0.04f)));
            _mirrorTexture = new RenderTexture(384, 128, 16) { name = "MirrorView" };
            var glass = GameObject.CreatePrimitive(PrimitiveType.Quad);
            Destroy(glass.GetComponent<Collider>());
            glass.transform.SetParent(mirror, false);
            glass.transform.localPosition = new Vector3(0f, 0f, 0.017f);
            glass.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);  // facing the people in the car
            glass.transform.localScale = new Vector3(0.27f, 0.08f, 1f);
            var mat = new Material(Shader.Find("Unlit/Texture")) { mainTexture = _mirrorTexture };
            mat.mainTextureScale = new Vector2(-1f, 1f);   // a mirror shows things the other way round
            mat.mainTextureOffset = new Vector2(1f, 0f);
            glass.GetComponent<Renderer>().sharedMaterial = mat;

            var cam = new GameObject("MirrorCamera");
            cam.transform.SetParent(mirror, false);
            _mirrorCam = cam.AddComponent<Camera>();
            _mirrorCam.targetTexture = _mirrorTexture;
            _mirrorCam.fieldOfView = 30f;
            _mirrorCam.nearClipPlane = 0.05f;
            _mirrorCam.farClipPlane = 60f;
            _mirrorCam.clearFlags = CameraClearFlags.SolidColor;
            _mirrorCam.backgroundColor = new Color(0.01f, 0.012f, 0.02f);
        }

        void UpdateMirror()
        {
            if (_mirrorCam == null) return;
            // Picking someone shows their face in the mirror for a moment.
            if (Mode == State.Select && Selected != _lastSelected && Selected >= 0)
                _mirrorShotUntil = Time.time + 2.5f;
            _lastSelected = Selected;
            int who = Selected >= 0 ? Selected : 0;
            var face = _figures[who] != null ? _figures[who].position + Vector3.up * 1.5f : _car.position + Vector3.up * 1.4f;
            var from = _mirrorCam.transform.position;
            _mirrorCam.transform.rotation = Quaternion.Slerp(_mirrorCam.transform.rotation, Quaternion.LookRotation(face - from), Time.unscaledDeltaTime * 6f);
            _mirrorCam.enabled = Mode == State.Select || Mode == State.Talk;
        }

        void OnDestroy()
        {
            if (_mirrorTexture != null) _mirrorTexture.Release();
        }

        void UpdateArrival(float dt)
        {
            var sp = _station.localPosition;
            sp.z += _speed * dt;
            _station.localPosition = sp;
            // Brake smoothly so the gate stops right in front of the car.
            float remaining = StationStopZ - sp.z;
            if (remaining > 0.05f && _speed > 0.3f && _stoppedAt < 0f)
                _speed = Mathf.Max(_speed - _speed * _speed / (2f * remaining) * dt, 0.3f);
            else
            {
                _speed = 0f;
                if (_stoppedAt < 0f) _stoppedAt = Time.time;
            }
            // Trees past the gate would stand inside the station grounds, so hide them.
            foreach (var tree in _trees)
                tree.gameObject.SetActive(tree.localPosition.z > sp.z + 3f || Mathf.Abs(tree.localPosition.x) > 40f);

            ArrivalText = Mathf.MoveTowards(ArrivalText, _stoppedAt < 0f ? 1f : 0f, dt * 0.5f);
            if (_stoppedAt >= 0f && Time.time - _stoppedAt >= FadeAt)
            {
                Fade = Mathf.MoveTowards(Fade, 1f, dt / 1.5f);
                if (Fade >= 1f && !_arrivedCalled)
                {
                    _arrivedCalled = true;
                    _onArrived?.Invoke();
                }
            }
        }

        // ---------------------------------------------------------------- building

        void BuildEnvironment()
        {
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = new Color(0.25f, 0.3f, 0.4f) * 0.25f;
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.Exponential;
            RenderSettings.fogDensity = 0.045f;
            RenderSettings.fogColor = new Color(0.05f, 0.06f, 0.08f);
            RenderSettings.skybox = null;
            SZGraphics.DarkReflections(new Color(0.03f, 0.035f, 0.05f));

            var moon = new GameObject("Moon").AddComponent<Light>();
            moon.transform.SetParent(transform);
            moon.type = LightType.Directional;
            moon.color = new Color(0.55f, 0.65f, 0.85f);
            moon.intensity = 0.12f;
            moon.transform.rotation = Quaternion.Euler(35f, 150f, 0f);
        }

        static readonly Dictionary<string, Material> Mats = new Dictionary<string, Material>();

        static Material Mat(Color c, float smooth = 0.1f, Color? glow = null)
        {
            string key = c.ToString() + smooth + glow;
            if (!Mats.TryGetValue(key, out var m) || m == null)
            {
                m = SZGraphics.Lit(c, smooth, glow);
                if (c.a < 1f)
                {
                    // Standard shader "Fade" mode, for glass and the chain-link fence.
                    m.SetFloat("_Mode", 2f);
                    m.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    m.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    m.SetInt("_ZWrite", 0);
                    m.EnableKeyword("_ALPHABLEND_ON");
                    m.renderQueue = 3000;
                }
                Mats[key] = m;
            }
            return m;
        }

        static Transform Box(Transform parent, Vector3 size, Vector3 pos, Material mat, float tiltX = 0f)
        {
            var b = GameObject.CreatePrimitive(PrimitiveType.Cube);
            b.transform.SetParent(parent, false);
            b.transform.localPosition = pos;
            b.transform.localScale = size;
            b.transform.localRotation = Quaternion.Euler(tiltX, 0f, 0f);
            b.GetComponent<Renderer>().sharedMaterial = mat;
            Destroy(b.GetComponent<Collider>());
            return b.transform;
        }

        static Transform Cylinder(Transform parent, float radius, float height, Vector3 pos, Material mat)
        {
            var c = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            c.transform.SetParent(parent, false);
            c.transform.localPosition = pos;
            c.transform.localScale = new Vector3(radius * 2f, height / 2f, radius * 2f);
            c.GetComponent<Renderer>().sharedMaterial = mat;
            Destroy(c.GetComponent<Collider>());
            return c.transform;
        }

        static Mesh _cone;

        static Transform Cone(Transform parent, float radius, float height, Vector3 pos, Material mat)
        {
            if (_cone == null)
            {
                // A unit cone: radius 1 at y = -0.5, point at y = +0.5.
                const int sides = 10;
                var verts = new List<Vector3> { new Vector3(0f, 0.5f, 0f), new Vector3(0f, -0.5f, 0f) };
                var tris = new List<int>();
                for (int i = 0; i < sides; i++)
                {
                    float a = i * Mathf.PI * 2f / sides;
                    verts.Add(new Vector3(Mathf.Cos(a), -0.5f, Mathf.Sin(a)));
                }
                for (int i = 0; i < sides; i++)
                {
                    int a = 2 + i, b = 2 + (i + 1) % sides;
                    tris.AddRange(new[] { 0, b, a, 1, a, b });
                }
                _cone = new Mesh { name = "Cone" };
                _cone.SetVertices(verts);
                _cone.SetTriangles(tris, 0);
                _cone.RecalculateNormals();
                _cone.RecalculateBounds();
            }
            var go = new GameObject("Cone");
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            go.transform.localScale = new Vector3(radius, height, radius);
            go.AddComponent<MeshFilter>().sharedMesh = _cone;
            go.AddComponent<MeshRenderer>().sharedMaterial = mat;
            return go.transform;
        }

        void BuildRoadAndForest()
        {
            Box(transform, new Vector3(120f, 0.02f, 260f), new Vector3(0f, -0.02f, -100f), Mat(new Color(0.03f, 0.045f, 0.03f)));
            Box(transform, new Vector3(7.5f, 0.02f, 260f), G(0.9f, 0f, -100f), Mat(new Color(0.06f, 0.06f, 0.065f), 0.3f));
            var paint = Mat(new Color(0.75f, 0.68f, 0.4f), 0.4f);
            var edge = Mat(new Color(0.55f, 0.55f, 0.52f), 0.4f);
            for (int i = 0; i < (int)(RoadLength / 6f); i++)
                _scrollers.Add(Box(transform, new Vector3(0.12f, 0.02f, 2.4f), G(0.9f, 0.015f, 25f - i * 6f), paint));
            foreach (var x in new[] { -2.8f, 4.6f })
                Box(transform, new Vector3(0.1f, 0.02f, 260f), G(x, 0.015f, -100f), edge);

            // Pine trees on both sides of the road.
            var trunk = Mat(new Color(0.05f, 0.035f, 0.025f));
            var needles = Mat(new Color(0.02f, 0.05f, 0.03f));
            for (int i = 0; i < 70; i++)
            {
                float side = i % 2 == 0 ? -1f : 1f;
                var tree = new GameObject("Tree").transform;
                tree.SetParent(transform, false);
                tree.localPosition = G(side * Random.Range(5.5f, 20f) + 0.9f, 0f, 30f - Random.value * RoadLength);
                float h = Random.Range(7f, 13f);
                Cylinder(tree, 0.16f, h, new Vector3(0f, h * 0.5f, 0f), trunk);
                for (int layer = 0; layer < 3; layer++)
                    Cone(tree, Random.Range(1.6f, 2.4f) - layer * 0.45f, h * 0.45f, new Vector3(0f, h * (0.35f + layer * 0.22f), 0f), needles);
                _scrollers.Add(tree);
                _trees.Add(tree);
            }

            // Reflector posts passing by.
            var post = Mat(new Color(0.5f, 0.5f, 0.48f), 0.5f, new Color(0.9f, 0.8f, 0.5f) * 0.25f);
            for (int i = 0; i < 12; i++)
                _scrollers.Add(Box(transform, new Vector3(0.08f, 0.9f, 0.08f), G(5.1f, 0.45f, 25f - i * 14f), post));
        }

        // The Blackwater Weather Station: fence and gate, and the 1960s building behind it.
        void BuildStation()
        {
            _station = new GameObject("Station").transform;
            _station.SetParent(transform, false);
            _station.localPosition = G(0.9f, 0f, StationStartZ);
            _station.gameObject.SetActive(false);

            var concrete = Mat(new Color(0.5f, 0.5f, 0.47f), 0.05f);
            var darkGlass = Mat(new Color(0.03f, 0.035f, 0.04f), 0.8f);
            var litGlass = Mat(new Color(0.3f, 0.25f, 0.15f), 0.7f, new Color(1f, 0.75f, 0.4f) * 0.6f);
            var metal = Mat(new Color(0.3f, 0.3f, 0.3f), 0.5f);
            var fence = Mat(new Color(0.45f, 0.45f, 0.45f, 0.25f), 0.4f);

            for (int i = 0; i < 21; i++)
            {
                float px = -40f + i * 4f;
                if (Mathf.Abs(px) < 3.9f) continue;
                Box(_station, new Vector3(0.08f, 2.4f, 0.08f), G(px, 1.2f, 0f), metal);
            }
            foreach (var side in new[] { -1f, 1f })
            {
                Box(_station, new Vector3(36f, 2.2f, 0.02f), G(side * 22f, 1.1f, 0f), fence);
                Box(_station, new Vector3(36f, 0.05f, 0.05f), G(side * 22f, 2.4f, 0f), metal);
                Box(_station, new Vector3(0.16f, 2.8f, 0.16f), G(side * 4f, 1.4f, 0f), metal);
            }
            Box(_station, new Vector3(7.8f, 2.2f, 0.03f), G(0f, 1.15f, 0f), fence);
            Box(_station, new Vector3(7.8f, 0.06f, 0.06f), G(0f, 2.25f, 0f), metal);
            Box(_station, new Vector3(7.8f, 0.06f, 0.06f), G(0f, 0.1f, 0f), metal);

            // Warning sign on the gate.
            Box(_station, new Vector3(1.6f, 0.9f, 0.03f), G(1.6f, 1.4f, 0.05f), Mat(new Color(0.75f, 0.72f, 0.62f)));
            var sign = new GameObject("SignText");
            sign.transform.SetParent(_station, false);
            sign.transform.localPosition = G(1.6f, 1.4f, 0.08f);
            sign.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);
            var text = sign.AddComponent<TextMesh>();
            text.text = "U.S. GOVERNMENT PROPERTY\nBLACKWATER WEATHER STATION\nNO TRESPASSING";
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            sign.GetComponent<MeshRenderer>().sharedMaterial = text.font.material;
            text.fontSize = 48;
            text.characterSize = 0.0165f;
            text.anchor = TextAnchor.MiddleCenter;
            text.alignment = TextAlignment.Center;
            text.color = new Color(0.12f, 0.08f, 0.06f);

            // The building, 25-30 m behind the gate.
            Box(_station, new Vector3(22f, 7f, 12f), G(-19.5f, 3.5f, -30f), concrete);
            Box(_station, new Vector3(17f, 10.5f, 14f), G(0f, 5.25f, -29f), concrete);
            Box(_station, new Vector3(26f, 8f, 12f), G(21.5f, 4f, -30f), concrete);
            float frontWing = -24f + 0.06f, frontCenter = -22f + 0.06f;
            foreach (var row in new[] { 2f, 4.8f })
                foreach (var wx in new[] { -28f, -23.5f, -19f, -14.5f, -10.5f })
                    Box(_station, new Vector3(2.6f, 1.3f, 0.1f), G(wx, row, frontWing), row == 4.8f && wx == -19f ? litGlass : darkGlass);
            foreach (var row in new[] { 2.2f, 5.6f })
                foreach (var wx in new[] { 12f, 19f, 26f, 32f })
                    Box(_station, new Vector3(5f, 1.9f, 0.1f), G(wx, row, frontWing), darkGlass);
            foreach (var wx in new[] { -6.5f, -4f, 4f, 6.5f })
                foreach (var row in new[] { 3.4f, 5.6f, 7.8f })
                    Box(_station, new Vector3(0.8f, 1f, 0.1f), G(wx, row, frontCenter), darkGlass);
            Box(_station, new Vector3(4.4f, 3.6f, 0.1f), G(0f, 7.6f, frontCenter), Mat(new Color(0.18f, 0.16f, 0.14f)));
            Box(_station, new Vector3(6f, 0.25f, 1.6f), G(0f, 3.2f, frontCenter + 0.8f), concrete);
            Box(_station, new Vector3(3.8f, 3f, 0.1f), G(0f, 1.5f, frontCenter),
                Mat(new Color(0.05f, 0.06f, 0.06f), 0.8f, new Color(0.4f, 0.9f, 0.7f) * 0.15f));
            Box(_station, new Vector3(0.25f, 9f, 0.25f), G(26f, 12.5f, -31f), metal);
            Box(_station, new Vector3(2.4f, 0.1f, 0.1f), G(26f, 16.2f, -31f), metal);
            Box(_station, new Vector3(0.1f, 0.1f, 2f), G(26f, 15f, -31f), metal);

            PointLight(_station, G(0f, 4f, -19.5f), new Color(1f, 0.85f, 0.6f), 2f, 14f);
            Box(_station, new Vector3(0.12f, 4.5f, 0.12f), G(-5f, 2.25f, 0.4f), metal);
            PointLight(_station, G(-5f, 4.6f, 0.6f), new Color(0.85f, 0.9f, 1f), 1.4f, 9f);
        }

        static Light PointLight(Transform parent, Vector3 pos, Color color, float energy, float range)
        {
            var go = new GameObject("Light");
            go.transform.SetParent(parent, false);
            go.transform.localPosition = pos;
            var l = go.AddComponent<Light>();
            l.type = LightType.Point;
            l.color = color;
            l.intensity = energy;
            l.range = range;
            return l;
        }

        void BuildCar()
        {
            _car = new GameObject("Car").transform;
            _car.SetParent(transform, false);
            var paint = Mat(new Color(0.34f, 0.1f, 0.08f), 0.6f);
            var trim = Mat(new Color(0.06f, 0.06f, 0.06f), 0.4f);
            var chrome = Mat(new Color(0.5f, 0.5f, 0.5f), 0.75f);
            var glass = Mat(new Color(0.35f, 0.42f, 0.5f, 0.2f), 0.95f);
            var seat = Mat(new Color(0.12f, 0.09f, 0.07f));
            var dash = Mat(new Color(0.05f, 0.05f, 0.05f), 0.2f, new Color(0.3f, 0.9f, 0.6f) * 0.06f);
            // The outside of the car (a downloaded car from Asset Slots replaces it;
            // the seats, dashboard and wheel stay so everyone still has a seat).
            var shell = new GameObject("Shell").transform;
            shell.SetParent(_car, false);

            Box(shell, new Vector3(2f, 0.45f, 4.8f), G(0f, 0.55f, 0.2f), paint);
            Box(shell, new Vector3(1.84f, 0.02f, 2.6f), G(0f, 0.79f, 0.4f), Mat(new Color(0.05f, 0.045f, 0.04f)));
            Box(shell, new Vector3(2f, 0.35f, 1.5f), G(0f, 0.95f, -1.55f), paint);
            Box(shell, new Vector3(2f, 0.35f, 1f), G(0f, 0.95f, 2.1f), paint);
            Box(shell, new Vector3(0.08f, 0.38f, 2.4f), G(-0.96f, 0.95f, 0.4f), paint);
            Box(shell, new Vector3(0.08f, 0.38f, 2.4f), G(0.96f, 0.95f, 0.4f), paint);
            Box(shell, new Vector3(2.04f, 0.1f, 4.9f), G(0f, 0.3f, 0.2f), chrome);
            Box(shell, new Vector3(1.86f, 0.06f, 2.1f), G(0f, 1.84f, 0.5f), paint);
            Box(shell, new Vector3(1.8f, 0.02f, 2.04f), G(0f, 1.8f, 0.5f), Mat(new Color(0.13f, 0.12f, 0.11f)));

            foreach (var x in new[] { -0.93f, 0.93f })
            {
                Box(shell, new Vector3(0.07f, 0.78f, 0.07f), G(x, 1.47f, -0.75f), trim, 28f);
                Box(shell, new Vector3(0.07f, 0.72f, 0.07f), G(x, 1.48f, 0.55f), trim);
                Box(shell, new Vector3(0.07f, 0.78f, 0.07f), G(x, 1.47f, 1.6f), trim, -25f);
            }
            Box(shell, new Vector3(1.8f, 0.8f, 0.02f), G(0f, 1.47f, -0.75f), glass, 28f);
            Box(shell, new Vector3(1.8f, 0.78f, 0.02f), G(0f, 1.47f, 1.63f), glass, -25f);
            foreach (var x in new[] { -0.95f, 0.95f })
                Box(shell, new Vector3(0.02f, 0.66f, 2.2f), G(x, 1.47f, 0.45f), glass);

            Box(_car, new Vector3(1.8f, 0.22f, 0.4f), G(0f, 1.08f, -0.82f), dash);
            var wheel = Cylinder(_car, 0.17f, 0.03f, G(-0.38f, 1.18f, -0.55f), trim);
            wheel.localRotation = Quaternion.Euler(65f, 0f, 0f);
            foreach (var p in new[] { G(-0.38f, 0.85f, 0.15f), G(0.38f, 0.85f, 0.15f) })
            {
                Box(_car, new Vector3(0.55f, 0.12f, 0.55f), p, seat);
                Box(_car, new Vector3(0.55f, 0.5f, 0.12f), p + new Vector3(0f, 0.3f, 0.3f), seat);
            }
            Box(_car, new Vector3(1.8f, 0.12f, 0.6f), G(0f, 0.9f, 1.05f), seat);
            Box(_car, new Vector3(1.8f, 0.65f, 0.12f), G(0f, 1.25f, 1.38f), seat);

            var tire = Mat(new Color(0.02f, 0.02f, 0.02f));
            foreach (var p in new[] { G(-0.95f, 0.38f, -1.4f), G(0.95f, 0.38f, -1.4f), G(-0.95f, 0.38f, 1.7f), G(0.95f, 0.38f, 1.7f) })
                Cylinder(shell, 0.38f, 0.25f, p, tire).localRotation = Quaternion.Euler(0f, 0f, 90f);

            var head = Mat(new Color(1f, 1f, 0.9f), 0.8f, new Color(1f, 0.95f, 0.8f) * 3f);
            var tail = Mat(new Color(0.5f, 0.02f, 0.02f), 0.7f, new Color(1f, 0.05f, 0.03f) * 2f);
            foreach (var x in new[] { -0.7f, 0.7f })
            {
                Box(shell, new Vector3(0.32f, 0.14f, 0.04f), G(x, 0.9f, -2.31f), head);
                Box(shell, new Vector3(0.3f, 0.1f, 0.04f), G(x, 0.92f, 2.61f), tail);
                var beam = new GameObject("Headlight");
                beam.transform.SetParent(_car, false);
                beam.transform.localPosition = G(x, 0.9f, -2.4f);
                beam.transform.localRotation = Quaternion.Euler(4f, 180f, 0f);
                var l = beam.AddComponent<Light>();
                l.type = LightType.Spot;
                l.color = new Color(1f, 0.94f, 0.8f);
                l.intensity = 4f;
                l.range = 45f;
                l.spotAngle = 56f;
                l.shadows = LightShadows.Soft;
            }
            PointLight(_car, G(0f, 1.45f, 0.35f), new Color(1f, 0.9f, 0.78f), 0.55f, 2.4f);
            PointLight(_car, G(0f, 1.25f, -0.6f), new Color(0.4f, 1f, 0.7f), 0.15f, 1.6f);
            var spot = new GameObject("CarAsset").transform;
            spot.SetParent(_car, false);
            spot.localPosition = G(0f, 0f, 0.2f);
            spot.localRotation = Quaternion.Euler(0f, 180f, 0f);  // our car's front is -Z
            if (SZAssets.Spawn("car", spot, onGround: true, size: 4.9f) != null) shell.gameObject.SetActive(false);
        }

        void BuildCharacter(int i)
        {
            var root = new GameObject(SZCharacters.Names[i]).transform;
            root.SetParent(_car, false);
            root.localPosition = Seats[i];
            // Everyone faces the front of the car (-Z).
            var holder = new GameObject("Holder").transform;
            holder.SetParent(root, false);
            holder.localRotation = Quaternion.Euler(0f, 180f, 0f);

            // The simple sitting figure: the team's models are T-pose statues
            // (no skeleton yet), so they can't sit in a car. They appear in the game.
            StandIn(holder, i);

            // Clickable area around the whole figure.
            var hit = new GameObject("Click");
            hit.transform.SetParent(root, false);
            var capsule = hit.AddComponent<CapsuleCollider>();
            capsule.isTrigger = true;
            capsule.radius = 0.28f;
            capsule.height = 1f;
            capsule.center = new Vector3(0f, 1.2f, 0f);

            var tag = new GameObject("NameTag");
            tag.transform.SetParent(root, false);
            tag.transform.localPosition = new Vector3(0f, 1.9f, -0.25f);
            var text = tag.AddComponent<TextMesh>();
            text.text = SZCharacters.Names[i].Split(' ')[0].ToUpper();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            tag.GetComponent<MeshRenderer>().sharedMaterial = text.font.material;
            text.fontSize = 48;
            text.characterSize = 0.006f;
            text.anchor = TextAnchor.MiddleCenter;
            text.color = new Color(0.91f, 0.69f, 0.29f);
            tag.AddComponent<SZBillboard>();
            tag.SetActive(false);
            _figures[i] = root;
        }

        // The Godot home screen's simple sitting figure.
        void StandIn(Transform holder, int i)
        {
            float s = Sizes[i];
            var body = Mat(StandInColors[i], 0.15f);
            var skin = Mat(new Color(0.62f, 0.48f, 0.38f), 0.3f);
            var legs = Mat(new Color(0.08f, 0.09f, 0.12f));
            Part(holder, PrimitiveType.Capsule, new Vector3(0f, 1.12f, -0.12f), new Vector3(0.4f * s, 0.34f * s, 0.4f * s), Quaternion.Euler(-8f, 0f, 0f), body);
            Part(holder, PrimitiveType.Sphere, new Vector3(0f, 1.12f + 0.44f * s, -0.1f), new Vector3(0.24f * s, 0.26f * s, 0.24f * s), Quaternion.identity, skin);
            foreach (var side in new[] { -1f, 1f })
            {
                Part(holder, PrimitiveType.Capsule, new Vector3(side * 0.1f, 0.98f, 0.12f), new Vector3(0.16f * s, 0.25f, 0.16f * s), Quaternion.Euler(90f, 0f, 0f), legs);
                Part(holder, PrimitiveType.Capsule, new Vector3(side * 0.22f * s, 1.12f, 0.05f), new Vector3(0.12f * s, 0.25f * s, 0.12f * s),
                    Quaternion.Euler(i == 0 ? -55f : -25f, 0f, 0f), body);
            }
        }

        static void Part(Transform parent, PrimitiveType type, Vector3 pos, Vector3 scale, Quaternion rot, Material mat)
        {
            var p = GameObject.CreatePrimitive(type);
            p.transform.SetParent(parent, false);
            p.transform.localPosition = pos;
            p.transform.localScale = scale;
            p.transform.localRotation = rot;
            p.GetComponent<Renderer>().sharedMaterial = mat;
            Destroy(p.GetComponent<Collider>());
        }
    }
}
