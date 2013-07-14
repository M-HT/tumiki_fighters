/*
 * $Id: bulletactor.d,v 1.4 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.bulletactor;

private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import bulletml;
private import abagames.util.actor;
private import abagames.util.vector;
private import abagames.util.bulletml.bullet;
private import abagames.tf.field;
private import abagames.tf.bulletinst;
private import abagames.tf.bulletactorpool;
private import abagames.tf.enemy;
private import abagames.tf.ship;
private import abagames.tf.screen;
private import abagames.tf.tumiki;
private import abagames.tf.bullettarget;
private import abagames.tf.particle;
private import abagames.tf.splinter;
private import abagames.tf.soundmanager;
private import abagames.tf.stuckenemy;
private import abagames.tf.stagemanager;

/**
 * Actor of the bullet.
 */
public class BulletActor: Actor {
 public:
  static float totalBulletsSpeed;
  BulletInst bullet;
 private:
  static const float FIELD_SPACE = 0.5;
  Field field;
  Ship ship;
  ParticlePool particles;
  SplinterPool splinters;
  EnemyPool enemies;
  static int nextId;
  bool isSimple;
  bool isTop;
  bool isVisible;
  Vector ppos;
  const float SHIP_HIT_WIDTH = 0.4;
  int cnt;
  bool shouldBeRemoved;
  bool isWait;
  int postWait;
  int waitCnt;
  bool isMorphSeed;

  public static void init() {
    nextId = 0;
  }

  public static void resetTotalBulletsSpeed() {
    totalBulletsSpeed = 0;
  }

  public override Actor newActor() {
    return new BulletActor;
  }

  public override void init(ActorInitializer ini) {
    BulletActorInitializer bi = cast(BulletActorInitializer) ini;
    field = bi.field;
    ship = bi.ship;
    particles = bi.particles;
    splinters = bi.splinters;
    bullet = new BulletInst(nextId);
    ppos = new Vector;
    nextId++;
  }

  public void setEnemies(EnemyPool enemies) {
    this.enemies = enemies;
  }

  public void setStageManager(StageManager stageManager) {
    bullet.setStageManager(stageManager);
  }

  private void start(float speedRank, int shape, int color, float size,
		     float xReverse, float yReverse,
		     BulletTarget target, int type) {
    isExist = true;
    isTop = false;
    isWait = false;
    isVisible = true;
    isMorphSeed = false;
    ppos.x = bullet.pos.x;
    ppos.y = bullet.pos.y;
    bullet.setParam(speedRank, shape, color, size, xReverse, yReverse, target, type);
    cnt = 0;
    shouldBeRemoved = false;
  }

  public void set(BulletMLRunner* runner,
		  float x, float y, float deg, float speed,
		  float rank, float speedRank,
		  int shape, int color, float size,
		  float xReverse, float yReverse,
		  BulletTarget target, int type,
		  BulletMLParser *parser[], float[] ranks, float[] speeds,
		  int morphNum, int morphIdx) {
    bullet.set(runner, x, y, deg, speed, rank);
    bullet.setMorph(parser, ranks, speeds, morphNum, morphIdx);
    isSimple = false;
    start(speedRank, shape, color, size, xReverse, yReverse, target, type);
  }

  public void set(float x, float y, float deg, float speed,
		  float rank, float speedRank,
		  int shape, int color, float size,
		  float xReverse, float yReverse,
		  BulletTarget target, int type) {
    bullet.set(x, y, deg, speed, rank);
    bullet.morphNum = bullet.morphIdx = 0;
    isSimple = true;
    start(speedRank, shape, color, size, xReverse, yReverse, target, type);
  }

  public void setInvisible() {
    isVisible = false;
  }

  public void setTop() {
    isTop = true;
    setInvisible();
  }

  public void unsetTop() {
    isTop = false;
  }

  public void setWait(int prvw, int pstw) {
    isWait = true;
    waitCnt = prvw;
    postWait = pstw;
  }

  public void setMorphSeed() {
    isMorphSeed = true;
  }

  public void rewind() {
    bullet.remove();
    BulletMLRunner *runner = BulletMLRunner_new_parser(bullet.parser[0]);
    BulletActorPool.registFunctions(runner);
    bullet.setRunner(runner);
    bullet.resetMorph();
  }

  public void remove() {
    shouldBeRemoved = true;
  }

  public void removeForced() {
    if (!isSimple)
      bullet.remove();
    isExist = false;
  }

  public void removeForcedVisible() {
    if (isVisible) {
      particles.add(1, bullet.pos, bullet.deg, 0, bullet.speed * bullet.speedRank, 0.4,
		    Particle.TypeName.SPARK);
      removeForced();
    }
  }

  public void removeForcedVisibleEnemy() {
    if (isVisible && bullet.type == BulletInst.Type.ENEMY) {
      particles.add(1, bullet.pos, bullet.deg, 0, bullet.speed * bullet.speedRank, 0.4,
		    Particle.TypeName.SPARK);
      removeForced();
    }
  }

