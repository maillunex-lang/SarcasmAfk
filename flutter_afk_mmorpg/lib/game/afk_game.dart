import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'actor.dart';
import 'projectiles.dart';
import 'roster.dart';

typedef ToastCallback = void Function(String text);
typedef FinishedCallback = void Function(bool won);

class AfkGame extends FlameGame {
  AfkGame({
    required this.heroKit,
    required this.enemyKit,
    required this.onToast,
    required this.onFinished,
  });

  final FighterKit heroKit;
  final FighterKit enemyKit;
  final ToastCallback onToast;
  final FinishedCallback onFinished;

  late Actor hero;
  late Actor foe;
  late Sprite iceSprite;
  late Sprite fireSprite;
  late Sprite boomSprite;

  double speed = 1;
  double elapsed = 0;
  double nextHeroAtk = 999;
  double nextEnemyAtk = 999;
  double ultCd = 0;
  bool done = false;
  bool fighting = false;
  bool busy = false;

  double heroHp = 120;
  double foeHp = 140;
  final double heroMax = 120;
  final double foeMax = 140;

  final _rng = math.Random();

  bool get heroIsMage => !heroKit.melee;

  @override
  Color backgroundColor() => const Color(0xFF0A0810);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'arena_bg.jpg',
      'ice_icicle.png',
      'fireball.png',
      'explosion.png',
    ]);

    await add(
      SpriteComponent(
        sprite: Sprite(images.fromCache('arena_bg.jpg')),
        size: size.clone(),
        priority: 0,
      ),
    );

    iceSprite = Sprite(images.fromCache('ice_icicle.png'));
    fireSprite = Sprite(images.fromCache('fireball.png'));
    boomSprite = Sprite(images.fromCache('explosion.png'));

    final groundY = size.y * 0.78;
    final heroIdle = await loadAnim(heroKit.idle);
    final heroRun = await loadAnim(heroKit.run);
    final heroAtk = await loadAnim(heroKit.attack);
    final foeIdle = await loadAnim(enemyKit.idle);
    final foeRun = await loadAnim(enemyKit.run);
    final foeAtk = await loadAnim(enemyKit.attack);

    hero = Actor(
      idleAnim: heroIdle,
      runAnim: heroRun,
      attackAnim: heroAtk,
      home: Vector2(size.x * 0.28, groundY),
      faceRight: true,
      displaySize: heroKit.displaySize.clone(),
    )..priority = 10;

    foe = Actor(
      idleAnim: foeIdle,
      runAnim: foeRun,
      attackAnim: foeAtk,
      home: Vector2(size.x * 0.72, groundY),
      faceRight: false,
      displaySize: enemyKit.displaySize.clone(),
    )..priority = 10;

    await addAll([hero, foe]);
    await add(AfkHud()..priority = 80);
    await _startRound();
  }

  Future<void> _startRound() async {
    done = false;
    fighting = false;
    busy = true;
    elapsed = 0;
    ultCd = 0;
    heroHp = heroMax;
    foeHp = foeMax;
    nextHeroAtk = 999;
    nextEnemyAtk = 999;
    onToast('Сближение…');

    hero.resetVisual();
    foe.resetVisual();

    await Future.wait([
      hero.enterFromOffscreen(duration: 1.1 / speed),
      foe.enterFromOffscreen(duration: 1.1 / speed),
    ]);

    fighting = true;
    busy = false;
    nextHeroAtk = 0.7;
    nextEnemyAtk = 1.2;
    ultCd = 2.5;
    onToast('Автобой · AFK');
  }

  void restart({double speed = 1}) {
    this.speed = speed;
    // ignore: discarded_futures
    _startRound();
  }

  void setSpeed(double s) => speed = s;

  void castUlt() {
    if (!fighting || done || busy) return;
    if (ultCd > 0) {
      onToast('Ульт · ${ultCd.toStringAsFixed(1)}с');
      return;
    }
    // ignore: discarded_futures
    if (heroIsMage) {
      _heroFireball();
    } else {
      _heroHeavySlash();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = dt * speed;
    if (done) return;
    elapsed += t;
    if (!fighting || busy) return;

    ultCd = math.max(0, ultCd - t);
    nextHeroAtk -= t;
    nextEnemyAtk -= t;

    if (nextHeroAtk <= 0) {
      nextHeroAtk = 1.15 + _rng.nextDouble() * 0.4;
      // ignore: discarded_futures
      if (heroIsMage) {
        _heroIce();
      } else {
        _heroSlash();
      }
    } else if (nextEnemyAtk <= 0) {
      nextEnemyAtk = 1.35 + _rng.nextDouble() * 0.45;
      // ignore: discarded_futures
      _enemyBite();
    }

    if (ultCd <= 0 && !busy && _rng.nextDouble() < 0.012) {
      // ignore: discarded_futures
      if (heroIsMage) {
        _heroFireball();
      } else {
        _heroHeavySlash();
      }
    }
  }

  Future<void> _heroIce() async {
    if (done || busy || !fighting || hero.dead || foe.dead) return;
    busy = true;
    // ignore: unawaited_futures
    hero.playCast(duration: 0.42 / speed);

    await Future<void>.delayed(Duration(milliseconds: (160 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    final start = hero.position + Vector2(40, -110);
    final target = foe.position + Vector2(-20, -70);
    await add(
      IceIcicle(
        sprite: iceSprite,
        start: start,
        target: target,
        onHit: (at) {
          add(IceShatter(at: at));
          _damageFoe(14 + _rng.nextDouble() * 8, 'Сосулька');
          // ignore: discarded_futures
          foe.playHurt(duration: 0.32 / speed);
          _shake();
        },
      ),
    );

    await Future<void>.delayed(Duration(milliseconds: (420 / speed).round()));
    busy = false;
  }

  Future<void> _heroFireball() async {
    if (done || busy || !fighting || hero.dead || foe.dead) return;
    busy = true;
    ultCd = 5.5;
    onToast('Огненный шар!');
    // ignore: unawaited_futures
    hero.playCast(duration: 0.5 / speed);

    await Future<void>.delayed(Duration(milliseconds: (180 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    final start = hero.position + Vector2(30, -120);
    final target = foe.position + Vector2(-10, -80);
    await add(
      Fireball(
        sprite: fireSprite,
        start: start,
        target: target,
        onHit: (at) {
          add(ExplosionBurst(sprite: boomSprite, at: at));
          _damageFoe(28 + _rng.nextDouble() * 12, 'Огненный шар');
          // ignore: discarded_futures
          foe.playHurt(duration: 0.4 / speed);
          _shake(strong: true);
        },
      ),
    );

    await Future<void>.delayed(Duration(milliseconds: (700 / speed).round()));
    busy = false;
  }

  Future<void> _heroSlash() async {
    if (done || busy || !fighting || hero.dead || foe.dead) return;
    busy = true;
    // ignore: unawaited_futures
    hero.playMeleeLunge(duration: 0.48 / speed);

    await Future<void>.delayed(Duration(milliseconds: (170 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    _damageFoe(16 + _rng.nextDouble() * 8, 'Удар');
    // ignore: discarded_futures
    foe.playHurt(duration: 0.32 / speed);
    _shake();

    await Future<void>.delayed(Duration(milliseconds: (320 / speed).round()));
    busy = false;
  }

  Future<void> _heroHeavySlash() async {
    if (done || busy || !fighting || hero.dead || foe.dead) return;
    busy = true;
    ultCd = 5.5;
    onToast('Мощный удар!');
    // ignore: unawaited_futures
    hero.playMeleeLunge(duration: 0.55 / speed);

    await Future<void>.delayed(Duration(milliseconds: (200 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    _damageFoe(30 + _rng.nextDouble() * 12, 'Мощный удар');
    // ignore: discarded_futures
    foe.playHurt(duration: 0.4 / speed);
    _shake(strong: true);

    await Future<void>.delayed(Duration(milliseconds: (380 / speed).round()));
    busy = false;
  }

  Future<void> _enemyBite() async {
    if (done || busy || !fighting || hero.dead || foe.dead) return;
    busy = true;
    // ignore: unawaited_futures
    foe.playMeleeLunge(duration: 0.48 / speed);

    await Future<void>.delayed(Duration(milliseconds: (180 / speed).round()));
    if (done) {
      busy = false;
      return;
    }

    final dmg = 9 + _rng.nextDouble() * 7;
    heroHp = math.max(0, heroHp - dmg);
    onToast('${enemyKit.name} бьёт · −${dmg.round()}');
    // ignore: unawaited_futures
    hero.playHurt(duration: 0.34 / speed);
    _shake();

    if (heroHp <= 0) {
      done = true;
      fighting = false;
      await hero.playDeath(duration: 0.85 / speed);
      onFinished(false);
      busy = false;
      return;
    }

    await Future<void>.delayed(Duration(milliseconds: (320 / speed).round()));
    busy = false;
  }

  void _damageFoe(double dmg, String label) {
    if (done) return;
    foeHp = math.max(0, foeHp - dmg);
    onToast('$label · −${dmg.round()}');
    if (foeHp <= 0 && !done) {
      done = true;
      fighting = false;
      // ignore: discarded_futures
      () async {
        await foe.playDeath(duration: 0.85 / speed);
        onFinished(true);
        busy = false;
      }();
    }
  }

  void _shake({bool strong = false}) {
    final a = strong ? 7.0 : 4.0;
    camera.viewfinder.add(
      SequenceEffect([
        MoveByEffect(Vector2(-a, 2), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(a * 2, -3), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(-a, 2), EffectController(duration: 0.04)),
        MoveByEffect(Vector2(a * 0.3, 0), EffectController(duration: 0.04)),
      ]),
    );
  }
}

class AfkHud extends PositionComponent with HasGameReference<AfkGame> {
  @override
  Future<void> onLoad() async {
    size = game.size.clone();
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    _bar(
      canvas,
      Rect.fromLTWH(12, 16, size.x * 0.36, 44),
      g.heroKit.name,
      g.heroHp / g.heroMax,
      const Color(0xFF6EC8FF),
      alignRight: false,
    );
    _bar(
      canvas,
      Rect.fromLTWH(size.x - 12 - size.x * 0.36, 16, size.x * 0.36, 44),
      g.enemyKit.name,
      g.foeHp / g.foeMax,
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
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.x / 2, 34),
          width: tp.width + 18,
          height: 30,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xCC120E18),
    );
    tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, 34 - tp.height / 2));

    final cd = g.ultCd;
    final cdText = cd <= 0 ? 'ULT готов' : 'ULT ${cd.toStringAsFixed(1)}с';
    final cdp = TextPainter(
      text: TextSpan(
        text: cdText,
        style: TextStyle(
          color: cd <= 0 ? const Color(0xFFFFB07A) : const Color(0xFF9A90A4),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cdp.paint(canvas, Offset(size.x / 2 - cdp.width / 2, 58));
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
    canvas.drawRRect(r, Paint()..color = const Color(0xD1120E18));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x55C45C26),
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
      Paint()..color = const Color(0xFF1A1520),
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
