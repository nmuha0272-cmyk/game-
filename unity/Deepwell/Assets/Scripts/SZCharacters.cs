using UnityEngine;

// The four playable characters (same as the Godot version's characters.gd),
// and loading their 3D models. The models are the Godot project's own .glb
// files: the Deepwell > "Copy Character Models" menu (it also runs by itself
// the first time) copies them into Assets/Resources/Characters/. If they
// aren't there, people show up as simple stand-in figures.
namespace Deepwell
{
    public enum SZCharacter { Eli, Cole, Nora, Walter }

    public static class SZCharacters
    {
        public static readonly string[] Names = { "Eli Reyes", "Cole Brennan", "Nora Vance", "Walter Kessler" };
        public static readonly string[] Roles = { "The Son  //  Tracker", "The Guard  //  Protector", "The Journalist  //  Stunner", "The Engineer  //  Fixer" };
        // From the Godot home screen (main_menu_car.gd).
        public static readonly string[] About =
        {
            "21. College student and Army Reserve soldier. Both his parents died here in 1999. Now his two best friends are missing in there.",
            "36. Former soldier. Raised Eli after his parents died, like a father. Knows this place better than he admits.",
            "35. Investigative journalist. Her source vanished trying to expose Deepwell. She wants the proof.",
            "60. Worked at Deepwell before it was sealed. Nervous, quiet, and hiding something.",
        };
        public static readonly string[] Quotes =
        {
            "\"Dad always said: slow is smooth, smooth is fast.\"",
            "\"Eyes up, kid. Stay behind me.\"",
            "\"If it's real, I'm getting it on film.\"",
            "\"I can fix it. Just keep them away from me.\"",
        };
        public static readonly string[] Abilities =
        {
            "SENSE (Q): see the Long Man and your friends through walls for a few seconds.",
            "STRENGTH (hold Q on a closed door): hold it shut. The Long Man can't get through.",
            "CAMERA FLASH (Q): a bright flash that stuns the Long Man if he's in front of you.",
            "REPAIR (hold Q on a broken, flickering light): fix it so it stays on.",
        };
        // Model file names in Resources/Characters (kept the same as the Godot project's).
        static readonly string[] Models = { "eli", "frank", "journalist", "engineer" };
        // Asset slot names: a rigged model with idle/walk/run clips (Mixamo, the
        // Human Basic Motions pack...) can be dropped in and replaces the file.
        static readonly string[] SlotIds = { "eli", "cole", "nora", "walter" };
        public static readonly Color[] Colors =
        {
            new Color(0.35f, 0.55f, 0.95f), new Color(0.45f, 0.6f, 0.35f),
            new Color(0.85f, 0.65f, 0.3f), new Color(0.75f, 0.35f, 0.3f),
        };

        // Cole is big: a bit slower, and louder (the Long Man hears him further away).
        public static float SpeedMultiplier(SZCharacter c) => c == SZCharacter.Cole ? 0.85f : 1f;
        public static float NoiseMultiplier(SZCharacter c) => c == SZCharacter.Cole ? 1.5f : 1f;
        // How tall each person is (meters), same as Godot.
        static readonly float[] Heights = { 1.78f, 1.9f, 1.68f, 1.75f };

        public static string ModelFile(SZCharacter c) => Models[(int)c];
        public static float Height(SZCharacter c) => Heights[(int)c];

        public static GameObject MakeBody(SZCharacter c, Transform parent)
        {
            var slot = SZAssets.Spawn(SlotIds[(int)c], parent, onGround: true, size: Heights[(int)c]);
            if (slot != null)
            {
                PlayAnimation(slot, "idle");
                return slot;
            }
            return LoadModel(Models[(int)c], parent, Heights[(int)c]) ?? StandIn(parent, Colors[(int)c]);
        }

        // A model from Resources/Characters, scaled to the given height, feet on the ground.
        public static GameObject LoadModel(string file, Transform parent, float height)
        {
            var prefab = Resources.Load<GameObject>("Characters/" + file);
            if (prefab == null) return null;
            var model = Object.Instantiate(prefab, parent);
            model.name = "Model";
            SZGraphics.NotSoShiny(model);  // the model files say "metal"; that looked like chrome
            model.transform.localPosition = Vector3.zero;
            model.transform.localRotation = Quaternion.identity;
            var renderers = model.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0) return model;
            var bounds = renderers[0].bounds;
            foreach (var r in renderers) bounds.Encapsulate(r.bounds);
            if (bounds.size.y > 0.01f)
            {
                float scale = height / bounds.size.y;
                model.transform.localScale = Vector3.one * scale;
                float feet = (bounds.min.y - parent.position.y) * scale;
                model.transform.localPosition = new Vector3(0f, -feet, 0f);
            }
            foreach (var col in model.GetComponentsInChildren<Collider>()) Object.Destroy(col);
            var anim = model.AddComponent<SZModelAnim>();
            anim.Init();
            PlayAnimation(model, "idle");
            return model;
        }

        // Plays the model's own clip for idle/walk/run if it has one; models
        // without clips (the game's own .glb files) get made-up motion instead.
        public static void PlayAnimation(GameObject model, string word, float speed = 0f)
        {
            var anim = ModelAnim(model);
            if (anim != null) anim.Play(word, speed);
        }

        // The Long Man's made-up motion is slower and heavier than a person's.
        public static void SetHeavy(GameObject model, bool heavy)
        {
            var anim = ModelAnim(model);
            if (anim != null) anim.Heavy = heavy;
        }

        static SZModelAnim ModelAnim(GameObject model)
        {
            if (!model) return null;
            var anim = model.GetComponent<SZModelAnim>();
            if (anim == null)
            {
                anim = model.AddComponent<SZModelAnim>();
                anim.Init();
            }
            return anim;
        }

        static GameObject StandIn(Transform parent, Color color)
        {
            var root = new GameObject("Model");
            root.transform.SetParent(parent, false);
            var mat = SZGraphics.Lit(color * 0.6f, 0.15f);
            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            body.transform.SetParent(root.transform, false);
            body.transform.localPosition = new Vector3(0f, 0.9f, 0f);
            body.transform.localScale = new Vector3(0.55f, 0.9f, 0.45f);
            body.GetComponent<Renderer>().sharedMaterial = mat;
            var head = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            head.transform.SetParent(root.transform, false);
            head.transform.localPosition = new Vector3(0f, 1.62f, 0.02f);
            head.transform.localScale = Vector3.one * 0.3f;
            head.GetComponent<Renderer>().sharedMaterial = SZGraphics.Lit(new Color(0.75f, 0.6f, 0.5f), 0.2f);
            foreach (var col in root.GetComponentsInChildren<Collider>()) Object.Destroy(col);
            return root;
        }
    }
}
