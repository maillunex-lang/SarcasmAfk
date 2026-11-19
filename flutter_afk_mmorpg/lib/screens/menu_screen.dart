import 'package:material_ui/material_ui.dart';

import '../game/roster.dart';
import 'battle_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String heroId = heroes.first.id;
  String enemyId = enemies.first.id;

  FighterKit get selectedHero => heroById(heroId);
  FighterKit get selectedEnemy => enemyById(enemyId);

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
                        stops: [0.15, 0.72],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'БАШЛЕГЕНДЫ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFC45C26),
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'AFK MMORPG',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Выбери героя и врага · анимации с OpenGameArt',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFA9A0B0),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                const _SectionLabel('Герой'),
                                const SizedBox(height: 8),
                                ...heroes.map(
                                  (h) => _PickTile(
                                    title: h.name,
                                    subtitle: h.credit,
                                    selected: heroId == h.id,
                                    preview: 'assets/images/roster/${h.folder}/idle.png',
                                    onTap: () => setState(() => heroId = h.id),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const _SectionLabel('Враг'),
                                const SizedBox(height: 8),
                                ...enemies.map(
                                  (e) => _PickTile(
                                    title: e.name,
                                    subtitle: e.credit,
                                    selected: enemyId == e.id,
                                    preview: 'assets/images/roster/${e.folder}/idle.png',
                                    onTap: () => setState(() => enemyId = e.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC45C26),
                              foregroundColor: const Color(0xFFFFF3E8),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BattleScreen(
                                    heroId: selectedHero.id,
                                    enemyId: selectedEnemy.id,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'В бой · ${selectedHero.name} vs ${selectedEnemy.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFF3EEE4),
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xE6C45C26) : const Color(0xCC16121C),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: const Color(0xFF0E0B12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        preview,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFFF3E8)
                              : const Color(0xFFF3EEE4),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xCCFFE8D6)
                              : const Color(0xFF8E8498),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: Color(0xFFFFF3E8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
