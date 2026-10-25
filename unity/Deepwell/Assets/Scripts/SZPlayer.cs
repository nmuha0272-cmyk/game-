using UnityEngine;

// You. Same controls and speeds as the Godot version:
//   WASD move, mouse look, Shift sprint (uses stamina), Ctrl or C crouch,
//   Space jump, F flashlight (uses battery), E use / pick up,
//   1 battery, 2 throw a flare, Q your ability, Tab your bag.
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
        public float reach = 2.5f;

        // Seconds of sprinting from full, and how long a full flashlight battery lasts.
        const float StaminaSeconds = 6f;
        const float BatterySeconds = 240f;

        public static float MouseSensitivity = 2.0f;
        public static float FlashlightBrightness = 1f;

        public SZCharacter Character { get; private set; }
        public string PlayerName { get; private set; }
        public Camera Camera { get; private set; }
        public Light Flashlight { get; private set; }
        public ISZInteractable Target { get; private set; }
        public SZInventory Inventory { get; } = new SZInventory();
        public float Stamina { get; private set; } = 1f;
        public float Battery { get; private set; } = 1f;
        public float AbilityCooldown { get; private set; }   // seconds left
        public float SenseUntil { get; private set; }         // Eli's sense is on until this time
        public float AbilityProgress { get; private set; }    // Walter's repair, 0..1
        public string AbilityPrompt { get; private set; }

        public bool Crouching => _crouching;
        public bool Moving => _moving;
        public bool Sprinting => _sprinting;

        public SZWorld.PlayerView View => new SZWorld.PlayerView
        {
            id = SZNet.MyId, alive = Time.time > _safeUntil, position = transform.position, character = Character,
            crouching = _crouching, flashlight = Flashlight.enabled, sprinting = _sprinting, moving = _moving,
        };

        CharacterController _body;
        Transform _head;
        float _pitch, _verticalSpeed, _stepDistance, _bob, _safeUntil, _nextHold;
        bool _crouching, _moving, _sprinting, _tired;
        AudioSource _steps;

        const float StandHeight = 1.8f;
        const float CrouchHeight = 1.15f;

        public static SZPlayer Spawn(Vector3 position, Quaternion rotation, SZCharacter character, string playerName)
        {
            var go = new GameObject("Player (you)");
            go.transform.SetPositionAndRotation(position + Vector3.up * 0.1f, Quaternion.Euler(0f, rotation.eulerAngles.y, 0f));
            var body = go.AddComponent<CharacterController>();
            body.height = StandHeight;
            body.radius = 0.35f;
            body.center = new Vector3(0f, StandHeight / 2f, 0f);
            body.stepOffset = 0.3f;
            var player = go.AddComponent<SZPlayer>();
            player.Character = character;
            player.PlayerName = string.IsNullOrEmpty(playerName) ? SZCharacters.Names[(int)character] : playerName;
            player._safeUntil = Time.time + 3f;
            return player;
        }

        void Awake()
        {
            _body = GetComponent<CharacterController>();
            _head = new GameObject("Head").transform;
            _head.SetParent(transform, false);
            _head.localPosition = new Vector3(0f, 1.6f, 0f);
            Camera = _head.gameObject.AddComponent<Camera>();
            Camera.nearClipPlane = 0.05f;
            Camera.farClipPlane = 400f;
            Camera.fieldOfView = 75f;
            Camera.clearFlags = CameraClearFlags.SolidColor;
            Camera.backgroundColor = new Color(0.008f, 0.01f, 0.016f);
            _head.gameObject.AddComponent<AudioListener>();
            _head.tag = "MainCamera";
            SZGraphics.SetupCamera(Camera);

            var torch = new GameObject("Flashlight");
            torch.transform.SetParent(_head, false);
            torch.transform.localPosition = new Vector3(0.18f, -0.15f, 0.1f);
            Flashlight = torch.AddComponent<Light>();
            Flashlight.type = LightType.Spot;
            Flashlight.spotAngle = 52f;
            Flashlight.innerSpotAngle = 20f;
            Flashlight.range = 24f;
            Flashlight.color = new Color(1f, 0.95f, 0.85f);
            Flashlight.shadows = LightShadows.Soft;
            Flashlight.shadowBias = 0.02f;
            Flashlight.enabled = false;

            _steps = SZAudio.Attach(gameObject, "footstep_placeholder", 0.35f, 15f);
            SZAudio.Attach(_head.gameObject, "ambient_drone", 0.25f, 1000f, loop: true).spatialBlend = 0f;
        }

        void Update()
        {
            UpdateFlashlight();
            if (SZGame.Paused || SZGame.Reading) return;
            Look();
            Move();
            if (SZInput.Down(SZKey.F))
            {
                if (Battery > 0f) Flashlight.enabled = !Flashlight.enabled;
                else SZGame.Instance.Say("The flashlight is dead. Find a battery.", 2f);
                SZAudio.Play2D("repair_click", 0.3f);
            }
            if (SZInput.Down(SZKey.One)) UseBattery();
            if (SZInput.Down(SZKey.Two)) ThrowFlare();
            if (SZInput.Down(SZKey.Three))
                SZGame.Instance.Say(Inventory.Medkits > 0
                    ? "Medkits are used by themselves: if the Long Man catches you, you get away."
                    : "You don't have a medkit.", 3f);
            FindTarget();
            if (SZInput.Down(SZKey.E)) Target?.Interact(this);
            Ability();
        }

        // ---------------------------------------------------------------- moving

        void Look()
        {
            var mouse = SZInput.MouseDelta * MouseSensitivity;
            transform.Rotate(0f, mouse.x, 0f);
            _pitch = Mathf.Clamp(_pitch - mouse.y, -85f, 85f);
            _head.localEulerAngles = new Vector3(_pitch, 0f, 0f);
        }

        void Move()
        {
            bool wantCrouch = SZInput.Held(SZKey.Ctrl) || SZInput.Held(SZKey.C);
            if (wantCrouch != _crouching && (wantCrouch || CanStandUp()))
            {
                _crouching = wantCrouch;
                _body.height = _crouching ? CrouchHeight : StandHeight;
                _body.center = new Vector3(0f, _body.height / 2f, 0f);
            }

            var input = SZInput.Move;
            _moving = input.sqrMagnitude > 0.01f;
            _sprinting = _moving && !_crouching && !_tired && SZInput.Held(SZKey.Shift) && input.y > 0f;
            Stamina = Mathf.Clamp01(Stamina + (_sprinting ? -1f / StaminaSeconds : 1f / (StaminaSeconds * 1.5f)) * Time.deltaTime);
            if (Stamina <= 0f) _tired = true;
            if (_tired && Stamina > 0.35f) _tired = false;

            float speed = _crouching ? crouchSpeed : _sprinting ? sprintSpeed : walkSpeed;
            speed *= SZCharacters.SpeedMultiplier(Character);
            var velocity = transform.TransformDirection(new Vector3(input.x, 0f, input.y)) * speed;

            if (_body.isGrounded)
            {
                _verticalSpeed = -1f;
                if (SZInput.Down(SZKey.Space) && !_crouching) _verticalSpeed = jumpSpeed;
            }
            else
            {
                _verticalSpeed -= gravity * Time.deltaTime;
            }
            velocity.y = _verticalSpeed;
            _body.Move(velocity * Time.deltaTime);

            // Footsteps and a little head bob.
            float flat = new Vector2(_body.velocity.x, _body.velocity.z).magnitude;
            float stand = _crouching ? 1.0f : 1.6f;
            if (_body.isGrounded && flat > 0.5f)
            {
                _bob += flat * Time.deltaTime * 2.2f;
                _stepDistance += flat * Time.deltaTime;
                if (_stepDistance > (_sprinting ? 2.2f : 1.6f))
                {
                    _stepDistance = 0f;
                    _steps.pitch = Random.Range(0.85f, 1.1f);
                    _steps.volume = (_crouching ? 0.08f : _sprinting ? 0.5f : 0.3f) * SZCharacters.NoiseMultiplier(Character);
                    _steps.Play();
                }
            }
            float bob = Mathf.Sin(_bob * Mathf.PI) * (_sprinting ? 0.05f : 0.025f);
            var target = new Vector3(0f, stand + bob, 0f);
            _head.localPosition = Vector3.Lerp(_head.localPosition, target, Time.deltaTime * 12f);

            // Fell out of the world (the lowest floor is at -9 m): put them back.
            if (transform.position.y < -25f) Respawn();
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
            // Items and notes are "trigger" colliders; walls in front of them still block the ray.
            if (Physics.Raycast(ray, out var hit, reach, ~0, QueryTriggerInteraction.Collide))
                Target = hit.collider.GetComponentInParent<ISZInteractable>();
        }

        // ---------------------------------------------------------------- flashlight and items

        void UpdateFlashlight()
        {
            if (Flashlight.enabled)
            {
                Battery = Mathf.Max(0f, Battery - Time.deltaTime / BatterySeconds);
                if (Battery <= 0f)
                {
                    Flashlight.enabled = false;
                    SZGame.Instance.Say("The flashlight died. Press 1 to put in a battery.", 3f);
                }
            }
            float power = 3.4f * FlashlightBrightness;
            // A dying battery dims and stutters.
            if (Battery < 0.15f) power *= 0.5f + 0.5f * Mathf.PerlinNoise(Time.time * 6f, 0f) * (Battery / 0.15f);
            Flashlight.intensity = power;
        }

        void UseBattery()
        {
            if (Inventory.Batteries <= 0)
            {
                SZGame.Instance.Say("No batteries.", 1.5f);
                return;
            }
            Inventory.Batteries--;
            Battery = 1f;
            SZAudio.Play2D("repair_click", 0.6f);
            SZGame.Instance.Say("Flashlight recharged.", 1.5f);
        }

        void ThrowFlare()
        {
            if (Inventory.Flares <= 0)
            {
                SZGame.Instance.Say("No flares.", 1.5f);
                return;
            }
            Inventory.Flares--;
            var from = Camera.transform.position + Camera.transform.forward * 0.5f;
            SZWorld.Instance.ThrowFlare(from, Camera.transform.forward * 9f + Vector3.up * 2f + _body.velocity * 0.5f);
        }

        // ---------------------------------------------------------------- abilities (Q)

        void Ability()
        {
            AbilityCooldown = Mathf.Max(0f, AbilityCooldown - Time.deltaTime);
            AbilityPrompt = null;
            switch (Character)
            {
                case SZCharacter.Eli:
                    if (SZInput.Down(SZKey.Q) && AbilityCooldown <= 0f)
                    {
                        SenseUntil = Time.time + 6f;
                        AbilityCooldown = 20f;
                        SZAudio.Play2D("sense_pulse", 0.8f);
                    }
                    break;
                case SZCharacter.Nora:
                    if (SZInput.Down(SZKey.Q) && AbilityCooldown <= 0f)
                    {
                        AbilityCooldown = 12f;
                        SZPostEffect.Flash = 0.35f;
                        SZWorld.Instance.CameraFlash(Camera.transform.position + Camera.transform.forward * 0.3f, Camera.transform.forward);
                    }
                    break;
                case SZCharacter.Cole:
                    if (Target is SZDoor door && !door.IsOpen)
                    {
                        AbilityPrompt = SZInput.Held(SZKey.Q) ? "Holding the door shut..." : "[Hold Q] Hold the door shut";
                        if (SZInput.Held(SZKey.Q) && Time.time >= _nextHold)
                        {
                            _nextHold = Time.time + 0.25f;
                            SZWorld.Instance.HoldDoor(door);
                        }
                    }
                    break;
                case SZCharacter.Walter:
                    var light = BrokenLightInView();
                    if (light == null)
                    {
                        AbilityProgress = 0f;
                        break;
                    }
                    AbilityPrompt = "[Hold Q] Repair the light";
                    if (SZInput.Held(SZKey.Q))
                    {
                        AbilityProgress += Time.deltaTime / 2f;
                        if (AbilityProgress >= 1f)
                        {
                            AbilityProgress = 0f;
                            SZWorld.Instance.RepairLight(light);
                            SZGame.Instance.Say("Fixed. That light will stay on now.", 2f);
                        }
                    }
                    else
                    {
                        AbilityProgress = 0f;
                    }
                    break;
            }
        }

        SZFlicker BrokenLightInView()
        {
            SZFlicker best = null;
            float bestAngle = 25f;
            foreach (var f in SZWorld.Instance.GetComponentsInChildren<SZFlicker>())
            {
                if (f.Repaired) continue;
                var to = f.transform.position - Camera.transform.position;
                if (to.magnitude > 5f) continue;
                float angle = Vector3.Angle(Camera.transform.forward, to);
                if (angle < bestAngle)
                {
                    bestAngle = angle;
                    best = f;
                }
            }
            return best;
        }

        // ---------------------------------------------------------------- caught

        public void OnCaught()
        {
            SZPostEffect.Damage = 1f;
            SZPostEffect.Flash = 0.6f;
            SZAudio.Play2D("neck_crack", 0.9f);
            _safeUntil = Time.time + 4f;  // he leaves you alone for a moment
            if (Inventory.Medkits > 0)
            {
                Inventory.Medkits--;
                SZGame.Instance.Say("The Long Man grabbed you... you fought free and patched yourself up. RUN!", 4f);
                return;
            }
            SZGame.Instance.Say("The Long Man caught you. Back to the last checkpoint.", 4f);
            Respawn();
        }

        public void Respawn()
        {
            var spawn = SZWorld.Instance.SpawnPoint(SZNet.MyId);
            _body.enabled = false;  // CharacterController ignores teleports unless it's off
            transform.SetPositionAndRotation(spawn.position + Vector3.up * 0.1f, Quaternion.Euler(0f, spawn.rotation.eulerAngles.y, 0f));
            _body.enabled = true;
            _verticalSpeed = 0f;
        }

        // ---------------------------------------------------------------- network

        // "S|id|x|y|z|yaw|pitch|flags|character|name"
        public string StateMessage()
        {
            int flags = (_crouching ? 1 : 0) | (Flashlight.enabled ? 2 : 0) | (_moving ? 4 : 0) | (_sprinting ? 8 : 0);
            var p = transform.position;
            return SZNet.Msg("S", SZNet.MyId, p.x, p.y, p.z, transform.eulerAngles.y, _pitch, flags, (int)Character, PlayerName);
        }
    }
}
