import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../services/sync_service.dart';
import '../../widgets/widgets.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _ipCtrl = TextEditingController();
  bool _connected = false;
  bool _syncing = false;
  String _status = 'Not connected';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    final ip = SyncService.instance.serverIp;
    if (ip != null) _ipCtrl.text = ip;
  }

  void _log(String msg) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} $msg');
      if (_logs.length > 20) _logs = _logs.sublist(0, 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('🔄 Sync with Desktop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ThemeManager.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ThemeManager.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How to Sync', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _step('1', 'On your PC, run: python sync_server.py'),
              _step('2', 'Make sure both devices are on the same WiFi'),
              _step('3', 'Enter the IP shown on the PC below'),
              _step('4', 'Tap Connect, then Sync'),
            ]),
          ),

          const SizedBox(height: 16),

          // Connection
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ipCtrl,
                decoration: InputDecoration(
                  hintText: 'Desktop IP (e.g. 192.168.1.5)',
                  prefixIcon: Icon(Icons.computer, color: ThemeManager.textSecondary),
                  suffixText: ':8765',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _syncing ? null : _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: _connected ? ThemeManager.success : ThemeManager.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text(_connected ? '✓ Connected' : 'Connect'),
            ),
          ]),

          const SizedBox(height: 8),
          // Status
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: _connected ? ThemeManager.success : ThemeManager.danger,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_status, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
          ]),

          const SizedBox(height: 20),

          // Sync buttons
          Row(children: [
            Expanded(child: _syncButton(
              icon: Icons.cloud_download_outlined,
              label: '↓ Pull from PC',
              subtitle: 'Get desktop data',
              onTap: _connected ? _pull : null,
            )),
            const SizedBox(width: 10),
            Expanded(child: _syncButton(
              icon: Icons.cloud_upload_outlined,
              label: '↑ Push to PC',
              subtitle: 'Send mobile data',
              onTap: _connected ? _push : null,
            )),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _syncButton(
              icon: Icons.sync,
              label: '🔄 Full Sync (Push + Pull)',
              subtitle: 'Bidirectional — recommended',
              onTap: _connected ? _fullSync : null,
            ),
          ),

          // Loading
          if (_syncing) ...[
            const SizedBox(height: 16),
            Center(child: CircularProgressIndicator(color: ThemeManager.primary)),
            const SizedBox(height: 8),
            Center(child: Text('Syncing…', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13))),
          ],

          // Sync log
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: '📋 Sync Log'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _logs.map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(log, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11, fontFamily: 'monospace')),
                )).toList(),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: ThemeManager.primary.withAlpha(40), shape: BoxShape.circle),
          child: Center(child: Text(num, style: TextStyle(color: ThemeManager.primary, fontSize: 11, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _syncButton({required IconData icon, required String label, required String subtitle, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onTap != null ? ThemeManager.card : ThemeManager.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onTap != null ? ThemeManager.primary.withAlpha(60) : ThemeManager.border),
        ),
        child: Column(children: [
          Icon(icon, color: onTap != null ? ThemeManager.primary : ThemeManager.textSecondary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: onTap != null ? ThemeManager.textColor : ThemeManager.textSecondary, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
          Text(subtitle, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 10), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Future<void> _connect() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) {
      setState(() => _status = '⚠️ Enter the desktop IP first');
      return;
    }
    setState(() { _status = 'Connecting…'; _syncing = true; });
    SyncService.instance.setServer(ip);
    final ok = await SyncService.instance.ping();
    setState(() {
      _connected = ok;
      _syncing = false;
      _status = ok ? '✅ Connected to StudentTrack Pro on $ip' : '❌ Could not reach $ip:8765';
    });
    _log(ok ? 'Connected to $ip' : 'Connection failed to $ip');
  }

  Future<void> _pull() async {
    setState(() => _syncing = true);
    _log('Starting pull from desktop…');
    final result = await SyncService.instance.pullFromDesktop();
    setState(() => _syncing = false);
    _log(result.message);
    _showSnack(result.success ? '✅ ${result.message}' : '❌ ${result.message}');
  }

  Future<void> _push() async {
    setState(() => _syncing = true);
    _log('Starting push to desktop…');
    final result = await SyncService.instance.pushToDesktop();
    setState(() => _syncing = false);
    _log(result.message);
    _showSnack(result.success ? '✅ ${result.message}' : '❌ ${result.message}');
  }

  Future<void> _fullSync() async {
    setState(() => _syncing = true);
    _log('Starting full sync…');
    final result = await SyncService.instance.fullSync();
    setState(() => _syncing = false);
    for (final line in result.message.split('\n')) {
      _log(line);
    }
    _showSnack(result.success ? '✅ Sync complete!' : '❌ ${result.message}');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  }
}
