using System.Collections.Generic;
using UnityEngine;

// Sounds. They're the Godot project's own .wav files, copied into
// Assets/Resources/Audio.
namespace Deepwell
{
    public static class SZAudio
    {
        static readonly Dictionary<string, AudioClip> Clips = new Dictionary<string, AudioClip>();

        public static AudioClip Clip(string name)
        {
            if (!Clips.TryGetValue(name, out var clip))
            {
                clip = Resources.Load<AudioClip>("Audio/" + name);
                Clips[name] = clip;
            }
            return clip;
        }

        // A one-off sound somewhere in the world.
        public static void PlayAt(string name, Vector3 position, float volume = 1f, float range = 20f)
        {
            var clip = Clip(name);
            if (clip == null) return;
            var go = new GameObject("Sound " + name);
            go.transform.position = position;
            var source = Setup(go.AddComponent<AudioSource>(), clip, volume, range);
            source.Play();
            Object.Destroy(go, clip.length + 0.1f);
        }

        public static void PlayClipAt(AudioClip clip, Vector3 position, float volume = 1f, float range = 20f)
        {
            if (clip == null) return;
            var go = new GameObject("Sound " + clip.name);
            go.transform.position = position;
            Setup(go.AddComponent<AudioSource>(), clip, volume, range).Play();
            Object.Destroy(go, clip.length + 0.1f);
        }

        // A gunshot, made from noise (there's no gunshot .wav yet; drop one in
        // Resources/Audio as "gunshot.wav" and it's used instead).
        static AudioClip _gunshot;

        public static AudioClip Gunshot()
        {
            if (_gunshot != null) return _gunshot;
            _gunshot = Clip("gunshot");
            if (_gunshot != null) return _gunshot;
            const int rate = 44100;
            int length = (int)(rate * 0.6f);
            var data = new float[length];
            var rng = new System.Random(7);
            float low = 0f;
            for (int i = 0; i < length; i++)
            {
                float t = i / (float)rate;
                float noise = (float)(rng.NextDouble() * 2.0 - 1.0);
                low += (noise - low) * 0.08f;  // a deeper boom under the crack
                float crack = noise * Mathf.Exp(-t * 60f);
                float boom = low * 3f * Mathf.Exp(-t * 9f);
                data[i] = Mathf.Clamp(crack * 0.8f + boom, -1f, 1f);
            }
            _gunshot = AudioClip.Create("gunshot", length, 1, rate, false);
            _gunshot.SetData(data, 0);
            return _gunshot;
        }

        // A one-off sound with no position (menus, stingers).
        public static void Play2D(string name, float volume = 1f)
        {
            var clip = Clip(name);
            if (clip == null) return;
            var go = new GameObject("Sound " + name);
            var source = go.AddComponent<AudioSource>();
            source.clip = clip;
            source.volume = volume;
            source.spatialBlend = 0f;
            source.Play();
            Object.Destroy(go, clip.length + 0.1f);
        }

        // A sound that belongs to something (a door, the monster). Call Play() on it.
        public static AudioSource Attach(GameObject owner, string name, float volume = 1f, float range = 20f, bool loop = false)
        {
            var source = Setup(owner.AddComponent<AudioSource>(), Clip(name), volume, range);
            source.loop = loop;
            source.playOnAwake = false;
            if (loop && source.clip) source.Play();
            return source;
        }

        static AudioSource Setup(AudioSource source, AudioClip clip, float volume, float range)
        {
            source.clip = clip;
            source.volume = volume;
            source.spatialBlend = 1f;
            source.rolloffMode = AudioRolloffMode.Linear;
            source.minDistance = 1f;
            source.maxDistance = range;
            source.dopplerLevel = 0f;
            return source;
        }
    }
}
