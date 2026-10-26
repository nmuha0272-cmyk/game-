using System.Collections.Generic;
using System.Text;
using UnityEngine;

// Chapter 1's puzzles, rebuilt from the Godot level (tools/export_for_unity.gd
// writes every puzzle piece and how they're wired). Same rules as Godot:
//   Inputs  - levers, buttons, things you hold, fuse boxes and card readers,
//             keypads, breaker panels, the radio, the terminal, the darkroom,
//             the generator, tape machines, a pressure plate.
//   Gates   - the "brain": when ALL (or ANY) of its inputs are active, its
//             outputs switch on (and stay on if it "latches").
//   Outputs - doors, lights, gates and shutters that move, status lamps.
// Code displays around the level show the keypad codes, the breaker pattern
// and the radio frequency once their clue is unlocked.
// Online, the host decides; everyone else asks the host and is told the result.
namespace Deepwell
{
    public class SZPuzzles : MonoBehaviour
    {
        public static SZPuzzles Instance { get; private set; }
        public readonly List<SZPiece> Pieces = new List<SZPiece>();

        public static SZPuzzles Create(SZLevelData data, Transform parent)
        {
            var go = new GameObject("Puzzles");
            go.transform.SetParent(parent);
            var puzzles = go.AddComponent<SZPuzzles>();
            Instance = puzzles;
            var list = data.puzzles ?? new PuzzleData[0];
            for (int i = 0; i < list.Length; i++) puzzles.Pieces.Add(SZPiece.Create(list[i], i, go.transform));
            foreach (var p in puzzles.Pieces) p.Wire(puzzles);
            if (SZNet.IsAuthority)
                foreach (var p in puzzles.Pieces) p.HostStart();
            return puzzles;
        }

        void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        public SZPiece Get(int index) => index >= 0 && index < Pieces.Count ? Pieces[index] : null;

        // A player did something to a piece (pulled a lever, typed a key...).
        public void Request(SZPiece piece, string action, string arg = "")
        {
            if (SZNet.IsAuthority) piece.HostAction(action, arg, SZNet.MyId);
            else SZNet.Instance.SendToHost(SZNet.Msg("PZA", piece.Index, action, arg));
        }

        // Host: a piece changed. Tell everyone, then let the gates think.
        public void HostChanged(SZPiece piece)
        {
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("PZS", piece.Index, piece.Pack()));
            foreach (var p in Pieces)
                if (p is PzGate gate) gate.InputChanged(piece);
        }

        void Update()
        {
            if (!SZNet.IsAuthority) return;
            foreach (var p in Pieces) p.HostTick(Time.deltaTime);
        }

        // ---------------------------------------------------------------- network

        public void OnMessage(int from, string[] m)
        {
            var piece = Get(SZNet.I(m, 1));
            if (piece == null) return;
            if (m[0] == "PZA" && SZNet.IsHost) piece.HostAction(SZNet.T(m, 2), SZNet.T(m, 3), from);
            else if (m[0] == "PZS" && !SZNet.IsHost) piece.Unpack(SZNet.T(m, 2));
        }

        // Everything in one line for the host's once-a-second summary.
        public string Summary()
        {
            var sb = new StringBuilder();
            for (int i = 0; i < Pieces.Count; i++)
            {
                if (i > 0) sb.Append('~');
                sb.Append(Pieces[i].Pack());
            }
            return sb.ToString();
        }

