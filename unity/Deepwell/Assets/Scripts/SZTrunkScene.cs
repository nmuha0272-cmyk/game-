using System.Collections.Generic;
using UnityEngine;

// The start of Chapter 1, the same as the Godot version (opening_dialogue.gd):
// Eli and Cole at the trunk of the team's car. Cole hands Eli a pistol, they
// talk about the seven missing people, and Eli takes out the old photo of him
// with his mom and dad. Then the whole team talks.
// Cutscene-only bodies act the trunk part, so it looks the same on every
// screen wherever the players are standing.
namespace Deepwell
{
    public class SZTrunkScene : MonoBehaviour
    {
        // Where Eli and Cole stand, in the car's own space (the trunk is at +Z).
        // Godot's spots with X flipped.
        static readonly Vector3 EliSpot = new Vector3(0.5f, 0f, 3.35f);
        static readonly Vector3 ColeSpot = new Vector3(-0.5f, 0f, 3.35f);

        Transform _car, _lid;
        readonly List<GameObject> _trunkPistols = new List<GameObject>();
        GameObject _eli, _cole, _photoProp;
        readonly List<GameObject> _hidden = new List<GameObject>();
        float _lidOpen;     // 0..1
        bool _opening;

        // Builds the moving parts of the car (the level model has the rest).
        public static SZTrunkScene Create(SpawnData car, Transform parent)
        {
            var go = new GameObject("TeamCar");
            go.transform.SetParent(parent);
            go.transform.SetPositionAndRotation(SZLevelData.V(car.p), SZLevelData.Q(car.r));
            var scene = go.AddComponent<SZTrunkScene>();
            scene._car = go.transform;
            var paint = SZGraphics.Lit(new Color(0.34f, 0.1f, 0.08f), 0.6f);
            scene._lid = new GameObject("TrunkLid").transform;
            scene._lid.SetParent(go.transform, false);
            scene._lid.localPosition = new Vector3(0f, 1.1f, 1.6f);
            // (A downloaded car brings its own trunk, so no extra lid then.)
            if (!SZAssets.Has("car")) Box(scene._lid, new Vector3(2f, 0.05f, 1f), new Vector3(0f, 0f, 0.5f), paint);
            var black = SZGraphics.Lit(new Color(0.05f, 0.05f, 0.055f), 0.5f);
            foreach (var x in new[] { 0.25f, -0.25f })
                scene._trunkPistols.Add(Pistol(go.transform, new Vector3(x, 1.09f, 2.1f), black));
            return scene;
        }

        // A pistol: the downloaded one if there is one (Asset Slots), or a simple shape.
        static GameObject Pistol(Transform parent, Vector3 pos, Material mat)
        {
            var spot = new GameObject("Pistol").transform;
            spot.SetParent(parent, false);
            spot.localPosition = pos;
            if (SZAssets.Spawn("pistol", spot, onGround: false) == null)
                Box(spot, new Vector3(0.035f, 0.05f, 0.19f), Vector3.zero, mat);
            return spot.gameObject;
        }

        static Transform Box(Transform parent, Vector3 size, Vector3 pos, Material mat)
        {
            var b = GameObject.CreatePrimitive(PrimitiveType.Cube);
            b.transform.SetParent(parent, false);
            b.transform.localPosition = pos;
            b.transform.localScale = size;
            b.GetComponent<Renderer>().sharedMaterial = mat;
            Destroy(b.GetComponent<Collider>());
            return b.transform;
        }

        // Hooked to the opening cutscene: each line, and where its camera goes.
        public void Attach(SZCutscene cutscene)
        {
            cutscene.OnLine = (i, line) =>
            {
                if (line.trunk) Begin(); else End();
                if (line.pistols) TakePistols();
                cutscene.ShowPhoto = line.photo;
                ShowPhotoProp(line.photo);
            };
            cutscene.LineShot = (i, line) => line.trunk && _eli != null ? Shot(line) : (Pose?)null;
        }

