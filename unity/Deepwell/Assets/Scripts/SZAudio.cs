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
