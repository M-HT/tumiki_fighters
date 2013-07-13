/*
 * $Id: particle.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.particle;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.tf.screen;

/**
 * Particles(smoke and spark).
 */
public class Particle: Actor {
 public:
  static enum TypeName {
    SMOKE, SPARK
  }
 private:
  static Rand rand;
  Vector pos;
  Vector vel;
  float alpha;
  float size;
  int type;
  int cnt;

  public static void initRand() {
    rand = new Rand;
  }

  public override Actor newActor() {
    return new Particle;
  }

  public override void init(ActorInitializer ini) {
    pos = new Vector;
    vel = new Vector;
  }

  public void set(Vector p, float deg, float od, float speed, float s, int t) {
    pos.x = p.x;
    pos.y = p.y;
    float sb = rand.nextFloat(0.5) + 0.75;
    float d = deg + rand.nextSignedFloat(od);
    vel.x = -sin(d) * speed * sb;
    vel.y = -cos(d) * speed * sb;
    cnt = 16 + rand.nextInt(16);
    alpha = 0.8 + rand.nextFloat(0.2);
    sb = rand.nextFloat(0.5) + 0.75;
    size = s * sb;
    type = t;
    isExist = true;
  }

  public override void move() {
    cnt--;
    if (cnt < 0) {
      isExist = false;
      return;
    }
    pos.add(vel);
    vel.mul(0.9);
    alpha *= 0.9;
    switch (type) {
    case TypeName.SMOKE:
      size *= 1.025;
      break;
    case TypeName.SPARK:
      size *= 1.01;
      break;
    default:
      break;
    }
  }

  public override void draw() {
    switch (type) {
    case TypeName.SMOKE:
      Screen.setColor(0.8, 0.8, 0.8, alpha);
      break;
    case TypeName.SPARK:
      if ((cnt & 1) == 0)
	Screen.setColor(1, 0.4, 0.2, alpha);
      else
	Screen.setColor(1, 1, 0.1, alpha);
      break;
    default:
      break;
    }
    glVertex3f(pos.x - size, pos.y - size, 0);
    glVertex3f(pos.x + size, pos.y - size, 0);
    glVertex3f(pos.x + size, pos.y + size, 0);
    glVertex3f(pos.x - size, pos.y + size, 0);
  }
}

public class ParticleInitializer: ActorInitializer {
}

public class ParticlePool: ActorPool {
 private:

  public this(int n, ActorInitializer ini) {
    scope Particle particleClass = new Particle;
    super(n, particleClass, ini);
  }

  public void add(int n, Vector pos, float deg, float degWdt, float speed, float size, int type) {
    for (int i = 0; i < n; i++) {
      Particle p = cast(Particle) getInstanceForced();
      p.set(pos, deg, degWdt, speed, size, type);
    }
  }
}
