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

            // A downloaded asset in this item's slot, or the simple stand-in shape.
            if (SZAssets.Spawn(SZAssets.SlotForItem(d.id), go.transform, onGround: true) == null)
                SZItemLooks.Build(d, go.transform);
            // A bigger invisible box so it's easy to aim at.
            var hit = go.AddComponent<BoxCollider>();
            hit.center = new Vector3(0f, 0.15f, 0f);
            hit.size = new Vector3(0.45f, 0.35f, 0.45f);
            hit.isTrigger = true;  // you can aim at it, but you don't trip over it
            return pickup;
        }

        public void Interact(SZPlayer by) => SZWorld.Instance.RequestPickup(this, by);

        void Update()
        {
            // A slow turn so items catch the flashlight.
            transform.Rotate(0f, 25f * Time.deltaTime, 0f);
        }
    }

    // One thing in the case: what it is, how many (ammo, batteries and flares
    // stack), bullets loaded (guns), and where it sits in the grid.
    public class SZItem
    {
        public ItemData data;
        public int count = 1;
        public int clip;
        public int x, y;
        public bool turned;   // rotated a quarter turn (a long gun standing up)

        public string Id => data.id;
        public bool IsGun => data.id.StartsWith("weapon_");
        public int W => turned ? SZInventory.SizeOf(Id).y : SZInventory.SizeOf(Id).x;
        public int H => turned ? SZInventory.SizeOf(Id).x : SZInventory.SizeOf(Id).y;
    }

    // The attaché case, like Resident Evil 4: a grid where every item takes
    // up space by its size (a rifle is long, a box of bullets is small). Ammo
    // is its own item and reloading takes bullets from it. Keys 1-4 hold
    // whatever you put on them (in the case, point at an item and press 1-4).
    // A pouch adds a row, a backpack adds two.
    public class SZInventory
    {
        public const int Cols = 9, StartRows = 5, MaxRows = 8;

        public int Rows { get; private set; } = StartRows;
        public readonly List<SZItem> Items = new List<SZItem>();
        public readonly SZItem[] Hotkeys = new SZItem[4];
        public int Selected;  // which hotkey is in your hand (0-3)

        // What's in your hand (null if that hotkey is empty or the item is gone).
        public SZItem Held
        {
            get
            {
                var it = Hotkeys[Selected];
                return it != null && Items.Contains(it) ? it : null;
            }
        }

        // ---------------------------------------------------------------- item facts

        // How many grid cells an item takes (columns x rows).
        // Sizes vary like Resident Evil 7: handguns are small, shotguns/rifles are long.
        public static Vector2Int SizeOf(string id)
        {
            switch (id)
            {
                case "weapon_pistol": case "weapon_flare_gun": return new Vector2Int(1, 2);
                case "weapon_revolver": case "weapon_suppressed_9mm": case "weapon_smg": case "weapon_tranq": return new Vector2Int(2, 2);
                case "weapon_shotgun": return new Vector2Int(4, 2);
                case "weapon_rifle": return new Vector2Int(6, 2);
                case "flare": case "medkit": case "walkie": return new Vector2Int(1, 2);
                case "crowbar": return new Vector2Int(1, 3);
                case "gas_mask": case "car_battery": return new Vector2Int(1, 2);
                case "fuel_can": return new Vector2Int(2, 3);
                default: return new Vector2Int(1, 1);
            }
        }

        public static int StackMax(string id)
        {
            switch (id)
            {
                case "battery": return 10;
                case "flare": return 5;
                case "medkit": return 3;
                case "ammo_9mm": return 50;
                case "ammo_38": return 30;
                case "ammo_12ga": case "ammo_308": return 20;
                case "ammo_dart": case "ammo_flare_shell": return 10;
                default: return 1;
            }
        }

        // How much one pickup gives (a box of bullets has several).
        public static int PickupAmount(string id)
        {
            switch (id)
            {
                case "ammo_9mm": return 15;
                case "ammo_38": return 6;
                case "ammo_12ga": return 6;
                case "ammo_308": return 5;
                case "ammo_dart": return 3;
                case "ammo_flare_shell": return 2;
                default: return 1;
            }
        }

        public static int ClipSize(string gun)
        {
            switch (gun)
            {
                case "weapon_revolver": return 6;
                case "weapon_shotgun": return 6;
                case "weapon_smg": return 30;
                case "weapon_rifle": return 5;
                case "weapon_tranq": case "weapon_flare_gun": return 1;
                default: return 15;
            }
        }

        public static string AmmoFor(string gun)
        {
            switch (gun)
            {
                case "weapon_revolver": return "ammo_38";
                case "weapon_shotgun": return "ammo_12ga";
                case "weapon_rifle": return "ammo_308";
                case "weapon_tranq": return "ammo_dart";
                case "weapon_flare_gun": return "ammo_flare_shell";
                default: return "ammo_9mm";
            }
        }

        // ---------------------------------------------------------------- the grid

        public SZItem At(int cx, int cy)
        {
            foreach (var it in Items)
                if (cx >= it.x && cx < it.x + it.W && cy >= it.y && cy < it.y + it.H) return it;
            return null;
        }

        // Would an item of this size fit with its corner at (x, y)? (ignore = the item being moved)
        public bool Fits(int x, int y, int w, int h, SZItem ignore = null)
        {
            if (x < 0 || y < 0 || x + w > Cols || y + h > Rows) return false;
            foreach (var it in Items)
            {
                if (it == ignore) continue;
                if (x < it.x + it.W && x + w > it.x && y < it.y + it.H && y + h > it.y) return false;
            }
            return true;
        }

        // The first free spot, trying it lying down and standing up.
        bool FindSpot(SZItem item)
        {
            foreach (var turned in new[] { false, true })
            {
                item.turned = turned;
                for (int y = 0; y < Rows; y++)
                    for (int x = 0; x < Cols; x++)
                        if (Fits(x, y, item.W, item.H, item))
                        {
                            item.x = x;
                            item.y = y;
                            return true;
                        }
            }
            item.turned = false;
            return false;
        }

        public bool MoveTo(SZItem item, int x, int y, bool turned)
        {
            bool was = item.turned;
            item.turned = turned;
            if (!Fits(x, y, item.W, item.H, item))
            {
                item.turned = was;
                return false;
            }
            item.x = x;
            item.y = y;
            return true;
        }

        // ---------------------------------------------------------------- adding and using

        // Picks something up. Returns false (and keeps nothing) if there's no room.
        public bool Add(ItemData data)
        {
            // Packs are worn straight away: a bigger case.
            if (data.id == "pouch" || data.id == "backpack")
            {
                if (Rows >= MaxRows) return false;
                Rows = Mathf.Min(MaxRows, Rows + (data.id == "pouch" ? 1 : 2));
                return true;
            }
            int amount = PickupAmount(data.id);
            int max = StackMax(data.id);
            // Top up stacks you already have.
            foreach (var it in Items)
            {
                if (amount <= 0) break;
                if (it.Id != data.id || it.count >= max) continue;
                int put = Mathf.Min(amount, max - it.count);
                it.count += put;
                amount -= put;
            }
            while (amount > 0)
            {
                var item = new SZItem { data = data, count = Mathf.Min(amount, max) };
                if (item.IsGun) item.clip = ClipSize(data.id);
                if (!FindSpot(item)) return amount < PickupAmount(data.id);  // part of it fit
                Items.Add(item);
                amount -= item.count;
                AutoHotkey(item);
            }
            return true;
        }

        // New guns, batteries and flares go on an empty number key by themselves.
        void AutoHotkey(SZItem item)
        {
            foreach (var h in Hotkeys) if (h != null && h.Id == item.Id && Items.Contains(h)) return;
            if (!item.IsGun && item.Id != "battery" && item.Id != "flare" && item.Id != "medkit") return;
            for (int i = 0; i < Hotkeys.Length; i++)
                if (Hotkeys[i] == null || !Items.Contains(Hotkeys[i]))
                {
                    Hotkeys[i] = item;
                    return;
                }
        }

        public void SetHotkey(int key, SZItem item)
        {
            for (int i = 0; i < Hotkeys.Length; i++) if (Hotkeys[i] == item) Hotkeys[i] = null;
            Hotkeys[key] = item;
        }

        public void Remove(SZItem item)
        {
            Items.Remove(item);
            for (int i = 0; i < Hotkeys.Length; i++) if (Hotkeys[i] == item) Hotkeys[i] = null;
        }

        public int Count(string id)
        {
            int n = 0;
            foreach (var it in Items) if (it.Id == id) n += it.count;
            return n;
        }

        public bool Has(string id) => Count(id) > 0;

        // A keycard opens its color's doors and every weaker one (green < yellow < red).
        public bool HasKeycard(string color)
        {
            int need = color == "red" ? 3 : color == "yellow" ? 2 : 1;
            foreach (var it in Items)
            {
                if (!it.Id.StartsWith("keycard_")) continue;
                var c = it.Id.Substring(8);
                if ((c == "red" ? 3 : c == "yellow" ? 2 : 1) >= need) return true;
            }
            return false;
        }

        // Uses up one of something. Returns what it was, or null if you had none.
        public ItemData Take(string id)
        {
            var it = Items.Find(x => x.Id == id);
            if (it == null) return null;
            Take(id, 1);
            return it.data;
        }

        // Uses up to `amount`; returns how many it could.
        public int Take(string id, int amount)
        {
            int got = 0;
            for (int i = Items.Count - 1; i >= 0 && got < amount; i--)
            {
                var it = Items[i];
                if (it.Id != id) continue;
                int take = Mathf.Min(it.count, amount - got);
                it.count -= take;
                got += take;
                if (it.count <= 0) Remove(it);
            }
            return got;
        }

        public ItemData FindTape(string lore)
        {
            foreach (var it in Items)
                if (it.Id == "reel_tape" && (string.IsNullOrEmpty(lore) || it.data.lore == lore)) return it.data;
            return null;
        }

        // Reload a gun from your ammo. Returns how many bullets went in.
        public int Reload(SZItem gun)
        {
            int need = ClipSize(gun.Id) - gun.clip;
            if (need <= 0) return 0;
            int got = Take(AmmoFor(gun.Id), need);
            gun.clip += got;
            return got;
        }

        // Loading a save: empty the case, then Put everything back where it was.
        public void Restore(int rows, int selected)
        {
            Items.Clear();
            for (int i = 0; i < Hotkeys.Length; i++) Hotkeys[i] = null;
            Rows = Mathf.Clamp(rows, StartRows, MaxRows);
            Selected = Mathf.Clamp(selected, 0, Hotkeys.Length - 1);
        }

        public void Put(ItemData data, int count, int clip, int x, int y, bool turned, int hotkey)
        {
            var item = new SZItem { data = data, count = Mathf.Max(1, count), clip = clip, x = x, y = y, turned = turned };
            if (!Fits(x, y, item.W, item.H) && !FindSpot(item)) return;
            Items.Add(item);
            if (hotkey >= 0 && hotkey < Hotkeys.Length) Hotkeys[hotkey] = item;
        }

        // Eli and Cole start with the pistol from the trunk, and a box of bullets.
        public void GiveStartingPistol()
        {
            Add(new ItemData { id = "weapon_pistol", name = "9mm Pistol", hint = "Left click to shoot, R to reload. Uses 9mm ammo.", color = new[] { 0.28f, 0.28f, 0.3f, 1f } });
            Add(new ItemData { id = "ammo_9mm", name = "9mm Ammo", hint = "Bullets for the pistol.", color = new[] { 0.7f, 0.55f, 0.2f, 1f } });
            Selected = 0;
        }
    }

    // Simple stand-in shapes for items (on the floor and in the case's pictures)
    // until a downloaded model is in that item's slot.
    public static class SZItemLooks
    {
        public static GameObject Build(ItemData d, Transform parent)
        {
            var root = new GameObject("Look");
            root.transform.SetParent(parent, false);
            var c = SZLevelData.C(d.color);
            var metal = SZGraphics.Lit(c, 0.45f);
            var dark = SZGraphics.Lit(new Color(0.08f, 0.08f, 0.09f), 0.5f);
            string id = d.id;
            if (id.StartsWith("weapon_"))
            {
                bool longGun = id == "weapon_shotgun" || id == "weapon_rifle";
                if (longGun)
                {
                    Part(root, PrimitiveType.Cube, new Vector3(0f, 0.05f, 0.35f), new Vector3(0.04f, 0.04f, 0.6f), dark);   // barrel
                    Part(root, PrimitiveType.Cube, new Vector3(0f, 0.04f, -0.05f), new Vector3(0.06f, 0.07f, 0.3f), dark);  // body
                    Part(root, PrimitiveType.Cube, new Vector3(0f, 0.02f, -0.35f), new Vector3(0.05f, 0.1f, 0.3f), SZGraphics.Lit(new Color(0.35f, 0.22f, 0.12f), 0.3f));  // stock
                }
                else
                {
                    bool smg = id == "weapon_smg";
                    Part(root, PrimitiveType.Cube, new Vector3(0f, 0.05f, 0.03f), new Vector3(0.035f, 0.045f, smg ? 0.32f : 0.19f), dark);  // slide
                    Part(root, PrimitiveType.Cube, new Vector3(0f, -0.01f, -0.05f), new Vector3(0.03f, 0.1f, 0.045f), dark);              // grip
                    if (id == "weapon_revolver") Part(root, PrimitiveType.Cylinder, new Vector3(0f, 0.05f, 0f), new Vector3(0.05f, 0.025f, 0.05f), metal, 90f);
                    if (smg) Part(root, PrimitiveType.Cube, new Vector3(0f, -0.02f, 0.07f), new Vector3(0.025f, 0.12f, 0.035f), dark);  // magazine
                }
                return root;
            }
            var size = SZInventory.SizeOf(id);
            switch (id)
            {
                case "battery": Part(root, PrimitiveType.Cylinder, new Vector3(0f, 0.045f, 0f), new Vector3(0.05f, 0.045f, 0.05f), metal); break;
                case "flare": Part(root, PrimitiveType.Cylinder, new Vector3(0f, 0.03f, 0f), new Vector3(0.035f, 0.13f, 0.035f), metal, 90f); break;
                case "medkit": Part(root, PrimitiveType.Cube, new Vector3(0f, 0.06f, 0f), new Vector3(0.2f, 0.12f, 0.3f), metal); break;
                case "reel_tape": Part(root, PrimitiveType.Cylinder, new Vector3(0f, 0.01f, 0f), new Vector3(0.18f, 0.01f, 0.18f), metal); break;
                case "crowbar": Part(root, PrimitiveType.Cube, new Vector3(0f, 0.02f, 0f), new Vector3(0.03f, 0.03f, 0.7f), metal); break;
                default:
                    if (id.StartsWith("keycard")) Part(root, PrimitiveType.Cube, new Vector3(0f, 0.003f, 0f), new Vector3(0.09f, 0.005f, 0.055f), metal);
                    else if (id.StartsWith("ammo_")) Part(root, PrimitiveType.Cube, new Vector3(0f, 0.04f, 0f), new Vector3(0.12f, 0.08f, 0.08f), metal);
                    else Part(root, PrimitiveType.Cube, new Vector3(0f, 0.06f * size.y, 0f), new Vector3(0.12f * size.x, 0.12f * size.y, 0.12f), metal);
                    break;
            }
            return root;
        }

        static void Part(GameObject root, PrimitiveType type, Vector3 at, Vector3 size, Material mat, float tiltX = 0f)
        {
            var p = GameObject.CreatePrimitive(type);
            p.transform.SetParent(root.transform, false);
            p.transform.localPosition = at;
            p.transform.localScale = size;
            p.transform.localRotation = Quaternion.Euler(tiltX, 0f, 0f);
            p.GetComponent<Renderer>().sharedMaterial = mat;
            Object.Destroy(p.GetComponent<Collider>());
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