        public void ApplySummary(string summary)
        {
            if (string.IsNullOrEmpty(summary)) return;
            var parts = summary.Split('~');
            for (int i = 0; i < parts.Length && i < Pieces.Count; i++) Pieces[i].Unpack(parts[i]);
        }
    }

    // ==================================================================== pieces

    public abstract class SZPiece : MonoBehaviour, ISZInteractable
    {
        public int Index { get; private set; }
        public PuzzleData Data { get; private set; }
        public bool Active { get; protected set; }
        protected SZPuzzles Puzzles;

        public virtual string Prompt => "";
        public virtual void Interact(SZPlayer by) { }
        public virtual string DisplayCode => "";

        public static SZPiece Create(PuzzleData d, int index, Transform parent)
        {
            var go = new GameObject(d.kind + " " + d.name);
            go.transform.SetParent(parent);
            if (d.Has3D) go.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            SZPiece piece;
            switch (d.kind)
            {
                case "puzzle_gate": piece = go.AddComponent<PzGate>(); break;
                case "door": piece = go.AddComponent<PzDoor>(); break;
                case "puzzle_lights": piece = go.AddComponent<PzLights>(); break;
                case "puzzle_mover": piece = go.AddComponent<PzMover>(); break;
                case "status_lamp": piece = go.AddComponent<PzLamp>(); break;
                case "lever": piece = go.AddComponent<PzLever>(); break;
                case "puzzle_button": piece = go.AddComponent<PzButton>(); break;
                case "hold_switch": piece = go.AddComponent<PzHold>(); break;
                case "item_socket": piece = go.AddComponent<PzSocket>(); break;
                case "keypad": piece = go.AddComponent<PzKeypad>(); break;
                case "breaker_panel": piece = go.AddComponent<PzBreakerPanel>(); break;
                case "breaker_switch": piece = go.AddComponent<PzBreakerSwitch>(); break;
                case "radio": piece = go.AddComponent<PzRadio>(); break;
                case "tune_button": piece = go.AddComponent<PzTune>(); break;
                case "terminal": piece = go.AddComponent<PzTerminal>(); break;
                case "character_station": piece = go.AddComponent<PzStation>(); break;
                case "generator": piece = go.AddComponent<PzGenerator>(); break;
                case "tape_machine": piece = go.AddComponent<PzTape>(); break;
                case "lore_check": piece = go.AddComponent<PzLoreCheck>(); break;
                case "pressure_plate": piece = go.AddComponent<PzPlate>(); break;
                case "signal_light": piece = go.AddComponent<PzSignal>(); break;
                case "airlock": piece = go.AddComponent<PzAirlock>(); break;
                default: piece = go.AddComponent<PzGeneric>(); break;
            }
            piece.Index = index;
            piece.Data = d;
            piece.Build();
            return piece;
        }

        // Find the pieces this one points at.
        public virtual void Wire(SZPuzzles puzzles) => Puzzles = puzzles;
        protected virtual void Build() { }
        public virtual void HostStart() { }
        public virtual void HostTick(float dt) { }
        public virtual void HostAction(string action, string arg, int by) { }
        // As a gate's output: switch on/off (host).
        public virtual void PuzzleSet(bool on) => SetActive(on);

        // Host: change state, show it, tell everyone.
        protected void SetActive(bool value)
        {
            if (value == Active) return;
            Active = value;
            Show();
            Puzzles.HostChanged(this);
        }

        // Resend this piece's state (after changing something other than Active).
        protected void Changed() => Puzzles.HostChanged(this);

        // Make it look like its state (lever down, lamp green, lights on...).
        protected virtual void Show() { }

        public virtual string Pack() => Active ? "1" : "0";

        public virtual void Unpack(string s)
        {
            bool value = s.Length > 0 && s[0] == '1';
            if (value == Active) return;
            Active = value;
            Show();
        }

        // ---------------------------------------------------------------- shared helpers

        // PuzzleInput.requires: another piece that has to be done first.
        protected bool RequirementMet(out string message)
        {
            message = Data.S("requires_message", "Not yet.");
            var need = Puzzles != null ? Puzzles.Get(Data.Ref("requires")) : null;
            return need == null || need.Active;
        }

        protected Transform Part(PrimitiveType type, Vector3 at, Vector3 size, Color color, float glow = 0f)
        {
            var p = GameObject.CreatePrimitive(type);
            p.transform.SetParent(transform, false);
            p.transform.localPosition = at;
            p.transform.localScale = size;
            p.GetComponent<Renderer>().sharedMaterial = SZGraphics.Lit(color, 0.35f, glow > 0f ? color * glow : (Color?)null);
            Destroy(p.GetComponent<Collider>());
            return p.transform;
        }

        // Makes it something you can look at and press E on.
        protected void Clickable(Vector3 center, Vector3 size)
        {
            var box = gameObject.AddComponent<BoxCollider>();
            box.isTrigger = true;
            box.center = center;
            box.size = size;
        }

        protected TextMesh Text(Vector3 at, float height, Color color)
        {
            var go = new GameObject("Text");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = at;
            go.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);  // readable from the front
            var t = go.AddComponent<TextMesh>();
            t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            go.GetComponent<MeshRenderer>().sharedMaterial = t.font.material;
            t.fontSize = 48;
            t.characterSize = height / 4.8f;
            t.anchor = TextAnchor.MiddleCenter;
            t.alignment = TextAlignment.Center;
            t.color = color;
            return t;
        }

        protected static void Say(string text, float seconds = 3f) => SZGame.Instance.Say(text, seconds);

        // Host: show a message to everyone (a puzzle solved, a door unlocked...).
        protected static void SayAll(string text)
        {
            if (string.IsNullOrEmpty(text)) return;
            Say(text, 4f);
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("SAY", text));
        }

        protected static bool TeamHas(SZCharacter c)
        {
            foreach (var v in SZWorld.Instance.PlayerViews()) if (v.character == c) return true;
            return false;
        }

        protected static int TeamSize => SZWorld.Instance.PlayerViews().Count;

        protected static string ItemName(string id)
        {
            var d = SZWorld.Instance.Data.items;
            var known = d != null ? System.Array.Find(d, i => i.id == id) : null;
            return known != null ? known.name : id.Replace('_', ' ');
        }
    }

    // ---------------------------------------------------------------- the brain

    public class PzGate : SZPiece
    {
        int[] _inputs, _outputs;
        bool _solvedOnce;

        public override void Wire(SZPuzzles puzzles)
        {
            base.Wire(puzzles);
            _inputs = Data.Refs("inputs");
            _outputs = Data.Refs("outputs");
        }

        public void InputChanged(SZPiece piece)
        {
            if (System.Array.IndexOf(_inputs, piece.Index) < 0) return;
            if (Data.B("latch") && Active) return;
            int on = 0, count = 0;
            foreach (var i in _inputs)
            {
                var p = Puzzles.Get(i);
                if (p == null) continue;
                count++;
                if (p.Active) on++;
            }
            bool any = Mathf.RoundToInt(Data.N("mode")) == 1;
            bool result = any ? on > 0 : count > 0 && on == count;
            if (result == Active) return;
            SetActive(result);
            foreach (var o in _outputs) Puzzles.Get(o)?.PuzzleSet(result);
            if (result && !_solvedOnce)
            {
                _solvedOnce = true;
                SayAll(Data.S("solved_message"));
            }
        }
    }

    // ---------------------------------------------------------------- outputs

    // A door a puzzle opens (or a locked door: its lock is on the SZDoor itself).
    public class PzDoor : SZPiece
    {
        public SZDoor Door { get; private set; }

        public override void Wire(SZPuzzles puzzles)
        {
            base.Wire(puzzles);
            foreach (var d in SZWorld.Instance.Doors)
                if (d.PieceIndex == Index) Door = d;
        }

        public override void PuzzleSet(bool on)
        {
            Active = on;
            if (Door != null)
            {
                Door.PuzzleOpened = Door.PuzzleOpened || on;
                SZWorld.Instance.RequestDoor(Door, on);
            }
            Changed();
        }

        protected override void Show()
        {
            if (Door != null && Active) Door.PuzzleOpened = true;
        }
    }

    // Lights that come on when the puzzle is solved (like the power coming back).
    public class PzLights : SZPiece
    {
        protected override void Show()
        {
            if (SZLevelBuilder.LightGroups.TryGetValue(Index, out var lights))
                foreach (var l in lights) if (l) l.enabled = Active;
            if (Active) SZAudio.PlayAt("generator_hum", transform.position, 0.6f, 25f);
        }
    }

    // A gate, shutter or flood water that moves when solved.
    public class PzMover : SZPiece
    {
        Vector3 _offset;
        float _t, _time;
        readonly List<Transform> _parts = new List<Transform>();
        readonly List<Vector3> _closed = new List<Vector3>();

        protected override void Build()
        {
            var v = Data.V("open_offset");
            // Godot is right-handed: flip X.
            _offset = v != null && v.Length >= 3 ? new Vector3(-v[0], v[1], v[2]) : Vector3.up * 2f;
            _time = Mathf.Max(Data.N("move_time", 1f), 0.1f);
            if (SZLevelBuilder.MoverParts.TryGetValue(Index, out var parts))
                foreach (var p in parts)
                {
                    _parts.Add(p);
                    _closed.Add(p.position);
                }
        }

        protected override void Show() => SZAudio.PlayAt("metal_creak", transform.position, 0.9f, 25f);

        void Update()
        {
            float target = Active ? 1f : 0f;
            if (Mathf.Approximately(_t, target)) return;
            _t = Mathf.MoveTowards(_t, target, Time.deltaTime / _time);
            float k = Mathf.SmoothStep(0f, 1f, _t);
            for (int i = 0; i < _parts.Count; i++) if (_parts[i]) _parts[i].position = _closed[i] + _offset * k;
        }
    }

    // A small lamp: red, green when the puzzle is solved.
    public class PzLamp : SZPiece
    {
        Renderer _bulb;

        protected override void Build()
        {
            _bulb = Part(PrimitiveType.Sphere, Vector3.zero, Vector3.one * 0.08f, Color.red, 2f).GetComponent<Renderer>();
        }

        protected override void Show()
        {
            var c = Active ? Color.green : Color.red;
            _bulb.material.color = c;
            _bulb.material.SetColor("_EmissionColor", c * 2f);
        }
    }

    // ---------------------------------------------------------------- inputs

    public class PzLever : SZPiece
    {
        Transform _handle;

        protected override void Build()
        {
            Part(PrimitiveType.Cube, new Vector3(0f, 0f, 0f), new Vector3(0.22f, 0.32f, 0.08f), new Color(0.3f, 0.3f, 0.28f));
            _handle = Part(PrimitiveType.Cube, new Vector3(0f, 0.08f, 0.1f), new Vector3(0.04f, 0.04f, 0.22f), new Color(0.7f, 0.15f, 0.1f));
            Clickable(new Vector3(0f, 0f, 0.05f), new Vector3(0.4f, 0.5f, 0.35f));
        }

        public override string Prompt
        {
            get
            {
                if (Active && Data.B("one_way")) return "Done.";
                return RequirementMet(out var why) ? (Active ? "[E] Push the lever back" : "[E] Pull the lever") : why;
            }
        }

        public override void Interact(SZPlayer by)
        {
            if (!RequirementMet(out var why)) { Say(why, 2f); return; }
            if (Active && Data.B("one_way")) return;
            Puzzles.Request(this, "use");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "use" || (Active && Data.B("one_way"))) return;
            SetActive(!Active);
            SZAudio.PlayAt("metal_creak", transform.position, 0.6f, 12f);
        }

        protected override void Show() =>
            _handle.localPosition = new Vector3(0f, Active ? -0.08f : 0.08f, 0.1f);
    }

    public class PzButton : SZPiece
    {
        Renderer _cap;
        float _offAt;

        protected override void Build()
        {
            Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.24f, 0.24f, 0.06f), new Color(0.25f, 0.25f, 0.25f));
            _cap = Part(PrimitiveType.Cylinder, new Vector3(0f, 0f, 0.05f), new Vector3(0.09f, 0.02f, 0.09f), new Color(0.8f, 0.1f, 0.08f), 0.6f).GetComponent<Renderer>();
            _cap.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            Clickable(new Vector3(0f, 0f, 0.05f), new Vector3(0.35f, 0.35f, 0.3f));
        }

        public override string Prompt => RequirementMet(out var why) ? (Active ? "..." : "[E] " + Data.S("prompt_text", "Press the button")) : why;

        public override void Interact(SZPlayer by)
        {
            if (!RequirementMet(out var why)) { Say(why, 2f); return; }
            Puzzles.Request(this, "use");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "use" || Active) return;
            // The elevator's Descend button ends the chapter (Godot's elevator.gd):
            // only once the key consoles powered it, and the whole team is inside.
            if (Data.name == "DescendButton")
            {
                var power = Puzzles.Pieces.Find(p => p.Data.name == "DualKey");
                if (power != null && !power.Active) { SayAll("The elevator has no power. Turn both keys first."); return; }
                foreach (var v in SZWorld.Instance.PlayerViews())
                    if (Vector3.Distance(v.position, transform.position) > 3.5f) { SayAll("Everyone has to be in the elevator."); return; }
                SZWorld.Instance.EndChapter();
            }
            _offAt = Time.time + Mathf.Max(Data.N("active_time", 3f), 0.2f);
            SetActive(true);
            SZAudio.PlayAt("repair_click", transform.position, 0.8f, 10f);
        }

        public override void HostTick(float dt)
        {
            if (Active && Time.time >= _offAt) SetActive(false);
        }

        protected override void Show() => _cap.material.color = Active ? Color.green : new Color(0.8f, 0.1f, 0.08f);
    }

    // Something one player keeps holding (a heavy gate, a vent cover, a breaker):
    // E to grab, E again (or walk away) to let go. Playing alone, it stays on.
    public class PzHold : SZPiece
    {
        int _holder = -1;
        Vector3 _holdFrom;

        protected override void Build()
        {
            Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.3f, 0.3f, 0.08f), new Color(0.32f, 0.3f, 0.26f));
            Part(PrimitiveType.Cube, new Vector3(0f, 0f, 0.08f), new Vector3(0.22f, 0.04f, 0.06f), new Color(0.75f, 0.6f, 0.15f));
            Clickable(new Vector3(0f, 0f, 0.05f), new Vector3(0.6f, 0.6f, 0.4f));
        }

        bool Allowed(SZCharacter who)
        {
            int need = Mathf.RoundToInt(Data.N("required_character", -1f));
            if (need < 0) return true;
            var c = GodotCharacter(need);
            return who == c || !TeamHas(c);  // BACKUP: if nobody plays them, anyone can
        }

        // Godot's character ids: SON 0, JOURNALIST 1, ENGINEER 2, GUARD 3.
        public static SZCharacter GodotCharacter(int id) =>
            id == 1 ? SZCharacter.Nora : id == 2 ? SZCharacter.Walter : id == 3 ? SZCharacter.Cole : SZCharacter.Eli;

        public override string Prompt
        {
            get
            {
                var me = SZWorld.Instance.Local;
                if (!RequirementMet(out var why)) return why;
                if (_holder == SZNet.MyId) return "[E] Let go";
                if (Active) return TeamSize <= 1 ? "Done." : "Someone is holding it.";
                if (!Allowed(me.Character)) return "Only " + SZCharacters.Names[(int)GodotCharacter(Mathf.RoundToInt(Data.N("required_character")))] + " is strong enough.";
                return "[E] " + Data.S("prompt_text", "Hold it");
            }
        }

        public override void Interact(SZPlayer by)
        {
            if (!RequirementMet(out var why)) { Say(why, 2f); return; }
            if (!Allowed(by.Character) && _holder != SZNet.MyId) return;
            Puzzles.Request(this, _holder == SZNet.MyId ? "release" : "hold");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action == "hold" && !Active)
            {
                var view = SZWorld.Instance.PlayerViews().Find(v => v.id == by);
                if (!Allowed(view.character)) return;
                _holder = by;
                _holdFrom = view.position;
                SetActive(true);
                if (TeamSize <= 1) SayAll("(Playing alone, it stays up by itself.)");
                Changed();
            }
            else if (action == "release" && _holder == by && TeamSize > 1)
            {
                _holder = -1;
                SetActive(false);
            }
        }

        public override void HostTick(float dt)
        {
            if (!Active || _holder < 0 || TeamSize <= 1) return;
            // Walk away and you let go.
            var views = SZWorld.Instance.PlayerViews();
            var v = views.Find(x => x.id == _holder);
            float limit = Data.N("max_distance", 0.8f) + 0.4f;
            if (v.id != _holder || Vector3.Distance(v.position, _holdFrom) > limit)
            {
                _holder = -1;
                SetActive(false);
            }
        }

        public override string Pack() => (Active ? "1" : "0") + ":" + _holder;

        public override void Unpack(string s)
        {
            base.Unpack(s);
            var parts = s.Split(':');
            if (parts.Length > 1 && int.TryParse(parts[1], out var h)) _holder = h;
        }
    }

    // A fuse box, card reader, gate clamp...: hold E to put the item in.
    public class PzSocket : SZPiece, ISZHoldable
    {
        Renderer _light;
        string Item => Data.S("item_id", "fuse");

        protected override void Build()
        {
            Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.32f, 0.42f, 0.12f), new Color(0.35f, 0.36f, 0.33f));
            _light = Part(PrimitiveType.Sphere, new Vector3(0f, 0.15f, 0.07f), Vector3.one * 0.04f, Color.red, 2f).GetComponent<Renderer>();
            var label = Data.S("label_text");
            if (label.Length > 0) Text(new Vector3(0f, -0.05f, 0.07f), 0.03f, new Color(0.9f, 0.85f, 0.6f)).text = label;
            Clickable(new Vector3(0f, 0f, 0.05f), new Vector3(0.5f, 0.6f, 0.4f));
        }

        public override string Prompt
        {
            get
            {
                if (Active) return "Done.";
                if (!SZWorld.Instance.Local.Inventory.Has(Item)) return "Needs a " + ItemName(Item) + ".";
                return RequirementMet(out var why) ? "[Hold E] Put in the " + ItemName(Item) : why;
            }
        }

        public float HoldTime(SZPlayer by)
        {
            if (Active || !by.Inventory.Has(Item) || !RequirementMet(out _)) return 0f;
            return by.Character == SZCharacter.Walter ? Data.N("engineer_insert_time", 1f) : Data.N("insert_time", 4f);
        }

        public override void Interact(SZPlayer by)
        {
            if (Active) return;
            if (!by.Inventory.Has(Item)) Say("Needs a " + ItemName(Item) + ".", 2f);
            else if (!RequirementMet(out var why)) Say(why, 2f);
        }

        public void HoldDone(SZPlayer by)
        {
            if (Active || by.Inventory.Take(Item) == null) return;
            Puzzles.Request(this, "use");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "use" || Active) return;
            SetActive(true);
            SZAudio.PlayAt("repair_click", transform.position, 1f, 12f);
        }

        protected override void Show()
        {
            _light.material.color = Active ? Color.green : Color.red;
            _light.material.SetColor("_EmissionColor", (Active ? Color.green : Color.red) * 2f);
        }
    }

    // A keypad: E opens it on your screen; type the code (shown somewhere else).
    public class PzKeypad : SZPiece, SZGame.IPanel
    {
        string _code = "", _entered = "";
        float _wrongUntil, _nextRotate;
        TextMesh _screen;

        public override string DisplayCode => _code;

        protected override void Build()
        {
            // A downloaded keypad (Asset Slots), or a simple box.
            if (SZAssets.Spawn("keypad", transform, onGround: false) == null)
            {
                Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.18f, 0.26f, 0.05f), new Color(0.16f, 0.16f, 0.17f));
                Part(PrimitiveType.Cube, new Vector3(0f, 0.08f, 0.03f), new Vector3(0.14f, 0.05f, 0.01f), new Color(0.05f, 0.12f, 0.06f));
            }
            _screen = Text(new Vector3(0f, 0.08f, 0.04f), 0.03f, new Color(0.4f, 1f, 0.5f));
            Clickable(new Vector3(0f, 0f, 0.03f), new Vector3(0.35f, 0.4f, 0.3f));
            Show();
        }

        int Length => Mathf.Max(Mathf.RoundToInt(Data.N("code_length", 4f)), 1);

        public override void HostStart()
        {
            _code = RandomCode();
            float every = Data.N("rotate_every");
            _nextRotate = every > 0f ? Time.time + every : float.MaxValue;
            Changed();
        }

        string RandomCode()
        {
            var sb = new StringBuilder();
            for (int i = 0; i < Length; i++) sb.Append(Random.Range(0, 10));
            return sb.ToString();
        }

        public override void HostTick(float dt)
        {
            if (Active || Time.time < _nextRotate) return;
            _nextRotate = Time.time + Data.N("rotate_every");
            _code = RandomCode();
            Changed();
        }

        public override string Prompt => Active ? "Unlocked." : "[E] Use the keypad";

        public override void Interact(SZPlayer by)
        {
            if (!Active) SZGame.Instance.OpenPanel(this);
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "key" || Active) return;
            if (arg == "CLR") _entered = "";
            else if (arg == "ENT")
            {
                if (_entered == _code)
                {
                    _entered = "";
                    SetActive(true);
                    SZAudio.PlayAt("ping", transform.position, 1f, 10f);
                    return;
                }
                _entered = "";
                _wrongUntil = Time.time + 1.2f;
                SZAudio.PlayAt("door_pound", transform.position, 0.4f, 8f);
            }
            else if (_entered.Length < Length) _entered += arg;
            Show();
            Changed();
        }

        protected override void Show()
        {
            if (_screen) _screen.text = Active ? "OPEN" : Time.time < _wrongUntil ? "WRONG" : _entered.PadRight(Length, '-');
        }

        public override string Pack() => (Active ? "1" : "0") + ":" + _code + ":" + _entered + ":" + (Time.time < _wrongUntil ? "1" : "0");

        public override void Unpack(string s)
        {
            var p = s.Split(':');
            Active = p.Length > 0 && p[0] == "1";
            if (p.Length > 1) _code = p[1];
            if (p.Length > 2) _entered = p[2];
            if (p.Length > 3 && p[3] == "1") _wrongUntil = Time.time + 1.2f;
            Show();
        }

        void Update()
        {
            if (_screen && Time.time > _wrongUntil && _screen.text == "WRONG") Show();
        }

        // The big keypad on your screen (right side).
        public void Draw(SZGame game)
        {
            float w = 300f, h = 420f;
            var r = new Rect(Screen.width - 320f, Screen.height / 2f - h / 2f, w, h);
            game.Fill(r, new Color(0.08f, 0.08f, 0.09f, 0.97f));
            game.Fill(new Rect(r.x + 20, r.y + 20, w - 40, 60), new Color(0.03f, 0.08f, 0.04f));
            var screen = new GUIStyle(game.TitleStyle) { fontSize = 34, alignment = TextAnchor.MiddleCenter };
            screen.normal.textColor = new Color(0.4f, 1f, 0.5f);
            GUI.Label(new Rect(r.x + 20, r.y + 20, w - 40, 60), Active ? "OPEN" : Time.time < _wrongUntil ? "WRONG" : _entered.PadRight(Length, '-'), screen);
            string[] keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "CLR", "0", "ENT" };
            for (int i = 0; i < keys.Length; i++)
            {
                var b = new Rect(r.x + 20 + (i % 3) * 88, r.y + 96 + (i / 3) * 66, 80, 58);
                if (GUI.Button(b, keys[i], new GUIStyle(game.ButtonStyle) { alignment = TextAnchor.MiddleCenter, padding = new RectOffset(0, 0, 0, 0) }))
                {
                    Puzzles.Request(this, "key", keys[i]);
                    SZAudio.Play2D("repair_click", 0.4f);
                }
            }
            if (GUI.Button(new Rect(r.x + 20, r.yMax - 52, w - 40, 40), "CLOSE (Esc)", new GUIStyle(game.ButtonStyle) { alignment = TextAnchor.MiddleCenter })
                || Active)
                SZGame.Instance.ClosePanel();
        }
    }

    // Breaker switches that must match a pattern (shown on a wiring diagram).
    public class PzBreakerPanel : SZPiece
    {
        public bool[] Pattern = new bool[0];
        readonly List<PzBreakerSwitch> _switches = new List<PzBreakerSwitch>();

        public override string DisplayCode
        {
            get
            {
                var parts = new List<string>();
                for (int i = 0; i < Pattern.Length; i++) parts.Add((i + 1) + " " + (Pattern[i] ? "UP" : "DOWN"));
                return string.Join("   ", parts);
            }
        }

        protected override void Build() =>
            Part(PrimitiveType.Cube, new Vector3(0f, 0f, -0.04f), new Vector3(0.9f, 0.4f, 0.06f), new Color(0.22f, 0.24f, 0.22f));

        public override void Wire(SZPuzzles puzzles)
        {
            base.Wire(puzzles);
            foreach (var p in puzzles.Pieces)
                if (p is PzBreakerSwitch s && s.Data.parent == Index) _switches.Add(s);
            _switches.Sort((a, b) => a.Number.CompareTo(b.Number));
            Pattern = new bool[_switches.Count];
        }

        public override void HostStart()
        {
            for (int i = 0; i < Pattern.Length; i++) Pattern[i] = Random.value < 0.5f;
            if (Pattern.Length > 0 && System.Array.IndexOf(Pattern, true) < 0) Pattern[Random.Range(0, Pattern.Length)] = true;
            Changed();
        }

        bool Powered
        {
            get
            {
                var power = Puzzles.Get(Data.Ref("powered_by"));
                return power == null || power.Active;
            }
        }

        public void HostCheck()
        {
            if (Active || !Powered) return;
            for (int i = 0; i < _switches.Count; i++) if (_switches[i].Up != Pattern[i]) return;
            SetActive(true);
            SZAudio.PlayAt("generator_hum", transform.position, 0.8f, 20f);
        }

        public override void HostTick(float dt)
        {
            if (!Active && Time.frameCount % 30 == 0) HostCheck();  // the power may have come on
        }

        public bool IsPowered => Powered;

        public override string Pack()
        {
            var sb = new StringBuilder(Active ? "1:" : "0:");
            foreach (var b in Pattern) sb.Append(b ? '1' : '0');
            return sb.ToString();
        }

        public override void Unpack(string s)
        {
            base.Unpack(s);
            var p = s.Split(':');
            if (p.Length > 1)
                for (int i = 0; i < Pattern.Length && i < p[1].Length; i++) Pattern[i] = p[1][i] == '1';
        }
    }

    public class PzBreakerSwitch : SZPiece
    {
        public bool Up { get; private set; }
        public int Number => Mathf.RoundToInt(Data.N("number", 1f));
        Transform _toggle;

        protected override void Build()
        {
            Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.12f, 0.2f, 0.05f), new Color(0.12f, 0.12f, 0.12f));
            _toggle = Part(PrimitiveType.Cube, new Vector3(0f, -0.04f, 0.04f), new Vector3(0.05f, 0.08f, 0.05f), new Color(0.85f, 0.85f, 0.8f));
            Text(new Vector3(0f, 0.14f, 0.03f), 0.04f, Color.white).text = Number.ToString();
            Clickable(new Vector3(0f, 0f, 0.03f), new Vector3(0.18f, 0.3f, 0.25f));
        }

        PzBreakerPanel Panel => Puzzles.Get(Data.parent) as PzBreakerPanel;

        public override string Prompt
        {
            get
            {
                var panel = Panel;
                if (panel != null && panel.Active) return "The breakers are set.";
                return "[E] Flip switch " + Number + " (now " + (Up ? "UP" : "DOWN") + ")" + (panel != null && !panel.IsPowered ? "  - no power" : "");
            }
        }

        public override void Interact(SZPlayer by)
        {
            if (Panel != null && Panel.Active) return;
            Puzzles.Request(this, "flip");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "flip" || (Panel != null && Panel.Active)) return;
            Up = !Up;
            Show();
            Changed();
            SZAudio.PlayAt("repair_click", transform.position, 0.8f, 8f);
            Panel?.HostCheck();
        }

        protected override void Show() => _toggle.localPosition = new Vector3(0f, Up ? 0.04f : -0.04f, 0.04f);

        public override string Pack() => Up ? "1" : "0";

        public override void Unpack(string s)
        {
            Up = s.Length > 0 && s[0] == '1';
            Show();
        }
    }

    // An old radio: tune it (- and + buttons) to the frequency on the chart.
    public class PzRadio : SZPiece
    {
        float _freq, _target;
        TextMesh _dial;

        float Min => Data.N("min_frequency", 90f);
        float Max => Data.N("max_frequency", 99.5f);
        float Step => Mathf.Max(Data.N("step", 0.5f), 0.1f);

        public override string DisplayCode => _target.ToString("0.0") + " MHz";

        protected override void Build()
        {
            Part(PrimitiveType.Cube, Vector3.zero, new Vector3(0.5f, 0.3f, 0.25f), new Color(0.3f, 0.22f, 0.14f));
            _dial = Text(new Vector3(0f, 0.05f, 0.13f), 0.05f, new Color(1f, 0.75f, 0.3f));
            _freq = Min;
            Show();
        }

        public override void HostStart()
        {
            int steps = Mathf.RoundToInt((Max - Min) / Step);
            do _target = Min + Step * Random.Range(0, steps + 1); while (Mathf.Approximately(_target, _freq) && steps > 0);
            Changed();
        }

        public void HostTune(int dir)
        {
            if (Active) return;
            _freq = Mathf.Clamp(_freq + dir * Step, Min, Max);
            SZAudio.PlayAt("radio_static", transform.position, 0.3f, 10f);
            if (Mathf.Abs(_freq - _target) < Step * 0.5f)
            {
                SetActive(true);
                SZAudio.PlayAt("ping", transform.position, 1f, 12f);
            }
            Show();
            Changed();
        }

        protected override void Show()
        {
            if (_dial) _dial.text = _freq.ToString("0.0") + " MHz" + (Active ? "\nSIGNAL" : "");
        }

        public string Frequency => _freq.ToString("0.0");

        public override string Pack() => (Active ? "1" : "0") + ":" + _freq.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture) +
                                         ":" + _target.ToString("0.0", System.Globalization.CultureInfo.InvariantCulture);

        public override void Unpack(string s)
        {
            var p = s.Split(':');
            Active = p.Length > 0 && p[0] == "1";
            if (p.Length > 2)
            {
                float.TryParse(p[1], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out _freq);
                float.TryParse(p[2], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out _target);
            }
            Show();
        }
    }

    public class PzTune : SZPiece
    {
        int Dir => Data.N("direction", 1f) >= 0f ? 1 : -1;
        PzRadio Radio => Puzzles.Get(Data.parent) as PzRadio;

        protected override void Build()
        {
            Part(PrimitiveType.Cylinder, Vector3.zero, new Vector3(0.05f, 0.015f, 0.05f), new Color(0.15f, 0.15f, 0.15f)).localRotation = Quaternion.Euler(90f, 0f, 0f);
            Clickable(Vector3.zero, new Vector3(0.12f, 0.12f, 0.12f));
        }

        public override string Prompt => Radio == null ? "" : Radio.Active ? "Tuned in." : "[E] Tune " + (Dir > 0 ? "up" : "down") + " (" + Radio.Frequency + " MHz)";

        public override void Interact(SZPlayer by)
        {
            if (Radio != null) Puzzles.Request(this, "tune");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action == "tune") Radio?.HostTune(Dir);
        }
    }

    // An old terminal: a "lights out" grid on your screen. Light every tile.
    public class PzTerminal : SZPiece, SZGame.IPanel
    {
        readonly bool[] _board = new bool[9];

        protected override void Build()
        {
            if (SZAssets.Spawn("computer", transform, onGround: true, size: 0.45f) == null)  // a downloaded computer, or boxes
            {
                Part(PrimitiveType.Cube, new Vector3(0f, 0.2f, 0f), new Vector3(0.45f, 0.35f, 0.35f), new Color(0.75f, 0.72f, 0.62f));
                Part(PrimitiveType.Cube, new Vector3(0f, 0.22f, 0.18f), new Vector3(0.34f, 0.24f, 0.01f), new Color(0.03f, 0.25f, 0.08f), 0.5f);
            }
            Clickable(new Vector3(0f, 0.2f, 0.1f), new Vector3(0.6f, 0.5f, 0.6f));
        }

        public override string Prompt => Active ? "The terminal is running." : RequirementMet(out var why) ? "[E] Use the terminal" : why;

        public override void Interact(SZPlayer by)
        {
            if (Active) return;
            if (!RequirementMet(out var why)) { Say(why, 2f); return; }
            // A fresh scramble every time (never already solved).
            for (int i = 0; i < 9; i++) _board[i] = false;
            for (int n = 0; n < 4; n++) Press(Random.Range(0, 9));
            if (System.Array.TrueForAll(_board, b => b)) Press(4);
            SZGame.Instance.OpenPanel(this);
        }

        void Press(int i)
        {
            int x = i % 3, y = i / 3;
            _board[i] = !_board[i];
            if (x > 0) _board[i - 1] = !_board[i - 1];
            if (x < 2) _board[i + 1] = !_board[i + 1];
            if (y > 0) _board[i - 3] = !_board[i - 3];
            if (y < 2) _board[i + 3] = !_board[i + 3];
        }

        public void Draw(SZGame game)
        {
            float w = 330f, h = 420f;
            var r = new Rect(Screen.width - 350f, Screen.height / 2f - h / 2f, w, h);
            game.Fill(r, new Color(0.02f, 0.06f, 0.03f, 0.97f));
            var title = new GUIStyle(game.SmallStyle) { alignment = TextAnchor.MiddleCenter };
            title.normal.textColor = new Color(0.4f, 1f, 0.5f);
            GUI.Label(new Rect(r.x, r.y + 12, w, 40), "SYSTEM BOOT: LIGHT EVERY TILE\nEach tile flips itself and its neighbours.", title);
            for (int i = 0; i < 9; i++)
            {
                var b = new Rect(r.x + 30 + (i % 3) * 94, r.y + 70 + (i / 3) * 94, 84, 84);
                game.Fill(b, _board[i] ? new Color(0.35f, 1f, 0.45f) : new Color(0.05f, 0.15f, 0.07f));
                if (GUI.Button(b, GUIContent.none, GUIStyle.none))
                {
                    Press(i);
                    SZAudio.Play2D("repair_click", 0.3f);
                    if (System.Array.TrueForAll(_board, x => x))
                    {
                        Puzzles.Request(this, "use");
                        SZGame.Instance.ClosePanel();
                        Say("The terminal boots up.", 2f);
                        return;
                    }
                }
            }
            if (GUI.Button(new Rect(r.x + 30, r.yMax - 56, w - 60, 40), "CLOSE (Esc)", new GUIStyle(game.ButtonStyle) { alignment = TextAnchor.MiddleCenter }))
                SZGame.Instance.ClosePanel();
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action == "use") SetActive(true);
        }
    }

    // A job only one character knows (the Journalist developing photos).
    // BACKUP: if that character isn't in the team, anyone can, slower.
    public class PzStation : SZPiece, ISZHoldable
    {
        protected override void Build()
        {
            Part(PrimitiveType.Cube, new Vector3(0f, 0.45f, 0f), new Vector3(1.2f, 0.9f, 0.6f), new Color(0.2f, 0.15f, 0.12f));
            Part(PrimitiveType.Cube, new Vector3(0f, 0.95f, 0f), new Vector3(0.4f, 0.08f, 0.3f), new Color(0.6f, 0.1f, 0.08f), 0.4f);
            Clickable(new Vector3(0f, 0.6f, 0f), new Vector3(1.4f, 1.3f, 0.9f));
        }

        SZCharacter Who => PzHold.GodotCharacter(Mathf.RoundToInt(Data.N("required_character", 1f)));

        public override string Prompt
        {
            get
            {
                if (Active) return Data.S("done_text", "Done.");
                if (!RequirementMet(out var why)) return why;
                var me = SZWorld.Instance.Local;
                if (me.Character != Who && TeamHas(Who)) return "Only " + SZCharacters.Names[(int)Who] + " knows how to " + Data.S("action_text", "do this") + ".";
                return "[Hold E] " + Data.S("action_text", "do it");
            }
        }

        public float HoldTime(SZPlayer by)
        {
            if (Active || !RequirementMet(out _)) return 0f;
            if (by.Character == Who) return Data.N("work_time", 6f);
            return TeamHas(Who) ? 0f : Data.N("backup_time", 20f);
        }

        public override void Interact(SZPlayer by) => Say(Prompt, 2f);
        public void HoldDone(SZPlayer by) => Puzzles.Request(this, "use");

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "use" || Active) return;
            SetActive(true);
            SayAll(Data.S("done_text"));
        }
    }

    // A broken generator: Walter fixes it (hold E). Without Walter, anyone can, 4 times slower.
    public class PzGenerator : SZPiece, ISZHoldable
    {
        Light _lamp;
        AudioSource _hum;

        protected override void Build()
        {
            Part(PrimitiveType.Cube, new Vector3(0f, 0.5f, 0f), new Vector3(1.4f, 1f, 0.8f), new Color(0.3f, 0.32f, 0.22f));
            Part(PrimitiveType.Cylinder, new Vector3(0.4f, 1.1f, 0f), new Vector3(0.12f, 0.15f, 0.12f), new Color(0.15f, 0.15f, 0.15f));
            var go = new GameObject("Lamp");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(0f, 1.5f, 0f);
            _lamp = go.AddComponent<Light>();
            _lamp.type = LightType.Point;
            _lamp.color = new Color(1f, 0.85f, 0.6f);
            _lamp.range = 8f;
            _lamp.intensity = 1.5f;
            _lamp.enabled = false;
            _hum = SZAudio.Attach(gameObject, "generator_hum", 0.6f, 18f, loop: false);
            _hum.loop = true;
            Clickable(new Vector3(0f, 0.6f, 0f), new Vector3(1.6f, 1.4f, 1.1f));
        }

        float RepairTime => Data.N("repair_time", 4f);

        public override string Prompt
        {
            get
            {
                if (Active) return "The generator is running.";
                var me = SZWorld.Instance.Local;
                if (me.Character != SZCharacter.Walter && TeamHas(SZCharacter.Walter)) return "Broken. Walter can fix this.";
                return "[Hold E] Repair the generator";
            }
        }

        public float HoldTime(SZPlayer by)
        {
            if (Active) return 0f;
            if (by.Character == SZCharacter.Walter) return RepairTime;
            return TeamHas(SZCharacter.Walter) ? 0f : RepairTime * 4f;
        }

        public override void Interact(SZPlayer by) => Say(Prompt, 2f);
        public void HoldDone(SZPlayer by) => Puzzles.Request(this, "use");

        public override void HostAction(string action, string arg, int by)
        {
            if (action == "use") SetActive(true);
        }

        protected override void Show()
        {
            _lamp.enabled = Active;
            if (Active && !_hum.isPlaying) _hum.Play();
        }
    }

    // A tape machine: hold E with a reel tape to play it (everyone nearby hears it).
    public class PzTape : SZPiece, ISZHoldable
    {
        protected override void Build()
        {
            Part(PrimitiveType.Cube, new Vector3(0f, 0.12f, 0f), new Vector3(0.5f, 0.24f, 0.32f), new Color(0.18f, 0.18f, 0.18f));
            foreach (var x in new[] { -0.12f, 0.12f })
                Part(PrimitiveType.Cylinder, new Vector3(x, 0.25f, 0f), new Vector3(0.16f, 0.01f, 0.16f), new Color(0.35f, 0.22f, 0.12f));
            Clickable(new Vector3(0f, 0.15f, 0f), new Vector3(0.7f, 0.5f, 0.5f));
        }

        public override string Prompt => SZWorld.Instance.Local.Inventory.FindTape(null) != null ? "[Hold E] Play a reel tape" : "A tape machine. It needs a reel tape.";

        public float HoldTime(SZPlayer by) => by.Inventory.FindTape(null) != null ? 1f : 0f;
        public override void Interact(SZPlayer by) => Say(Prompt, 2f);

        public void HoldDone(SZPlayer by)
        {
            var needed = Data.S("required_lore");
            var tape = by.Inventory.FindTape(needed) ?? by.Inventory.FindTape(null);
            if (tape == null) return;
            SZAudio.PlayAt("radio_static", transform.position, 0.6f, 12f);
            var entry = SZWorld.Instance.LoreEntry(tape.lore);
            if (entry != null)
            {
                SZGame.Instance.Read(entry.title, entry.text);
                SZWorld.Instance.HearLore(entry.id);
            }
            Puzzles.Request(this, "tape", tape.lore ?? "");
        }

        public override void HostAction(string action, string arg, int by)
        {
            if (action != "tape" || Active) return;
            var needed = Data.S("required_lore");
            if (needed.Length == 0 || needed == arg) SetActive(true);
        }
    }

    // Active once the team has heard/read a particular story entry.
    public class PzLoreCheck : SZPiece
    {
        public override void HostTick(float dt)
        {
            if (!Active && SZWorld.Instance.HasHeard(Data.S("lore_id"))) SetActive(true);
        }
    }

    // A heavy floor plate: down while someone stands on it.
    public class PzPlate : SZPiece
    {
        Transform _plate;
        float _lingerUntil;

        protected override void Build()
        {
            var size = Data.size != null && Data.size.Length == 3 ? new Vector3(Data.size[0], 0.06f, Data.size[2]) : new Vector3(1.2f, 0.06f, 1.2f);
            _plate = Part(PrimitiveType.Cube, new Vector3(0f, 0.03f, 0f), size, new Color(0.35f, 0.33f, 0.3f));
            // The exported box is where the trigger is; put the plate at its bottom.
            if (Data.size != null && Data.size.Length == 3 && Data.p != null)
                transform.position = SZLevelData.V(Data.p) - Vector3.up * Data.size[1] * 0.5f;
        }

        public override void HostTick(float dt)
        {
            bool on = false;
            var half = Data.size != null && Data.size.Length == 3 ? new Vector3(Data.size[0], 2f, Data.size[2]) * 0.5f : new Vector3(0.6f, 1f, 0.6f);
            foreach (var v in SZWorld.Instance.PlayerViews())
            {
                var local = transform.InverseTransformPoint(v.position + Vector3.up * 0.1f);
                if (Mathf.Abs(local.x) <= half.x && Mathf.Abs(local.z) <= half.z && local.y > -0.5f && local.y < 2f) on = true;
            }
            float linger = Data.N("solo_linger");
            if (on) _lingerUntil = Time.time + (TeamSize <= 1 ? linger : 0f);
            SetActive(on || Time.time < _lingerUntil);
        }

        protected override void Show() => _plate.localPosition = new Vector3(0f, Active ? 0.0f : 0.03f, 0f);
    }

    // A lamp that blinks a keypad's code in Morse, over and over.
    public class PzSignal : SZPiece
    {
        static readonly Dictionary<char, string> Morse = new Dictionary<char, string>
        {
            {'0', "-----"}, {'1', ".----"}, {'2', "..---"}, {'3', "...--"}, {'4', "....-"},
            {'5', "....."}, {'6', "-...."}, {'7', "--..."}, {'8', "---.."}, {'9', "----."},
        };

        Light _light;
        Renderer _bulb;
        readonly List<(bool on, float time)> _steps = new List<(bool, float)>();
        int _step;
        float _next;
        string _shownCode = "";

        protected override void Build()
        {
            _bulb = Part(PrimitiveType.Sphere, Vector3.zero, Vector3.one * 0.25f, new Color(1f, 0.9f, 0.6f), 0.2f).GetComponent<Renderer>();
            var go = new GameObject("Light");
            go.transform.SetParent(transform, false);
            _light = go.AddComponent<Light>();
            _light.type = LightType.Point;
            _light.range = 10f;
            _light.intensity = 3f;
            _light.color = new Color(1f, 0.9f, 0.6f);
            _light.enabled = false;
        }

        void Rebuild(string code)
        {
            _shownCode = code;
            _steps.Clear();
            float dot = Data.N("dot_time", 0.3f), dash = Data.N("dash_time", 0.9f), gap = Data.N("gap_time", 0.35f);
            foreach (var digit in code)
            {
                if (!Morse.TryGetValue(digit, out var symbols)) continue;
                foreach (var s in symbols)
                {
                    _steps.Add((true, s == '.' ? dot : dash));
                    _steps.Add((false, gap));
                }
                _steps.Add((false, Data.N("letter_gap", 1.4f)));
            }
            _steps.Add((false, Data.N("repeat_gap", 3.5f)));
            _step = 0;
            _next = Time.time;
        }

        void Update()
        {
            var source = Puzzles != null ? Puzzles.Get(Data.Ref("source")) : null;
            var power = Puzzles != null ? Puzzles.Get(Data.Ref("powered_by")) : null;
            bool powered = power == null || power.Active;
            string code = source != null ? source.DisplayCode : "";
            if (code != _shownCode) Rebuild(code);
            if (!powered || _steps.Count == 0)
            {
                _light.enabled = false;
                return;
            }
            if (Time.time < _next) return;
            var step = _steps[_step];
            _light.enabled = step.on;
            _bulb.material.SetColor("_EmissionColor", step.on ? new Color(3f, 2.6f, 1.6f) : Color.black);
            _next = Time.time + step.time;
            _step = (_step + 1) % _steps.Count;
        }
    }

    // Two doors that are never open at the same time: a button cycles them.
    public class PzAirlock : SZPiece
    {
        bool _outerOpen = true, _cycling;
        float _switchAt;
        readonly HashSet<int> _buttonsSeen = new HashSet<int>();

        PzDoor Door(string key) => Puzzles.Get(Data.Ref(key)) as PzDoor;

        public override void HostStart() => Door("outer_door")?.PuzzleSet(true);

        public override void HostTick(float dt)
        {
            foreach (var b in Data.Refs("buttons"))
            {
                var button = Puzzles.Get(b);
                if (button == null) continue;
                bool pressed = button.Active;
                if (pressed && !_buttonsSeen.Contains(b) && !_cycling)
                {
                    // Shut the open door, hiss, then open the other one.
                    _cycling = true;
                    _switchAt = Time.time + Data.N("cycle_time", 6f);
                    Door(_outerOpen ? "outer_door" : "inner_door")?.PuzzleSet(false);
                    SZAudio.PlayAt("flare_hiss", transform.position, 0.8f, 15f);
                    SayAll("The airlock hisses...");
                }
                if (pressed) _buttonsSeen.Add(b); else _buttonsSeen.Remove(b);
            }
            if (_cycling && Time.time >= _switchAt)
            {
                _cycling = false;
                _outerOpen = !_outerOpen;
                Door(_outerOpen ? "outer_door" : "inner_door")?.PuzzleSet(true);
            }
        }
    }

    // Anything else: press E and it's done (so a puzzle never blocks you).
    public class PzGeneric : SZPiece
    {
        protected override void Build()
        {
            if (Data.Has3D)
            {
                Part(PrimitiveType.Cube, Vector3.zero, Vector3.one * 0.25f, new Color(0.4f, 0.4f, 0.45f));
                Clickable(Vector3.zero, Vector3.one * 0.4f);
            }
        }

        public override string Prompt => Data.Has3D ? (Active ? "Done." : "[E] Use") : "";
        public override void Interact(SZPlayer by) => Puzzles.Request(this, "use");

        public override void HostAction(string action, string arg, int by)
        {
            if (action == "use") SetActive(true);
        }
    }

    // A sign that shows a puzzle's code (keypad code, breaker pattern, radio
    // frequency) once its clue is unlocked.
    public class SZCodeLabel : MonoBehaviour
    {
        public LabelData Data;
        TextMesh _text;
        float _next;

        void Start() => _text = GetComponent<TextMesh>();

        void Update()
        {
            if (Time.time < _next || SZPuzzles.Instance == null || _text == null) return;
            _next = Time.time + 0.3f;
            var source = SZPuzzles.Instance.Get(Data.source);
            var hidden = SZPuzzles.Instance.Get(Data.hidden_until);
            string code = source != null ? source.DisplayCode : "";
            if (Data.digit >= 0) code = Data.digit < code.Length ? code[Data.digit].ToString() : "?";
            bool show = hidden == null || hidden.Active;
            var template = string.IsNullOrEmpty(Data.template) ? "%s" : Data.template;
            _text.text = template.Replace("%s", show && code.Length > 0 ? code : string.IsNullOrEmpty(Data.hidden_text) ? "???" : Data.hidden_text);
        }
    }
}
