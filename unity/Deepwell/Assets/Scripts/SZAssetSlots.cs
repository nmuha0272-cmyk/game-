using System;
using System.Collections.Generic;
using UnityEngine;

// Asset slots: the places where a downloaded asset (from the Unity Asset
// Store, for example a pistol or a medkit) replaces the game's simple
// placeholder shape. Each slot holds one prefab or model.
//
// You don't have to do anything: when an asset is imported, the editor
// script (Editor/SZAssetSlotsEditor.cs) looks at its name ("Glock",
// "Medkit", "Flashlight"...) and puts it in the matching empty slot. You can
// also open Deepwell > Asset Slots to drag something in yourself, turn it,
// or clear a slot. Empty slots keep the placeholder.
//
// The slots are saved in Assets/Resources/SZAssetSlots.asset.
namespace Deepwell
{
    [CreateAssetMenu(menuName = "Deepwell/Asset Slots")]
    public class SZAssetSlots : ScriptableObject
    {
        [Serializable]
        public class Slot
        {
            public string id;
            public GameObject prefab;
            public Vector3 rotation;       // turn the model if it faces the wrong way
            public float sizeMultiplier = 1f;
            public bool manual;            // you picked it yourself (never replaced automatically)
        }

        public List<Slot> slots = new List<Slot>();

        // Every slot the game uses: id, what it is, how big it should be (meters,
        // its longest side), and words that find a matching asset by name.
        public static readonly SlotInfo[] Info =
        {
            new SlotInfo("pistol", "Pistol (held, in the trunk, and on the floor)", 0.22f, "pistol", "handgun", "glock", "beretta", "m1911", "1911", "colt", "9mm", "usp", "p226", "sidearm"),
            new SlotInfo("revolver", "Revolver", 0.3f, "revolver", "magnum"),
            new SlotInfo("shotgun", "Shotgun", 1.0f, "shotgun", "remington", "pump action"),
            new SlotInfo("smg", "Submachine gun", 0.6f, "smg", "mp5", "uzi", "submachine"),
            new SlotInfo("rifle", "Rifle", 1.0f, "rifle", "ak47", "ak 47", "m4a1", "m16", "ar15", "sniper", "carbine"),
            new SlotInfo("flashlight", "Flashlight (in your hand)", 0.25f, "flashlight", "torch light", "torchlight"),
            new SlotInfo("battery", "Battery", 0.09f, "battery", "batteries", "aa cell"),
            new SlotInfo("flare", "Flare", 0.22f, "flare", "road flare"),
            new SlotInfo("medkit", "Medkit", 0.32f, "medkit", "med kit", "first aid", "firstaid", "health kit", "healthkit"),
            new SlotInfo("keycard", "Keycard", 0.09f, "keycard", "key card", "access card", "id card", "security card"),
            new SlotInfo("fuse", "Fuse", 0.1f, "fuse"),
            new SlotInfo("crowbar", "Crowbar", 0.7f, "crowbar", "pry bar", "prybar"),
            new SlotInfo("gas_mask", "Gas mask", 0.3f, "gas mask", "gasmask", "respirator"),
            new SlotInfo("walkie", "Walkie-talkie", 0.22f, "walkie", "talkie", "handheld radio", "two way radio"),
            new SlotInfo("reel_tape", "Reel tape", 0.18f, "reel tape", "tape reel", "cassette", "audio tape"),
            new SlotInfo("ammo", "Ammo box", 0.14f, "ammo", "ammunition", "bullets", "cartridge"),
            new SlotInfo("backpack", "Backpack", 0.5f, "backpack", "rucksack"),
            new SlotInfo("pouch", "Pouch", 0.22f, "pouch"),
            new SlotInfo("fuel_can", "Fuel can", 0.45f, "fuel can", "jerry can", "jerrycan", "gas can", "petrol can"),
            new SlotInfo("car_battery", "Car battery", 0.35f, "car battery"),
            new SlotInfo("note", "Notes and files", 0.3f, "note", "paper", "document", "letter", "folder", "clipboard"),
            new SlotInfo("car", "The team's car (home screen and at the station)", 4.8f, "car", "sedan", "vehicle", "suv", "pickup truck", "station wagon"),
            new SlotInfo("keypad", "Keypads", 0.26f, "keypad", "key pad", "code lock", "numpad", "pin pad"),
            new SlotInfo("locker", "Lockers you hide in", 2.15f, "locker", "metal cabinet", "wardrobe"),
            new SlotInfo("desk", "Desks", 1.6f, "desk", "office table", "work table", "writing table"),
            new SlotInfo("computer", "Computers, monitors and the terminal", 0.5f, "computer", "monitor", "crt", "desktop pc", "pc", "terminal"),
            new SlotInfo("door", "Doors (2 m x 3 m)", 3.0f, "door"),
            new SlotInfo("long_man", "The Long Man (monster)", 2.9f, "long man", "longman", "slender", "creature", "monster"),
        };

