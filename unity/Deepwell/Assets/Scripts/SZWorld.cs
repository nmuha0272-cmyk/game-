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
        public SZPuzzles Puzzles { get; private set; }
        public readonly List<SZLocker> Lockers = new List<SZLocker>();
        readonly HashSet<string> _heard = new HashSet<string>();  // story entries the team has read or heard
        public SZPlayer Local { get; private set; }
        public int TeamCheckpoint { get; private set; }  // 0 = the start
        public string Chapter { get; private set; }
        public string SaveToken;   // which save this game came from (or was last saved as)

        // Items on the floor by number: the level's own (0, 1, 2...) and dropped ones (big numbers).
        readonly Dictionary<int, SZPickup> _items = new Dictionary<int, SZPickup>();
        readonly HashSet<int> _gone = new HashSet<int>();
        int _levelItems, _dropCount;
        bool[] _triggerFired = new bool[0];
        readonly List<SZFlicker> _brokenLights = new List<SZFlicker>();
        readonly Dictionary<int, SZRemotePlayer> _remotes = new Dictionary<int, SZRemotePlayer>();
        float _nextState, _nextSummary;
        SZTrunkScene _trunk;
        bool _gotSummary;

        public struct PlayerView
        {
            public int id;
            public bool alive;
            public Vector3 position;
            public bool crouching, flashlight, sprinting, moving;
            public bool hidden;   // in a locker: the Long Man can't see or hear them
            public SZCharacter character;
        }

        // load: start from a save (no intro). skipIntro: a friend's game reloading with the host.
        public static SZWorld Create(string chapter, SZCharacter character, string playerName, SZSaveData load = null, bool skipIntro = false)
        {
            var go = new GameObject("Chapter");
            var world = go.AddComponent<SZWorld>();
            Instance = world;
            world.Build(chapter, character, playerName, load, skipIntro || load != null);
            return world;
        }

        void Build(string chapter, SZCharacter character, string playerName, SZSaveData load, bool skipIntro)
        {
            Chapter = chapter;
            Data = SZLevelBuilder.Build(chapter, transform);
            if (Data == null) return;
            Physics.SyncTransforms();  // make sure the new floors are solid before anyone stands on them
            BakeNavigation();

            var root = Group("Doors");
            for (int i = 0; i < Data.doors.Length; i++) Doors.Add(SZDoor.Create(Data.doors[i], i, root));

            root = Group("Items");
            var items = Data.items ?? new ItemData[0];
            _levelItems = items.Length;
            for (int i = 0; i < items.Length; i++) _items[i] = SZPickup.Create(items[i], i, root);

            root = Group("Lore");
            foreach (var l in Data.lore ?? new LoreData[0]) SZLore.Create(l, root);

            Puzzles = SZPuzzles.Create(Data, transform);
            root = Group("Lockers");
            var lockers = Data.lockers ?? new SpawnData[0];
            for (int i = 0; i < lockers.Length; i++) Lockers.Add(SZLocker.Create(lockers[i], i, root));
            _triggerFired = new bool[Data.triggers != null ? Data.triggers.Length : 0];
            foreach (var flicker in GetComponentsInChildren<SZFlicker>()) _brokenLights.Add(flicker);
            if (Data.monster != null && Data.monster.p != null && Data.monster.p.Length == 3)
                Monster = SZMonster.Create(Data.monster, transform);

            var spawn = SpawnPoint(SZNet.MyId);
            Local = SZPlayer.Spawn(spawn.position, spawn.rotation, character, playerName);
            Local.transform.SetParent(transform);

            // The chapter intro (camera over the station with captions), then Eli and
            // Cole at the trunk of the team's car, then the whole team talks.
            // (Not when loading a save: that's already happened.)
            if (Data.team_car != null && Data.team_car.p != null && Data.team_car.p.Length == 3)
                _trunk = SZTrunkScene.Create(Data.team_car, transform);
            if (skipIntro)
            {
                _trunk?.AlreadyOpen();
            }
            else
            {
                var intro = Data.cutscenes != null ? System.Array.Find(Data.cutscenes, c => c.play_on_start) : null;
                var opening = SZCutscene.Play(intro?.shots, Data.dialogue, Local.Camera, () => _trunk?.End());
                _trunk?.Attach(opening);
            }
            if (load != null) LoadSave(load);

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
            for (int i = 0; i < list.Count; i++)
            {
                var v = list[i];
                v.hidden = Lockers.Exists(l => l.Occupant == v.id);
                list[i] = v;
            }
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
                // "SUBJECT 7": the Long Man rises in his cell.
                var reveal = t.chase && Data.cutscenes != null ? System.Array.Find(Data.cutscenes, c => c.name == "Reveal") : null;
                if (reveal != null) SZCutscene.Play(reveal.shots, null, Local.Camera, () => SZGame.Instance.Say(t.message, 3f));
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
            if (!show) return;
            // The host (or you, playing solo) saves the game by itself at every checkpoint.
            bool saved = SZNet.IsAuthority && SZSave.SaveGame(this);
            SZGame.Instance.Say(saved ? "Checkpoint reached - game saved" : "Checkpoint reached", 2.5f);
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
            if (_gone.Contains(pickup.Index)) return;
            if (!by.Inventory.Add(pickup.Data))
            {
                SZGame.Instance.Say("Your inventory is full. Drop something (G) or find a pouch or backpack.", 2.5f);
                return;
            }
            SZGame.Instance.Say("Picked up: " + pickup.Data.name + (string.IsNullOrEmpty(pickup.Data.hint) ? "" : "\n" + pickup.Data.hint), 3f);
            SZAudio.Play2D("ping", 0.5f);
            RemoveItem(pickup.Index);
            SZNet.Instance?.SendAll(SZNet.Msg("GONE", pickup.Index));
        }

        void RemoveItem(int i)
        {
            if (!_gone.Add(i)) return;
            if (_items.TryGetValue(i, out var pickup) && pickup) Destroy(pickup.gameObject);
            _items.Remove(i);
        }

        // Something put down with G (or from the inventory screen): it appears for everyone.
        public void DropItem(ItemData item, Vector3 at)
        {
            int index = 100000 + SZNet.MyId * 10000 + _dropCount++;
            SpawnDropped(index, item.id, item.lore, at);
            SZNet.Instance?.SendAll(SZNet.Msg("DROP", index, item.id, item.lore ?? "", at.x, at.y, at.z));
        }

        void SpawnDropped(int index, string id, string lore, Vector3 at)
        {
            if (_gone.Contains(index) || _items.ContainsKey(index)) return;
            int mine = 100000 + SZNet.MyId * 10000;  // (so my next drop never reuses a loaded one's number)
            if (index >= mine && index < mine + 10000) _dropCount = Mathf.Max(_dropCount, index - mine + 1);
            // Name, hint and color from the level's copy of the same item.
            var known = Data.items != null ? System.Array.Find(Data.items, d => d.id == id) : null;
            var item = new ItemData
            {
                id = id, lore = lore, name = known?.name ?? id, hint = known?.hint ?? "",
                color = known?.color ?? new[] { 0.6f, 0.6f, 0.6f, 1f }, p = new[] { at.x, at.y, at.z },
            };
            if (Physics.Raycast(at + Vector3.up * 0.5f, Vector3.down, out var floor, 3f, ~0, QueryTriggerInteraction.Ignore))
                item.p = new[] { floor.point.x, floor.point.y, floor.point.z };
            _items[index] = SZPickup.Create(item, index, transform);
        }

        // The reel tape lore entry for a tape machine (or null).
        public LoreData LoreEntry(string id) =>
            Data.lore_book != null && !string.IsNullOrEmpty(id) ? System.Array.Find(Data.lore_book, e => e.id == id) : null;

        // ---------------------------------------------------------------- lockers

        // Getting into (or out of) a locker. The host decides; everyone is told.
        public void RequestLocker(SZLocker locker, bool enter)
        {
            if (SZNet.IsAuthority) HostLocker(locker.Index, enter, SZNet.MyId);
            else SZNet.Instance.SendToHost(SZNet.Msg("HIDE", locker.Index, enter));
        }

        void HostLocker(int index, bool enter, int by)
        {
            if (index < 0 || index >= Lockers.Count) return;
            var locker = Lockers[index];
            if (enter)
            {
                if (!locker.Empty || Lockers.Exists(l => l.Occupant == by)) return;
                SetLocker(locker, by);
                // Did the Long Man see you climb in? Then he's coming to drag you out.
                if (Monster) Monster.SawHide(locker, by);
            }
            else if (locker.Occupant == by)
            {
                SetLocker(locker, -1);
            }
        }

        // Host: someone is in (or out of) a locker now.
        public void SetLocker(SZLocker locker, int who)
        {
            locker.SetOccupant(who);
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("LOCKER", locker.Index, who));
        }

        // A keycard or a crowbar opened a locked door: it stays unlocked for everyone.
        public void UnlockDoor(SZDoor door)
        {
            door.Unlocked = true;
            SZNet.Instance?.SendAll(SZNet.Msg("UNLOCK", door.Index));
        }

        // The team read a note or heard a tape (some puzzles need that).
        public void HearLore(string id)
        {
            if (string.IsNullOrEmpty(id) || !_heard.Add(id)) return;
            SZNet.Instance?.SendAll(SZNet.Msg("HEARD", id));
        }

        public bool HasHeard(string id) => !string.IsNullOrEmpty(id) && _heard.Contains(id);

        // The end of Chapter 1: the elevator goes down... and the cable snaps.
        public void EndChapter()
        {
            if (SZNet.IsHost) SZNet.Instance.Broadcast("END");
            SZAudio.Play2D("elevator_hum", 0.8f);
            SZGame.Instance.ShowEnding();
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

        // A pistol shot: everyone hears it; the host checks if it hit the Long Man.
        public void Shoot(Vector3 from, Vector3 direction)
        {
            ShowShot(from);
            if (SZNet.IsAuthority) CheckShotHit(from, direction);
            if (SZNet.Online)
                SZNet.Instance.SendAll(SZNet.Msg("SHOT", from.x, from.y, from.z, direction.x, direction.y, direction.z));
        }

        void ShowShot(Vector3 at)
        {
            SZAudio.PlayClipAt(SZAudio.Gunshot(), at, 1f, 60f);
            var go = new GameObject("MuzzleFlash");
            go.transform.position = at;
            var light = go.AddComponent<Light>();
            light.type = LightType.Point;
            light.range = 8f;
            light.intensity = 5f;
            light.color = new Color(1f, 0.8f, 0.5f);
            Destroy(go, 0.06f);
        }

        void CheckShotHit(Vector3 from, Vector3 direction)
        {
            if (Monster == null) return;
            Monster.HearNoise(from, 35f);
            // The first wall (or door) in the way stops the bullet.
            float wall = Physics.Raycast(from, direction, out var solid, 40f, ~0, QueryTriggerInteraction.Ignore) ? solid.distance : 40f;
            foreach (var hit in Physics.RaycastAll(from, direction, wall, ~0, QueryTriggerInteraction.Collide))
            {
                if (hit.collider.GetComponentInParent<SZMonster>() != Monster) continue;
                Monster.Stun(2.5f);
                SZGame.Instance.Say("Hit! The Long Man staggers.", 2f);
                return;
            }
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

        // Host -> everyone, once a second: "WORLD|doors|items|triggers|lights|checkpoint|
        // puzzles|unlocked|heard|lockers|save token|dropped items".
        string Summary(bool forSave = false)
        {
            var doors = new StringBuilder();
            foreach (var d in Doors) doors.Append(d.IsOpen ? '1' : '0');
            var items = new StringBuilder();
            for (int i = 0; i < _levelItems; i++) items.Append(_gone.Contains(i) ? '1' : '0');
            var triggers = new StringBuilder();
            foreach (var t in _triggerFired) triggers.Append(t ? '1' : '0');
            var lights = new StringBuilder();
            foreach (var l in _brokenLights) lights.Append(l != null && l.Repaired ? '1' : '0');
            var unlocked = new StringBuilder();
            foreach (var d in Doors) unlocked.Append(d.Unlocked ? '1' : '0');
            var hiding = new StringBuilder();
            if (!forSave) foreach (var l in Lockers) hiding.Append(l.Occupant).Append(',');  // (a save starts with nobody hiding)
            var drops = new StringBuilder();
            foreach (var pair in _items)
            {
                if (pair.Key < _levelItems || pair.Value == null) continue;
                var d = pair.Value.Data;
                var at = pair.Value.transform.position;
                if (drops.Length > 0) drops.Append(';');
                drops.Append(pair.Key).Append('^').Append(d.id).Append('^').Append((d.lore ?? "").Replace('^', ' ').Replace(';', ' '))
                     .Append('^').Append(SZNet.Msg(at.x)).Append('^').Append(SZNet.Msg(at.y)).Append('^').Append(SZNet.Msg(at.z));
            }
            return SZNet.Msg("WORLD", doors, items, triggers, lights, TeamCheckpoint,
                Puzzles != null ? Puzzles.Summary() : "", unlocked, string.Join(",", _heard), hiding, SaveToken ?? "", drops);
        }

        public string SaveSummary() => Summary(true);

        // Starting from a save: put the chapter back the way it was, then you.
        void LoadSave(SZSaveData save)
        {
            SaveToken = save.token;
            ApplySummary(save.world.Split('|'));
            SZSave.Apply(save.me, Local);
            // If the Long Man was already awake, he still is.
            if (SZNet.IsAuthority && Monster && Data.triggers != null)
                for (int i = 0; i < _triggerFired.Length; i++)
                    if (_triggerFired[i] && Data.triggers[i].chase) { Monster.Wake(SZNet.MyId); break; }
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
            Puzzles?.ApplySummary(SZNet.T(m, 6));
            var unlocked = SZNet.T(m, 7);
            for (int i = 0; i < unlocked.Length && i < Doors.Count; i++) if (unlocked[i] == '1') Doors[i].Unlocked = true;
            foreach (var id in SZNet.T(m, 8).Split(',')) if (id.Length > 0) _heard.Add(id);
            var hiding = SZNet.T(m, 9).Split(',');
            for (int i = 0; i < hiding.Length && i < Lockers.Count; i++)
                if (int.TryParse(hiding[i], out var who)) Lockers[i].SetOccupant(who);
            SaveToken = SZNet.T(m, 10);
            foreach (var drop in SZNet.T(m, 11).Split(';'))
            {
                var f = drop.Split('^');
                if (f.Length < 6 || !int.TryParse(f[0], out var index)) continue;
                SpawnDropped(index, f[1], f[2].Length > 0 ? f[2] : null,
                    new Vector3(SZNet.F(f, 3), SZNet.F(f, 4), SZNet.F(f, 5)));
            }
            if (!_gotSummary)
            {
                // Joined late: start where the team is.
                _gotSummary = true;
                if (TeamCheckpoint > 0) Local.Respawn();
                // Coming back to a saved game: your own place and inventory from that save.
                if (!SZNet.IsAuthority) SZSave.Apply(SZSave.LoadMine(SaveToken), Local);
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
                case "PZA":
                case "PZS":
                    Puzzles?.OnMessage(from, m);
                    break;
                case "HIDE":
                    if (host) HostLocker(SZNet.I(m, 1), SZNet.I(m, 2) == 1, from);
                    break;
                case "LOCKER":
                    int lockerIndex = SZNet.I(m, 1);
                    if (!host && lockerIndex >= 0 && lockerIndex < Lockers.Count) Lockers[lockerIndex].SetOccupant(SZNet.I(m, 2));
                    break;
                case "END":
                    if (!host) EndChapter();
                    break;
                case "SAVE":
                    if (!host) SZSave.SaveMine(SZNet.T(m, 1), Local);
                    break;
                case "LOAD":
                    if (!host) SZGame.Instance.ReloadWithHost();
                    break;
                case "SAY":
                    if (!host) SZGame.Instance.Say(SZNet.T(m, 1), 4f);
                    break;
                case "UNLOCK":
                    int locked = SZNet.I(m, 1);
                    if (locked >= 0 && locked < Doors.Count) Doors[locked].Unlocked = true;
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "HEARD":
                    _heard.Add(SZNet.T(m, 1));
                    if (host) SZNet.Instance.Broadcast(string.Join("|", m), from);
                    break;
                case "DROP":
                    SpawnDropped(SZNet.I(m, 1), SZNet.T(m, 2), SZNet.T(m, 3), new Vector3(SZNet.F(m, 4), SZNet.F(m, 5), SZNet.F(m, 6)));
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
                case "SHOT":
                    var shotFrom = new Vector3(SZNet.F(m, 1), SZNet.F(m, 2), SZNet.F(m, 3));
                    ShowShot(shotFrom);
                    if (host)
                    {
                        CheckShotHit(shotFrom, new Vector3(SZNet.F(m, 4), SZNet.F(m, 5), SZNet.F(m, 6)));
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
