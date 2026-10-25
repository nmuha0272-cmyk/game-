using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.AI;

// One chapter while it's being played: the level, doors, items, notes, story
// triggers, checkpoints, the Long Man, and the other players. It also keeps
// everyone's game the same online: the host is the boss, and every second it
// sends a short summary (which doors are open, which items are gone...) so
// a lost message never matters for long.
namespace Deepwell
{
    public class SZWorld : MonoBehaviour
    {
        public static SZWorld Instance { get; private set; }

        public SZLevelData Data { get; private set; }
        public readonly List<SZDoor> Doors = new List<SZDoor>();
        public SZMonster Monster { get; private set; }
        public SZPlayer Local { get; private set; }
        public int TeamCheckpoint { get; private set; }  // 0 = the start

        readonly List<SZPickup> _items = new List<SZPickup>();
        bool[] _itemGone = new bool[0];
        bool[] _triggerFired = new bool[0];
        readonly List<SZFlicker> _brokenLights = new List<SZFlicker>();
        readonly Dictionary<int, SZRemotePlayer> _remotes = new Dictionary<int, SZRemotePlayer>();
        float _nextState, _nextSummary;
        bool _gotSummary;

        public struct PlayerView
        {
            public int id;
            public bool alive;
            public Vector3 position;
            public bool crouching, flashlight, sprinting, moving;
            public SZCharacter character;
        }

        public static SZWorld Create(string chapter, SZCharacter character, string playerName)
        {
            var go = new GameObject("Chapter");
            var world = go.AddComponent<SZWorld>();
            Instance = world;
            world.Build(chapter, character, playerName);
            return world;
        }

        void Build(string chapter, SZCharacter character, string playerName)
        {
            Data = SZLevelBuilder.Build(chapter, transform);
            if (Data == null) return;
            BakeNavigation();

            var root = Group("Doors");
            for (int i = 0; i < Data.doors.Length; i++) Doors.Add(SZDoor.Create(Data.doors[i], i, root));

            root = Group("Items");
            var items = Data.items ?? new ItemData[0];
            _itemGone = new bool[items.Length];
            for (int i = 0; i < items.Length; i++) _items.Add(SZPickup.Create(items[i], i, root));

            root = Group("Lore");
            foreach (var l in Data.lore ?? new LoreData[0]) SZLore.Create(l, root);

            _triggerFired = new bool[Data.triggers != null ? Data.triggers.Length : 0];
            foreach (var flicker in GetComponentsInChildren<SZFlicker>()) _brokenLights.Add(flicker);
            if (Data.monster != null && Data.monster.p != null && Data.monster.p.Length == 3)
                Monster = SZMonster.Create(Data.monster, transform);

            var spawn = SpawnPoint(SZNet.MyId);
            Local = SZPlayer.Spawn(spawn.position, spawn.rotation, character, playerName);
            Local.transform.SetParent(transform);

            var net = SZNet.Instance;
            if (net != null)
            {
                net.Received += OnMessage;
                net.PeerJoined += OnPeerJoined;
                net.PeerLeft += RemoveRemote;
            }
        }

        void OnDestroy()
        {
            var net = SZNet.Instance;
            if (net != null)
            {
                net.Received -= OnMessage;
                net.PeerJoined -= OnPeerJoined;
                net.PeerLeft -= RemoveRemote;
            }
            if (Instance == this) Instance = null;
            NavMesh.RemoveAllNavMeshData();
        }

        Transform Group(string name)
        {
            var g = new GameObject(name).transform;
            g.SetParent(transform);
            return g;
        }

        // The Long Man finds his way with a navigation mesh made from the level's colliders.
        void BakeNavigation()
        {
            if (!SZNet.IsAuthority) return;  // only the host moves him
            if (Data.monster == null || Data.monster.patrol == null || Data.monster.patrol.Length == 0) return;
            var bounds = new Bounds(SZLevelData.V(Data.monster.p), Vector3.one);
            foreach (var p in Data.monster.patrol) bounds.Encapsulate(SZLevelData.V(p.p));
            bounds.Expand(new Vector3(30f, 10f, 30f));
            var sources = new List<NavMeshBuildSource>();
            NavMeshBuilder.CollectSources(bounds, ~0, NavMeshCollectGeometry.PhysicsColliders, 0,
                new List<NavMeshBuildMarkup>(), sources);
            var settings = NavMesh.GetSettingsByID(0);
            settings.agentRadius = 0.4f;
            settings.agentHeight = 2.0f;
            settings.agentClimb = 0.45f;
            settings.agentSlope = 40f;
            settings.overrideVoxelSize = true;
            settings.voxelSize = 0.15f;  // a little coarser than normal, so it builds fast
            var data = NavMeshBuilder.BuildNavMeshData(settings, sources, bounds, Vector3.zero, Quaternion.identity);
            if (data != null) NavMesh.AddNavMeshData(data);
        }

