// lib/src/ui/screens/memorama_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';

class MemoramaPage extends StatefulWidget {
  const MemoramaPage({super.key});
  static const route = '/games/memorama';

  @override
  State<MemoramaPage> createState() => _MemoramaPageState();
}

class _MemoramaPageState extends State<MemoramaPage> {
  final List<IconData> _icons = const [
    Icons.favorite,
    Icons.star,
    Icons.pets,
    Icons.coffee,
    Icons.flash_on,
    Icons.face,
    Icons.catching_pokemon,
    Icons.rocket_launch,
  ];

  late List<int> _cards;
  late List<bool> _revealed;
  int? _firstIndex;
  bool _waiting = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    final base = List.generate(_icons.length, (i) => i);
    _cards = [...base, ...base]..shuffle(Random());
    _revealed = List<bool>.filled(_cards.length, false);
    _firstIndex = null;
    _waiting = false;
    _moves = 0;
    setState(() {});
  }

  Future<void> _onCardTap(int index) async {
    if (_waiting || _revealed[index]) return;
    setState(() => _revealed[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _moves++;

    if (_cards[_firstIndex!] != _cards[index]) {
      _waiting = true;
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _revealed[_firstIndex!] = false;
        _revealed[index] = false;
      });
      _waiting = false;
    }

    _firstIndex = null;

    if (_revealed.every((r) => r)) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Felicidades!'),
          content: Text('Completaste el juego en $_moves movimientos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text('Jugar otra vez', style: TextStyle(color: kInk)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: kInk)),
            ),
          ],
        ),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Memorama'),
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Encabezado ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 20, color: kInk),
                  const SizedBox(width: 6),
                  Text(
                    'Movimientos: $_moves',
                    style: const TextStyle(
                      color: kInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reiniciar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kBlue.withOpacity(0.7),
                      foregroundColor: kInk,
                    ),
                  ),
                ],
              ),
            ),

            // --- Tablero ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: _cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, i) {
                    final isUp = _revealed[i];
                    final icon = _icons[_cards[i]];

                    return InkWell(
                      onTap: () => _onCardTap(i),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isUp ? kBlue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUp ? kPurple : Colors.black26,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isUp ? 1 : 0,
                            child: Icon(icon, size: 38, color: kInk),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
