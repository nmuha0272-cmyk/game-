using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

// The Long Man (Subject 7). He waits in his cell until someone walks into
// the "RUN!" trigger in the tunnels, then hunts. Same rules as Godot:
// - He walks his patrol route through the tunnels.
// - He SEES you if you're in front of him and nothing is in the way
//   (further if your flashlight is on, less far if you crouch).
// - He HEARS you running (Cole is louder). He goes to check the noise.
// - He chases you, opens doors (unless Cole holds them shut), and if he
//   catches you, you go back to the last checkpoint.
// - Nora's camera flash stuns him for a few seconds.
// Only the host runs his brain; everyone else just sees where he is.
namespace Deepwell
{
    public class SZMonster : MonoBehaviour
    {
        public enum State { Asleep, Patrol, Investigate, Chase, Search, Stunned, Leave }

        public State Mode { get; private set; } = State.Asleep;
        public Vector3 Eyes => transform.position + Vector3.up * 2.5f;

        const float SightAngle = 70f;
        const float SightLit = 24f, SightDark = 14f;
        const float LoseSightAfter = 4f, SearchFor = 7f;

        MonsterData _d;
        NavMeshAgent _agent;
        readonly List<Vector3> _patrol = new List<Vector3>();
        int _target = -1;            // player id being chased
        Vector3 _lastSeen, _goal;
        float _wakeAt;
        int _wakeTarget;
        float _stateTime, _sinceSeen, _nextThink, _nextSend, _blockedFor;
        GameObject _model;
        AudioSource _breath;
        Light _eyeGlow;

        // Clients: where the host says he is.
        Vector3 _netPos;
        float _netYaw;

        public static SZMonster Create(MonsterData d, Transform parent)
        {
            var go = new GameObject("LongMan");
            go.transform.SetParent(parent);
            go.transform.SetPositionAndRotation(SZLevelData.V(d.p), SZLevelData.Q(d.r));
            var m = go.AddComponent<SZMonster>();
            m._d = d;
            if (d.patrol != null)
                foreach (var p in d.patrol) m._patrol.Add(SZLevelData.V(p.p));
            m._netPos = go.transform.position;
            m._netYaw = go.transform.eulerAngles.y;
            m.Build();
            return m;
        }

        void Build()
        {
            _model = SZCharacters.LoadModel("long_man", transform, 2.9f) ?? StandIn();
            var eyes = new GameObject("EyeGlow");
            eyes.transform.SetParent(transform, false);
            eyes.transform.localPosition = new Vector3(0f, 2.6f, 0.3f);
            _eyeGlow = eyes.AddComponent<Light>();
            _eyeGlow.type = LightType.Point;
            _eyeGlow.color = new Color(1f, 0.15f, 0.1f);
            _eyeGlow.range = 2.5f;
            _eyeGlow.intensity = 1.2f;
            _breath = SZAudio.Attach(gameObject, "monster_breath", 0.8f, 16f, loop: true);
            // Something for bullets to hit (a trigger, so it doesn't block anyone).
            var body = gameObject.AddComponent<CapsuleCollider>();
            body.isTrigger = true;
            body.radius = 0.45f;
            body.height = 2.9f;
            body.center = new Vector3(0f, 1.45f, 0f);

            if (!SZNet.IsAuthority) return;
            if (NavMesh.SamplePosition(transform.position, out var hit, 4f, NavMesh.AllAreas))
            {
                transform.position = hit.position;
                _agent = gameObject.AddComponent<NavMeshAgent>();
                _agent.radius = 0.4f;
                _agent.height = 2.8f;
                _agent.acceleration = 14f;
                _agent.angularSpeed = 360f;
                _agent.stoppingDistance = 0.3f;
                _agent.autoBraking = true;
                _agent.isStopped = true;
            }
            else
            {
                Debug.LogWarning("Deepwell: the Long Man isn't on the navigation mesh, so he walks in straight lines.");
            }
        }

