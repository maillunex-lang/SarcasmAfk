import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../game/arena_game.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final ArenaGame game;
  String toast = 'Автобой';
  bool finished = false;
  bool won = false;
  double speed = 1;

  @override
  void initState() {
    super.initState();
    game = ArenaGame(
      onToast: (t) {
        if (!mounted) return;
        setState(() => toast = t);
      },
      onFinished: (didWin) {
        if (!mounted) return;
        setState(() {
          finished = true;
          won = didWin;
          toast = didWin ? '+180 soft' : 'Печать победила…';
        });
      },
    );
  }

  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  void _restart() {
    setState(() {
      finished = false;
      won = false;
      toast = 'Автобой';
      speed = 1;
    });
    game.restart(speed: speed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 860),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  Expanded(
                    child: GameWidget(game: game),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xEB1A2238), Color(0xFF10182A)],
                      ),
                      border: Border(
                        top: BorderSide(color: Color(0x40C9A227)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          toast,
                          style: const TextStyle(
                            color: Color(0xFF9AA3B5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: _ActButton(
                                label: 'ULT',
                                gold: true,
                                onPressed: () => game.triggerUlt(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: _ActButton(
                                label: speed > 1.5 ? '×2' : '×1',
                                onPressed: () {
                                  setState(() {
                                    speed = speed < 1.5 ? 2 : 1;
                                  });
                                  game.setSpeed(speed);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: _ActButton(
                                label: 'Меню',
                                onPressed: () {
                                  Navigator.of(context).pop(won ? 180 : 0);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (finished) ...[
                          const SizedBox(height: 12),
                          Text(
                            won ? 'Победа' : 'Поражение',
                            style: TextStyle(
                              color: won
                                  ? const Color(0xFF5DCEA0)
                                  : const Color(0xFFE35D6A),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ActButton(
                            label: 'Ещё раз',
                            gold: true,
                            onPressed: _restart,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActButton extends StatelessWidget {
  const _ActButton({
    required this.label,
    required this.onPressed,
    this.gold = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              gold ? const Color(0xFFC9A227) : const Color(0xE61A2238),
          foregroundColor:
              gold ? const Color(0xFF1A1508) : const Color(0xFFF3EEE4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: gold
                ? BorderSide.none
                : const BorderSide(color: Color(0x24F3EEE4)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
