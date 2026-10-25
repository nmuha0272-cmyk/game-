using System.Collections.Generic;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM && !ENABLE_LEGACY_INPUT_MANAGER
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Controls;
#endif

// Keyboard and mouse, read the same way whichever input setting the project
// has ("Input Manager (Old)", "Input System Package (New)" or "Both"), so
// nobody has to change Project Settings before pressing Play.
namespace Deepwell
{
    public enum SZKey
    {
        W, A, S, D, E, F, Q, G, C, R, Tab, Space, Shift, Ctrl, Escape, Enter,
        One, Two, Three, Four, Up, Down, Left, Right, QuickSave, QuickLoad,
    }

    public static class SZInput
    {
        // ---------------------------------------------------------------- changing the keys

        // The keys you can change in Settings > Controls, with their names.
        public static readonly SZKey[] Changeable =
        {
            SZKey.W, SZKey.S, SZKey.A, SZKey.D, SZKey.Shift, SZKey.C, SZKey.Space, SZKey.E,
            SZKey.F, SZKey.Q, SZKey.R, SZKey.G, SZKey.Tab, SZKey.QuickSave, SZKey.QuickLoad,
        };

        public static string ActionName(SZKey k)
        {
            switch (k)
            {
                case SZKey.W: return "Move forward";
                case SZKey.S: return "Move back";
                case SZKey.A: return "Move left";
                case SZKey.D: return "Move right";
                case SZKey.Shift: return "Sprint";
                case SZKey.C: return "Crouch";
                case SZKey.Space: return "Jump";
                case SZKey.E: return "Use / pick up";
                case SZKey.F: return "Flashlight";
                case SZKey.Q: return "Ability";
                case SZKey.R: return "Reload";
                case SZKey.G: return "Drop item";
                case SZKey.Tab: return "Inventory";
                case SZKey.QuickSave: return "Quick save";
                case SZKey.QuickLoad: return "Quick load";
                default: return k.ToString();
            }
        }

        static readonly Dictionary<SZKey, KeyCode> Custom = new Dictionary<SZKey, KeyCode>();
        static bool _loaded;

        static void LoadKeys()
        {
            if (_loaded) return;
            _loaded = true;
            foreach (var k in Changeable)
            {
                int code = PlayerPrefs.GetInt("sz_key_" + k, 0);
                if (code != 0) Custom[k] = (KeyCode)code;
            }
        }

        // The key used for an action right now (yours if you changed it).
        public static KeyCode KeyFor(SZKey k)
        {
            LoadKeys();
            return Custom.TryGetValue(k, out var code) ? code : DefaultKey(k);
        }

        public static void SetKey(SZKey k, KeyCode code)
        {
            LoadKeys();
            Custom[k] = code;
            PlayerPrefs.SetInt("sz_key_" + k, (int)code);
            PlayerPrefs.Save();
        }

        public static void ResetKeys()
        {
            LoadKeys();
            foreach (var k in Changeable) PlayerPrefs.DeleteKey("sz_key_" + k);
            Custom.Clear();
            PlayerPrefs.Save();
        }

        static KeyCode DefaultKey(SZKey k)
        {
            switch (k)
            {
                case SZKey.W: return KeyCode.W;
                case SZKey.A: return KeyCode.A;
                case SZKey.S: return KeyCode.S;
                case SZKey.D: return KeyCode.D;
                case SZKey.E: return KeyCode.E;
                case SZKey.F: return KeyCode.F;
                case SZKey.Q: return KeyCode.Q;
                case SZKey.G: return KeyCode.G;
                case SZKey.C: return KeyCode.C;
                case SZKey.R: return KeyCode.R;
                case SZKey.Tab: return KeyCode.Tab;
                case SZKey.Space: return KeyCode.Space;
                case SZKey.Shift: return KeyCode.LeftShift;
                case SZKey.Ctrl: return KeyCode.LeftControl;
                case SZKey.Escape: return KeyCode.Escape;
                case SZKey.Enter: return KeyCode.Return;
                case SZKey.One: return KeyCode.Alpha1;
                case SZKey.Two: return KeyCode.Alpha2;
                case SZKey.Three: return KeyCode.Alpha3;
                case SZKey.Four: return KeyCode.Alpha4;
                case SZKey.Up: return KeyCode.UpArrow;
                case SZKey.Down: return KeyCode.DownArrow;
                case SZKey.Left: return KeyCode.LeftArrow;
                case SZKey.QuickSave: return KeyCode.F5;
                case SZKey.QuickLoad: return KeyCode.F9;
                default: return KeyCode.RightArrow;
            }
        }