        GameObject StandIn()
        {
            // A very tall, thin, pale figure with long arms.
            var root = new GameObject("Model");
            root.transform.SetParent(transform, false);
            var skin = SZGraphics.Lit(new Color(0.55f, 0.52f, 0.48f), 0.35f);
            var gown = SZGraphics.Lit(new Color(0.18f, 0.2f, 0.2f), 0.1f);
            Limb(root, PrimitiveType.Capsule, new Vector3(0f, 1.75f, 0f), new Vector3(0.45f, 0.75f, 0.3f), gown, 0f);
            Limb(root, PrimitiveType.Capsule, new Vector3(-0.13f, 0.55f, 0f), new Vector3(0.14f, 0.6f, 0.14f), skin, 0f);
            Limb(root, PrimitiveType.Capsule, new Vector3(0.13f, 0.55f, 0f), new Vector3(0.14f, 0.6f, 0.14f), skin, 0f);
            Limb(root, PrimitiveType.Capsule, new Vector3(-0.32f, 1.55f, 0.05f), new Vector3(0.09f, 0.85f, 0.09f), skin, 8f);
            Limb(root, PrimitiveType.Capsule, new Vector3(0.32f, 1.55f, 0.05f), new Vector3(0.09f, 0.85f, 0.09f), skin, -8f);
            Limb(root, PrimitiveType.Sphere, new Vector3(0f, 2.65f, 0.05f), new Vector3(0.26f, 0.34f, 0.26f), skin, 0f);
            var eye = SZGraphics.Lit(Color.black, 0.9f, new Color(3f, 0.3f, 0.2f));
            Limb(root, PrimitiveType.Sphere, new Vector3(-0.06f, 2.7f, 0.15f), Vector3.one * 0.04f, eye, 0f);
            Limb(root, PrimitiveType.Sphere, new Vector3(0.06f, 2.7f, 0.15f), Vector3.one * 0.04f, eye, 0f);
            return root;
        }

        static void Limb(GameObject root, PrimitiveType type, Vector3 at, Vector3 size, Material mat, float tilt)
        {
            var part = GameObject.CreatePrimitive(type);
            part.transform.SetParent(root.transform, false);
            part.transform.localPosition = at;
            part.transform.localScale = size;
            part.transform.localRotation = Quaternion.Euler(0f, 0f, tilt);
            part.GetComponent<Renderer>().sharedMaterial = mat;
            Destroy(part.GetComponent<Collider>());
        }

        // ---------------------------------------------------------------- what others call

        // The "RUN!" trigger: wake up and come for whoever set it off.
        public void Wake(int playerId)
        {
            // Wait for the reveal cutscene ("SUBJECT 7") to finish first.
            if (Mode != State.Asleep || _wakeAt > 0f) return;
            _wakeAt = Time.time + 3.5f;
            _wakeTarget = playerId;
        }

        void WakeNow(int playerId)
        {
            SZAudio.PlayAt("monster_shriek", Eyes, 1f, 45f);
            StartChase(playerId);
            _sinceSeen = -6f;  // he knows where you are for a few seconds
        }

        public void Stun(float seconds)
        {
            if (Mode == State.Asleep) return;
            SetState(State.Stunned);
            _stateTime = -seconds;
            SZAudio.PlayAt("monster_screech", Eyes, 1f, 30f);
        }

        // A loud noise (a gunshot): he comes to look, unless he's already busy.
        public void HearNoise(Vector3 where, float range)
        {
            if (Mode == State.Asleep || Mode == State.Chase || Mode == State.Stunned) return;
            if (Vector3.Distance(where, transform.position) > range) return;
            _goal = where;
            SetState(State.Investigate);
            SZAudio.PlayAt("monster_click", Eyes, 0.8f, 20f);
        }

        // Clients: the host's latest word on where he is.
        public void NetUpdate(Vector3 pos, float yaw, State state)
        {
            _netPos = pos;
            _netYaw = yaw;
            if (state != Mode)
            {
                if (state == State.Chase && Mode != State.Chase) SZAudio.PlayAt("monster_shriek", Eyes, 0.9f, 40f);
                Mode = state;
            }
        }

        // ---------------------------------------------------------------- brain (host only)

        void Update()
        {
            Animate();
            if (!SZNet.IsAuthority)
            {
                transform.position = Vector3.Lerp(transform.position, _netPos, Time.deltaTime * 10f);
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.Euler(0f, _netYaw, 0f), Time.deltaTime * 10f);
                return;
            }

