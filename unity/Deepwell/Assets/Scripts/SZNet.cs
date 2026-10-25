using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using UnityEngine;

// Online co-op for up to 4 players, with no extra packages. One player hosts
// (their game is the "boss": the monster, doors and items live there), the
// others join with the host's IP address. Messages are short text lines like
// "DOOR|Door3|1", sent over UDP on port 7777.
//
// Playing over the internet needs the host's port 7777 (UDP) forwarded on
// their router, or a free "virtual LAN" app (Radmin VPN, ZeroTier, Hamachi).
// On the same Wi-Fi it just works.
namespace Deepwell
{
    public class SZNet : MonoBehaviour
    {
        public const int Port = 7777;
        public const int MaxPlayers = 4;
        const float JoinTimeout = 10f;
        const float DropAfter = 8f;

        public static SZNet Instance { get; private set; }

        public static bool IsHost => Instance != null && Instance._mode == Mode.Host;
        public static bool IsClient => Instance != null && Instance._mode == Mode.Client;
        public static bool Online => IsHost || IsClient;
        // The host (or a solo game) decides what really happens.
        public static bool IsAuthority => !IsClient;
        // Host is player 0; clients get 1, 2, 3.
        public static int MyId => Instance != null ? Instance._myId : 0;

        // (player id, message parts). On the host, "from" is who sent it; on a client it's always 0 (the host).
        public event Action<int, string[]> Received;
        public event Action<int> PeerJoined;   // host only
        public event Action<int> PeerLeft;     // host only
        public event Action<int> Joined;       // client: the host said yes (your id)
        public event Action<string> Failed;    // client: couldn't join, or lost the host

        enum Mode { Off, Host, Joining, Client }
        Mode _mode = Mode.Off;
        UdpClient _udp;
        IPEndPoint _hostEndPoint;
        int _myId;
        float _joinStarted, _lastHello, _lastHeardHost;

        class Peer
        {
            public IPEndPoint endPoint;
            public float lastHeard;
        }
        readonly Dictionary<int, Peer> _peers = new Dictionary<int, Peer>();

        public static SZNet Ensure()
        {
            if (Instance == null)
            {
                var go = new GameObject("Network");
                DontDestroyOnLoad(go);
                Instance = go.AddComponent<SZNet>();
            }
            return Instance;
        }

        public bool Host(out string error)
        {
            Stop();
            try
            {
                _udp = new UdpClient(Port);
                IgnoreWindowsResets();
            }
            catch (Exception e)
            {
                error = "Couldn't host on port " + Port + ". Is another copy of the game already hosting? (" + e.Message + ")";
                return false;
            }
            _mode = Mode.Host;
            _myId = 0;
            error = null;
            return true;
        }

        public void Join(string address)
        {
            Stop();
            try
            {
                address = address.Trim();
                IPAddress ip;
                if (!IPAddress.TryParse(address, out ip))
                    ip = Array.Find(Dns.GetHostAddresses(address), a => a.AddressFamily == AddressFamily.InterNetwork);
                if (ip == null) throw new Exception("unknown address");
                _hostEndPoint = new IPEndPoint(ip, Port);
                _udp = new UdpClient(0);
                IgnoreWindowsResets();
            }
            catch (Exception e)
            {
                Failed?.Invoke("Couldn't find \"" + address + "\" (" + e.Message + ")");
                return;
            }
            _mode = Mode.Joining;
            _joinStarted = Time.unscaledTime;
            _lastHello = -1f;
        }

        public void Stop()
        {
            if (_udp != null)
            {
                if (_mode == Mode.Client) SendToHost("BYE");
                if (_mode == Mode.Host) Broadcast("BYE");
                _udp.Close();
            }
            _udp = null;
            _mode = Mode.Off;
            _myId = 0;
            _peers.Clear();
        }

        void OnDestroy() => Stop();
        void OnApplicationQuit() => Stop();

        public IEnumerable<int> PeerIds => _peers.Keys;

        // Your local IP address(es), to tell your friends.
        public static string LocalAddresses()
        {
            var list = new List<string>();
            try
            {
                foreach (var a in Dns.GetHostAddresses(Dns.GetHostName()))
                    if (a.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(a))
                        list.Add(a.ToString());
            }
            catch (Exception) { }
            return list.Count > 0 ? string.Join("  or  ", list) : "127.0.0.1";
        }

        // ---------------------------------------------------------------- sending

        public static string Msg(params object[] parts)
        {
            var sb = new StringBuilder();
            for (int i = 0; i < parts.Length; i++)
            {
                if (i > 0) sb.Append('|');
                var p = parts[i];
                if (p is float f) sb.Append(f.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture));
                else if (p is bool b) sb.Append(b ? '1' : '0');
                else sb.Append(Convert.ToString(p, System.Globalization.CultureInfo.InvariantCulture)?.Replace('|', '/'));
            }
            return sb.ToString();
        }

        public void SendToHost(string message)
        {
            if (_udp == null || _hostEndPoint == null) return;
            Send(message, _hostEndPoint);
        }