        public static string KeyName(KeyCode code)
        {
            switch (code)
            {
                case KeyCode.LeftShift: return "Left Shift";
                case KeyCode.RightShift: return "Right Shift";
                case KeyCode.LeftControl: return "Left Ctrl";
                case KeyCode.RightControl: return "Right Ctrl";
                case KeyCode.Return: return "Enter";
                case KeyCode.Mouse0: return "Left click";
                case KeyCode.Mouse1: return "Right click";
                case KeyCode.Mouse2: return "Middle click";
                default:
                    var name = code.ToString();
                    return name.StartsWith("Alpha") ? name.Substring(5) : name;
            }
        }

#if ENABLE_INPUT_SYSTEM && !ENABLE_LEGACY_INPUT_MANAGER
        // The new Input System names keys a little differently from KeyCode.
        static Key ToKey(SZKey k)
        {
            var code = KeyFor(k);
            switch (code)
            {
                case KeyCode.Return: return Key.Enter;
                case KeyCode.LeftControl: return Key.LeftCtrl;
                case KeyCode.RightControl: return Key.RightCtrl;
                case KeyCode.LeftAlt: return Key.LeftAlt;
                case KeyCode.UpArrow: return Key.UpArrow;
                case KeyCode.DownArrow: return Key.DownArrow;
                case KeyCode.LeftArrow: return Key.LeftArrow;
                case KeyCode.RightArrow: return Key.RightArrow;
            }
            var name = code.ToString();
            if (name.StartsWith("Alpha")) name = "Digit" + name.Substring(5);
            if (name.StartsWith("Keypad")) name = "Numpad" + name.Substring(6);
            return System.Enum.TryParse<Key>(name, out var key) ? key : Key.None;
        }

        static bool IsMouse(SZKey k, out ButtonControl button)
        {
            var code = KeyFor(k);
            button = null;
            if (Mouse.current == null) return code >= KeyCode.Mouse0 && code <= KeyCode.Mouse6;
            if (code == KeyCode.Mouse0) button = Mouse.current.leftButton;
            else if (code == KeyCode.Mouse1) button = Mouse.current.rightButton;
            else if (code == KeyCode.Mouse2) button = Mouse.current.middleButton;
            return code >= KeyCode.Mouse0 && code <= KeyCode.Mouse6;
        }

        static KeyControl Control(SZKey k)
        {
            var key = ToKey(k);
            return Keyboard.current != null && key != Key.None ? Keyboard.current[key] : null;
        }

        public static bool Held(SZKey k) => IsMouse(k, out var b) ? b != null && b.isPressed : Control(k)?.isPressed ?? false;
        public static bool Down(SZKey k) => IsMouse(k, out var b) ? b != null && b.wasPressedThisFrame : Control(k)?.wasPressedThisFrame ?? false;
        public static bool Up(SZKey k) => IsMouse(k, out var b) ? b != null && b.wasReleasedThisFrame : Control(k)?.wasReleasedThisFrame ?? false;
        // The new system gives pixels; scale it to match the old system's mouse axes.
        public static Vector2 MouseDelta => Mouse.current != null ? Mouse.current.delta.ReadValue() * 0.05f : Vector2.zero;
        public static bool Click => Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame;
        public static bool ClickHeld => Mouse.current != null && Mouse.current.leftButton.isPressed;
        // Mouse position in pixels from the bottom-left corner.
        public static Vector2 MousePosition => Mouse.current != null ? Mouse.current.position.ReadValue() : Vector2.zero;
#else
        static KeyCode ToKey(SZKey k) => KeyFor(k);

        public static bool Held(SZKey k) => Input.GetKey(ToKey(k));
        public static bool Down(SZKey k) => Input.GetKeyDown(ToKey(k));
        public static bool Up(SZKey k) => Input.GetKeyUp(ToKey(k));
        public static Vector2 MouseDelta => new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));
        public static bool Click => Input.GetMouseButtonDown(0);
        public static bool ClickHeld => Input.GetMouseButton(0);
        public static Vector2 MousePosition => Input.mousePosition;
#endif

        // WASD or the arrow keys, as a direction (x = right, y = forward).
        public static Vector2 Move
        {
            get
            {
                float x = (Held(SZKey.D) || Held(SZKey.Right) ? 1f : 0f) - (Held(SZKey.A) || Held(SZKey.Left) ? 1f : 0f);
                float y = (Held(SZKey.W) || Held(SZKey.Up) ? 1f : 0f) - (Held(SZKey.S) || Held(SZKey.Down) ? 1f : 0f);
                return Vector2.ClampMagnitude(new Vector2(x, y), 1f);
            }
        }
    }
}