            _stateTime += Time.deltaTime;
            if (Mode == State.Asleep)
            {
                if (_wakeAt > 0f && Time.time >= _wakeAt) WakeNow(_wakeTarget);
                else return;
            }
            if (Time.time >= _nextThink)
            {
                _nextThink = Time.time + 0.2f;
                Think();
            }
            if (_agent == null) MoveStraight();
            if (Time.time >= _nextSend && SZNet.IsHost)
            {
                _nextSend = Time.time + 0.1f;
                SZNet.Instance.Broadcast(SZNet.Msg("MON", transform.position.x, transform.position.y, transform.position.z,
                    transform.eulerAngles.y, (int)Mode));
            }
        }

        void Think()
        {
            var players = SZWorld.Instance.PlayerViews();
            if (Mode == State.Stunned)
            {
                Stop();
                if (_stateTime >= 0f) SetState(State.Search);
                return;
            }

            // Look and listen.
            int seen = -1;
            float best = float.MaxValue;
            foreach (var p in players)
            {
                if (!p.alive) continue;
                float dist = Vector3.Distance(transform.position, p.position);
                if (CanSee(p, dist) && dist < best)
                {
                    best = dist;
                    seen = p.id;
                }
                else if (Mode != State.Chase && Heard(p, dist))
                {
                    _goal = p.position;
                    if (Mode != State.Investigate) SZAudio.PlayAt("monster_click", Eyes, 0.8f, 20f);
                    SetState(State.Investigate);
                }
            }
            if (seen >= 0)
            {
                if (Mode != State.Chase) StartChase(seen);
                _target = seen;
                _sinceSeen = 0f;
            }
            else
            {
                _sinceSeen += 0.2f;
            }

            OpenDoorsInTheWay();

            switch (Mode)
            {
                case State.Chase:
                    var target = players.Find(p => p.id == _target);
                    if (target.alive)
                    {
                        if (_sinceSeen <= 0f) _lastSeen = target.position;
                        float dist = Vector3.Distance(transform.position, target.position);
                        if (dist <= _d.catch_distance + 0.35f && _sinceSeen <= 0.5f)
                        {
                            SZWorld.Instance.Caught(target.id);
                            _goal = FarthestPatrolPoint(target.position);
                            SetState(State.Leave);
                            return;
                        }
                    }
                    GoTo(_sinceSeen <= 0f && target.alive ? target.position : _lastSeen, _d.chase_speed);
                    if (_sinceSeen > LoseSightAfter)
                    {
                        _goal = _lastSeen;
                        SetState(State.Search);
                    }
                    break;
                case State.Investigate:
                    GoTo(_goal, _d.investigate_speed);
                    if (Arrived() || _stateTime > 15f) SetState(State.Search);
                    break;
                case State.Search:
                    // Look around the spot where he lost you.
                    if (Arrived())
                    {
                        var around = _goal + new Vector3(Random.Range(-5f, 5f), 0f, Random.Range(-5f, 5f));
                        GoTo(around, _d.investigate_speed);
                    }
                    if (_stateTime > SearchFor) SetState(State.Patrol);
                    break;
                case State.Leave:
                    GoTo(_goal, _d.patrol_speed * 1.5f);
                    if (_stateTime > _d.catch_cooldown) SetState(State.Patrol);
                    break;
                default:
                    if (_patrol.Count == 0) break;
                    if (_stateTime < 0.25f || Arrived())
                        _goal = _patrol[Random.Range(0, _patrol.Count)];
                    GoTo(_goal, _d.patrol_speed);
                    break;
            }
        }

        void StartChase(int playerId)
        {
            _target = playerId;
            var target = SZWorld.Instance.PlayerViews().Find(p => p.id == playerId);
            _lastSeen = target.alive ? target.position : transform.position;
            if (Mode != State.Chase) SZAudio.PlayAt("monster_shriek", Eyes, 0.9f, 40f);
            SetState(State.Chase);
        }

