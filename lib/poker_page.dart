import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'poker_socket.dart';

class PokerPage extends StatefulWidget {
  const PokerPage({super.key});

  @override
  State<PokerPage> createState() => _PokerPageState();
}

class _PokerPageState extends State<PokerPage> {
  // iOS sim: 127.0.0.1, Android emu: 10.0.2.2, gerçek cihaz: LAN IP
  final String base = 'http://127.0.0.1:3000';
  final String code = 'ABC123';

  String? participantId;
  String? storyId;

  bool _resetting = false;
  String? _jwt;
  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (_jwt != null) 'Authorization': 'Bearer $_jwt!',
  };

  @override
  void initState() {
    super.initState();

    PokerSocket.I.connect(hostBase: base);

    // 🔒 duplicate listener önleme: önce off, sonra on
    PokerSocket.I.off('joined');
    PokerSocket.I.on('joined', (data) async {
      final pid = (data['participant']?['id'] as String?) ?? '';
      final activeId = (data['session']?['activeStoryId'] as String?) ?? '';
      if (!mounted) return;
      setState(() {
        participantId = pid;
        if (activeId.isNotEmpty) storyId = activeId;
      });
      await _fetchToken(pid);
      debugPrint('joined => participantId: $participantId, activeStoryId: $storyId');
      if (pid.isNotEmpty) {
        await _fetchToken(pid); // 👈 burada token al
      }
    });

    PokerSocket.I.off('story:revealed');
    PokerSocket.I.on('story:revealed', (data) {
      debugPrint('revealed => ${jsonEncode(data)}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story revealed; konsol loglarına bak!')),
      );
    });

    PokerSocket.I.off('story:reset');
    PokerSocket.I.on('story:reset', (data) {
      debugPrint('story:reset => ${jsonEncode(data)}');
      if (!mounted) return;
      // ileride local selectedCard gibi alanlar varsa burada sıfırla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni tur başladı (oylar temizlendi)')),
      );
    });

    PokerSocket.I.off('reveal:accepted');
    PokerSocket.I.on('reveal:accepted', (data) {
      debugPrint('reveal:accepted => ${jsonEncode(data)}');
    });

    PokerSocket.I.off('error');
    PokerSocket.I.on('error', (e) {
      debugPrint('socket error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WS error: $e')),
      );
    });

    PokerSocket.I.off('session:activeChanged');
    PokerSocket.I.on('session:activeChanged', (data) {
      final newId = (data['storyId'] as String?) ?? '';
      if (!mounted) return;
      setState(() => storyId = newId.isNotEmpty ? newId : null);
      debugPrint('session:activeChanged => new active story: $storyId');
    });

    PokerSocket.I.join(code: code, name: 'Ekrem');
  }

  @override
  void dispose() {
    PokerSocket.I.disconnect();
    super.dispose();
  }

  Future<void> _fetchToken(String participantId) async {
    final resp = await http.post(
      Uri.parse('$base/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'participantId': participantId}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _jwt = data['token'] as String?;
      if (_jwt != null) {
        // WS handshake auth için yeniden bağlan
        PokerSocket.I.reconnectWithAuth(token: _jwt!);
      }
    } else {
      debugPrint('token error: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> _createStory() async {
    try {
      final resp = await http.post(
        Uri.parse('$base/stories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'title': 'Login story', 'order': 1}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        final createdId = data['id'] as String?;
        if (createdId != null && createdId.isNotEmpty) {
          if (!mounted) return;
          setState(() => storyId = createdId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Story created: $storyId')),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create story failed: HTTP ${resp.statusCode} ${resp.body}')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create story error: $err')),
      );
    }
  }

  Future<void> _fetchStoriesAndPickLast() async {
    try {
      final resp = await http.get(Uri.parse('$base/sessions/$code/stories'));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final last = list.last as Map<String, dynamic>;
          if (!mounted) return;
          setState(() => storyId = last['id'] as String);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Picked Story: $storyId')),
          );
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No stories yet / HTTP ${resp.statusCode}')),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetch stories error: $err')),
      );
    }
  }

  Future<void> _resetStory() async {
    if (storyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce story seç/oluştur')),
      );
      return;
    }
    if (_resetting) return;
    setState(() => _resetting = true);
    try {
      final resp = await http.post(Uri.parse('$base/stories/$storyId/reset'), headers: _headers());
      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story resetlendi (votes silindi, revealed=false)')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: HTTP ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset error: $err')),
      );
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _activeNext() async {
    final resp = await http.post(Uri.parse('$base/sessions/$code/active/next'), headers: _headers());
    debugPrint('active/next => ${resp.statusCode} ${resp.body}');
  }

  Future<void> _activePrev() async {
    final resp = await http.post(Uri.parse('$base/sessions/$code/active/prev'), headers: _headers());
    debugPrint('active/prev => ${resp.statusCode} ${resp.body}');
  }

  void _vote5() {
    if (participantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('joined bekleniyor')),
      );
      return;
    }
    // Gateway aktif story desteklediği için storyId olmadan da gönderebilirsin.
    PokerSocket.I.vote(
      code: code,
      storyId: storyId, // null bırakılırsa aktif story kullanılacak
      participantId: participantId!,
      value: '5',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vote 5 gönderildi')),
    );
  }

  void _reveal() {
    debugPrint('emit reveal (code=$code)');
    PokerSocket.I.reveal(code: code); // storyId göndermiyoruz (aktif kullanılacak)
  }

  @override
  Widget build(BuildContext context) {
    final connected = PokerSocket.I.isConnected;
    final hasParticipant = participantId != null && participantId!.isNotEmpty;
    final hasStory = storyId != null && storyId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Scrum Poker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WS connected: $connected'),
            Text('ParticipantId: ${participantId ?? "-"}'),
            Text('StoryId: ${storyId ?? "-"}'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(onPressed: _createStory, child: const Text('Create Story')),
                ElevatedButton(onPressed: _fetchStoriesAndPickLast, child: const Text('Pick Last Story')),
                ElevatedButton(onPressed: hasParticipant ? _vote5 : null, child: const Text('Vote 5')),
                ElevatedButton(onPressed: hasParticipant ? _reveal : null, child: const Text('Reveal')),
                ElevatedButton(onPressed: hasStory && !_resetting ? _resetStory : null, child: const Text('Reset Story')),
                ElevatedButton(onPressed: _activePrev, child: const Text('Prev Story')),
                ElevatedButton(onPressed: _activeNext, child: const Text('Next Story')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
