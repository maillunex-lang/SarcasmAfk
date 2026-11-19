import 'package:material_ui/material_ui.dart';

import 'battle_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
                  Image.asset('assets/images/arena_bg.jpg', fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x66000000), Color(0xF208060A)],
                        stops: [0.2, 0.78],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
                      child: Column(
                        children: [
                          const Spacer(),
                          const Text(
                            'БАШЛЕГЕНДЫ',
                            style: TextStyle(
                              color: Color(0xFFC45C26),
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'AFK MMORPG',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2.5D · маг vs волк · сосулька / огненный шар',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFA9A0B0),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Semantics(
                            button: true,
                            label: 'В бой',
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFC45C26),
                                foregroundColor: const Color(0xFFFFF3E8),
                                minimumSize: const Size(220, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BattleScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'В бой',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Flutter + Flame · автобой',
                            style: TextStyle(
                              color: Color(0xFF7E7588),
                              fontSize: 12,
                            ),
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
