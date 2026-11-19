import 'package:material_ui/material_ui.dart';

import 'battle_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int gold = 1200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 860),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/menu_bg.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xE0080C16),
                        ],
                        stops: [0.28, 0.72],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
                      child: Column(
                        children: [
                          const Spacer(),
                          const Text(
                            'БАШЛЕГЕНДЫ',
                            style: TextStyle(
                              color: Color(0xFFC9A227),
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Арена 1×1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Flutter + Flame · бег · удар · VFX',
                            style: TextStyle(
                              color: Color(0xFF9AA3B5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Semantics(
                            button: true,
                            label: 'В бой',
                            child: _FightButton(
                              onPressed: () async {
                                final reward = await Navigator.of(context).push<int>(
                                  MaterialPageRoute(
                                    builder: (_) => const BattleScreen(),
                                  ),
                                );
                                if (reward != null && mounted) {
                                  setState(() => gold += reward);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Chip(
                                icon: 'assets/images/icon_gold.png',
                                label: '$gold',
                              ),
                              const SizedBox(width: 10),
                              const _Chip(
                                icon: 'assets/images/icon_battle.png',
                                label: 'Каэрон vs Печать',
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _FightButton extends StatelessWidget {
  const _FightButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE2C56A), Color(0xFFC9A227)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x47C9A227),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/icon_play.png', width: 36, height: 36),
                const SizedBox(width: 12),
                const Text(
                  'В бой',
                  style: TextStyle(
                    color: Color(0xFF1A1508),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE01A2238),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x47C9A227)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 28, height: 28),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
