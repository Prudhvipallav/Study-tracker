import 'package:flutter/material.dart';
import '../../theme/theme_manager.dart';
import '../../database/db_helper.dart';
import '../../widgets/widgets.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<Map<String, dynamic>> _decks = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final rows = await DbHelper.instance.fetchAll(
        'SELECT fd.*, COUNT(f.id) as card_count FROM flashcard_decks fd LEFT JOIN flashcards f ON f.deck_id=fd.id GROUP BY fd.id ORDER BY fd.created_at DESC');
    if (mounted) setState(() => _decks = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(title: const Text('🃏 Flashcard Decks')),
      body: _decks.isEmpty
          ? EmptyState(icon: '🃏', title: 'No decks yet', subtitle: 'Create a deck to start studying smarter!')
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
              itemCount: _decks.length,
              itemBuilder: (_, i) => _deckCard(_decks[i]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addDeck,
      ),
    );
  }

  Widget _deckCard(Map<String, dynamic> deck) {
    final count = (deck['card_count'] as int?) ?? 0;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _StudyScreen(deck: deck))).then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [ThemeManager.primary.withAlpha(51), ThemeManager.card], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ThemeManager.primary.withAlpha(77)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🃏', style: const TextStyle(fontSize: 32)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(deck['name'] as String? ?? '', style: TextStyle(color: ThemeManager.textColor, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('$count cards', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 12)),
              if (deck['subject'] != null && (deck['subject'] as String).isNotEmpty)
                Text(deck['subject'] as String, style: TextStyle(color: ThemeManager.primary, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _addDeck() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New Deck', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Deck name…')),
          const SizedBox(height: 12),
          TextField(controller: subjectCtrl, decoration: const InputDecoration(hintText: 'Subject (optional)…')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('flashcard_decks', {'name': nameCtrl.text.trim(), 'subject': subjectCtrl.text.trim()});
              await DbHelper.instance.awardXp(10, 'create_flashcard_deck');
              Navigator.pop(context); _load();
            },
            child: const Text('Create Deck'),
          )),
        ]),
      ),
    );
  }
}

// ── Study Screen ──────────────────────────────────────────────────────────
class _StudyScreen extends StatefulWidget {
  final Map<String, dynamic> deck;
  const _StudyScreen({required this.deck});
  @override
  State<_StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<_StudyScreen> {
  List<Map<String, dynamic>> _cards = [];
  int _idx = 0;
  bool _showAnswer = false;
  bool _isFlipping = false;
  int _correct = 0, _wrong = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final cards = await DbHelper.instance.fetchAll('SELECT * FROM flashcards WHERE deck_id=? ORDER BY RANDOM()', [widget.deck['id']]);
    if (mounted) setState(() { _cards = cards; _idx = 0; _showAnswer = false; });
  }

  Future<void> _addCard() async {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: ThemeManager.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Card', style: TextStyle(color: ThemeManager.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: qCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Question…'), maxLines: 3),
          const SizedBox(height: 12),
          TextField(controller: aCtrl, decoration: const InputDecoration(hintText: 'Answer…'), maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (qCtrl.text.trim().isEmpty || aCtrl.text.trim().isEmpty) return;
              await DbHelper.instance.insert('flashcards', {'deck_id': widget.deck['id'], 'question': qCtrl.text.trim(), 'answer': aCtrl.text.trim()});
              Navigator.pop(context); _load();
            },
            child: const Text('Add Card'),
          )),
        ]),
      ),
    );
  }

  void _flip() {
    if (_isFlipping) return;
    setState(() { _isFlipping = true; });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() { _showAnswer = !_showAnswer; _isFlipping = false; });
    });
  }

  void _next(bool wasCorrect) async {
    if (wasCorrect) _correct++; else _wrong++;
    final card = _cards[_idx];
    await DbHelper.instance.execute(
      wasCorrect
          ? 'UPDATE flashcards SET times_correct=times_correct+1, last_reviewed=? WHERE id=?'
          : 'UPDATE flashcards SET times_wrong=times_wrong+1, last_reviewed=? WHERE id=?',
      [DateTime.now().toIso8601String(), card['id']],
    );
    await DbHelper.instance.awardXp(wasCorrect ? 2 : 1, wasCorrect ? 'flashcard_easy' : 'flashcard_hard');
    if (_idx < _cards.length - 1) {
      setState(() { _idx++; _showAnswer = false; });
    } else {
      // Show completion
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        backgroundColor: ThemeManager.card,
        title: Text('Session Complete! 🎉', style: TextStyle(color: ThemeManager.textColor)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_cards.length} cards reviewed', style: TextStyle(color: ThemeManager.textSecondary)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Column(children: [Text('✅ $_correct', style: TextStyle(color: ThemeManager.success, fontSize: 22, fontWeight: FontWeight.bold)), Text('Correct')]),
            Column(children: [Text('❌ $_wrong', style: TextStyle(color: ThemeManager.danger, fontSize: 22, fontWeight: FontWeight.bold)), Text('Wrong')]),
          ]),
        ]),
        actions: [
          ElevatedButton(onPressed: () { Navigator.pop(context); _load(); setState(() { _correct = 0; _wrong = 0; }); }, child: const Text('Study Again')),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Done')),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.background,
      appBar: AppBar(
        title: Text(widget.deck['name'] as String? ?? 'Study'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addCard),
          if (_cards.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${_idx + 1}/${_cards.length}', style: TextStyle(color: ThemeManager.textSecondary)))),
        ],
      ),
      body: _cards.isEmpty
          ? EmptyState(icon: '🃏', title: 'No cards yet', subtitle: 'Tap + to add your first flashcard!')
          : GestureDetector(
              onTap: _flip,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  // Progress bar
                  LinearProgressIndicator(value: (_idx + 1) / _cards.length, backgroundColor: ThemeManager.surface2, valueColor: AlwaysStoppedAnimation(ThemeManager.primary), minHeight: 6),
                  const SizedBox(height: 40),
                  // Card
                  Expanded(child: Center(child: AnimatedOpacity(
                    opacity: _isFlipping ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _showAnswer
                              ? [ThemeManager.success.withAlpha(38), ThemeManager.card]
                              : [ThemeManager.primary.withAlpha(38), ThemeManager.card],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _showAnswer ? ThemeManager.success.withAlpha(102) : ThemeManager.primary.withAlpha(102), width: 2),
                        boxShadow: [BoxShadow(color: (_showAnswer ? ThemeManager.success : ThemeManager.primary).withAlpha(26), blurRadius: 20)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_showAnswer ? '✅ Answer' : '❓ Question', style: TextStyle(color: _showAnswer ? ThemeManager.success : ThemeManager.primary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        const SizedBox(height: 20),
                        Text(
                          _showAnswer ? (_cards[_idx]['answer'] as String? ?? '') : (_cards[_idx]['question'] as String? ?? ''),
                          style: TextStyle(color: ThemeManager.textColor, fontSize: 20, fontWeight: FontWeight.w600, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (!_showAnswer)
                          Text('Tap to reveal answer', style: TextStyle(color: ThemeManager.textSecondary, fontSize: 13)),
                      ]),
                    ),
                  ))),
                  const SizedBox(height: 16),
                  // Answer buttons
                  AnimatedOpacity(
                    opacity: _showAnswer ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _showAnswer ? Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _next(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Hard'),
                        style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _next(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Easy'),
                        style: ElevatedButton.styleFrom(backgroundColor: ThemeManager.success, padding: const EdgeInsets.symmetric(vertical: 14)),
                      )),
                    ]) : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }
}
