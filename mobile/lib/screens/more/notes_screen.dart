import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
      appBar: AppBar(
        title: const Text('📝 Notes'),
        actions: [
          // Import .md button
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import .md file',
            onPressed: _importMarkdown,
          ),
        ],
      ),
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
              ? EmptyState(icon: '📝', title: 'No notes yet', subtitle: 'Tap + to jot something down.\nOr tap 📤 to import a .md file.')
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
            border: isPinned ? Border.all(color: ThemeManager.primary.withAlpha(120)) : null,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // .MD IMPORT (FEAT-02)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _importMarkdown() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt', 'markdown'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String content;
    if (file.bytes != null) {
      content = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      _showSnack('❌ Could not read file');
      return;
    }
    final fileName = file.name;

    if (!mounted) return;

    // Show import options dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Import: $fileName', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${content.length} characters · ${content.split('\n').length} lines', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),

          // Option 1: Save as note
          _importOption(
            icon: Icons.note_add,
            title: '📝 Save as Note',
            subtitle: 'Import the full markdown content as a new note',
            onTap: () async {
              Navigator.pop(ctx);
              await _importAsNote(fileName, content);
            },
          ),
          const SizedBox(height: 8),

          // Option 2: Parse checklists → todos
          _importOption(
            icon: Icons.checklist,
            title: '✅ Extract Tasks',
            subtitle: 'Find checklist items (- [ ] ...) and import as To-Do tasks',
            onTap: () async {
              Navigator.pop(ctx);
              await _importAsTasks(fileName, content);
            },
          ),
          const SizedBox(height: 8),

          // Option 3: Generate study roadmap
          _importOption(
            icon: Icons.map_outlined,
            title: '🗺️ Generate Study Roadmap',
            subtitle: 'Create goals + milestones from headings and bullet points',
            onTap: () async {
              Navigator.pop(ctx);
              await _importAsRoadmap(fileName, content);
            },
          ),

          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: ThemeManager.textSecondary))),
        ]),
      ),
    );
  }

  Widget _importOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThemeManager.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ThemeManager.border),
        ),
        child: Row(children: [
          Icon(icon, color: ThemeManager.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: ThemeManager.textSecondary, fontSize: 11)),
          ])),
          Icon(Icons.chevron_right, color: ThemeManager.textSecondary),
        ]),
      ),
    );
  }

  // ── Option 1: Save as Note ────────────────────────────────────────────────

  Future<void> _importAsNote(String fileName, String content) async {
    final title = fileName.replaceAll(RegExp(r'\.(md|txt|markdown)$'), '');
    final now = DateTime.now().toIso8601String();
    await DbHelper.instance.insert('notes', {
      'title': title,
      'content': content,
      'created_at': now,
      'updated_at': now,
    });
    await DbHelper.instance.awardXp(5, 'import_note');
    _showSnack('📝 Note imported: $title (+5 XP)');
    _load();
  }

  // ── Option 2: Extract Tasks ───────────────────────────────────────────────

  Future<void> _importAsTasks(String fileName, String content) async {
    final lines = content.split('\n');
    int imported = 0;
    String currentCategory = '';
    final now = DateTime.now().toIso8601String();

    for (final line in lines) {
      final trimmed = line.trim();

      // Headings become categories
      if (trimmed.startsWith('#')) {
        currentCategory = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        continue;
      }

      // Checklist items: - [ ] task or - [x] task
      final checkMatch = RegExp(r'^[-*]\s*\[([ xX])\]\s*(.+)$').firstMatch(trimmed);
      if (checkMatch != null) {
        final isDone = checkMatch.group(1) != ' ';
        final title = checkMatch.group(2)!.trim();
        await DbHelper.instance.insert('todos', {
          'title': title,
          'category': currentCategory.isNotEmpty ? currentCategory : null,
          'priority': 'medium',
          'is_completed': isDone ? 1 : 0,
          'completed_at': isDone ? now : null,
          'created_at': now,
        });
        imported++;
        continue;
      }

      // Plain bullet items: - task or * task
      final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final title = bulletMatch.group(1)!.trim();
        if (title.length > 3) { // skip very short bullets
          await DbHelper.instance.insert('todos', {
            'title': title,
            'category': currentCategory.isNotEmpty ? currentCategory : null,
            'priority': 'medium',
            'is_completed': 0,
            'created_at': now,
          });
          imported++;
        }
      }
    }

    if (imported > 0) {
      await DbHelper.instance.awardXp(imported * 2, 'import_tasks');
      _showSnack('✅ Imported $imported tasks (+${imported * 2} XP)');
    } else {
      _showSnack('⚠️ No checklist items found in this file');
    }
  }

  // ── Option 3: Generate Study Roadmap ──────────────────────────────────────

  Future<void> _importAsRoadmap(String fileName, String content) async {
    final lines = content.split('\n');
    final title = fileName.replaceAll(RegExp(r'\.(md|txt|markdown)$'), '');
    final now = DateTime.now().toIso8601String();

    // Parse structure: headings become goals, bullets/checklists become milestones
    String currentGoalTitle = '';
    List<String> currentMilestones = [];
    int goalsCreated = 0;
    int milestonesCreated = 0;

    Future<void> flushGoal() async {
      if (currentGoalTitle.isEmpty) return;
      // Create goal
      final goalId = await DbHelper.instance.insert('goals', {
        'title': currentGoalTitle,
        'description': 'Auto-generated from: $fileName',
        'type': 'long',
        'progress_percent': 0,
        'is_completed': 0,
        'created_at': now,
      });
      goalsCreated++;

      // Create milestones
      for (int i = 0; i < currentMilestones.length; i++) {
        await DbHelper.instance.insert('milestones', {
          'goal_id': goalId,
          'title': currentMilestones[i],
          'is_completed': 0,
          'order_index': i,
        });
        milestonesCreated++;
      }
      currentMilestones.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // H1/H2 → new goal
      if (trimmed.startsWith('#')) {
        await flushGoal();
        currentGoalTitle = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        continue;
      }

      // Checklists and bullets → milestones
      final checkMatch = RegExp(r'^[-*]\s*\[[ xX]\]\s*(.+)$').firstMatch(trimmed);
      if (checkMatch != null) {
        currentMilestones.add(checkMatch.group(1)!.trim());
        continue;
      }

      final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final text = bulletMatch.group(1)!.trim();
        if (text.length > 3) currentMilestones.add(text);
        continue;
      }

      // Numbered items → milestones
      final numMatch = RegExp(r'^\d+[.)]\s*(.+)$').firstMatch(trimmed);
      if (numMatch != null) {
        currentMilestones.add(numMatch.group(1)!.trim());
        continue;
      }

      // If we have a goal title but this is a plain text line, add as milestone
      if (currentGoalTitle.isNotEmpty && trimmed.length > 10) {
        currentMilestones.add(trimmed);
      }
    }

    // Flush last goal
    await flushGoal();

    // If no headings found, create a single goal from the filename
    if (goalsCreated == 0) {
      final goalId = await DbHelper.instance.insert('goals', {
        'title': 'Study: $title',
        'description': 'Auto-generated roadmap from: $fileName\n\n$content',
        'type': 'long',
        'progress_percent': 0,
        'is_completed': 0,
        'created_at': now,
      });
      goalsCreated = 1;

      // Try to extract any bullet points as milestones
      for (final line in lines) {
        final trimmed = line.trim();
        final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed);
        if (bulletMatch != null) {
          final text = bulletMatch.group(1)!.trim();
          if (text.length > 3) {
            await DbHelper.instance.insert('milestones', {
              'goal_id': goalId,
              'title': text,
              'is_completed': 0,
              'order_index': milestonesCreated,
            });
            milestonesCreated++;
          }
        }
      }
    }

    if (goalsCreated > 0) {
      await DbHelper.instance.awardXp(goalsCreated * 20 + milestonesCreated * 5, 'import_roadmap');
      final xp = goalsCreated * 20 + milestonesCreated * 5;
      _showSnack('🗺️ Roadmap created: $goalsCreated goals, $milestonesCreated milestones (+$xp XP)');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ThemeManager.primary, duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating),
    );
  }
}
