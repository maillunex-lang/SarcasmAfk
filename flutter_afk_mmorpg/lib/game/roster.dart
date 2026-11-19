import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart' show rootBundle;

class AnimSpec {
  const AnimSpec({
    required this.path,
    this.stepTime = 0.12,
  });

  final String path;
  final double stepTime;
}

class FighterKit {
  const FighterKit({
    required this.id,
    required this.name,
    required this.folder,
    required this.displaySize,
    this.melee = false,
    this.idleStep = 0.14,
    this.runStep = 0.1,
    this.attackStep = 0.09,
    this.credit = '',
  });

  final String id;
  final String name;
  final String folder;
  final Vector2 displaySize;
  final bool melee;
  final double idleStep;
  final double runStep;
  final double attackStep;
  final String credit;

  AnimSpec get idle => AnimSpec(path: 'roster/$folder/idle.png', stepTime: idleStep);
  AnimSpec get run => AnimSpec(path: 'roster/$folder/run.png', stepTime: runStep);
  AnimSpec get attack =>
      AnimSpec(path: 'roster/$folder/attack.png', stepTime: attackStep);
}

final heroes = <FighterKit>[
  FighterKit(
    id: 'mage',
    name: 'Маг',
    folder: 'mage',
    displaySize: Vector2(140, 190),
    idleStep: 0.2,
    runStep: 0.1,
    attackStep: 0.1,
    credit: 'TEMP generated',
  ),
  FighterKit(
    id: 'swordsman',
    name: 'Мечник',
    folder: 'swordsman',
    displaySize: Vector2(150, 150),
    melee: true,
    idleStep: 0.18,
    runStep: 0.09,
    attackStep: 0.08,
    credit: 'CC0 · tbbk / OpenGameArt',
  ),
  FighterKit(
    id: 'knight',
    name: 'Тёмный рыцарь',
    folder: 'knight',
    displaySize: Vector2(160, 160),
    melee: true,
    idleStep: 0.1,
    runStep: 0.08,
    attackStep: 0.07,
    credit: 'CC0 · comphonia / OpenGameArt',
  ),
];

final enemies = <FighterKit>[
  FighterKit(
    id: 'wolf',
    name: 'Волк',
    folder: 'wolf',
    displaySize: Vector2(160, 140),
    melee: true,
    idleStep: 0.2,
    runStep: 0.1,
    attackStep: 0.1,
    credit: 'TEMP generated',
  ),
  FighterKit(
    id: 'skeleton',
    name: 'Скелет',
    folder: 'skeleton',
    displaySize: Vector2(130, 170),
    melee: true,
    idleStep: 0.14,
    runStep: 0.1,
    attackStep: 0.09,
    credit: 'CC-BY 3.0 · OpenGameArt',
  ),
  FighterKit(
    id: 'goblin',
    name: 'Гоблин',
    folder: 'goblin',
    displaySize: Vector2(140, 140),
    melee: true,
    idleStep: 0.14,
    runStep: 0.1,
    attackStep: 0.09,
    credit: 'OGA-BY 4.0 · RPG Combat Pack',
  ),
  FighterKit(
    id: 'forest',
    name: 'Лесная тварь',
    folder: 'forest',
    displaySize: Vector2(150, 150),
    melee: true,
    idleStep: 0.16,
    runStep: 0.1,
    attackStep: 0.09,
    credit: 'OGA-BY 4.0 · Dark Forest Pack',
  ),
];

FighterKit heroById(String id) =>
    heroes.firstWhere((h) => h.id == id, orElse: () => heroes.first);

FighterKit enemyById(String id) =>
    enemies.firstWhere((e) => e.id == id, orElse: () => enemies.first);

Future<SpriteAnimation> loadAnim(AnimSpec spec) async {
  final metaAsset = 'assets/images/${spec.path.replaceAll('.png', '.meta')}';
  final metaText = (await rootBundle.loadString(metaAsset)).trim();
  final parts = metaText.split(',');
  final fw = double.parse(parts[0]);
  final fh = double.parse(parts[1]);
  final amount = int.parse(parts[2]);
  final image = await Flame.images.load(spec.path);
  return SpriteAnimation.fromFrameData(
    image,
    SpriteAnimationData.sequenced(
      amount: amount,
      stepTime: spec.stepTime,
      textureSize: Vector2(fw, fh),
      loop: true,
    ),
  );
}
