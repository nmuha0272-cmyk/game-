using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using UnityEngine;

// Saving the game: F5 quick save, F9 quick load, and a save by itself at
// every checkpoint. The menu's CONTINUE starts from the save.
//
// The save is a small text file: where everything in the chapter is (the same
// summary the host sends to friends every second: doors, items, puzzles, tapes
// heard...), where you're standing, your flashlight battery and your inventory.
// Online only the host saves; each friend's computer keeps their own place and
// inventory next to it (same "token"), so everyone comes back together.
namespace Deepwell
{
    public class SZSaveData
    {
        public string token, chapter = "chapter1", name, world, time;
        public SZCharacter character;
        public SZPlayerSave me;
    }

    // One player's own part: where they stand, battery, inventory.
    public class SZPlayerSave
    {
        public Vector3 position;
        public float yaw, battery = 1f;
        public int rows = SZInventory.StartRows, selected;
        public readonly List<string[]> items = new List<string[]>();  // id, name, hint, lore, count, clip, x, y, turned, hotkey, r, g, b
    }

    public static class SZSave
    {
        static string Folder => Application.persistentDataPath;
        static string GamePath => Path.Combine(Folder, "deepwell_save.txt");
        static string MinePath => Path.Combine(Folder, "deepwell_save_mine.txt");  // a friend's own part, online
        static readonly CultureInfo Num = CultureInfo.InvariantCulture;

        public static bool Exists => File.Exists(GamePath);

        // ---------------------------------------------------------------- writing

        // The whole game (solo, or the host). Returns false if it couldn't.
        public static bool SaveGame(SZWorld world)
        {
            if (world == null || world.Local == null) return false;
            world.SaveToken = System.Guid.NewGuid().ToString("N").Substring(0, 12);
            var sb = new StringBuilder();
            sb.Append("version=1\n");
            sb.Append("token=").Append(world.SaveToken).Append('\n');
            sb.Append("chapter=").Append(world.Chapter).Append('\n');
            sb.Append("character=").Append((int)world.Local.Character).Append('\n');
            sb.Append("name=").Append(Clean(world.Local.PlayerName)).Append('\n');
            sb.Append("time=").Append(System.DateTime.Now.ToString("MMM d, h:mm tt", Num)).Append('\n');
            sb.Append("world=").Append(world.SaveSummary()).Append('\n');
            WritePlayer(sb, world.Local);
            if (!Write(GamePath, sb.ToString())) return false;
            // Friends save their own part with the same token.
            if (SZNet.IsHost) SZNet.Instance.Broadcast(SZNet.Msg("SAVE", world.SaveToken));
            return true;
        }

        // A friend's own part (when the host saves).
        public static void SaveMine(string token, SZPlayer me)
        {
            if (me == null) return;
            var sb = new StringBuilder();
            sb.Append("token=").Append(token).Append('\n');
            WritePlayer(sb, me);
            Write(MinePath, sb.ToString());
        }

        static void WritePlayer(StringBuilder sb, SZPlayer p)
        {
            var at = p.transform.position;
            sb.Append("pos=").Append(F(at.x)).Append(',').Append(F(at.y)).Append(',').Append(F(at.z))
              .Append(',').Append(F(p.transform.eulerAngles.y)).Append('\n');
            sb.Append("battery=").Append(F(p.Battery)).Append('\n');
            var inv = p.Inventory;
            sb.Append("rows=").Append(inv.Rows).Append('\n');
            sb.Append("selected=").Append(inv.Selected).Append('\n');
            foreach (var it in inv.Items)
            {
                var c = it.data.color != null && it.data.color.Length >= 3 ? it.data.color : new[] { 0.6f, 0.6f, 0.6f };
                sb.Append("item=").Append(string.Join("\t", new[]
                {
                    it.data.id, Clean(it.data.name), Clean(it.data.hint), Clean(it.data.lore),
                    it.count.ToString(Num), it.clip.ToString(Num), it.x.ToString(Num), it.y.ToString(Num),
                    it.turned ? "1" : "0", System.Array.IndexOf(inv.Hotkeys, it).ToString(Num),
                    F(c[0]), F(c[1]), F(c[2]),
                })).Append('\n');
            }
        }

