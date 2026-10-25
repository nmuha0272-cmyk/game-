using UnityEngine;

// A metal locker you can hide in, like the Godot version (hiding_spot.gd):
// press E to get in, E again to get out. While you're inside, the Long Man
// can't see or hear you... unless he SAW you climb in. Then he walks straight
// over and drags you out. One person per locker. Online, the host decides
// who is inside (SZWorld sends "LOCKER|number|who").
namespace Deepwell
{
    public class SZLocker : MonoBehaviour, ISZInteractable
    {
        // Same size as Godot's locker: 0.9 m wide, 2.15 m tall, 0.7 m deep; the door faces +Z.
        const float Width = 0.9f, Height = 2.15f, Depth = 0.7f;

        public int Index { get; private set; }
        public int Occupant { get; private set; } = -1;   // player id inside (-1 = empty)
        public bool Empty => Occupant < 0;

        Transform _door;
        float _doorOpen;   // 0..1, swings open for a moment when someone gets in or out
        AudioSource _creak;

        public string Prompt
        {
            get
            {
                if (Occupant == SZNet.MyId) return "[E] Get out";
                if (!Empty) return "Someone is hiding in here.";
                return "[E] Hide in the locker";
            }
        }

        // Where the person inside stands (Godot: (0, 0.02, -0.03)), and where they step out.
        public Vector3 Inside => transform.TransformPoint(new Vector3(0f, 0.02f, -0.03f));
        public Vector3 Outside => transform.TransformPoint(new Vector3(0f, 0.05f, 0.85f));

        public static SZLocker Create(SpawnData d, int index, Transform parent)
        {
            var go = new GameObject("Locker " + index);
            go.transform.SetParent(parent);
            go.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            var locker = go.AddComponent<SZLocker>();
            locker.Index = index;
            locker.Build();
            return locker;
        }

        void Build()
        {
            var metal = SZGraphics.Lit(new Color(0.32f, 0.36f, 0.34f), 0.35f);
            // A downloaded locker (Deepwell > Asset Slots) replaces the look; the walls stay solid.
            bool asset = SZAssets.Spawn("locker", transform, onGround: true, size: Height) != null;
            Wall("Back", new Vector3(0f, Height / 2f, -Depth / 2f + 0.02f), new Vector3(Width, Height, 0.04f), metal, asset);
            Wall("Left", new Vector3(-Width / 2f + 0.02f, Height / 2f, 0f), new Vector3(0.04f, Height, Depth), metal, asset);
            Wall("Right", new Vector3(Width / 2f - 0.02f, Height / 2f, 0f), new Vector3(0.04f, Height, Depth), metal, asset);
            Wall("Top", new Vector3(0f, Height - 0.02f, 0f), new Vector3(Width, 0.04f, Depth), metal, asset);
            Wall("Bottom", new Vector3(0f, 0.02f, 0f), new Vector3(Width, 0.04f, Depth), metal, asset);

            // The door, hinged on the left; it has slits near the top to peek through.
            _door = new GameObject("DoorHinge").transform;
            _door.SetParent(transform, false);
            _door.localPosition = new Vector3(-Width / 2f, 0f, Depth / 2f - 0.02f);
            var door = GameObject.CreatePrimitive(PrimitiveType.Cube);
            door.name = "Door";
            door.transform.SetParent(_door, false);
            door.transform.localPosition = new Vector3(Width / 2f, Height / 2f, 0f);
            door.transform.localScale = new Vector3(Width, Height, 0.04f);
            door.GetComponent<Renderer>().sharedMaterial = metal;
            if (asset) door.GetComponent<Renderer>().enabled = false;
            var dark = SZGraphics.Lit(new Color(0.02f, 0.02f, 0.02f), 0f);
            for (int i = 0; i < 4; i++)
            {
                var slit = GameObject.CreatePrimitive(PrimitiveType.Cube);
                Destroy(slit.GetComponent<Collider>());
                slit.transform.SetParent(_door, false);
                slit.transform.localPosition = new Vector3(Width / 2f, 1.62f + i * 0.06f, 0.021f);
                slit.transform.localScale = new Vector3(Width * 0.6f, 0.015f, 0.005f);
                slit.GetComponent<Renderer>().sharedMaterial = dark;
                if (asset) slit.GetComponent<Renderer>().enabled = false;
            }
            _creak = SZAudio.Attach(gameObject, "door_creak", 0.6f, 12f);
            _creak.pitch = 1.3f;
        }

        void Wall(string name, Vector3 at, Vector3 size, Material mat, bool hidden)
        {
            var w = GameObject.CreatePrimitive(PrimitiveType.Cube);
            w.name = name;
            w.transform.SetParent(transform, false);
            w.transform.localPosition = at;
            w.transform.localScale = size;
            w.GetComponent<Renderer>().sharedMaterial = mat;
            if (hidden) w.GetComponent<Renderer>().enabled = false;
        }

        public void Interact(SZPlayer by)
        {
            if (Occupant == SZNet.MyId) SZWorld.Instance.RequestLocker(this, false);
            else if (Empty && by.HidingIn == null) SZWorld.Instance.RequestLocker(this, true);
        }

        // Someone got in (id) or out (-1). Runs on every computer.
        public void SetOccupant(int id)
        {
            if (id == Occupant) return;
            int was = Occupant;
            Occupant = id;
            _doorOpen = 1f;
            _creak.Play();
            var me = SZWorld.Instance.Local;
            if (me == null) return;
            if (id == SZNet.MyId) me.EnterLocker(this);
            else if (was == SZNet.MyId) me.LeaveLocker(this);
        }

        // While you're inside, your own screen doesn't draw the locker (you peek
        // out through the slits instead: SZGame draws them). Only on your computer.
        public void PeekFromInside(bool inside)
        {
            foreach (var r in GetComponentsInChildren<Renderer>(true)) r.forceRenderingOff = inside;
        }

        void Update()
        {
            // The door swings open for a moment, then shuts again.
            _doorOpen = Mathf.MoveTowards(_doorOpen, 0f, Time.deltaTime * 1.6f);
            float angle = Mathf.Sin(Mathf.Clamp01(_doorOpen) * Mathf.PI) * 85f;
            _door.localRotation = Quaternion.Euler(0f, -angle, 0f);
        }
    }
}
