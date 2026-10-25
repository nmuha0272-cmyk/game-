using UnityEngine;

// A door that swings open and shut with E, like Godot's door.gd:
// - A puzzle door stays shut until its puzzle opens it (SZPuzzles).
// - A keycard door opens for anyone carrying that color or a higher one
//   (green < yellow < red); the card isn't used up.
// - A jammed door needs a crowbar: hold E to pry it (the crowbar breaks).
// Online, the host decides if a door is open (SZWorld).
// Cole can hold a closed door shut (hold Q): the Long Man can't open it.
namespace Deepwell
{
    public class SZDoor : MonoBehaviour, ISZInteractable, ISZHoldable
    {
        // Same door as Godot: 2 m wide, 3 m tall, hinged at one edge.
        const float Width = 2f, Height = 3f, Thickness = 0.12f;
        // Godot opens to -100 degrees; X is mirrored in Unity, so it's +100 here.
        const float OpenAngle = 100f;
        const float SwingTime = 0.6f;

        public int Index { get; private set; }
        public bool IsOpen { get; private set; }
        // Cole is holding it shut (until this time).
        public float HeldUntil;
        public bool IsHeld => Time.time < HeldUntil;
        public Vector3 Middle => transform.TransformPoint(new Vector3(-Width / 2f, Height / 2f, 0f));

        public int PieceIndex { get; private set; } = -1;  // its puzzle piece, if a puzzle opens it
        public bool PuzzleControlled { get; private set; }
        public bool PuzzleOpened;                            // its puzzle was solved
        public string Lock { get; private set; } = "";       // "keycard_green"... or "jammed"
        public bool Unlocked;                                // the lock was opened (stays open)
        // Shut for good until a puzzle or a key opens it (the Long Man can't get through either).
        public bool LockedShut => !IsOpen && ((PuzzleControlled && !PuzzleOpened) || (Lock.Length > 0 && !Unlocked));

        public string Prompt
        {
            get
            {
                if (IsHeld && !IsOpen) return "Cole is holding this door shut";
                if (IsOpen) return "[E] Close door";
                if (PuzzleControlled && !PuzzleOpened) return "It won't open. Something else unlocks it.";
                if (!Unlocked && Lock.StartsWith("keycard_"))
                {
                    var color = Lock.Substring(8);
                    return SZWorld.Instance.Local.Inventory.HasKeycard(color) ? "[E] Swipe the keycard" : "Locked. Needs a " + color + " keycard.";
                }
                if (!Unlocked && Lock == "jammed")
                    return SZWorld.Instance.Local.Inventory.Has("crowbar") ? "[Hold E] Pry it open with the crowbar" : "It's jammed. A crowbar could pry it open.";
                return "[E] Open door";
            }
        }

        Quaternion _closed;
        float _t = 1f;
        AudioSource _sound;

        static Material _wood, _metal;

