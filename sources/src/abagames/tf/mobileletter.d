/*
 * $Id: mobileletter.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.mobileletter;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.tf.letterrender;
private import abagames.tf.field;

/**
 * Letters moves as a mobile.
 */
public class MobileLetter: Actor {
 private:
  static Rand rand;
  Vector pos;
  float deg;
  float md;
  Vector vel;
  Vector root;
  float length;
  int str;
  int color;
  float size;
  int cnt;

  public static void initRand() {
    rand = new Rand;
  }

  public override Actor newActor() {
    return new MobileLetter;
  }

  public override void init(ActorInitializer ini) {
    pos = new Vector;
    vel = new Vector;
    root = new Vector;
  }

  public void set(float px, float py, float rx, float ry,
		  float l, int st, int cl, float si, int cn) {
    pos.x = px;
    pos.y = py;
    root.x = rx;
    root.y = ry;
    length = l;
    vel.x = rand.nextSignedFloat(2.5);
    vel.y = rand.nextSignedFloat(1);
    str = st;
    color = cl;
    size = si;
    cnt = cn;
    deg = 0;
    md = rand.nextSignedFloat(10);
    isExist = true;
  }

  private static const float GRAVITY = 0.2;

  public override void move() {
    cnt--;
    if (cnt < 0) {
      pos.x += (root.x - pos.x) * 0.97;
      deg *= 0.95;
      pos.y -= 3;
      if (pos.y < root.y - size * LetterRender.LETTER_HEIGHT)
	isExist = false;
      return;
    }
    pos.add(vel);
    vel.y += GRAVITY;
    deg += md;
    deg *= 0.95;
    if (pos.dist(root) > length) {
      vel.mul(-0.57);
      md *= -0.4;
      pos.add(vel);
      pos.x += (root.x - pos.x) * 0.5;
    }
    deg *= 0.99;
  }

  public override void draw() {
    LetterRender.drawLetter(str, pos.x, pos.y, size, deg, color);
  }
}

public class MobileLetterInitializer: ActorInitializer {
}

public class MobileLetterPool: ActorPool {
 private:
  Field field;
  Rand rand;

  public this(int n, ActorInitializer ini, Field f) {
    field = f;
    scope MobileLetter mlClass = new MobileLetter;
    super(n, mlClass, ini);
    rand = new Rand;
  }

  public void add(string str, float x, float lgt, float size, int cnt, int col) {
    int color = col;
    if (col < 0)
      rand.setSeed(-col);
    foreach (char c; str) {
      MobileLetter ml = cast(MobileLetter) getInstance();
      if (!ml)
	return;
      if (c != ' ') {
	int idx = LetterRender.convertCharToInt(c);
	if (col < 0)
	  color = rand.nextInt(LetterRender.COLOR_NUM);
	ml.set(x, field.size.y, x, field.size.y, lgt, idx, color, size, cnt);
      }
      x += LetterRender.LETTER_WIDTH * size;
    }
  }
}

