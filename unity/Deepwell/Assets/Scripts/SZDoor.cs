using UnityEngine;

// A door that swings open and shut with E. Until puzzles come over (phase
// U3), puzzle doors and locked doors simply start open, so you can walk
// through the whole chapter (same as the Unreal version).
namespace Deepwell
{
    public class SZDoor : MonoBehaviour, ISZInteractable
    {
        // Same door as Godot: 2 m wide, 3 m tall, hinged at one edge.
        const float Width = 2f, Height = 3f, Thickness = 0.12f;
        // Godot opens to -100 degrees; X is mirrored in Unity, so it's +100 here.
        const float OpenAngle = 100f;
        const float SwingTime = 0.6f;

        public bool IsOpen { get; private set; }
        public string Prompt => IsOpen ? "[E] Close door" : "[E] Open door";

        Transform _panel;
        Quaternion _closed;
        float _t;

        public static SZDoor Create(DoorData d, Transform parent)
        {
            var hinge = new GameObject(d.name);
            hinge.transform.SetParent(parent);
            hinge.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            var door = hinge.AddComponent<SZDoor>();

            var panel = GameObject.CreatePrimitive(PrimitiveType.Cube);
            panel.name = "Panel";
            panel.transform.SetParent(hinge.transform, false);
            // In Godot the door reaches along its +X from the hinge; X is mirrored in Unity.
            panel.transform.localPosition = new Vector3(-Width / 2f, Height / 2f, 0f);
            panel.transform.localScale = new Vector3(Width, Height, Thickness);
            var mat = new Material(Shader.Find("Standard"));
            mat.color = new Color(0.28f, 0.24f, 0.2f);
            mat.SetFloat("_Glossiness", 0.2f);
            panel.GetComponent<MeshRenderer>().sharedMaterial = mat;

            door._panel = hinge.transform;
            door._closed = hinge.transform.localRotation;
            if (d.puzzle || d.locked) door.SetOpen(true, instant: true);
            return door;
        }

        public void Interact(SZPlayer by) => SetOpen(!IsOpen);

        public void SetOpen(bool open, bool instant = false)
        {
            IsOpen = open;
            _t = instant ? 1f : 0f;
            if (instant) Apply(1f);
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
            _panel.localRotation = Quaternion.Slerp(from, to, k);
        }
    }
}
