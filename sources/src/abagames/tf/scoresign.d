/*
 * $Id: scoresign.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.scoresign;

private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.tf.letterrender;

/**
 * Score sign.
 */
public class ScoreSign: Actor {
 private:
  Vector pos;
  float my;
  float size;
  int num;
  int cnt;

  public override Actor newActor() {
    return new ScoreSign;
  }

  public override void init(ActorInitializer ini) {
    pos = new Vector;
  }

  private static const float FIELD_X = 14.5;

  public void set(Vector p, int n, float s) {
    pos.x = p.x;
    pos.y = p.y;
    if (pos.x > FIELD_X - s * 2)
      pos.x = FIELD_X - s * 2;
    num = n;
    size = s;
    my = 0.3;
    cnt = 60;
    isExist = true;
  }

  public override void move() {
    cnt--;
    if (cnt < 0) {
      isExist = false;
      return;
    }
    pos.y += my;
    my *= 0.92;
  }

  public override void draw() {
    LetterRender.drawNumSign(num, pos.x, pos.y, size, 3);
  }
}

public class ScoreSignInitializer: ActorInitializer {
}