        // ---------------------------------------------------------------- spawning

        public Pose SpawnPoint(int playerId)
        {
            if (TeamCheckpoint > 0 && Data.checkpoints != null)
            {
                foreach (var cp in Data.checkpoints)
                {
                    if (cp.order != TeamCheckpoint || cp.spawns == null || cp.spawns.Length == 0) continue;
                    var p = SZLevelData.V(cp.spawns[playerId % cp.spawns.Length].p);
                    return new Pose(p, SZLevelData.Q(cp.r));
                }
            }
            if (Data.spawns != null && Data.spawns.Length > 0)
            {
                var s = Data.spawns[playerId % Data.spawns.Length];
                return new Pose(SZLevelData.V(s.p), SZLevelData.Q(s.r));
            }
            return new Pose(new Vector3(0f, 1f, 45f), Quaternion.identity);
        }

        public string NameOf(int id)
        {
            if (id == SZNet.MyId && Local) return Local.PlayerName;
            return _remotes.TryGetValue(id, out var r) ? r.PlayerName : "Someone";
        }

        public List<PlayerView> PlayerViews()
        {
            var list = new List<PlayerView>();
            if (Local) list.Add(Local.View);
            foreach (var r in _remotes.Values) list.Add(r.View);
            return list;
        }

        public IEnumerable<SZRemotePlayer> Remotes => _remotes.Values;

        // ---------------------------------------------------------------- every frame

        void Update()
        {
            if (Local == null) return;
            CheckTriggers();
            CheckCheckpoints();

            var net = SZNet.Instance;
            if (net == null || !SZNet.Online) return;
            if (Time.time >= _nextState)
            {
                _nextState = Time.time + 1f / 15f;
                var msg = Local.StateMessage();
                if (SZNet.IsHost) net.Broadcast(msg);
                else net.SendToHost(msg);
            }
            if (SZNet.IsHost && Time.time >= _nextSummary)
            {
                _nextSummary = Time.time + 1f;
                net.Broadcast(Summary());
            }
        }

        void CheckTriggers()
        {
            if (Data.triggers == null) return;
            var at = Local.transform.position + Vector3.up;
            for (int i = 0; i < Data.triggers.Length; i++)
            {
                if (_triggerFired[i]) continue;
                var t = Data.triggers[i];
                if (!Inside(at, t.p, t.r, t.size)) continue;
                FireTrigger(i, SZNet.MyId, true);
                if (SZNet.IsClient) SZNet.Instance.SendToHost(SZNet.Msg("TRIG", i));
            }
        }

        void FireTrigger(int i, int by, bool show)
        {
            if (i < 0 || i >= _triggerFired.Length || _triggerFired[i]) return;
            _triggerFired[i] = true;
            var t = Data.triggers[i];
            if (show)
            {
                SZGame.Instance.Say(t.message, 5f);
                SZAudio.Play2D("stinger", 0.7f);
            }
            if (SZNet.IsAuthority)
            {
                if (t.chase && Monster) Monster.Wake(by);
                if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("TRIG", i), by);
            }
        }

        void CheckCheckpoints()
        {
            if (Data.checkpoints == null) return;
            var at = Local.transform.position + Vector3.up;
            foreach (var cp in Data.checkpoints)
            {
                if (cp.order <= TeamCheckpoint || !Inside(at, cp.p, cp.r, cp.size)) continue;
                ReachCheckpoint(cp.order, true);
                SZNet.Instance?.SendAll(SZNet.Msg("CP", cp.order));
            }
        }

        void ReachCheckpoint(int order, bool show)
        {
            if (order <= TeamCheckpoint) return;
            TeamCheckpoint = order;
            if (show) SZGame.Instance.Say("Checkpoint reached", 2.5f);
        }

        static bool Inside(Vector3 point, float[] p, float[] r, float[] size)
        {
            var local = Quaternion.Inverse(SZLevelData.Q(r)) * (point - SZLevelData.V(p));
            var half = size != null && size.Length == 3 ? new Vector3(size[0], size[1], size[2]) * 0.5f : Vector3.one;
            return Mathf.Abs(local.x) <= half.x && Mathf.Abs(local.y) <= half.y + 0.5f && Mathf.Abs(local.z) <= half.z;
        }

        // ---------------------------------------------------------------- actions

        public void RequestDoor(SZDoor door, bool open)
        {
            door.SetOpen(open);
            SZNet.Instance?.SendAll(SZNet.Msg("DOOR", door.Index, open));
        }

