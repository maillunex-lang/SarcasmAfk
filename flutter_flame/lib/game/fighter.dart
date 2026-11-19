import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

enum FighterPose { idle, run, attack }

enum FighterSide { hero, enemy }

class Fighter extends PositionComponent {
  Fighter({
    required this.side,
    required this.idle,
    required this.run,
    required this.attack,
    required Vector2 home,
    required this.faceRight,
  }) : homePosition = home.clone() {
    position = home.clone();
    anchor = Anchor.bottomCenter;
  }

  final FighterSide side;
  final Sprite idle;
  final Sprite run;
  final Sprite attack;
  final Vector2 homePosition;
  final bool faceRight;

  late final SpriteComponent body = SpriteComponent(
    sprite: idle,
    size: Vector2(160, 210),
    anchor: Anchor.bottomCenter,
    position: Vector2(80, 210),
  );
  FighterPose pose = FighterPose.idle;
  bool dead = false;

  double _bobT = 0;
  double _runT = 0;
  bool _bobbing = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(160, 210);
    if (!faceRight && body.scale.x > 0) {
      body.flipHorizontally();
    }
    await add(body);
  }

  void resetVisual() {
    dead = false;
    pose = FighterPose.idle;
    body.sprite = idle;
    body.opacity = 1;
    body.angle = 0;
    body.scale.setValues(faceRight ? 1 : -1, 1);
    body.position = Vector2(size.x / 2, size.y);
    position = homePosition.clone();
    setBobbing(false);
  }

  void setPose(FighterPose next) {
    if (dead || pose == next) return;
    pose = next;
    body.sprite = switch (next) {
      FighterPose.idle => idle,
      FighterPose.run => run,
      FighterPose.attack => attack,
    };
  }

  void setBobbing(bool on) {
    _bobbing = on;
    if (!on) {
      body.position = Vector2(size.x / 2, size.y);
      body.angle = 0;
      body.scale.setValues(1, 1);
    }
  }

  Future<void> enterFromOffscreen({required double duration}) async {
    setPose(FighterPose.run);
    setBobbing(true);
    final start = homePosition.clone();
    start.x += faceRight ? -size.x * 1.6 : size.x * 1.6;
    position = start;
    final controller =
        EffectController(duration: duration, curve: Curves.easeOutCubic);
    final effect = MoveToEffect(homePosition.clone(), controller);
    await add(effect);
    await effect.completed;
    if (!dead) {
      setPose(FighterPose.idle);
      setBobbing(true);
    }
  }

  Future<void> playAttack({required double duration}) async {
    if (dead) return;
    setBobbing(false);
    setPose(FighterPose.attack);
    final lunge = faceRight ? size.x * 0.85 : -size.x * 0.85;
    final windup = faceRight ? -18.0 : 18.0;
    final effect = SequenceEffect([
      MoveByEffect(
        Vector2(windup, 8),
        EffectController(duration: duration * 0.22, curve: Curves.easeOut),
      ),
      MoveByEffect(
        Vector2(lunge - windup, -18),
        EffectController(duration: duration * 0.28, curve: Curves.easeOut),
      ),
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: duration * 0.5, curve: Curves.easeInOut),
      ),
    ]);
    await add(effect);
    await effect.completed;
    if (!dead) {
      setPose(FighterPose.idle);
      setBobbing(true);
    }
  }

  Future<void> playHurt({required double duration}) async {
    if (dead) return;
    setBobbing(false);
    final knock = faceRight ? -28.0 : 28.0;
    final move = SequenceEffect([
      MoveByEffect(
        Vector2(knock, 6),
        EffectController(duration: duration * 0.35, curve: Curves.easeOut),
      ),
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: duration * 0.65, curve: Curves.easeOut),
      ),
    ]);
    final flash = SequenceEffect([
      OpacityEffect.to(0.35, EffectController(duration: duration * 0.2)),
      OpacityEffect.to(1, EffectController(duration: duration * 0.8)),
    ]);
    await add(move);
    await body.add(flash);
    await Future.wait([move.completed, flash.completed]);
    if (!dead) setBobbing(true);
  }

  Future<void> playDeath({required double duration}) async {
    dead = true;
    setBobbing(false);
    final fallX = faceRight ? -40.0 : 40.0;
    final rot = faceRight ? -0.9 : 0.9;
    final move = MoveByEffect(
      Vector2(fallX, 80),
      EffectController(duration: duration, curve: Curves.easeIn),
    );
    final spin = RotateEffect.by(rot, EffectController(duration: duration));
    final fade = OpacityEffect.to(0, EffectController(duration: duration));
    await add(move);
    await body.add(spin);
    await body.add(fade);
    await Future.wait([move.completed, spin.completed, fade.completed]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead || !_bobbing) return;
    if (pose == FighterPose.run) {
      _runT += dt * 14;
      final bounce = math.sin(_runT).abs() * 10;
      final tilt = math.sin(_runT) * 0.05;
      body.position = Vector2(size.x / 2, size.y - bounce);
      body.angle = faceRight ? tilt : -tilt;
      body.scale.setValues(1, 1 - bounce * 0.004);
    } else {
      _bobT += dt;
      final y = math.sin(_bobT * 2.2) * 6;
      body.position = Vector2(size.x / 2, size.y + y);
      body.angle = 0;
      body.scale.setValues(1, 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final shadow = Paint()
      ..color = const Color(0x80000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 4),
        width: size.x * 0.55,
        height: 14,
      ),
      shadow,
    );
    super.render(canvas);
  }
}
