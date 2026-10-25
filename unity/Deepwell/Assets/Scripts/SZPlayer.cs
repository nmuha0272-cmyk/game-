using UnityEngine;

// The player: walk (WASD), sprint (Shift), crouch (Ctrl or C), jump (Space),
// mouse look, flashlight (F), and E to use things (doors). Same speeds as the
// Godot version: walk 3.5, sprint 6.0, crouch 1.8 meters per second.
namespace Deepwell
{
    public interface ISZInteractable
    {
        string Prompt { get; }
        void Interact(SZPlayer by);
    }

    [RequireComponent(typeof(CharacterController))]
    public class SZPlayer : MonoBehaviour
    {
        public float walkSpeed = 3.5f;
        public float sprintSpeed = 6.0f;
        public float crouchSpeed = 1.8f;
        public float jumpSpeed = 4.2f;
        public float gravity = 14f;
        public float mouseSensitivity = 2.0f;
        public float reach = 2.5f;

        public Camera Camera { get; private set; }
        public Light Flashlight { get; private set; }
        public ISZInteractable Target { get; private set; }

        CharacterController _body;
        float _pitch;
        float _verticalSpeed;
        bool _crouching;

        const float StandHeight = 1.8f;
        const float CrouchHeight = 1.15f;

        public static SZPlayer Spawn(Vector3 position, Quaternion rotation)
        {
            var go = new GameObject("Player");
            go.transform.SetPositionAndRotation(position + Vector3.up * 0.1f, Quaternion.Euler(0f, rotation.eulerAngles.y, 0f));
            var body = go.AddComponent<CharacterController>();
            body.height = StandHeight;
            body.radius = 0.35f;
            body.center = new Vector3(0f, StandHeight / 2f, 0f);
            body.stepOffset = 0.3f;
            return go.AddComponent<SZPlayer>();
        }

        void Awake()
        {
            _body = GetComponent<CharacterController>();
            var head = new GameObject("Head");
            head.transform.SetParent(transform, false);
            head.transform.localPosition = new Vector3(0f, 1.6f, 0f);
            Camera = head.AddComponent<Camera>();
            Camera.nearClipPlane = 0.05f;
            Camera.fieldOfView = 75f;
            Camera.clearFlags = CameraClearFlags.SolidColor;
            Camera.backgroundColor = new Color(0.01f, 0.012f, 0.02f);
            head.AddComponent<AudioListener>();
            head.tag = "MainCamera";

            var torch = new GameObject("Flashlight");
            torch.transform.SetParent(head.transform, false);
            torch.transform.localPosition = new Vector3(0.18f, -0.15f, 0.1f);
            Flashlight = torch.AddComponent<Light>();
            Flashlight.type = LightType.Spot;
            Flashlight.spotAngle = 48f;
            Flashlight.range = 22f;
            Flashlight.intensity = 3.2f;
            Flashlight.color = new Color(1f, 0.95f, 0.85f);
            Flashlight.shadows = LightShadows.Soft;
            Flashlight.enabled = false;
        }

        void Update()
        {
            if (SZGame.Paused) return;
            Look();
            Move();
            if (Input.GetKeyDown(KeyCode.F)) Flashlight.enabled = !Flashlight.enabled;
            FindTarget();
            if (Input.GetKeyDown(KeyCode.E)) Target?.Interact(this);
        }

        void Look()
        {
            transform.Rotate(0f, Input.GetAxis("Mouse X") * mouseSensitivity, 0f);
            _pitch = Mathf.Clamp(_pitch - Input.GetAxis("Mouse Y") * mouseSensitivity, -85f, 85f);
            Camera.transform.localEulerAngles = new Vector3(_pitch, 0f, 0f);
        }

        void Move()
        {
            bool wantCrouch = Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.C);
            if (wantCrouch != _crouching && (wantCrouch || CanStandUp()))
            {
                _crouching = wantCrouch;
                _body.height = _crouching ? CrouchHeight : StandHeight;
                _body.center = new Vector3(0f, _body.height / 2f, 0f);
                Camera.transform.localPosition = new Vector3(0f, _crouching ? 1.0f : 1.6f, 0f);
            }

            var input = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical"));
            input = Vector3.ClampMagnitude(input, 1f);
            float speed = _crouching ? crouchSpeed : Input.GetKey(KeyCode.LeftShift) ? sprintSpeed : walkSpeed;
            var velocity = transform.TransformDirection(input) * speed;

            if (_body.isGrounded)
            {
                _verticalSpeed = -1f;
                if (Input.GetKeyDown(KeyCode.Space) && !_crouching) _verticalSpeed = jumpSpeed;
            }
            else
            {
                _verticalSpeed -= gravity * Time.deltaTime;
            }
            velocity.y = _verticalSpeed;
            _body.Move(velocity * Time.deltaTime);
        }

        bool CanStandUp()
        {
            var bottom = transform.position + Vector3.up * (_body.radius + 0.05f);
            return !Physics.SphereCast(bottom, _body.radius * 0.9f, Vector3.up, out _, StandHeight - _body.radius * 2f,
                ~0, QueryTriggerInteraction.Ignore);
        }

        void FindTarget()
        {
            Target = null;
            var ray = new Ray(Camera.transform.position, Camera.transform.forward);
            if (Physics.Raycast(ray, out var hit, reach, ~0, QueryTriggerInteraction.Ignore))
                Target = hit.collider.GetComponentInParent<ISZInteractable>();
        }
    }
}