        public void RequestPickup(SZPickup pickup, SZPlayer by)
        {
            if (_itemGone[pickup.Index]) return;
            by.Inventory.Add(pickup.Data);
            SZGame.Instance.Say("Picked up: " + pickup.Data.name + (string.IsNullOrEmpty(pickup.Data.hint) ? "" : "\n" + pickup.Data.hint), 3f);
            SZAudio.Play2D("ping", 0.5f);
            if (!string.IsNullOrEmpty(pickup.Data.lore) && Data.lore_book != null)
            {
                // A reel tape: play what's on it.
                var entry = System.Array.Find(Data.lore_book, e => e.id == pickup.Data.lore);
                if (entry != null) SZGame.Instance.Read(entry.title, entry.text);
            }
            RemoveItem(pickup.Index);
            SZNet.Instance?.SendAll(SZNet.Msg("GONE", pickup.Index));
        }

        void RemoveItem(int i)
        {
            if (i < 0 || i >= _itemGone.Length || _itemGone[i]) return;
            _itemGone[i] = true;
            if (_items[i]) Destroy(_items[i].gameObject);
        }

        public void HoldDoor(SZDoor door)
        {
            door.HeldUntil = Time.time + 0.6f;
            if (SZNet.IsClient) SZNet.Instance.SendToHost(SZNet.Msg("HOLD", door.Index));
        }

        public void ThrowFlare(Vector3 from, Vector3 velocity)
        {
            SZFlare.Throw(from, velocity);
            SZNet.Instance?.SendAll(SZNet.Msg("FLARE", from.x, from.y, from.z, velocity.x, velocity.y, velocity.z));
        }

        // Nora's flash: everyone sees it; the host checks if it stunned the Long Man.
        public void CameraFlash(Vector3 from, Vector3 forward)
        {
            ShowFlash(from);
            if (SZNet.IsAuthority) CheckFlashStun(from, forward);
            if (SZNet.Online)
                SZNet.Instance.SendAll(SZNet.Msg("FLASH", from.x, from.y, from.z, forward.x, forward.y, forward.z));
        }

        void ShowFlash(Vector3 at)
        {
            SZAudio.PlayAt("camera_flash", at, 1f, 25f);
            var go = new GameObject("CameraFlash");
            go.transform.position = at;
            var light = go.AddComponent<Light>();
            light.type = LightType.Point;
            light.range = 18f;
            light.intensity = 8f;
            light.color = new Color(0.9f, 0.95f, 1f);
            Destroy(go, 0.12f);
        }

        void CheckFlashStun(Vector3 from, Vector3 forward)
        {
            if (Monster == null) return;
            var to = Monster.Eyes - Vector3.up * 0.8f - from;
            if (to.magnitude > 12f || Vector3.Angle(forward, to) > 35f) return;
            if (Physics.Linecast(from, Monster.Eyes - Vector3.up * 0.8f, out var hit, ~0, QueryTriggerInteraction.Ignore)
                && hit.collider.GetComponentInParent<SZPlayer>() == null) return;
            Monster.Stun(4.5f);
            SZGame.Instance.Say("The Long Man is stunned! RUN!", 2.5f);
        }

        // Walter fixes a flickering light.
        public void RepairLight(SZFlicker light)
        {
            int i = _brokenLights.IndexOf(light);
            if (i < 0) return;
            FixLight(i);
            SZNet.Instance?.SendAll(SZNet.Msg("FIX", i));
        }

        void FixLight(int i)
        {
            if (i < 0 || i >= _brokenLights.Count || _brokenLights[i] == null) return;
            _brokenLights[i].Repair();
        }

        // The host says the Long Man caught someone.
        public void Caught(int id)
        {
            OnCaught(id);
            if (SZNet.IsHost)
                for (int k = 0; k < 3; k++) SZNet.Instance.Broadcast(SZNet.Msg("CAUGHT", id));  // said 3 times, in case one gets lost
        }

        float _lastCaught = -10f;

        void OnCaught(int id)
        {
            if (id == SZNet.MyId)
            {
                if (Time.time - _lastCaught < 3f) return;
                _lastCaught = Time.time;
                Local.OnCaught();
            }
            else
            {
                SZGame.Instance.Say(NameOf(id) + " was caught by the Long Man!", 3f);
            }
        }

        // ---------------------------------------------------------------- network

        void OnPeerJoined(int id)
        {
            SZNet.Instance.SendTo(id, Summary());
        }

