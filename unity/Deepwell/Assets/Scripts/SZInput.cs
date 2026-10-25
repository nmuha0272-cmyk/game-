using UnityEngine;
#if ENABLE_INPUT_SYSTEM && !ENABLE_LEGACY_INPUT_MANAGER
using UnityEngine.InputSystem;
#endif

// Keyboard and mouse, read the same way whichever input setting the project
// has ("Input Manager (Old)", "Input System Package (New)" or "Both"), so
// nobody has to change Project Settings before pressing Play.
namespace Deepwell
{
    public enum SZKey
    {
        W, A, S, D, E, F, Q, G, C, R, Tab, Space, Shift, Ctrl, Escape, Enter,
        One, Two, Three, Four, Up, Down, Left, Right,
    }

    public static class SZInput
    {
#if ENABLE_INPUT_SYSTEM && !ENABLE_LEGACY_INPUT_MANAGER
        static Key ToKey(SZKey k)
        {
            switch (k)
            {
                case SZKey.W: return Key.W;
                case SZKey.A: return Key.A;
                case SZKey.S: return Key.S;
                case SZKey.D: return Key.D;
                case SZKey.E: return Key.E;
                case SZKey.F: return Key.F;
                case SZKey.Q: return Key.Q;
                case SZKey.G: return Key.G;
                case SZKey.C: return Key.C;
                case SZKey.R: return Key.R;
                case SZKey.Tab: return Key.Tab;
                case SZKey.Space: return Key.Space;
                case SZKey.Shift: return Key.LeftShift;
                case SZKey.Ctrl: return Key.LeftCtrl;
                case SZKey.Escape: return Key.Escape;
                case SZKey.Enter: return Key.Enter;
                case SZKey.One: return Key.Digit1;
                case SZKey.Two: return Key.Digit2;
                case SZKey.Three: return Key.Digit3;
                case SZKey.Four: return Key.Digit4;
                case SZKey.Up: return Key.UpArrow;
                case SZKey.Down: return Key.DownArrow;
                case SZKey.Left: return Key.LeftArrow;
                default: return Key.RightArrow;
            }
        }

        public static bool Held(SZKey k) => Keyboard.current != null && Keyboard.current[ToKey(k)].isPressed;
        public static bool Down(SZKey k) => Keyboard.current != null && Keyboard.current[ToKey(k)].wasPressedThisFrame;
        public static bool Up(SZKey k) => Keyboard.current != null && Keyboard.current[ToKey(k)].wasReleasedThisFrame;
        // The new system gives pixels; scale it to match the old system's mouse axes.
        public static Vector2 MouseDelta => Mouse.current != null ? Mouse.current.delta.ReadValue() * 0.05f : Vector2.zero;
        public static bool Click => Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame;
        // Mouse position in pixels from the bottom-left corner.
        public static Vector2 MousePosition => Mouse.current != null ? Mouse.current.position.ReadValue() : Vector2.zero;
#else
        static KeyCode ToKey(SZKey k)
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
                default: return KeyCode.RightArrow;
            }
        }

        public static bool Held(SZKey k) => Input.GetKey(ToKey(k));
        public static bool Down(SZKey k) => Input.GetKeyDown(ToKey(k));
        public static bool Up(SZKey k) => Input.GetKeyUp(ToKey(k));
        public static Vector2 MouseDelta => new Vector2(Input.GetAxisRaw("Mouse X"), Input.GetAxisRaw("Mouse Y"));
        public static bool Click => Input.GetMouseButtonDown(0);
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