        public static SZDoor Create(DoorData d, int index, Transform parent)
        {
            var hinge = new GameObject(d.name);
            hinge.transform.SetParent(parent);
            hinge.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            var door = hinge.AddComponent<SZDoor>();
            door.Index = index;

            if (_wood == null)
            {
                _wood = SZGraphics.Lit(new Color(0.22f, 0.2f, 0.18f), 0.25f);
                _metal = SZGraphics.Lit(new Color(0.35f, 0.34f, 0.32f), 0.6f);
                _metal.SetFloat("_Metallic", 0.8f);
            }
            // In Godot the door reaches along its +X from the hinge; X is mirrored in Unity.
            Part(hinge.transform, "Panel", new Vector3(-Width / 2f, Height / 2f, 0f), new Vector3(Width, Height, Thickness), _wood, true);
            Part(hinge.transform, "Handle", new Vector3(-Width + 0.18f, 1.05f, 0f), new Vector3(0.14f, 0.04f, Thickness + 0.1f), _metal, false);
            Part(hinge.transform, "Kick", new Vector3(-Width / 2f, 0.15f, 0f), new Vector3(Width - 0.05f, 0.3f, Thickness + 0.02f), _metal, false);
            Part(hinge.transform, "Window", new Vector3(-Width / 2f, 2.1f, 0f), new Vector3(0.6f, 0.4f, Thickness + 0.01f),
                SZGraphics.Lit(new Color(0.05f, 0.06f, 0.06f), 0.9f), false);

            // A downloaded door (Deepwell > Asset Slots) replaces the look; the panel stays solid.
            var bottomMiddle = new GameObject("AssetSpot").transform;
            bottomMiddle.SetParent(hinge.transform, false);
            bottomMiddle.localPosition = new Vector3(-Width / 2f, 0f, 0f);
            if (SZAssets.Spawn("door", bottomMiddle, onGround: true) != null)
                foreach (var r in hinge.GetComponentsInChildren<MeshRenderer>())
                    if (!r.transform.IsChildOf(bottomMiddle)) r.enabled = false;

            door._sound = SZAudio.Attach(hinge, "door_creak", 0.7f, 14f);
            door._closed = hinge.transform.localRotation;
            door.PieceIndex = d.id;
            door.PuzzleControlled = d.puzzle;
            door.Lock = d.@lock ?? "";
            return door;
        }

        static void Part(Transform parent, string name, Vector3 at, Vector3 size, Material mat, bool solid)
        {
            var part = GameObject.CreatePrimitive(PrimitiveType.Cube);
            part.name = name;
            part.transform.SetParent(parent, false);
            part.transform.localPosition = at;
            part.transform.localScale = size;
            part.GetComponent<MeshRenderer>().sharedMaterial = mat;
            if (!solid) Object.Destroy(part.GetComponent<Collider>());
        }

        public void Interact(SZPlayer by)
        {
            if (IsHeld && !IsOpen) return;
            if (!IsOpen && PuzzleControlled && !PuzzleOpened)
            {
                SZAudio.PlayAt("door_pound", Middle, 0.4f, 8f);
                return;
            }
            if (!IsOpen && !Unlocked && Lock.StartsWith("keycard_"))
            {
                if (!by.Inventory.HasKeycard(Lock.Substring(8)))
                {
                    SZGame.Instance.Say("Locked. Needs a " + Lock.Substring(8) + " keycard.", 2f);
                    return;
                }
                SZAudio.Play2D("ping", 0.5f);
                SZWorld.Instance.UnlockDoor(this);
            }
            if (!IsOpen && !Unlocked && Lock == "jammed") return;  // hold E with a crowbar
            SZWorld.Instance.RequestDoor(this, !IsOpen);
        }

        // Prying a jammed door.
        public float HoldTime(SZPlayer by) =>
            !IsOpen && !Unlocked && Lock == "jammed" && by.Inventory.Has("crowbar") ? 3f : 0f;

        public void HoldDone(SZPlayer by)
        {
            if (by.Inventory.Take("crowbar") == null) return;
            SZAudio.PlayAt("metal_creak", Middle, 1f, 25f);
            SZGame.Instance.Say("The door gives way... and the crowbar snaps.", 2.5f);
            SZWorld.Instance.UnlockDoor(this);
            SZWorld.Instance.RequestDoor(this, true);
        }

        public void SetOpen(bool open, bool instant = false)
        {
            if (open == IsOpen && !instant) return;
            IsOpen = open;
            _t = instant ? 1f : 0f;
            if (instant) Apply(1f);
            else if (_sound) _sound.Play();
        }

        void Update()
        {
            if (_t >= 1f) return;
            _t = Mathf.Min(_t + Time.deltaTime / SwingTime, 1f);
            Apply(Mathf.SmoothStep(0f, 1f, _t));
        }

        void Apply(float k)
        {
            var open = _closed * Quaternion.Euler(0f, OpenAngle, 0f);
            var from = IsOpen ? _closed : open;
            var to = IsOpen ? open : _closed;
            transform.localRotation = Quaternion.Slerp(from, to, k);
        }
    }
}
