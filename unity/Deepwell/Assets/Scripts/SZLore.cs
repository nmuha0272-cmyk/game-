using UnityEngine;

// Notes, files, posters, notebooks and tape machines with the story on them.
// Press E to read. Reading is just for you; it doesn't pause the game for
// anyone else (or for you, so read somewhere safe).
namespace Deepwell
{
    public class SZLore : MonoBehaviour, ISZInteractable
    {
        public LoreData Data { get; private set; }
        public string Prompt => Data.kind == "tape_machine" ? "[E] Play tape: " + Data.title : "[E] Read: " + Data.title;

        public static SZLore Create(LoreData d, Transform parent)
        {
            var go = new GameObject("Lore " + d.id);
            go.transform.SetParent(parent);
            go.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            var lore = go.AddComponent<SZLore>();
            lore.Data = d;

            Vector3 size, at = Vector3.zero;
            Color color;
            switch (d.kind)
            {
                case "lore_poster": size = new Vector3(0.6f, 0.85f, 0.01f); color = new Color(0.75f, 0.7f, 0.55f); break;
                case "lore_file": size = new Vector3(0.24f, 0.03f, 0.32f); color = new Color(0.65f, 0.55f, 0.35f); break;
                case "lore_personal": size = new Vector3(0.15f, 0.025f, 0.21f); color = new Color(0.3f, 0.2f, 0.15f); break;
                case "tape_machine": size = new Vector3(0.45f, 0.22f, 0.3f); color = new Color(0.2f, 0.2f, 0.2f); at.y = 0.11f; break;
                default: size = new Vector3(0.21f, 0.004f, 0.29f); color = new Color(0.85f, 0.83f, 0.75f); break;
            }
            var look = GameObject.CreatePrimitive(PrimitiveType.Cube);
            look.name = "Look";
            look.transform.SetParent(go.transform, false);
            look.transform.localPosition = at;
            look.transform.localScale = size;
            // A faint glow so notes are findable in the dark (like the Godot version's shine).
            look.GetComponent<Renderer>().sharedMaterial = SZGraphics.Lit(color, 0.2f, color * 0.12f);
            var col = look.GetComponent<BoxCollider>();
            col.isTrigger = true;
            col.size = new Vector3(1f + 0.25f / size.x, 1f + 0.25f / size.y, 1f + 0.25f / size.z);
            if (d.kind != "tape_machine" && SZAssets.Spawn("note", go.transform, onGround: d.kind != "lore_poster") != null)
                look.GetComponent<Renderer>().enabled = false;  // keep its box so you can still aim at it
            return lore;
        }

        public void Interact(SZPlayer by)
        {
            if (Data.kind == "tape_machine") SZAudio.PlayAt("radio_static", transform.position, 0.6f, 10f);
            SZGame.Instance.Read(Data.title, Data.text);
        }
    }
}
