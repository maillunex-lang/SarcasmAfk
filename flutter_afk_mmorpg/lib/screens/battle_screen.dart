import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../game/afk_game.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final AfkGame game;
  String toast = 'Автобой';
  bool finished = false;
  bool won = false;
  double speed = 1;

  @override
  void initState() {
    super.initState();
    game = AfkGame(
      onToast: (t) {
        if (mounted) setState(() => toast = t);
      },
      onFinished: (didWin) {
        if (!mounted) return;
        setState(() {
          finished = true;
          won = didWin;
          toast = didWin ? 'Волк повержен' : 'Маг пал…';
        });
      },
    );
  }

  @override
  void dispose() {
    game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 860),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  Expanded(child: GameWidget(game: game)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    color: const Color(0xF2141018),
                    child: Column(
                      children: [
                        Text(
                          toast,
                          style: const TextStyle(
                            color: Color(0xFFA9A0B0),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: _Btn(
                                label: 'Огненный шар',
                                hot: true,
                                onPressed: () => game.castFireball(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: _Btn(
                                label: speed > 1.5 ? '×2' : '×1',
                                onPressed: () {
                                  setState(() => speed = speed < 1.5 ? 2 : 1);
                                  game.setSpeed(speed);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: _Btn(
                                label: 'Меню',
                                onPressed: () => Navigator.of(context).pop(),
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
                          const SizedBox(height: 8),
                          _Btn(
                            label: 'Ещё раз',
                            hot: true,
                            onPressed: () {
                              setState(() {
                                finished = false;
                                won = false;
                                toast = 'Автобой';
                                speed = 1;
                              });
                              game.restart(speed: 1);
                            },
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

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.onPressed,
    this.hot = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              hot ? const Color(0xFFC45C26) : const Color(0xE61A1520),
          foregroundColor:
              hot ? const Color(0xFFFFF3E8) : const Color(0xFFF3EEE4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}
