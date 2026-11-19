import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';

import 'fighter.dart';

typedef ToastCallback = void Function(String text);
typedef FinishedCallback = void Function(bool won);

class ArenaGame extends FlameGame {
  ArenaGame({
    required this.onToast,
    required this.onFinished,
  });

  final ToastCallback onToast;
  final FinishedCallback onFinished;

  late Fighter hero;
  late Fighter enemy;
  late SpriteComponent slashFx;
  late SpriteComponent burstFx;
  late ArenaHud hud;

  double speed = 1;
  double elapsed = 0;
  double nextHero = 999;
  double nextEnemy = 999;
  double energy = 0;
  bool ultNext = false;
  bool done = false;
  bool fighting = false;
  bool busy = false;

  double heroHp = 100;
  double enemyHp = 100;
  final double heroMax = 100;
  final double enemyMax = 100;

  final _rng = math.Random();

  @override
  Color backgroundColor() => const Color(0xFF0A0E16);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'arena_bg.jpg',
      'hero_idle.png',
      'hero_run.png',
      'hero_attack.png',
      'enemy_idle.png',
      'enemy_run.png',
      'enemy_attack.png',
      'fx_slash.png',
      'fx_hit.png',
    ]);

    add(
      SpriteComponent(
        sprite: Sprite(images.fromCache('arena_bg.jpg')),
        size: size.clone(),
        priority: 0,
      ),
    );

    final groundY = size.y * 0.82;
    hero = Fighter(
      side: FighterSide.hero,
      idle: Sprite(images.fromCache('hero_idle.png')),
      run: Sprite(images.fromCache('hero_run.png')),
      attack: Sprite(images.fromCache('hero_attack.png')),
      home: Vector2(size.x * 0.28, groundY),
      faceRight: true,
    )..priority = 5;
    enemy = Fighter(
      side: FighterSide.enemy,
      idle: Sprite(images.fromCache('enemy_idle.png')),
      run: Sprite(images.fromCache('enemy_run.png')),
      attack: Sprite(images.fromCache('enemy_attack.png')),
      home: Vector2(size.x * 0.72, groundY),
      faceRight: false,
    )..priority = 5;
    add(hero);
    add(enemy);

    slashFx = SpriteComponent(
      sprite: Sprite(images.fromCache('fx_slash.png')),
      size: Vector2(size.x * 0.55, size.x * 0.28),
      anchor: Anchor.center,
      position: Vector2(size.x * 0.5, size.y * 0.55),
      priority: 20,
    )..opacity = 0;
    burstFx = SpriteComponent(
      sprite: Sprite(images.fromCache('fx_hit.png')),
      size: Vector2(120, 120),
      anchor: Anchor.center,
      position: Vector2(size.x * 0.55, size.y * 0.52),
      priority: 21,
    )..opacity = 0;
    add(slashFx);
    add(burstFx);

    hud = ArenaHud()..priority = 50;
    add(hud);

    await _startRound();
  }

  Future<void> _startRound() async {
    done = false;
    fighting = false;
    busy = true;
    elapsed = 0;
    energy = 0;
    ultNext = false;
    heroHp = heroMax;
    enemyHp = enemyMax;
    nextHero = 999;
    nextEnemy = 999;
    onToast('Сближение…');

    hero.dead = false;
    enemy.dead = false;
    hero.body.opacity = 1;
    enemy.body.opacity = 1;
    hero.body.angle = 0;
    enemy.body.angle = 0;
    hero.position = hero.homePosition.clone();
    enemy.position = enemy.homePosition.clone();

    await Future.wait([
      hero.enterFromOffscreen(duration: 1.05 / speed),
      enemy.enterFromOffscreen(duration: 1.05 / speed),
    ]);

    fighting = true;
    busy = false;
    nextHero = 0.55;
    nextEnemy = 1.05;
    onToast('Автобой');
  }

  void restart({double speed = 1}) {
    this.speed = speed;
    // ignore: discarded_futures
    _startRound();
  }

  void setSpeed(double s) => speed = s;

  void triggerUlt() {
    if (!fighting || done || busy) return;
    if (energy < 70) {
      onToast('ULT ещё копится…');
      return;
    }
    energy = 0;
    ultNext = true;
    onToast('ULT готов!');
    // ignore: discarded_futures
    _attack(heroAttacks: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = dt * speed;
    if (done) return;
    elapsed += t;
    if (!fighting || busy) return;

    energy = math.min(100, energy + t * 22);
    nextHero -= t;
    nextEnemy -= t;
    if (nextHero <= 0) {
      nextHero = 1.05 + _rng.nextDouble() * 0.35;
      // ignore: discarded_futures
      _attack(heroAttacks: true);
    } else if (nextEnemy <= 0) {
      nextEnemy = 1.25 + _rng.nextDouble() * 0.45;
      // ignore: discarded_futures
      _attack(heroAttacks: false);
    }
  }

  Future<void> _attack({required bool heroAttacks}) async {
    if (done || busy || !fighting) return;
    busy = true;
    final atk = heroAttacks ? hero : enemy;
    final def = heroAttacks ? enemy : hero;

    // ignore: unawaited_futures
    atk.playAttack(duration: 0.48 / speed);

    await Future<void>.delayed(Duration(milliseconds: (200 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    await _playImpact(towardEnemy: heroAttacks);

    var dmg =
        (heroAttacks ? 10 + _rng.nextDouble() * 8 : 7 + _rng.nextDouble() * 6);
    if (heroAttacks && ultNext) {
      dmg *= 2.4;
      ultNext = false;
    }

    if (heroAttacks) {
      enemyHp = math.max(0, enemyHp - dmg);
      onToast('Каэрон бьёт · −${dmg.round()}');
    } else {
      heroHp = math.max(0, heroHp - dmg);
      onToast('Печать отвечает · −${dmg.round()}');
    }

    // ignore: unawaited_futures
    def.playHurt(duration: 0.35 / speed);

    if (enemyHp <= 0 || heroHp <= 0) {
      final won = enemyHp <= 0;
      done = true;
      fighting = false;
      await def.playDeath(duration: 0.85 / speed);
      onFinished(won);
      busy = false;
      return;
    }

    await Future<void>.delayed(Duration(milliseconds: (280 / speed).round()));
    busy = false;
  }

  Future<void> _playImpact({required bool towardEnemy}) async {
    final impact = towardEnemy
        ? Vector2(size.x * 0.62, size.y * 0.52)
        : Vector2(size.x * 0.38, size.y * 0.52);

    slashFx.position = impact + Vector2(towardEnemy ? -40 : 40, 0);
    slashFx.scale = Vector2(towardEnemy ? 1 : -1, 1);
    slashFx.opacity = 1;
    burstFx.position = impact;
    burstFx.opacity = 1;

    final slashFxAnim = SequenceEffect([
      ScaleEffect.by(Vector2.all(1.15), EffectController(duration: 0.18)),
      OpacityEffect.to(0, EffectController(duration: 0.2)),
    ]);
    final burstFxAnim = SequenceEffect([
      ScaleEffect.by(Vector2.all(1.25), EffectController(duration: 0.16)),
      OpacityEffect.to(0, EffectController(duration: 0.22)),
    ]);
    await slashFx.add(slashFxAnim);
    await burstFx.add(burstFxAnim);

    final color =
        towardEnemy ? const Color(0xFF4ECDC4) : const Color(0xFFE35D6A);
    add(
      ParticleSystemComponent(
        priority: 30,
        position: impact,
        particle: Particle.generate(
          count: 22,
          lifespan: 0.45,
          generator: (i) {
            final a = _rng.nextDouble() * math.pi * 2;
            final sp = 80 + _rng.nextDouble() * 160;
            return AcceleratedParticle(
              acceleration: Vector2(0, 220),
              speed: Vector2(math.cos(a) * sp, math.sin(a) * sp - 50),
              child: CircleParticle(
                radius: 2 + _rng.nextDouble() * 3,
                paint: Paint()..color = color,
              ),
            );
          },
        ),
      ),
    );

    final shake = SequenceEffect([
      MoveByEffect(Vector2(-4, 2), EffectController(duration: 0.05)),
      MoveByEffect(Vector2(9, -4), EffectController(duration: 0.05)),
      MoveByEffect(Vector2(-7, 2), EffectController(duration: 0.05)),
      MoveByEffect(Vector2(2, 0), EffectController(duration: 0.05)),
    ]);
    await camera.viewfinder.add(shake);

    await Future.wait([
      slashFxAnim.completed,
      burstFxAnim.completed,
      shake.completed,
    ]);
  }
}

class ArenaHud extends PositionComponent with HasGameReference<ArenaGame> {
  @override
  Future<void> onLoad() async {
    size = game.size.clone();
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    _bar(
      canvas,
      Rect.fromLTWH(12, 18, size.x * 0.34, 42),
      'Каэрон',
      g.heroHp / g.heroMax,
      const Color(0xFF5DCEA0),
      alignRight: false,
    );
    _bar(
      canvas,
      Rect.fromLTWH(size.x - 12 - size.x * 0.34, 18, size.x * 0.34, 42),
      'Живая Печать',
      g.enemyHp / g.enemyMax,
      const Color(0xFFE35D6A),
      alignRight: true,
    );

    final sec = g.elapsed.floor();
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    final tp = TextPainter(
      text: TextSpan(
        text: '$mm:$ss',
        style: const TextStyle(
          color: Color(0xFFF3EEE4),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final timerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.x / 2, 36),
        width: tp.width + 20,
        height: 32,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      timerRect,
      Paint()..color = const Color(0xCC0E1422),
    );
    tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, 36 - tp.height / 2));
  }

  void _bar(
    Canvas canvas,
    Rect rect,
    String name,
    double pct,
    Color fill, {
    required bool alignRight,
  }) {
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(r, Paint()..color = const Color(0xD10E1422));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x40C9A227),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Color(0xFFF3EEE4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16);
    tp.paint(
      canvas,
      Offset(
        alignRight ? rect.right - 10 - tp.width : rect.left + 10,
        rect.top + 7,
      ),
    );

    final bar =
        Rect.fromLTWH(rect.left + 10, rect.bottom - 14, rect.width - 20, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(99)),
      Paint()..color = const Color(0xFF111827),
    );
    final w = bar.width * pct.clamp(0, 1);
    final fillRect = alignRight
        ? Rect.fromLTWH(bar.right - w, bar.top, w, bar.height)
        : Rect.fromLTWH(bar.left, bar.top, w, bar.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, const Radius.circular(99)),
      Paint()..color = fill,
    );
  }
}