        void Begin()
        {
            if (_eli != null) return;
            // Hide whoever plays Eli and Cole (their own bodies stand somewhere else).
            foreach (var r in SZWorld.Instance.Remotes)
                if ((r.Character == SZCharacter.Eli || r.Character == SZCharacter.Cole) && r.gameObject.activeSelf)
                {
                    r.gameObject.SetActive(false);
                    _hidden.Add(r.gameObject);
                }
            _eli = Actor(SZCharacter.Eli, EliSpot);
            _cole = Actor(SZCharacter.Cole, ColeSpot);
            // Face each other.
            _eli.transform.rotation = Quaternion.LookRotation(Flat(_cole.transform.position - _eli.transform.position));
            _cole.transform.rotation = Quaternion.LookRotation(Flat(_eli.transform.position - _cole.transform.position));
            _opening = true;
            SZAudio.PlayAt("metal_creak", _lid.position, 0.8f, 20f);
        }

        GameObject Actor(SZCharacter who, Vector3 spot)
        {
            var go = new GameObject("TrunkActor " + who);
            go.transform.SetParent(transform);
            go.transform.position = _car.TransformPoint(spot);
            SZCharacters.MakeBody(who, go.transform);
            return go;
        }

        static Vector3 Flat(Vector3 v)
        {
            v.y = 0f;
            return v.sqrMagnitude > 0.0001f ? v : Vector3.forward;
        }

        void TakePistols()
        {
            foreach (var g in _trunkPistols) g.SetActive(false);
            var black = SZGraphics.Lit(new Color(0.05f, 0.05f, 0.055f), 0.5f);
            foreach (var actor in new[] { _eli, _cole })
            {
                if (actor == null) continue;
                Pistol(actor.transform, new Vector3(actor == _eli ? 0.24f : -0.24f, 1.0f, 0.3f), black);
            }
            SZAudio.PlayAt("repair_click", _lid.position, 1f, 15f);
        }

        void ShowPhotoProp(bool show)
        {
            if (show && _photoProp == null && _eli != null)
            {
                var tex = Resources.Load<Texture2D>("Textures/eli_family_photo");
                _photoProp = GameObject.CreatePrimitive(PrimitiveType.Quad);
                Destroy(_photoProp.GetComponent<Collider>());
                _photoProp.transform.SetParent(_eli.transform, false);
                _photoProp.transform.localPosition = new Vector3(0f, 1.15f, 0.32f);
                _photoProp.transform.localScale = new Vector3(0.1f, 0.12f, 1f);
                // A Quad shows its front toward -Z, which is toward Eli; tilt it up to his face.
                _photoProp.transform.localRotation = Quaternion.Euler(60f, 0f, 0f);
                var mat = SZGraphics.Lit(Color.white, 0.2f);
                mat.mainTexture = tex;
                _photoProp.GetComponent<Renderer>().sharedMaterial = mat;
            }
            else if (!show && _photoProp != null)
            {
                Destroy(_photoProp);
                _photoProp = null;
            }
        }

        // A two-shot from behind the car (leaning toward whoever talks), or over Eli's shoulder onto the photo.
        Pose Shot(DialogueLine line)
        {
            var back = _car.forward;
            var mid = (_eli.transform.position + _cole.transform.position) / 2f + Vector3.up * 1.45f;
            Vector3 pos, look;
            if (line.photo)
            {
                var head = _eli.transform.position + Vector3.up * 1.6f;
                pos = head - _eli.transform.forward * 0.95f + _eli.transform.right * 0.5f + Vector3.up * 0.2f;
                look = _eli.transform.position + Vector3.up * 1.1f + _eli.transform.forward * 0.35f;
            }
            else
            {
                var speaker = line.who == "Son" ? _eli : _cole;
                var lean = Vector3.Scale(speaker.transform.position + Vector3.up * 1.45f - mid, new Vector3(0.35f, 0f, 0.35f));
                pos = mid + back * 2.6f + lean + Vector3.up * 0.15f;
                look = mid + lean * 0.5f;
            }
            return new Pose(pos, Quaternion.LookRotation(look - pos));
        }

        // Back to the whole team: the real bodies come back. (The trunk stays open.)
        public void End()
        {
            ShowPhotoProp(false);
            if (_eli) Destroy(_eli);
            if (_cole) Destroy(_cole);
            _eli = _cole = null;
            foreach (var g in _hidden) if (g) g.SetActive(true);
            _hidden.Clear();
        }

        void Update()
        {
            if (!_opening || _lidOpen >= 1f) return;
            _lidOpen = Mathf.MoveTowards(_lidOpen, 1f, Time.deltaTime / 0.8f);
            _lid.localRotation = Quaternion.Euler(-75f * Mathf.SmoothStep(0f, 1f, _lidOpen), 0f, 0f);
        }
    }
}
