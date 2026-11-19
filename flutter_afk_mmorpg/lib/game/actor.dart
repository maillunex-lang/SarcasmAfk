import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

enum ActorPose { idle, run, attack }

class Actor extends PositionComponent {
  Actor({
    required this.idle,
    required this.run,
    required this.attack,
    required Vector2 home,
    required this.faceRight,
    required this.displaySize,
  }) : homePosition = home.clone() {
    position = home.clone();
    size = displaySize.clone();
    anchor = Anchor.bottomCenter;
  }

  final Sprite idle;
  final Sprite run;
  final Sprite attack;
  final Vector2 homePosition;
  final bool faceRight;
  final Vector2 displaySize;

  late final SpriteComponent body = SpriteComponent(
    sprite: idle,
    size: displaySize.clone(),
    anchor: Anchor.bottomCenter,
    position: Vector2(displaySize.x / 2, displaySize.y),
  );

  ActorPose pose = ActorPose.idle;
  bool dead = false;
  double _bobT = 0;
  double _runT = 0;
  bool _bobbing = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!faceRight && body.scale.x > 0) {
      body.flipHorizontally();
    }
    await add(body);
  }

  void resetVisual() {
    dead = false;
    pose = ActorPose.idle;
    body.sprite = idle;
    body.opacity = 1;
    body.angle = 0;
    body.scale.setValues(faceRight ? 1 : -1, 1);
    body.position = Vector2(size.x / 2, size.y);
    position = homePosition.clone();
    setBobbing(false);
  }

  void setPose(ActorPose next) {
    if (dead || pose == next) return;
    pose = next;
    body.sprite = switch (next) {
      ActorPose.idle => idle,
      ActorPose.run => run,
      ActorPose.attack => attack,
    };
  }

  void setBobbing(bool on) {
    _bobbing = on;
    if (!on) {
      body.position = Vector2(size.x / 2, size.y);
      body.angle = 0;
    }
  }

  Future<void> enterFromOffscreen({required double duration}) async {
    setPose(ActorPose.run);
    setBobbing(true);
    final start = homePosition.clone()
      ..x += faceRight ? -size.x * 1.8 : size.x * 1.8;
    position = start;
    final move = MoveToEffect(
      homePosition.clone(),
      EffectController(duration: duration, curve: Curves.easeOutCubic),
    );
    await add(move);
    await move.completed;
    if (!dead) {
      setPose(ActorPose.idle);
      setBobbing(true);
    }
  }

  Future<void> playCast({required double duration}) async {
    if (dead) return;
    setBobbing(false);
    setPose(ActorPose.attack);
    final wind = faceRight ? -10.0 : 10.0;
    final push = faceRight ? 18.0 : -18.0;
    final fx = SequenceEffect([
      MoveByEffect(
        Vector2(wind, 4),
        EffectController(duration: duration * 0.25, curve: Curves.easeOut),
      ),
      MoveByEffect(
        Vector2(push - wind, -8),
        EffectController(duration: duration * 0.3, curve: Curves.easeOut),
      ),
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: duration * 0.45, curve: Curves.easeInOut),
      ),
    ]);
    await add(fx);
    await fx.completed;
    if (!dead) {
      setPose(ActorPose.idle);
      setBobbing(true);
    }
  }

  Future<void> playMeleeLunge({required double duration}) async {
    if (dead) return;
    setBobbing(false);
    setPose(ActorPose.attack);
    final lunge = faceRight ? size.x * 0.7 : -size.x * 0.7;
    final fx = SequenceEffect([
      MoveByEffect(
        Vector2(lunge, -10),
        EffectController(duration: duration * 0.35, curve: Curves.easeOut),
      ),
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: duration * 0.65, curve: Curves.easeInOut),
      ),
    ]);
    await add(fx);
    await fx.completed;
    if (!dead) {
      setPose(ActorPose.idle);
      setBobbing(true);
    }
  }

  Future<void> playHurt({required double duration}) async {
    if (dead) return;
    setBobbing(false);
    final knock = faceRight ? -22.0 : 22.0;
    final move = SequenceEffect([
      MoveByEffect(
        Vector2(knock, 4),
        EffectController(duration: duration * 0.35),
      ),
      MoveToEffect(
        homePosition.clone(),
        EffectController(duration: duration * 0.65),
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
    final fallX = faceRight ? -36.0 : 36.0;
    final rot = faceRight ? -0.85 : 0.85;
    final move = MoveByEffect(
      Vector2(fallX, 70),
      EffectController(duration: duration, curve: Curves.easeIn),
    );
    final spin = RotateEffect.by(rot, EffectController(duration: duration));
    final fade = OpacityEffect.to(0, EffectController(duration: duration));
    await add(move);
    await body.addAll([spin, fade]);
    await Future.wait([move.completed, spin.completed, fade.completed]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead || !_bobbing) return;
    if (pose == ActorPose.run) {
      _runT += dt * 13;
      final bounce = math.sin(_runT).abs() * 9;
      body.position = Vector2(size.x / 2, size.y - bounce);
      body.angle = (faceRight ? 1 : -1) * math.sin(_runT) * 0.05;
    } else {
      _bobT += dt;
      body.position = Vector2(size.x / 2, size.y + math.sin(_bobT * 2.1) * 5);
      body.angle = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final shadow = Paint()
      ..color = const Color(0x88000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y + 3),
        width: size.x * 0.55,
        height: 12,
      ),
      shadow,
    );
    super.render(canvas);
  }
}
