/*
 * $Id: bulletactorpool.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.tf.bulletactorpool;

private import std.math;
private import bulletml;
private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.util.bulletml.bullet;
private import abagames.util.bulletml.bulletsmanager;
private import abagames.tf.bulletinst;
private import abagames.tf.bulletactor;
private import abagames.tf.bullettarget;
private import abagames.tf.enemy;
private import abagames.tf.stagemanager;
private import abagames.tf.stuckenemy;

/**
 * Bullet actor pool that works as the BulletsManager.
 */
//public class BulletActorPool: ActorPool, BulletsManager {
public class BulletActorPool: BulletsManager {
 private:
  int cnt;

  public this(int n, ActorInitializer ini) {
    scope BulletActor bulletActorClass = new BulletActor;
    super(n, bulletActorClass, ini);
    Bullet.setBulletsManager(this);
    BulletActor.init();
    cnt = 0;
  }

  public void setEnemies(EnemyPool enemies) {
    foreach (Actor a; actor)
      (cast(BulletActor) a).setEnemies(enemies);
  }

  public void setStageManager(StageManager stageManager) {
    foreach (Actor a; actor)
      (cast(BulletActor) a).setStageManager(stageManager);
  }

  public override void addBullet(float deg, float speed) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    BulletInst rb = cast(BulletInst) Bullet.now;
    if (rb.deactivated)
      return;
    int nmi = rb.morphIdx + 1;
    if (nmi < rb.morphNum) {
      BulletMLRunner *runner = BulletMLRunner_new_parser(rb.parser[nmi]);
      BulletActorPool.registFunctions(runner);
      ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     rb.ranks[nmi], rb.speeds[nmi],
	     rb.shape, rb.color, rb.bulletSize, rb.xReverse, rb.yReverse, rb.target, rb.type,
	     rb.parser, rb.ranks, rb.speeds, rb.morphNum, nmi);
      ba.setMorphSeed();
    } else {
      nmi--;
      ba.set(Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     rb.ranks[nmi], rb.speeds[nmi],
	     rb.shape, rb.color, rb.bulletSize, rb.xReverse, rb.yReverse, rb.target, rb.type);
    }
  }

  public override void addBullet(BulletMLState *state, float deg, float speed) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    BulletInst rb = cast(BulletInst) Bullet.now;
    if (rb.deactivated)
      return;
    BulletMLRunner* runner = BulletMLRunner_new_state(state);
    registFunctions(runner);
    ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	   rb.ranks[rb.morphIdx], rb.speeds[rb.morphIdx],
	   rb.shape, rb.color, rb.bulletSize, rb.xReverse, rb.yReverse, rb.target, rb.type,
	   rb.parser, rb.ranks, rb.speeds, rb.morphNum, rb.morphIdx);
  }

  public BulletActor addTopBullet(BulletMLParser *parser[],
				  float[] ranks, float[] speeds,
				  float x, float y, float deg, float speed,
				  int shape, int color, float size,
				  float xReverse, float yReverse,
				  BulletTarget target, int type,
				  int prevWait, int postWait) {
    BulletMLRunner *runner = BulletMLRunner_new_parser(parser[0]);
    BulletActorPool.registFunctions(runner);
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return null;
    ba.set(runner, x, y, deg, speed,
	   ranks[0], speeds[0],
	   shape, color, size, xReverse, yReverse, target, type,
	   parser, ranks, speeds, cast(int)(parser.length), 0);
    ba.setWait(prevWait, postWait);
    ba.setTop();
    return ba;
  }

  public BulletActor addMoveBullet(BulletMLParser *parser, float speed,
				   float x, float y, float deg, BulletTarget target) {
    BulletMLRunner *runner = BulletMLRunner_new_parser(parser);
    BulletActorPool.registFunctions(runner);
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return null;
    ba.set(runner, x, y, deg, 0,
	   0, speed,
	   0, 0, 0, 1, 1, target, BulletInst.Type.MOVE,
	   null, null, null, 0, 0);
    ba.setInvisible();
    return ba;
  }

  public override void move() {
    super.move();
    cnt++;
  }

  public void drawShots() {
    foreach (Actor ac; actor)
      if (ac.isExist) {
	BulletActor ba = cast(BulletActor) ac;
	if (ba.bullet.type == BulletInst.Type.SHIP)
	  ac.draw();
      }
  }

  public void drawBullets() {
    foreach (Actor ac; actor)
      if (ac.isExist) {
	BulletActor ba = cast(BulletActor) ac;
	if (ba.bullet.type == BulletInst.Type.ENEMY)
	  ac.draw();
      }
  }

  public override int getTurn() {
    return cnt;
  }

  public override void killMe(Bullet bullet) {
    assert((cast(BulletActor) actor[bullet.id]).bullet.id == bullet.id);
    (cast(BulletActor) actor[bullet.id]).remove();
  }

  public override void clear() {
    foreach (Actor ac; actor) {
      if (ac.isExist)
	(cast(BulletActor) ac).removeForced();
    }
  }

  public void clearVisible() {
    foreach (Actor ac; actor) {
      if (ac.isExist)
	(cast(BulletActor) ac).removeForcedVisible();
    }
  }

  public void clearVisibleEnemy() {
    foreach (Actor ac; actor) {
      if (ac.isExist)
	(cast(BulletActor) ac).removeForcedVisibleEnemy();
    }
  }

  public void clearStuckEnemyHit(StuckEnemy se) {
    se.setWideCollision();
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	BulletActor ba = cast(BulletActor) ac;
	if (se.checkHit(ba.bullet.pos)) {
	  ba.removeForcedVisible();
	}
      }
    }
  }

  public static void registFunctions(BulletMLRunner* runner) {
    BulletMLRunner_set_getBulletDirection(runner, &getBulletDirection_);
    BulletMLRunner_set_getAimDirection(runner, &getAimDirectionWithYRev_);
    BulletMLRunner_set_getBulletSpeed(runner, &getBulletSpeed_);
    BulletMLRunner_set_getDefaultSpeed(runner, &getDefaultSpeed_);
    BulletMLRunner_set_getRank(runner, &getRank_);
    BulletMLRunner_set_createSimpleBullet(runner, &createSimpleBullet_);
    BulletMLRunner_set_createBullet(runner, &createBullet_);
    BulletMLRunner_set_getTurn(runner, &getTurn_);
    BulletMLRunner_set_doVanish(runner, &doVanish_);

    BulletMLRunner_set_doChangeDirection(runner, &doChangeDirection_);
    BulletMLRunner_set_doChangeSpeed(runner, &doChangeSpeed_);
    BulletMLRunner_set_doAccelX(runner, &doAccelX_);
    BulletMLRunner_set_doAccelY(runner, &doAccelY_);
    BulletMLRunner_set_getBulletSpeedX(runner, &getBulletSpeedX_);
    BulletMLRunner_set_getBulletSpeedY(runner, &getBulletSpeedY_);
    BulletMLRunner_set_getRand(runner, &getRand_);
  }
}

extern (C) {
  double getAimDirectionWithYRev_(BulletMLRunner* r) {
    Vector b = Bullet.now.pos;
    Vector t = Bullet.target;
    float xrev = (cast(BulletInst) Bullet.now).xReverse;
    float yrev = (cast(BulletInst) Bullet.now).yReverse;
    return rtod((atan2(t.x - b.x, t.y - b.y) * xrev + PI / 2) * yrev - PI / 2);
  }
}
