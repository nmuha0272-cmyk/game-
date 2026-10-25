using UnityEngine;

// A door that swings open and shut with E. Puzzle doors and locked doors
// start open until puzzles come over to Unity, so you can always get through
// the whole chapter. Online, the host decides if a door is open (SZWorld).
// Cole can hold a closed door shut (hold Q): the Long Man can't open it.
namespace Deepwell
{
    public class SZDoor : MonoBehaviour, ISZInteractable
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

        public string Prompt => IsHeld && !IsOpen ? "Cole is holding this door shut" : IsOpen ? "[E] Close door" : "[E] Open door";

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

            door._sound = SZAudio.Attach(hinge, "door_creak", 0.7f, 14f);
            door._closed = hinge.transform.localRotation;
            if (d.puzzle || d.locked) door.SetOpen(true, instant: true);
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
            SZWorld.Instance.RequestDoor(this, !IsOpen);
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
