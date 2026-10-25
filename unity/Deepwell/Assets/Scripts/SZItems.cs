using System.Collections.Generic;
using UnityEngine;

// Items lying around the level (batteries, flares, medkits, keycards...),
// and what you're carrying. Press E to pick things up. Keys 1-4 pick what's
// in your hand; left click uses it:
//   Battery: recharge your flashlight.   Flare: throw it (red light).
//   Pistol: shoot (R reloads).            Medkit: if the Long Man catches
//   you while you carry one, you get away instead (it's used up).
// Keycards, fuses, the crowbar and tapes are used on things with E.
namespace Deepwell
{
    public class SZPickup : MonoBehaviour, ISZInteractable
    {
        public int Index { get; private set; }
        public ItemData Data { get; private set; }
        public string Prompt => "[E] Pick up " + Data.name;

        public static SZPickup Create(ItemData d, int index, Transform parent)
        {
            var go = new GameObject("Item " + d.id);
            go.transform.SetParent(parent);
            go.transform.position = SZLevelData.V(d.p);
            var pickup = go.AddComponent<SZPickup>();
            pickup.Index = index;
            pickup.Data = d;

            var color = SZLevelData.C(d.color);
            var look = GameObject.CreatePrimitive(Shape(d.id, out var size));
            look.name = "Look";
            look.transform.SetParent(go.transform, false);
            look.transform.localScale = size;
            look.transform.localPosition = new Vector3(0f, size.y * (d.id == "battery" || d.id == "flare" ? 1f : 0.5f), 0f);
            if (d.id == "flare") look.transform.localRotation = Quaternion.Euler(0f, 0f, 90f);
            look.GetComponent<Renderer>().sharedMaterial = SZGraphics.Lit(color, 0.45f, color * 0.25f);
            // A downloaded asset in this item's slot replaces the placeholder shape.
            if (SZAssets.Spawn(SZAssets.SlotForItem(d.id), go.transform, onGround: true) != null)
                look.GetComponent<Renderer>().enabled = false;
            // A bigger invisible box so it's easy to aim at.
            var box = look.GetComponent<Collider>();
            Destroy(box);
            var hit = go.AddComponent<BoxCollider>();
            hit.center = new Vector3(0f, 0.15f, 0f);
            hit.size = new Vector3(0.45f, 0.35f, 0.45f);
            hit.isTrigger = true;  // you can aim at it, but you don't trip over it
            return pickup;
        }

        static PrimitiveType Shape(string id, out Vector3 size)
        {
            switch (id)
            {
                case "battery": size = new Vector3(0.05f, 0.045f, 0.05f); return PrimitiveType.Cylinder;
                case "flare": size = new Vector3(0.035f, 0.13f, 0.035f); return PrimitiveType.Cylinder;
                case "medkit": size = new Vector3(0.3f, 0.12f, 0.2f); return PrimitiveType.Cube;
                case "reel_tape": size = new Vector3(0.18f, 0.02f, 0.18f); return PrimitiveType.Cylinder;
                default:
                    if (id.StartsWith("keycard")) { size = new Vector3(0.09f, 0.005f, 0.055f); return PrimitiveType.Cube; }
                    if (id.StartsWith("weapon")) { size = new Vector3(0.35f, 0.08f, 0.1f); return PrimitiveType.Cube; }
                    size = new Vector3(0.18f, 0.12f, 0.14f);
                    return PrimitiveType.Cube;
            }
        }

        public void Interact(SZPlayer by) => SZWorld.Instance.RequestPickup(this, by);

        void Update()
        {
            // A slow turn so items catch the flashlight.
            transform.Rotate(0f, 25f * Time.deltaTime, 0f);
        }
    }

    // One inventory slot: an item (or nothing), how many (batteries, flares,
    // medkits and ammo stack), and for a gun the bullets in it and spare.
    public class SZSlot
    {
        public ItemData item;
        public int count;
        public int clip, reserve;
        public bool Empty => item == null;
        public bool IsGun => item != null && item.id.StartsWith("weapon_");

        public void Clear()
        {
            item = null;
            count = clip = reserve = 0;
        }

        public void CopyFrom(SZSlot other)
        {
            item = other.item;
            count = other.count;
            clip = other.clip;
            reserve = other.reserve;
        }
    }

    // What one player carries, like the Godot version (scripts/items/inventory.gd):
    // 4 quick slots (keys 1-4 pick what's in your hand) and storage slots
    // (2 to start; a pouch adds 2, a backpack adds 4, up to 10).
    // Tab opens the inventory screen to move things around, use or drop them.
    public class SZInventory
    {
        public const int QuickSlots = 4, StartStorage = 2, MaxStorage = 10, StackMax = 5, ClipSize = 12;

        public readonly SZSlot[] Quick = new SZSlot[QuickSlots];
        public readonly List<SZSlot> Storage = new List<SZSlot>();
        public int Selected;  // which quick slot is in your hand
        public SZSlot Held => Quick[Selected];

        public SZInventory()
        {
            for (int i = 0; i < QuickSlots; i++) Quick[i] = new SZSlot();
            for (int i = 0; i < StartStorage; i++) Storage.Add(new SZSlot());
        }

        public IEnumerable<SZSlot> All()
        {
            foreach (var s in Quick) yield return s;
            foreach (var s in Storage) yield return s;
        }

        public static bool Stacks(string id) => id == "battery" || id == "flare" || id == "medkit" || id.StartsWith("ammo_");