        bool CanSee(SZWorld.PlayerView p, float dist)
        {
            float range = p.flashlight ? SightLit : SightDark;
            if (p.crouching) range *= 0.6f;
            if (Mode == State.Chase) range *= 1.5f;  // once he's after you, he keeps you in sight
            if (dist > range) return false;
            var head = p.position + Vector3.up * (p.crouching ? 0.9f : 1.5f);
            var toPlayer = head - Eyes;
            if (dist > 2f && Vector3.Angle(transform.forward, toPlayer) > SightAngle) return false;
            if (Physics.Linecast(Eyes, head, out var hit, ~0, QueryTriggerInteraction.Ignore))
                return hit.collider.GetComponentInParent<SZPlayer>() != null;
            return true;
        }

        bool Heard(SZWorld.PlayerView p, float dist)
        {
            if (!p.moving || p.crouching) return false;
            float range = (p.sprinting ? 16f : 5f) * SZCharacters.NoiseMultiplier(p.character);
            return dist < range;
        }

        void OpenDoorsInTheWay()
        {
            var here = transform.position + Vector3.up * 1.5f;
            bool blocked = false;
            foreach (var door in SZWorld.Instance.Doors)
            {
                if (door.IsOpen || Vector3.Distance(door.Middle, here) > 2.2f) continue;
                if (door.IsHeld)
                {
                    blocked = true;
                    SZAudio.PlayAt("door_pound", door.Middle, 1f, 25f);
                }
                else
                {
                    SZWorld.Instance.RequestDoor(door, true);
                    SZAudio.PlayAt("door_pound", door.Middle, 0.8f, 25f);
                }
            }
            if (!blocked)
            {
                _blockedFor = 0f;
                return;
            }
            // Cole is holding the door: wait, pound on it, then give up.
            Stop();
            _blockedFor += 0.2f;
            if (_blockedFor > 3f)
            {
                _blockedFor = 0f;
                _goal = FarthestPatrolPoint(transform.position);
                SetState(State.Leave);
            }
        }

        Vector3 FarthestPatrolPoint(Vector3 from)
        {
            var best = transform.position;
            float far = -1f;
            foreach (var p in _patrol)
            {
                float d = Vector3.Distance(p, from);
                if (d > far && d < 60f)
                {
                    far = d;
                    best = p;
                }
            }
            return best;
        }

        void SetState(State s)
        {
            Mode = s;
            _stateTime = 0f;
        }

        void GoTo(Vector3 where, float speed)
        {
            if (_agent == null)
            {
                _goal = where;
                _straightSpeed = speed;
                return;
            }
            _agent.isStopped = false;
            _agent.speed = speed;
            if ((_agent.destination - where).sqrMagnitude > 0.25f) _agent.SetDestination(where);
        }

        void Stop()
        {
            if (_agent != null) _agent.isStopped = true;
            _straightSpeed = 0f;
        }

        bool Arrived()
        {
            if (_agent == null) return Vector3.Distance(transform.position, _goal) < 1f;
            return !_agent.pathPending && _agent.remainingDistance <= 1f;
        }

        float _straightSpeed;

        void MoveStraight()
        {
            var to = _goal - transform.position;
            to.y = 0f;
            if (to.magnitude < 0.2f || _straightSpeed <= 0f) return;
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(to), Time.deltaTime * 5f);
            transform.position += to.normalized * Mathf.Min(_straightSpeed * Time.deltaTime, to.magnitude);
        }

        // ---------------------------------------------------------------- looks

        Vector3 _lastPos;

        void Animate()
        {
            float speed = (transform.position - _lastPos).magnitude / Mathf.Max(Time.deltaTime, 0.0001f);
            _lastPos = transform.position;
            SZCharacters.PlayAnimation(_model, speed > 3f ? "run" : speed > 0.3f ? "walk" : "idle");
            if (_breath) _breath.volume = Mode == State.Chase ? 1f : 0.6f;
            if (_eyeGlow) _eyeGlow.intensity = Mode == State.Chase ? 2.2f + Mathf.Sin(Time.time * 20f) * 0.4f : 1.0f;
            if (Mode == State.Asleep && _breath && _breath.isPlaying) _breath.volume = 0.3f;
        }
    }
}
