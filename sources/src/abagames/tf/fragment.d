/*
 * $Id: fragment.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.fragment;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.actor;
private import abagames.tf.tumiki;

/**
 * Enemys' fragments.
 */
public class Fragment: Actor {
 private:
  static Rand rand;
  Vector pos;
  Vector vel;
  Vector size;
  float deg;
  float md;
  int shape, color;
  int cnt;

  public static this() {
    rand = new Rand;
  }

  public override Actor newActor() {
    return new Fragment;
  }

  public override void init(ActorInitializer ini) {
    pos = new Vector;
    vel = new Vector;
    size = new Vector;
  }

  public void set(int sh, int cl, float x, float y, Vector s) {
    shape = sh;
    color = cl;
    pos.x = x;
    pos.y = y;
    size.x = s.x;
    size.y = s.y;
    vel.x = rand.nextSignedFloat(0.2);
    vel.y = rand.nextSignedFloat(0.1);
    deg = 0;
    md = rand.nextSignedFloat(8);
    cnt = 32 + rand.nextInt(48);
    isExist = true;
  }

  private const float GRAVITY = 0.012;

  public override void move() {
    cnt--;
    if (cnt < 0) {
      isExist = false;
      return;
    }
    pos.add(vel);
    vel.y -= GRAVITY;
    deg += md;
  }

  public override void draw() {
    if (cnt < 16) {
      if ((cnt & 1) == 1)
	return;
    } else if (cnt < 32) {
      if ((cnt % 3) == 2)
	return;
    } else {
      if ((cnt % 4) == 3)
	return;
    }
    glPushMatrix();
    glTranslatef(pos.x, pos.y, -1);
    glRotatef(deg, 0, 0, 1);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    glCallList(Tumiki.displayListIdx + shape + color * Tumiki.SHAPE_NUM +
	       Tumiki.SHAPE_NUM * Tumiki.COLOR_NUM);
    glPopMatrix();
  }
}

public class FragmentInitializer: ActorInitializer {
}