        // Picks something up. Returns false (and keeps nothing) if there's no room.
        public bool Add(ItemData item)
        {
            // Packs are worn straight away: more storage.
            if (item.id == "pouch" || item.id == "backpack")
            {
                int extra = item.id == "pouch" ? 2 : 4;
                if (Storage.Count >= MaxStorage) return false;
                for (int i = 0; i < extra && Storage.Count < MaxStorage; i++) Storage.Add(new SZSlot());
                return true;
            }
            // Ammo goes straight into a gun you already have.
            if (item.id.StartsWith("ammo_"))
            {
                var gun = FindGun();
                if (gun != null)
                {
                    gun.reserve += 8;
                    return true;
                }
            }
            if (Stacks(item.id))
                foreach (var s in All())
                    if (!s.Empty && s.item.id == item.id && s.count < StackMax)
                    {
                        s.count++;
                        return true;
                    }
            var free = FreeSlot();
            if (free == null) return false;
            free.item = item;
            free.count = 1;
            if (free.IsGun)
            {
                free.clip = item.id == "weapon_tranq" ? 4 : ClipSize;
                // Ammo you were already carrying loads into it.
                foreach (var s in All())
                    if (!s.Empty && s.item.id.StartsWith("ammo_"))
                    {
                        free.reserve += 8 * s.count;
                        s.Clear();
                    }
            }
            return true;
        }

        // A quick slot first (so it's ready in your hand), then storage.
        public SZSlot FreeSlot()
        {
            foreach (var s in Quick) if (s.Empty) return s;
            foreach (var s in Storage) if (s.Empty) return s;
            return null;
        }

        public int Count(string id)
        {
            int n = 0;
            foreach (var s in All()) if (!s.Empty && s.item.id == id) n += s.count;
            return n;
        }

        public bool Has(string id) => Count(id) > 0;

        // A keycard opens its color's doors and every weaker one (green < yellow < red).
        public bool HasKeycard(string color)
        {
            int need = color == "red" ? 3 : color == "yellow" ? 2 : 1;
            foreach (var s in All())
            {
                if (s.Empty || !s.item.id.StartsWith("keycard_")) continue;
                var c = s.item.id.Substring(8);
                int have = c == "red" ? 3 : c == "yellow" ? 2 : 1;
                if (have >= need) return true;
            }
            return false;
        }

        // Uses up one of something. Returns the item, or null if you had none.
        public ItemData Take(string id)
        {
            foreach (var s in All())
                if (!s.Empty && s.item.id == id)
                {
                    var item = s.item;
                    if (--s.count <= 0) s.Clear();
                    return item;
                }
            return null;
        }

        // The first reel tape (optionally a particular recording).
        public ItemData FindTape(string lore)
        {
            foreach (var s in All())
                if (!s.Empty && s.item.id == "reel_tape" && (string.IsNullOrEmpty(lore) || s.item.lore == lore)) return s.item;
            return null;
        }

        public SZSlot FindGun()
        {
            foreach (var s in All()) if (s.IsGun) return s;
            return null;
        }

        public void Swap(SZSlot a, SZSlot b)
        {
            var temp = new SZSlot();
            temp.CopyFrom(a);
            a.CopyFrom(b);
            b.CopyFrom(temp);
        }

        // Eli and Cole start with the pistol from the trunk.
        public void GiveStartingPistol()
        {
            Add(new ItemData { id = "weapon_pistol", name = "9mm Pistol", hint = "Left click to shoot, R to reload.", color = new[] { 0.28f, 0.28f, 0.3f, 1f } });
            var gun = FindGun();
            if (gun != null) gun.reserve = 12;
        }
    }

    // A thrown flare: red light, a hiss, burns out after a while.
    public class SZFlare : MonoBehaviour
    {
        const float BurnTime = 45f;
        Light _light;
        float _age;

        public static void Throw(Vector3 from, Vector3 velocity)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            go.name = "Flare";
            go.transform.position = from;
            go.transform.localScale = new Vector3(0.05f, 0.09f, 0.05f);
            go.GetComponent<Renderer>().sharedMaterial = SZGraphics.Lit(new Color(0.8f, 0.1f, 0.05f), 0.3f, new Color(4f, 0.6f, 0.3f));
            var body = go.AddComponent<Rigidbody>();
            body.mass = 0.3f;
            body.AddForce(velocity, ForceMode.VelocityChange);
            body.angularVelocity = Random.insideUnitSphere * 6f;
            body.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
            go.AddComponent<SZFlare>();
        }

        void Start()
        {
            var lightGo = new GameObject("Glow");
            lightGo.transform.SetParent(transform, false);
            _light = lightGo.AddComponent<Light>();
            _light.type = LightType.Point;
            _light.color = new Color(1f, 0.25f, 0.12f);
            _light.range = 11f;
            _light.intensity = 3.2f;
            _light.shadows = LightShadows.Soft;
            SZAudio.Attach(gameObject, "flare_hiss", 0.5f, 12f, loop: true);
        }

        void Update()
        {
            _age += Time.deltaTime;
            float life = 1f - Mathf.Clamp01((_age - (BurnTime - 5f)) / 5f);
            _light.intensity = (3.2f + Mathf.PerlinNoise(Time.time * 9f, 0f) * 1.4f) * life;
            if (_age > BurnTime) Destroy(gameObject);
        }
    }
}
