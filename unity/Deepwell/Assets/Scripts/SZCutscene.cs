using System;
using UnityEngine;

// A short movie moment, like the Godot version's cutscene.gd: black bars come
// down, the camera glides through a few shots with captions, then the team
// can talk (one caption per line). Nobody can move while it plays.
//   Tap Space = next line.  Hold Space = skip the rest.
// Used for the chapter intro ("1999. Site 12 was sealed...") and the team's
// talk when they arrive, and for the Long Man's reveal.
namespace Deepwell
{
    public class SZCutscene : MonoBehaviour
    {
        public static SZCutscene Current { get; private set; }
        public static bool Playing => Current != null;

        public string Caption { get; private set; }
        public string Speaker { get; private set; }
        public float Bars { get; private set; }      // 0..1, the black bars
        public float SkipHold { get; private set; }  // 0..1 while Space is held

        const float LineMin = 2.5f, LineMax = 7f;

        ShotData[] _shots;
        DialogueLine[] _lines;
        Action _done;
        Camera _cam, _playerCam;
        int _shot = -1, _line = -1;
        float _t, _lineTime;
        bool _ending;

        public static SZCutscene Play(ShotData[] shots, DialogueLine[] lines, Camera playerCam, Action done = null)
        {
            if (Current != null) Current.Finish();
            var go = new GameObject("Cutscene");
            var c = go.AddComponent<SZCutscene>();
            c._shots = shots ?? new ShotData[0];
            c._lines = lines ?? new DialogueLine[0];
            c._playerCam = playerCam;
            c._done = done;
            Current = c;
            if (c._shots.Length > 0)
            {
                c._cam = new GameObject("CutsceneCamera").AddComponent<Camera>();
                c._cam.transform.SetParent(go.transform);
                c._cam.fieldOfView = 60f;
                c._cam.nearClipPlane = 0.05f;
                c._cam.farClipPlane = 400f;
                c._cam.clearFlags = CameraClearFlags.SolidColor;
                c._cam.backgroundColor = new Color(0.01f, 0.012f, 0.02f);
                SZGraphics.SetupCamera(c._cam);
                if (playerCam) playerCam.enabled = false;
                c.NextShot();
            }
            else
            {
                c.NextLine();
            }
            return c;
        }

        // Who says it, by the Godot character names.
        static string NameOf(string who)
        {
            switch (who)
            {
                case "Son": return "ELI";
                case "Guard": return "COLE";
                case "Journalist": return "NORA";
                case "Engineer": return "WALTER";
                default: return who.ToUpper();
            }
        }

        void Update()
        {
            float dt = Time.unscaledDeltaTime;
            Bars = Mathf.MoveTowards(Bars, _ending ? 0f : 1f, dt * 2.5f);

            // Hold Space to skip everything; tap it to move on.
            if (SZInput.Held(SZKey.Space)) SkipHold += dt;
            else
            {
                if (SkipHold > 0f && SkipHold < 0.35f) Next();
                SkipHold = 0f;
            }
            if (SkipHold >= 1f)
            {
                Finish();
                return;
            }

            _t += dt;
            if (_shot >= 0 && _shot < _shots.Length)
            {
                var s = _shots[_shot];
                float k = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(_t / Mathf.Max(s.time, 0.1f)));
                var pos = Vector3.Lerp(SZLevelData.V(s.from), SZLevelData.V(s.to), k);
                var look = Vector3.Lerp(SZLevelData.V(s.from_look), SZLevelData.V(s.to_look), k);
                _cam.transform.SetPositionAndRotation(pos, Quaternion.LookRotation(look - pos));
                if (_t >= s.time) NextShot();
            }
            else if (_line >= 0 && _line < _lines.Length)
            {
                if (_t >= _lineTime) NextLine();
            }
        }

        void Next()
        {
            if (_shot >= 0 && _shot < _shots.Length) NextShot();
            else NextLine();
        }

        void NextShot()
        {
            _shot++;
            _t = 0f;
            if (_shot < _shots.Length)
            {
                Speaker = null;
                Caption = _shots[_shot].text;
                return;
            }
            // Shots done: back to your own eyes for the talking.
            if (_cam) Destroy(_cam.gameObject);
            if (_playerCam) _playerCam.enabled = true;
            NextLine();
        }

        void NextLine()
        {
            _line++;
            _t = 0f;
            if (_line >= _lines.Length)
            {
                Finish();
                return;
            }
            Speaker = NameOf(_lines[_line].who);
            Caption = _lines[_line].text;
            // Reading time: about 15 letters a second.
            _lineTime = Mathf.Clamp(Caption.Length / 15f, LineMin, LineMax);
        }

        public void Finish()
        {
            if (_ending) return;
            _ending = true;
            if (_cam) Destroy(_cam.gameObject);
            if (_playerCam) _playerCam.enabled = true;
            if (Current == this) Current = null;
            _done?.Invoke();
            Destroy(gameObject);
        }

        void OnDestroy()
        {
            if (Current == this) Current = null;
            if (_playerCam) _playerCam.enabled = true;
        }
    }
}