  // Check if the bullet hits the ship.
  private void checkShipHit() {
    float bmvx, bmvy, inaa;
    bmvx = ppos.x;
    bmvy = ppos.y;
    bmvx -= bullet.pos.x;
    bmvy -= bullet.pos.y;
    inaa = bmvx * bmvx + bmvy * bmvy;
    if (inaa > 0.00001) {
      float sofsx, sofsy, inab, hd;
      sofsx = ship.pos.x;
      sofsy = ship.pos.y;
      sofsx -= bullet.pos.x;
      sofsy -= bullet.pos.y;
      inab = bmvx * sofsx + bmvy * sofsy;
      if (inab >= 0 && inab <= inaa) {
	hd = sofsx * sofsx + sofsy * sofsy - inab * inab / inaa;
	if (hd >= 0 && hd <= SHIP_HIT_WIDTH) {
	  ship.destroyed();
	}
      }
    }
  }

  public override void move() {
    Vector tpos = bullet.target.getTargetPos();
    Bullet.target.x = tpos.x;
    Bullet.target.y = tpos.y;
    ppos.x = bullet.pos.x;
    ppos.y = bullet.pos.y;
    if (isTop) {
      bullet.deg = (atan2(tpos.x - bullet.pos.x, tpos.y - bullet.pos.y) * bullet.xReverse
		    + PI / 2) * bullet.yReverse - PI / 2;
    }
    if (isWait && waitCnt > 0) {
      waitCnt--;
      if (shouldBeRemoved)
	removeForced();
      return;
    }
    if (!isSimple) {
      bullet.move();
      if (bullet.isEnd()) {
	if (isTop) {
	  rewind();
	  if (isWait) {
	    waitCnt = postWait;
	    return;
	  }
	} else if (isMorphSeed) {
	  removeForced();
	  return;
	}
      }
    }
    if (shouldBeRemoved) {
      removeForced();
      return;
    }
    bullet.pos.x +=
      (sin(bullet.deg) * bullet.speed + bullet.acc.x) * bullet.speedRank * bullet.xReverse;
    bullet.pos.y +=
      (cos(bullet.deg) * bullet.speed - bullet.acc.y) * bullet.speedRank * bullet.yReverse;
    if (isVisible) {
      switch (bullet.type) {
      case BulletInst.Type.ENEMY:
	totalBulletsSpeed += bullet.speed * bullet.speedRank;
	if (splinters.checkHit(bullet.pos)) {
	  removeForcedVisible();
	} else {
	  StuckEnemy hse = ship.stuckEnemies.checkHitWithoutMyShip(bullet.pos);
	  if (hse) {
	    particles.add(3, bullet.pos, bullet.deg, 0.1,
			  bullet.speed * bullet.speedRank / 2, 0.6,
			  Particle.TypeName.SMOKE);
	    particles.add(20, bullet.pos, 0, PI * 2, 3, 0.4, Particle.TypeName.SPARK);
	    SoundManager.playSe(SoundManager.Se.STUCK_DESTROYED);
	    ship.hitStuckEnemiesPart(hse);
	    removeForced();
	  } else {
	    checkShipHit();
	  }
	}
	break;
      case BulletInst.Type.SHIP:
	if (enemies.checkHit(bullet.pos, 1)) {
	  particles.add(3, bullet.pos, bullet.deg, 0.1, bullet.speed * bullet.speedRank / 2, 0.5,
			Particle.TypeName.SMOKE);
	  particles.add(3, bullet.pos, bullet.deg + PI, 1, bullet.speed * bullet.speedRank, 0.3,
			Particle.TypeName.SPARK);
	  removeForced();
	}
	break;
      default:
	break;
      }
      if (field.checkHit(bullet.pos, FIELD_SPACE))
	removeForced();
    }
    cnt++;
  }

  private static const int BULLET_COLOR = 8;
  private static const int BULLET_SHADE = 3;

  public override void draw() {
    if (!isVisible)
      return;
    float d;
    d = (-bullet.deg * bullet.xReverse + PI / 2) * bullet.yReverse - PI / 2;
    glPushMatrix();
    glTranslatef(bullet.pos.x, bullet.pos.y, 0);
    int s;
    switch (bullet.shape) {
    case 0:
      glRotatef(rtod(d), 0, 0, 1);
      glScalef(bullet.bulletSize * 0.2, bullet.bulletSize * 0.5, 0.3);
      s = 0;
      break;
    case 1:
      glRotatef(rtod(d), 0, 0, 1);
      glScalef(bullet.bulletSize * 0.2, bullet.bulletSize * 0.5, 0.3);
      s = 5;
      break;
    case 2:
      glRotatef(cnt * 11, 0, 0, 1);
      glScalef(bullet.bulletSize * 0.4, bullet.bulletSize * 0.4, 0.3);
      s = 0;
      break;
    default:
      break;
    }
    Tumiki.drawShape(s, BULLET_COLOR + bullet.color, BULLET_SHADE);
    glPopMatrix();
  }
}

public class BulletActorInitializer: ActorInitializer {
 public:
  Field field;
  Ship ship;
  ParticlePool particles;
  SplinterPool splinters;

  public this(Field field, Ship ship, ParticlePool particles, SplinterPool splinters) {
    this.field = field;
    this.ship = ship;
    this.particles = particles;
    this.splinters = splinters;
  }
}