        static bool Write(string path, string text)
        {
            try
            {
                File.WriteAllText(path + ".tmp", text);
                if (File.Exists(path)) File.Delete(path);
                File.Move(path + ".tmp", path);
                return true;
            }
            catch (System.Exception e)
            {
                Debug.LogWarning("Deepwell: couldn't save (" + e.Message + ")");
                return false;
            }
        }

        static string F(float v) => v.ToString("0.###", Num);
        static string Clean(string s) => (s ?? "").Replace('\n', ' ').Replace('\t', ' ');

        // ---------------------------------------------------------------- reading

        public static SZSaveData LoadGame()
        {
            var lines = Read(GamePath);
            if (lines == null) return null;
            var save = new SZSaveData { me = new SZPlayerSave() };
            foreach (var line in lines)
            {
                string key = line.Key, value = line.Value;
                switch (key)
                {
                    case "token": save.token = value; break;
                    case "chapter": save.chapter = value; break;
                    case "character": save.character = (SZCharacter)Mathf.Clamp(Int(value), 0, 3); break;
                    case "name": save.name = value; break;
                    case "time": save.time = value; break;
                    case "world": save.world = value; break;
                    default: ReadPlayer(save.me, key, value); break;
                }
            }
            return save.world != null ? save : null;
        }

        // A friend's own part, if it belongs to this save.
        public static SZPlayerSave LoadMine(string token)
        {
            var lines = Read(MinePath);
            if (lines == null || string.IsNullOrEmpty(token)) return null;
            var me = new SZPlayerSave();
            bool match = false;
            foreach (var line in lines)
            {
                string key = line.Key, value = line.Value;
                if (key == "token") match = value == token;
                else ReadPlayer(me, key, value);
            }
            return match ? me : null;
        }

        static void ReadPlayer(SZPlayerSave me, string key, string value)
        {
            switch (key)
            {
                case "pos":
                    var p = value.Split(',');
                    if (p.Length >= 4) { me.position = new Vector3(Flt(p[0]), Flt(p[1]), Flt(p[2])); me.yaw = Flt(p[3]); }
                    break;
                case "battery": me.battery = Flt(value); break;
                case "rows": me.rows = Int(value); break;
                case "selected": me.selected = Int(value); break;
                case "item":
                    var f = value.Split('\t');
                    if (f.Length >= 13) me.items.Add(f);
                    break;
            }
        }

        static List<KeyValuePair<string, string>> Read(string path)
        {
            try
            {
                if (!File.Exists(path)) return null;
                var list = new List<KeyValuePair<string, string>>();
                foreach (var line in File.ReadAllLines(path))
                {
                    int eq = line.IndexOf('=');
                    if (eq > 0) list.Add(new KeyValuePair<string, string>(line.Substring(0, eq), line.Substring(eq + 1)));
                }
                return list;
            }
            catch (System.Exception e)
            {
                Debug.LogWarning("Deepwell: couldn't read the save (" + e.Message + ")");
                return null;
            }
        }

        static int Int(string s) => int.TryParse(s, NumberStyles.Integer, Num, out var v) ? v : 0;
        static float Flt(string s) => float.TryParse(s, NumberStyles.Float, Num, out var v) ? v : 0f;

        // ---------------------------------------------------------------- putting it back

        // Your place, battery and inventory (after the chapter is built).
        public static void Apply(SZPlayerSave me, SZPlayer player)
        {
            if (me == null || player == null) return;
            var inv = player.Inventory;
            inv.Restore(me.rows, me.selected);
            foreach (var f in me.items)
            {
                var data = new ItemData
                {
                    id = f[0], name = f[1], hint = f[2], lore = f[3].Length > 0 ? f[3] : null,
                    color = new[] { Flt(f[10]), Flt(f[11]), Flt(f[12]), 1f },
                };
                inv.Put(data, Int(f[4]), Int(f[5]), Int(f[6]), Int(f[7]), f[8] == "1", Int(f[9]));
            }
            player.LoadState(me.position, me.yaw, me.battery);
        }
    }
}