        public class SlotInfo
        {
            public readonly string id, label;
            public readonly float size;
            public readonly string[] words;

            public SlotInfo(string id, string label, float size, params string[] words)
            {
                this.id = id;
                this.label = label;
                this.size = size;
                this.words = words;
            }
        }

        public Slot Find(string id) => slots.Find(s => s.id == id);
    }

    // What the game calls: "is there a downloaded asset for this?"
    public static class SZAssets
    {
        static SZAssetSlots _slots;
        static bool _loaded;

        static SZAssetSlots Slots
        {
            get
            {
                if (!_loaded)
                {
                    _loaded = true;
                    _slots = Resources.Load<SZAssetSlots>("SZAssetSlots");
                }
                return _slots;
            }
        }

        // Which slot an item uses (weapon_pistol -> pistol, keycard_red -> keycard...).
        public static string SlotForItem(string itemId)
        {
            if (itemId.StartsWith("weapon_"))
            {
                var gun = itemId.Substring(7);
                if (gun == "suppressed_9mm" || gun == "tranq" || gun == "flare_gun") return "pistol";
                return gun;
            }
            if (itemId.StartsWith("ammo_")) return "ammo";
            if (itemId.StartsWith("keycard")) return "keycard";
            return itemId;
        }

        public static bool Has(string id)
        {
            var slot = Slots != null ? Slots.Find(id) : null;
            return slot != null && slot.prefab != null;
        }

        // Puts the asset in this slot under parent, fitted to the slot's size
        // (longest side), or returns null so the caller makes its placeholder.
        // onGround: its bottom sits at the parent; otherwise it's centered.
        public static GameObject Spawn(string id, Transform parent, bool onGround, float size = -1f)
        {
            var slot = Slots != null ? Slots.Find(id) : null;
            if (slot == null || slot.prefab == null) return null;
            var info = Array.Find(SZAssetSlots.Info, i => i.id == id);
            if (size <= 0f) size = info != null ? info.size : 0.3f;
            size *= Mathf.Max(slot.sizeMultiplier, 0.01f);

            // Made inside a switched-off holder, so the asset's own scripts (car
            // controllers, demo cameras...) never start; then switched off for good.
            var holder = new GameObject("Holder");
            holder.SetActive(false);
            var go = UnityEngine.Object.Instantiate(slot.prefab, holder.transform);
            MakeQuiet(go);
            go.transform.SetParent(parent, false);
            UnityEngine.Object.Destroy(holder);
            go.name = "Asset " + id;
            go.transform.localPosition = Vector3.zero;
            go.transform.localRotation = Quaternion.Euler(slot.rotation);
            go.transform.localScale = Vector3.one;
            SZGraphics.FixPink(go);   // HDRP/URP assets would be pink

            var renderers = go.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0) return go;
            var bounds = renderers[0].bounds;
            foreach (var r in renderers) bounds.Encapsulate(r.bounds);
            float longest = Mathf.Max(bounds.size.x, bounds.size.y, bounds.size.z);
            if (longest > 0.0001f) go.transform.localScale = Vector3.one * (size / longest);
            // Move it so it's centered on the parent (or standing on it).
            bounds = renderers[0].bounds;
            foreach (var r in renderers) bounds.Encapsulate(r.bounds);
            var anchor = onGround ? new Vector3(bounds.center.x, bounds.min.y, bounds.center.z) : bounds.center;
            go.transform.position += parent.position - anchor;
            return go;
        }

        // Swap a downloaded asset in for a level object (a desk, a computer, the
        // car): sitting where it stood, as big as it was. Null if the slot is empty.
        public static GameObject Replace(string id, Bounds where, Quaternion facing, Transform parent)
        {
            if (!Has(id)) return null;
            var anchor = new GameObject("Replaced " + id).transform;
            anchor.SetParent(parent, false);
            anchor.SetPositionAndRotation(new Vector3(where.center.x, where.min.y, where.center.z), facing);
            return Spawn(id, anchor, onGround: true, size: Mathf.Max(where.size.x, where.size.y, where.size.z));
        }

        // Store assets often come with their own scripts, physics and cameras.
        // Here they're only for looks, so those are switched off.
        static void MakeQuiet(GameObject go)
        {
            // Removed right away while it's still switched off (scripts first: some need the others).
            Remove<MonoBehaviour>(go);
            Remove<Joint>(go);
            Remove<Collider>(go);
            Remove<Rigidbody>(go);
            Remove<Camera>(go);
            Remove<AudioListener>(go);
        }

        static void Remove<T>(GameObject go) where T : Component
        {
            var list = go.GetComponentsInChildren<T>(true);
            for (int i = list.Length - 1; i >= 0; i--)
                if (list[i] != null) UnityEngine.Object.DestroyImmediate(list[i]);
        }
    }
}
