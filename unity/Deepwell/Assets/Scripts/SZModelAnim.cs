using UnityEngine;

// Idle / walk / run for a character or monster model.
//
// The game's own models (eli.glb, long_man.glb...) are single static meshes:
// no skeleton, no animation clips. So this makes them move by itself (breathing,
// a step bob, a lean while running). If a model that *does* have clips is used
// instead (a rigged Mixamo model dropped into an asset slot, or a .glb with
// animations), the clips are played and the made-up motion gets out of the way.
namespace Deepwell
{
    public class SZModelAnim : MonoBehaviour
    {
        public string State { get; private set; } = "idle";
        public bool Heavy;  // the Long Man: slower, heavier sway

        Animation _legacy;
        Animator _animator;
        string[] _clips = new string[0];
        bool _hasClips;
        string _playing;
        Vector3 _basePos;
        Quaternion _baseRot;
        float _phase;
        float _blend;   // 0 = standing, 1 = running
        float _speed;
        bool _ready;

        // Call once after the model is placed (so its rest position is saved).
        public void Init()
        {
            if (_ready) return;
            _ready = true;
            _legacy = GetComponentInChildren<Animation>();
            _animator = GetComponentInChildren<Animator>();
            if (_animator != null)
            {
                _animator.applyRootMotion = false;
                _animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
            }
            _clips = ClipNames();
            _hasClips = _clips.Length > 0;
            _basePos = transform.localPosition;
            _baseRot = transform.localRotation;
        }

        string[] ClipNames()
        {
            if (_legacy != null)
            {
                var names = new System.Collections.Generic.List<string>();
                foreach (AnimationState state in _legacy) names.Add(state.name);
                if (names.Count > 0) return names.ToArray();
            }
            var controller = _animator != null ? _animator.runtimeAnimatorController : null;
            if (controller == null) return new string[0];
            var clips = controller.animationClips;
            var list = new System.Collections.Generic.List<string>();
            foreach (var clip in clips) if (clip != null) list.Add(clip.name);
            return list.ToArray();
        }

        // state: "idle", "walk" or "run". speed (meters/sec) is optional; it
        // only makes the made-up motion match how fast the person is moving.
        public void Play(string state, float speed = 0f)
        {
            State = state;
            _speed = speed;
            if (!_hasClips) return;

            var name = FindClip(state) ?? FindClip("idle") ?? _clips[0];
            if (name == _playing) return;
            _playing = name;

            if (_legacy != null && _legacy.GetClip(name) != null)
            {
                var clip = _legacy.GetClip(name);
                clip.wrapMode = WrapMode.Loop;
                _legacy.CrossFade(name, 0.25f);
                return;
            }
            if (_animator != null && _animator.runtimeAnimatorController != null)
            {
                int hash = Animator.StringToHash(name);
                if (_animator.HasState(0, hash)) _animator.CrossFade(hash, 0.25f);
                else _animator.Play(hash);
            }
        }

        string FindClip(string word)
        {
            foreach (var name in _clips)
                if (name.ToLowerInvariant().Contains(word)) return name;
            return null;
        }

        void LateUpdate()
        {
            if (_hasClips) return;  // a real animation is playing

            // How fast: from the state, or from the actual speed when it's known.
            float target = State == "run" ? 1f : State == "walk" ? 0.45f : 0f;
            if (_speed > 0.05f) target = Mathf.Clamp01(_speed / 4.2f);
            _blend = Mathf.MoveTowards(_blend, target, Time.deltaTime * 3f);

            float rate = Heavy ? 0.55f : 1f;
            _phase += Time.deltaTime * Mathf.Lerp(1.7f, 9.5f, _blend) * rate;

            float breathe = Mathf.Sin(Time.time * (Heavy ? 0.9f : 1.6f)) * (Heavy ? 0.012f : 0.007f);
            float bob = Mathf.Abs(Mathf.Sin(_phase)) * (0.015f + 0.04f * _blend);
            float yaw = Mathf.Sin(_phase * 0.5f) * (1.0f + 2.2f * _blend);
            float roll = Mathf.Sin(_phase) * (0.8f + 3.0f * _blend);
            float lean = (Heavy ? 7f : 4.5f) * _blend;

            if (Heavy)
            {
                bob *= 1.5f;
                roll *= 1.5f;
                yaw *= 1.3f;
            }

            transform.localPosition = _basePos + Vector3.up * (bob + breathe * (1f - _blend));
            transform.localRotation = _baseRot * Quaternion.Euler(lean, yaw, roll);
        }
    }
}
