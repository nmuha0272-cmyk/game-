using UnityEngine;

// Light effects, the same as the Godot version's flickering_light.gd and
// pulsing_light.gd, plus signs that always face the camera.
namespace Deepwell
{
    // A failing light: cuts out for a moment now and then. brokenness 0 = fine, 1 = barely works.
    public class SZFlicker : MonoBehaviour
    {
        public float brokenness = 0.2f;
        Light _light;
        float _base, _timer;
        bool _lit = true;

        void Start()
        {
            _light = GetComponent<Light>();
            _base = _light.intensity;
        }

        void Update()
        {
            _timer -= Time.deltaTime;
            if (_timer > 0f) return;
            if (_lit && Random.value < brokenness)
            {
                _lit = false;
                _timer = Random.Range(0.03f, 0.12f) + Random.value * brokenness * 1.5f;
                _light.intensity = 0f;
            }
            else
            {
                _lit = true;
                _timer = Random.value < 0.5f ? Random.Range(0.05f, 0.4f) : Random.Range(0.5f, 4f * (1f - brokenness) + 0.5f);
                _light.intensity = _base * Random.Range(0.85f, 1f);
            }
        }
    }

    // A slow red alarm pulse.
    public class SZPulse : MonoBehaviour
    {
        public float speed = 2.2f;
        Light _light;
        float _base;

        void Start()
        {
            _light = GetComponent<Light>();
            _base = _light.intensity;
        }

        void Update() => _light.intensity = _base * (0.25f + 0.75f * (0.5f + 0.5f * Mathf.Sin(Time.time * speed)));
    }

    // Turns to face the camera (for billboard labels like name tags).
    public class SZBillboard : MonoBehaviour
    {
        void LateUpdate()
        {
            var cam = Camera.main;
            if (cam) transform.rotation = Quaternion.LookRotation(transform.position - cam.transform.position);
        }
    }
}
