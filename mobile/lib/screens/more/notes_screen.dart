import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final q = _search.isEmpty
        ? 'SELECT * FROM notes ORDER BY is_pinned DESC, updated_at DESC'
        : 'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? ORDER BY is_pinned DESC, updated_at DESC';
    final args = _search.isEmpty ? null : ['%$_search%', '%$_search%'];
    final rows = await DbHelper.instance.fetchAll(q, args);
    if (mounted) setState(() => _notes = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('📝 Notes')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(hintText: 'Search notes…', prefixIcon: Icon(Icons.search, color: ThemeManager.textSecondary)),
            onChanged: (v) { _search = v; _load(); },
          ),
        ),
        Expanded(
          child: _notes.isEmpty
              ? EmptyState(icon: '📝', title: 'No notes yet', subtitle: 'Tap + to jot something down.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _notes.length,
                  itemBuilder: (_, i) => _noteCard(_notes[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addNote,
      ),
    );
  }

  Widget _noteCard(Map<String, dynamic> n) {
    final isPinned = n['is_pinned'] == 1;
    return Dismissible(
      key: Key('note_${n['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) { DbHelper.instance.deleteWhere('notes', 'id=?', [n['id']]); _load(); },
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: ThemeManager.danger, child: const Icon(Icons.delete, color: Colors.white)),
      child: GestureDetector(
        onTap: () => _editNote(n),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ThemeManager.card,
            borderRadius: BorderRadius.circular(14),
            border: isPinned ? Border.all(color: ThemeManager.primary.withOpacity(0.5)) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (isPinned) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 14, color: ThemeManager.primary)),
              Expanded(child: Text(n['title'] as String? ?? 'Untitled', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14))),
              GestureDetector(onTap: () { DbHelper.instance.updateWhere('notes', {'is_pinned': isPinned ? 0 : 1}, 'id=?', [n['id']]); _load(); }, child: Icon(Icons.push_pin_outlined, color: ThemeManager.textSecondary, size: 16)),
            ]),
            if (n['content'] != null && (n['content'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text((n['content'] as String).length > 100 ? '${(n['content'] as String).substring(0, 100)}…' : n['content'] as String, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12))),
            if (n['subject'] != null && (n['subject'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Chip(label: Text(n['subject'] as String, style: const TextStyle(fontSize: 10)), backgroundColor: ThemeManager.surface2, padding: EdgeInsets.zero)),
          ]),
        ),
      ),
    );
  }

  void _addNote() => _openEditor(null);
  void _editNote(Map<String, dynamic> n) => _openEditor(n);

  void _openEditor(Map<String, dynamic>? existing) {
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final contentCtrl = TextEditingController(text: existing?['content'] as String? ?? '');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: ThemeManager.background,
        appBar: AppBar(
          title: Text(existing == null ? 'New Note' : 'Edit Note', style: TextStyle(color: ThemeManager.textColor)),
          actions: [
            TextButton(
              onPressed: () async {
                final now = DateTime.now().toIso8601String();
                if (existing == null) {
                  await DbHelper.instance.insert('notes', {'title': titleCtrl.text.isEmpty ? 'Untitled' : titleCtrl.text, 'content': contentCtrl.text, 'created_at': now, 'updated_at': now});
                } else {
                  await DbHelper.instance.updateWhere('notes', {'title': titleCtrl.text, 'content': contentCtrl.text, 'updated_at': now}, 'id=?', [existing['id']]);
                }
                Navigator.pop(context);
                _load();
              },
              child: Text('Save', style: TextStyle(color: ThemeManager.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(controller: titleCtrl, style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'Title…', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, hintStyle: TextStyle(color: ThemeManager.textSecondary))),
            Divider(color: ThemeManager.border),
            Expanded(child: TextField(controller: contentCtrl, style: TextStyle(color: ThemeManager.textColor, fontSize: 15), decoration: InputDecoration(hintText: 'Write something…', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, hintStyle: TextStyle(color: ThemeManager.textSecondary)), maxLines: null, expands: true, keyboardType: TextInputType.multiline)),
          ]),
        ),
      ),
    ));
  }
}
