using UnityEngine;

// Another player in an online game: their character model, name tag and
// flashlight, moved smoothly to where their computer says they are.
namespace Deepwell
{
    public class SZRemotePlayer : MonoBehaviour
    {
        public int Id { get; private set; }
        public string PlayerName { get; private set; }
        public SZCharacter Character { get; private set; }
        public SZWorld.PlayerView View => new SZWorld.PlayerView
        {
            id = Id, alive = true, position = transform.position, character = Character,
            crouching = _crouching, flashlight = _flash.enabled, sprinting = _sprinting, moving = _moving,
        };

        Vector3 _netPos;
        float _netYaw, _netPitch;
        bool _crouching, _sprinting, _moving;
        GameObject _model;
        Transform _head;
        Light _flash;

        public static SZRemotePlayer Create(int id, SZCharacter character, string name, Transform parent)
        {
            var go = new GameObject("Player " + id);
            go.transform.SetParent(parent);
            var r = go.AddComponent<SZRemotePlayer>();
            r.Id = id;
            r.Character = character;
            r.PlayerName = string.IsNullOrEmpty(name) ? SZCharacters.Names[(int)character] : name;
            r._model = SZCharacters.MakeBody(character, go.transform);

            r._head = new GameObject("Head").transform;
            r._head.SetParent(go.transform, false);
            r._head.localPosition = new Vector3(0f, 1.6f, 0f);
            var torch = new GameObject("Flashlight");
            torch.transform.SetParent(r._head, false);
            torch.transform.localPosition = new Vector3(0.2f, -0.2f, 0.3f);
            r._flash = torch.AddComponent<Light>();
            r._flash.type = LightType.Spot;
            r._flash.spotAngle = 50f;
            r._flash.range = 20f;
            r._flash.intensity = 2.8f;
            r._flash.color = new Color(1f, 0.95f, 0.85f);
            r._flash.enabled = false;

            var tag = new GameObject("NameTag");
            tag.transform.SetParent(go.transform, false);
            tag.transform.localPosition = new Vector3(0f, 2.2f, 0f);
            var text = tag.AddComponent<TextMesh>();
            text.text = r.PlayerName;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            tag.GetComponent<MeshRenderer>().sharedMaterial = text.font.material;
            text.fontSize = 48;
            text.characterSize = 0.012f;
            text.anchor = TextAnchor.MiddleCenter;
            text.color = SZCharacters.Colors[(int)character];
            tag.AddComponent<SZBillboard>();
            return r;
        }

        // "S|id|x|y|z|yaw|pitch|flags|character|name"
        public void NetUpdate(string[] m)
        {
            var pos = new Vector3(SZNet.F(m, 2), SZNet.F(m, 3), SZNet.F(m, 4));
            if (_netPos == Vector3.zero) transform.position = pos;
            _netPos = pos;
            _netYaw = SZNet.F(m, 5);
            _netPitch = SZNet.F(m, 6);
            int flags = SZNet.I(m, 7);
            _crouching = (flags & 1) != 0;
            _flash.enabled = (flags & 2) != 0;
            _moving = (flags & 4) != 0;
            _sprinting = (flags & 8) != 0;
        }

        void Update()
        {
            transform.position = Vector3.Lerp(transform.position, _netPos, Time.deltaTime * 12f);
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.Euler(0f, _netYaw, 0f), Time.deltaTime * 12f);
            _head.localRotation = Quaternion.Euler(_netPitch, 0f, 0f);
            _head.localPosition = new Vector3(0f, _crouching ? 1.0f : 1.6f, 0f);
            if (_model)
            {
                _model.transform.localScale = new Vector3(_model.transform.localScale.x,
                    Mathf.Abs(_model.transform.localScale.x) * (_crouching ? 0.7f : 1f), _model.transform.localScale.z);
                SZCharacters.PlayAnimation(_model, !_moving ? "idle" : _sprinting ? "run" : "walk",
                    !_moving ? 0f : _sprinting ? 4.2f : 1.7f);
            }
        }
    }
}