        void RemoveRemote(int id)
        {
            if (_remotes.TryGetValue(id, out var r))
            {
                SZGame.Instance.Say(r.PlayerName + " left the game.", 3f);
                Destroy(r.gameObject);
                _remotes.Remove(id);
            }
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("LEFT", id));
        }

        // Host -> everyone, once a second: "WORLD|doors|items|triggers|lights|checkpoint".
        string Summary()
        {
            var doors = new StringBuilder();
            foreach (var d in Doors) doors.Append(d.IsOpen ? '1' : '0');
            var items = new StringBuilder();
            foreach (var g in _itemGone) items.Append(g ? '1' : '0');
            var triggers = new StringBuilder();
            foreach (var t in _triggerFired) triggers.Append(t ? '1' : '0');
            var lights = new StringBuilder();
            foreach (var l in _brokenLights) lights.Append(l != null && l.Repaired ? '1' : '0');
            return SZNet.Msg("WORLD", doors, items, triggers, lights, TeamCheckpoint);
        }

        void ApplySummary(string[] m)
        {
            var doors = SZNet.T(m, 1);
            for (int i = 0; i < doors.Length && i < Doors.Count; i++) Doors[i].SetOpen(doors[i] == '1');
            var items = SZNet.T(m, 2);
            for (int i = 0; i < items.Length; i++) if (items[i] == '1') RemoveItem(i);
            var triggers = SZNet.T(m, 3);
            for (int i = 0; i < triggers.Length && i < _triggerFired.Length; i++) if (triggers[i] == '1') _triggerFired[i] = true;
            var lights = SZNet.T(m, 4);
            for (int i = 0; i < lights.Length; i++) if (lights[i] == '1') FixLight(i);
            ReachCheckpoint(SZNet.I(m, 5), false);
            if (!_gotSummary)
            {
                // Joined late: start where the team is.
                _gotSummary = true;
                if (TeamCheckpoint > 0) Local.Respawn();
            }
        }

        void OnMessage(int from, string[] m)
        {
            bool host = SZNet.IsHost;
            switch (m[0])
            {
                case "S":
                    // Host: a client's state (the host fills in who it is) -> pass it on.
                    if (host)
                    {
                        m[1] = from.ToString();
                        SZNet.Instance.Broadcast(string.Join("|", m), from);
                    }
                    int id = SZNet.I(m, 1);
                    if (id == SZNet.MyId) break;
                    if (!_remotes.TryGetValue(id, out var remote))
                    {
                        remote = SZRemotePlayer.Create(id, (SZCharacter)Mathf.Clamp(SZNet.I(m, 8), 0, 3), SZNet.T(m, 9), transform);
                        _remotes[id] = remote;
                        SZGame.Instance.Say(remote.PlayerName + " joined.", 3f);
                    }
                    remote.NetUpdate(m);
                    break;
                case "DOOR":
                    int door = SZNet.I(m, 1);
                    if (door >= 0 && door < Doors.Count) Doors[door].SetOpen(SZNet.I(m, 2) == 1);
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "GONE":
                    RemoveItem(SZNet.I(m, 1));
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "TRIG":
                    FireTrigger(SZNet.I(m, 1), from, true);
                    break;
                case "CP":
                    ReachCheckpoint(SZNet.I(m, 1), true);
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "HOLD":
                    int held = SZNet.I(m, 1);
                    if (held >= 0 && held < Doors.Count) Doors[held].HeldUntil = Time.time + 0.6f;
                    break;
                case "FLARE":
                    SZFlare.Throw(new Vector3(SZNet.F(m, 1), SZNet.F(m, 2), SZNet.F(m, 3)),
                        new Vector3(SZNet.F(m, 4), SZNet.F(m, 5), SZNet.F(m, 6)));
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "FLASH":
                    var at = new Vector3(SZNet.F(m, 1), SZNet.F(m, 2), SZNet.F(m, 3));
                    ShowFlash(at);
                    if (host)
                    {
                        CheckFlashStun(at, new Vector3(SZNet.F(m, 4), SZNet.F(m, 5), SZNet.F(m, 6)));
                        SZNet.Instance.Broadcast(string.Join("|", m), from);
                    }
                    break;
                case "FIX":
                    FixLight(SZNet.I(m, 1));
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "MON":
                    if (Monster)
                        Monster.NetUpdate(new Vector3(SZNet.F(m, 1), SZNet.F(m, 2), SZNet.F(m, 3)), SZNet.F(m, 4),
                            (SZMonster.State)SZNet.I(m, 5));
                    break;
                case "CAUGHT":
                    if (!host) OnCaught(SZNet.I(m, 1));
                    break;
                case "LEFT":
                    if (!host) RemoveRemote(SZNet.I(m, 1));
                    break;
                case "WORLD":
                    if (!host) ApplySummary(m);
                    break;
            }
        }
    }
}
