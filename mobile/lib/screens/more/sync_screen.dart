import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _codeCtrl = TextEditingController();
  bool _connected = false;
  bool _syncing = false;
  String _status = '';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    final ip = SyncService.instance.serverIp;
    if (ip != null) _codeCtrl.text = ip;
  }

  void _log(String msg) {
    setState(() {
      _logs.insert(0, msg);
      if (_logs.length > 15) _logs = _logs.sublist(0, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('📲 Transfer Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Friendly instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeManager.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeManager.primary.withAlpha(40)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.sync_alt, color: ThemeManager.primary, size: 24),
                const SizedBox(width: 8),
                Text('Move data between your phone & PC', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const SizedBox(height: 12),
              _friendlyStep('1', '📖 Open StudentTrack Pro on your PC'),
              _friendlyStep('2', '📂 Go to Settings → Transfer Data'),
              _friendlyStep('3', '📝 A number will appear — type it below'),
              _friendlyStep('4', '📲 Tap "Connect" & then "Transfer"'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ThemeManager.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.wifi, color: ThemeManager.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Both devices must be on the same WiFi', style: TextStyle(color: ThemeManager.primary, fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Connection — friendly label
          Text('Enter the number from your PC:', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.5',
                  prefixIcon: Icon(Icons.numbers, color: ThemeManager.textSecondary),
                  filled: true,
                  fillColor: ThemeManager.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ThemeManager.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ThemeManager.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ThemeManager.primary, width: 2)),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _connect,
              icon: Icon(_connected ? Icons.check_circle : Icons.link, size: 18),
              label: Text(_connected ? 'Connected!' : 'Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _connected ? ThemeManager.success : ThemeManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),

          // Status indicator
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _connected ? ThemeManager.success : ThemeManager.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_status, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
            ]),
          ],

          const SizedBox(height: 24),

          // Transfer buttons — big and clear
          if (_connected) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _syncing ? null : _fullSync,
                icon: const Icon(Icons.sync, size: 22),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Column(children: [
                    Text('Transfer All Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Sends your data to PC & gets PC data back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
                  ]),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeManager.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _syncing ? null : _push,
                icon: const Icon(Icons.phone_android, size: 18),
                label: const Text('Phone → PC', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeManager.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: ThemeManager.primary.withAlpha(100)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: _syncing ? null : _pull,
                icon: const Icon(Icons.computer, size: 18),
                label: const Text('PC → Phone', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeManager.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: ThemeManager.primary.withAlpha(100)),
                ),
              )),
            ]),
          ],

          // Not connected — show disabled state
          if (!_connected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeManager.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ThemeManager.border),
              ),
              child: Column(children: [
                Icon(Icons.sync_disabled, color: ThemeManager.textSecondary, size: 32),
                const SizedBox(height: 8),
                Text('Connect to your PC first', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
                Text('Enter the number and tap Connect', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
              ]),
            ),
          ],

          // Loading
          if (_syncing) ...[
            const SizedBox(height: 20),
            Center(child: Column(children: [
              CircularProgressIndicator(color: ThemeManager.primary),
              const SizedBox(height: 8),
              Text('Transferring data…', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
            ])),
          ],

          // Activity log — simplified
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Activity', style: TextStyle(color: ThemeManager.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ThemeManager.card, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _logs.map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('• ', style: TextStyle(color: ThemeManager.primary, fontSize: 12)),
                    Expanded(child: Text(log, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
                  ]),
                )).toList(),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _friendlyStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: ThemeManager.primary.withAlpha(30), borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(num, style: TextStyle(color: ThemeManager.primary, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: ThemeManager.textColor, fontSize: 13))),
      ]),
    );
  }

  Future<void> _connect() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _status = 'Enter the number shown on your PC');
      return;
    }
    setState(() { _status = 'Looking for your PC…'; _syncing = true; });
    SyncService.instance.setServer(code);
    final ok = await SyncService.instance.ping();
    setState(() {
      _connected = ok;
      _syncing = false;
      _status = ok ? '✅ Found your PC! Ready to transfer.' : '❌ Couldn\'t find your PC. Check if both are on the same WiFi.';
    });
    _log(ok ? 'Connected to your PC' : 'Couldn\'t connect — check WiFi');
  }

  Future<void> _pull() async {
    setState(() => _syncing = true);
    _log('Getting data from PC…');
    final result = await SyncService.instance.pullFromDesktop();
    setState(() => _syncing = false);
    _log(result.success ? 'Got data from PC ✅' : 'Failed to get data');
    _showSnack(result.success ? '✅ Data copied from PC!' : '❌ ${result.message}');
  }

  Future<void> _push() async {
    setState(() => _syncing = true);
    _log('Sending data to PC…');
    final result = await SyncService.instance.pushToDesktop();
    setState(() => _syncing = false);
    _log(result.success ? 'Sent data to PC ✅' : 'Failed to send data');
    _showSnack(result.success ? '✅ Data sent to PC!' : '❌ ${result.message}');
  }

  Future<void> _fullSync() async {
    setState(() => _syncing = true);
    _log('Transferring all data…');
    final result = await SyncService.instance.fullSync();
    setState(() => _syncing = false);
    _log(result.success ? 'All data transferred ✅' : 'Transfer failed');
    _showSnack(result.success ? '✅ All data transferred!' : '❌ ${result.message}');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  }
}
