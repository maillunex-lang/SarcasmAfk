import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

typedef HitCallback = void Function(Vector2 at);

class IceIcicle extends SpriteComponent {
  IceIcicle({
    required Sprite sprite,
    required Vector2 start,
    required this.target,
    required this.onHit,
    this.speed = 420,
  }) : super(
          sprite: sprite,
          size: Vector2(90, 28),
          anchor: Anchor.center,
          position: start.clone(),
          priority: 25,
        );

  final Vector2 target;
  final HitCallback onHit;
  final double speed;
  bool _done = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final dir = (target - position).normalized();
    angle = math.atan2(dir.y, dir.x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;
    final to = target - position;
    final dist = to.length;
    final step = speed * dt;
    if (dist <= step) {
      position.setFrom(target);
      _impact();
      return;
    }
    position += to.normalized() * step;
  }

  void _impact() {
    if (_done) return;
    _done = true;
    onHit(position.clone());
    removeFromParent();
  }
}

class Fireball extends SpriteComponent {
  Fireball({
    required Sprite sprite,
    required Vector2 start,
    required this.target,
    required this.onHit,
    this.speed = 280,
  }) : super(
          sprite: sprite,
          size: Vector2(64, 48),
          anchor: Anchor.center,
          position: start.clone(),
          priority: 26,
        );

  final Vector2 target;
  final HitCallback onHit;
  final double speed;
  bool _done = false;
  double _sparkT = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final dir = (target - position).normalized();
    angle = math.atan2(dir.y, dir.x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;
    _sparkT += dt;
    if (_sparkT > 0.04 && parent != null) {
      _sparkT = 0;
      _spawnTrailSparks();
    }
    final to = target - position;
    final dist = to.length;
    final step = speed * dt;
    if (dist <= step) {
      position.setFrom(target);
      _impact();
      return;
    }
    position += to.normalized() * step;
  }

  void _spawnTrailSparks() {
    final rng = math.Random();
    parent!.add(
      ParticleSystemComponent(
        priority: 27,
        position: position.clone(),
        particle: Particle.generate(
          count: 4,
          lifespan: 0.28,
          generator: (i) {
            final a = rng.nextDouble() * math.pi * 2;
            final sp = 40 + rng.nextDouble() * 70;
            return AcceleratedParticle(
              acceleration: Vector2(0, 120),
              speed: Vector2(math.cos(a) * sp, math.sin(a) * sp),
              child: CircleParticle(
                radius: 1.2 + rng.nextDouble() * 2,
                paint: Paint()
                  ..color = Color.lerp(
                    const Color(0xFFFFF1A8),
                    const Color(0xFFFF6A2A),
                    rng.nextDouble(),
                  )!,
              ),
            );
          },
        ),
      ),
    );
  }

  void _impact() {
    if (_done) return;
    _done = true;
    onHit(position.clone());
    removeFromParent();
  }
}

class ExplosionBurst extends SpriteComponent {
  ExplosionBurst({
    required Sprite sprite,
    required Vector2 at,
  }) : super(
          sprite: sprite,
          size: Vector2(120, 120),
          anchor: Anchor.center,
          position: at.clone(),
          priority: 30,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    opacity = 1;
    final fx = SequenceEffect([
      ScaleEffect.by(
        Vector2.all(1.35),
        EffectController(duration: 0.18),
      ),
      OpacityEffect.to(0, EffectController(duration: 0.22)),
      RemoveEffect(),
    ]);
    await add(fx);

    final rng = math.Random();
    parent?.add(
      ParticleSystemComponent(
        priority: 31,
        position: position.clone(),
        particle: Particle.generate(
          count: 28,
          lifespan: 0.55,
          generator: (i) {
            final a = rng.nextDouble() * math.pi * 2;
            final sp = 90 + rng.nextDouble() * 180;
            return AcceleratedParticle(
              acceleration: Vector2(0, 260),
              speed: Vector2(math.cos(a) * sp, math.sin(a) * sp - 40),
              child: CircleParticle(
                radius: 1.5 + rng.nextDouble() * 3,
                paint: Paint()
                  ..color = Color.lerp(
                    const Color(0xFFFFE08A),
                    const Color(0xFFFF3B1A),
                    rng.nextDouble(),
                  )!,
              ),
            );
          },
        ),
      ),
    );
  }
}

class IceShatter extends ParticleSystemComponent {
  IceShatter({required Vector2 at})
      : super(
          priority: 29,
          position: at.clone(),
          particle: Particle.generate(
            count: 16,
            lifespan: 0.4,
            generator: (i) {
              final rng = math.Random();
              final a = rng.nextDouble() * math.pi * 2;
              final sp = 70 + rng.nextDouble() * 120;
              return AcceleratedParticle(
                acceleration: Vector2(0, 180),
                speed: Vector2(math.cos(a) * sp, math.sin(a) * sp - 30),
                child: CircleParticle(
                  radius: 1.5 + rng.nextDouble() * 2.5,
                  paint: Paint()
                    ..color = Color.lerp(
                      const Color(0xFFE8F7FF),
                      const Color(0xFF6EC8FF),
                      rng.nextDouble(),
                    )!,
                ),
              );
            },
          ),
        );
}
