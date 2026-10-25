using System.Collections.Generic;
using UnityEngine;

// Items lying around the level (batteries, flares, medkits, keycards...),
// and what you're carrying. Press E to pick things up.
//   1 = Battery: recharge your flashlight.
//   2 = Flare: throw a red flare that lights up the dark for a while.
//   3 = Medkit: you have one? If the Long Man catches you, you get away
//       (the medkit is used up) instead of going back to the checkpoint.
// Everything else (keycards, fuses, tapes, weapons...) goes in your bag
// (Tab). Keycards and fuses are needed when the puzzles come to Unity.
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

    // What one player carries.
    public class SZInventory
    {
        public const int ClipSize = 12;
        public int Batteries, Flares, Medkits;
        public bool HasGun;
        public int Clip, Reserve;   // bullets in the gun, and spare bullets
        public readonly List<ItemData> Bag = new List<ItemData>();

        public void Add(ItemData item)
        {
            switch (item.id)
            {
                case "battery": Batteries++; break;
                case "flare": Flares++; break;
                case "medkit": Medkits++; break;
                default:
                    // Any gun works as a pistol for now; any ammo fits it.
                    if (item.id.StartsWith("weapon_")) GiveGun(item.id == "weapon_tranq" ? 4 : ClipSize);
                    else if (item.id.StartsWith("ammo_")) Reserve += 8;
                    else Bag.Add(item);
                    break;
            }
        }

        public void GiveGun(int bullets)
        {
            if (HasGun) Reserve += bullets;
            else Clip = Mathf.Min(bullets, ClipSize);
            HasGun = true;
        }

        public bool Has(string id) => Bag.Exists(i => i.id == id);
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