        public void SendTo(int id, string message)
        {
            if (_peers.TryGetValue(id, out var peer)) Send(message, peer.endPoint);
        }

        public void Broadcast(string message, int except = -1)
        {
            foreach (var pair in _peers)
                if (pair.Key != except) Send(message, pair.Value.endPoint);
        }

        // Host: to everyone. Client: to the host (who passes it on).
        public void SendAll(string message)
        {
            if (IsHost) Broadcast(message);
            else if (IsClient) SendToHost(message);
        }

        void Send(string message, IPEndPoint to)
        {
            try
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                _udp.Send(bytes, bytes.Length, to);
            }
            catch (Exception) { }  // a lost message is fine; the next update fixes it
        }

        // ---------------------------------------------------------------- receiving

        void Update()
        {
            if (_udp == null) return;
            float now = Time.unscaledTime;

            if (_mode == Mode.Joining)
            {
                if (now - _joinStarted > JoinTimeout)
                {
                    var host = _hostEndPoint.Address.ToString();
                    Stop();
                    Failed?.Invoke("No answer from " + host + ". Check the IP, and that the host pressed HOST first.");
                    return;
                }
                if (now - _lastHello > 0.5f)
                {
                    _lastHello = now;
                    SendToHost("HELLO");
                }
            }

            int guard = 0;
            while (_udp != null && guard++ < 500)
            {
                IPEndPoint from = null;
                byte[] bytes;
                try
                {
                    if (_udp.Available <= 0) break;
                    bytes = _udp.Receive(ref from);
                }
                catch (Exception)
                {
                    continue;  // Windows reports "connection reset" for UDP; ignore it
                }
                var parts = Encoding.UTF8.GetString(bytes).Split('|');
                if (_mode == Mode.Host) FromClient(from, parts, now);
                else FromHost(from, parts, now);
            }

            if (_mode == Mode.Host)
            {
                var gone = new List<int>();
                foreach (var pair in _peers)
                    if (now - pair.Value.lastHeard > DropAfter) gone.Add(pair.Key);
                foreach (var id in gone) DropPeer(id);
            }
            else if (_mode == Mode.Client && now - _lastHeardHost > DropAfter)
            {
                Stop();
                Failed?.Invoke("Lost the connection to the host.");
            }
        }

        void FromClient(IPEndPoint from, string[] parts, float now)
        {
            int id = -1;
            foreach (var pair in _peers)
                if (pair.Value.endPoint.Equals(from)) id = pair.Key;

            if (parts[0] == "HELLO")
            {
                if (id < 0)
                {
                    for (int i = 1; i < MaxPlayers && id < 0; i++)
                        if (!_peers.ContainsKey(i)) id = i;
                    if (id < 0)
                    {
                        Send("FULL", from);
                        return;
                    }
                    _peers[id] = new Peer { endPoint = from, lastHeard = now };
                    Send("WELCOME|" + id, from);
                    PeerJoined?.Invoke(id);
                }
                else
                {
                    Send("WELCOME|" + id, from);
                }
                return;
            }
            if (id < 0) return;  // someone we don't know
            _peers[id].lastHeard = now;
            if (parts[0] == "BYE")
            {
                DropPeer(id);
                return;
            }
            Received?.Invoke(id, parts);
        }

        void FromHost(IPEndPoint from, string[] parts, float now)
        {
            if (!from.Address.Equals(_hostEndPoint.Address)) return;
            _lastHeardHost = now;
            if (parts[0] == "WELCOME" && parts.Length > 1)
            {
                if (_mode == Mode.Joining)
                {
                    _mode = Mode.Client;
                    int.TryParse(parts[1], out _myId);
                    Joined?.Invoke(_myId);
                }
                return;
            }
            if (parts[0] == "FULL" && _mode == Mode.Joining)
            {
                Stop();
                Failed?.Invoke("That game is full (4 players).");
                return;
            }
            if (parts[0] == "BYE")
            {
                Stop();
                Failed?.Invoke("The host left the game.");
                return;
            }
            if (_mode == Mode.Client) Received?.Invoke(0, parts);
        }

        void DropPeer(int id)
        {
            _peers.Remove(id);
            PeerLeft?.Invoke(id);
        }

        // Windows sends an error to the next Receive when a message bounces; switch that off.
        void IgnoreWindowsResets()
        {
            try
            {
                const int SIO_UDP_CONNRESET = -1744830452;
                _udp.Client.IOControl(SIO_UDP_CONNRESET, new byte[] { 0 }, null);
            }
            catch (Exception) { }  // not Windows
        }

        // ---------------------------------------------------------------- reading numbers

        public static float F(string[] parts, int i) =>
            i < parts.Length && float.TryParse(parts[i], System.Globalization.NumberStyles.Float,
                System.Globalization.CultureInfo.InvariantCulture, out var v) ? v : 0f;

        public static int I(string[] parts, int i) => i < parts.Length && int.TryParse(parts[i], out var v) ? v : 0;

        public static string T(string[] parts, int i) => i < parts.Length ? parts[i] : "";
    }
}
