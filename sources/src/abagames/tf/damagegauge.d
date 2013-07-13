/*
 * $Id: damagegauge.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.damagegauge;

private import opengl;
private import abagames.tf.enemy;
private import abagames.tf.tumiki;
private import abagames.tf.tumikiset;

/**
 * Gauges that show the enemy part's damage.
 */
public class DamageGauge {
 private:
  int cnt;
  DamageGaugeItem[3] item;

  public this() {
    foreach (ref DamageGaugeItem dgi; item)
      dgi = new DamageGaugeItem;
  }

  public void init() {
    cnt = 0;
    foreach (DamageGaugeItem dgi; item)
      dgi.part = null;
  }

  public void add(EnemyPart ep) {
    int mc = int.max;
    DamageGaugeItem si = null;
    foreach (DamageGaugeItem dgi; item) {
      if (dgi.part) {
	if (dgi.part == ep) {
	  dgi.cnt = cnt;
	  return;
	}
	if (mc > dgi.cnt) {
	  si = dgi;
	  mc = dgi.cnt;
	}
      } else if (mc >= 0) {
	si = dgi;
	mc = int.min;
      }
    }
    si.part = ep;
    si.cnt = cnt;
  }

  public void move() {
    foreach (DamageGaugeItem dgi; item) {
      if (dgi.part) {
	if (dgi.part.shield <= 0) {
	  dgi.part = null;
	}
      }
    }
    cnt++;
  }

  public void draw() {
    float x = 18, y = -13;
    foreach (DamageGaugeItem dgi; item) {
      if (dgi.part) {
	TumikiSet ts = dgi.part.spec.tumikiSet;
	float s = 1 / ts.size * 3;
	float sx = x / s;
	float sy = y / s;
	glPushMatrix();
	glScalef(s, s, s);
	ts.draw(sx, sy, 0.9, false, false);
	glPopMatrix();
	float sl = dgi.part.shield;
	for (int i = 0; sl > 0; i++, sl -= 100) {
	  float sx2 = 11;
	  float slb = sl;
	  if (slb > 100)
	    slb = 100;
	  float sx1 = sx2 - slb / 10;
	  glPushMatrix();
	  glTranslatef(sx1 + sx2 / 2, y - 0.4, 1 + i * 0.1);
	  glScalef(sx2 - sx1, 0.4, 1);
	  glCallList(Tumiki.displayListIdx +
		     ((3 + i) % Tumiki.COLOR_NUM) * Tumiki.SHAPE_NUM +
		     3 * Tumiki.COLOR_NUM * Tumiki.SHAPE_NUM);
	  glPopMatrix();
	}
      }
      y += 1.8;
    }
  }

}

public class DamageGaugeItem {
 public:
  EnemyPart part;
  int cnt;
  int disapCnt;
}
