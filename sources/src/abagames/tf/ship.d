/*
 * $Id: ship.d,v 1.5 2004/05/15 07:46:52 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.ship;

private import std.math;
private import opengl;
private import abagames.util.vector;
private import abagames.util.rand;
private import abagames.util.actorpool;
private import abagames.util.sdl.pad;
private import abagames.util.bulletml.bullet;
private import abagames.tf.field;
private import abagames.tf.gamemanager;
private import abagames.tf.screen;
private import abagames.tf.soundmanager;
private import abagames.tf.tumikiset;
private import abagames.tf.bulletactorpool;
private import abagames.tf.bullettarget;
private import abagames.tf.bulletinst;
private import abagames.tf.enemy;
private import abagames.tf.stuckenemy;
private import abagames.tf.particle;
private import abagames.tf.splinter;

/**
 * My ship.
 */
public class Ship: BulletTarget {
 public:
  Vector pos;
  float deg;
  const float SIZE = 0.3;
  bool restart;
  static const int RESTART_CNT = 300;
  static const int INVINCIBLE_CNT = 228;
  static const int RESPAWN_CNT = 250;
  static const float RESPAWN_MOVE = 0.8;
  static const int NOBULLET_CNT = 150;
  int cnt;
  static const float TARGET_DISTANCE = 20;
  StuckEnemyPool stuckEnemies;
 private:
  static Rand rand;
  Pad pad;
  Field field;
  BulletActorPool bullets;
  ParticlePool particles;
  ActorPool fragments;
  GameManager manager;
  const float BASE_SPEED = 0.4;
  const float SLOW_SPEED = 0.33;
  float speed;
  Vector vel;
  const float BANK_BASE = 1.5;
  int fireCnt;
  const float FIELD_SPACE = 1.5;
  float fieldLimitX, fieldLimitY;
  TumikiSet tumikiSet;
  VirtualBulletTarget target;
  static const int FIRE_INTERVAL = 2;
  EnemyTopBullet[1] etb;
  float groundY;
  int startCnt;
  int endCnt;
  float smx, smy;
  Vector[8] friendPos;
  bool btnPrsd;
  bool pullIn;

  public static this() {
    rand = new Rand;
  }

  public void init(Pad pad, Field field, ParticlePool particles, ActorPool fragments,
		   GameManager manager) {
    this.pad = pad;
    this.field = field;
    this.particles = particles;
    this.fragments = fragments;
    this.manager = manager;
    pos = new Vector;
    vel = new Vector;
    fieldLimitX = field.size.x - FIELD_SPACE;
    fieldLimitY = field.size.y - FIELD_SPACE;
    target = new VirtualBulletTarget;
    etb[0] = new EnemyTopBullet;
    createTumiki();
    foreach (inout Vector fp; friendPos) {
      fp = new Vector;
    }
  }

  private void createTumiki() {
    tumikiSet = new TumikiSet("myship/ship.tmk");
  }

  public void setBulletActorPool(BulletActorPool bullets) {
    this.bullets = bullets;
  }

  public void initStuckEnemies(SplinterPool splinters) {
    StuckEnemyInitializer sei =
      new StuckEnemyInitializer(this, field, bullets, fragments, splinters, manager);
    stuckEnemies = new StuckEnemyPool(128, sei);
    stuckEnemies.init();
    setMyShipAsStuckEnemy();
  }

  private void setMyShipAsStuckEnemy() {
    StuckEnemy se = cast(StuckEnemy) stuckEnemies.getInstance();
    se.setAsMyShip(tumikiSet);
  }

  public void start() {
    pos.x = -field.size.x / 2;
    pos.y = 0;
    vel.x = vel.y = 0;
    speed = BASE_SPEED;
    restart = true;
    cnt = -INVINCIBLE_CNT;
    fireCnt = 0;
    deg = 0;
    pullIn = false;
  }

  public void startStage() {
    start();
    pos.x = -field.size.x / 3 * 2;
    pos.y = -field.size.y / 5 * 4;
    deg = 0.2;
    groundY = 120;
    field.setGroundY(groundY);
    startCnt = 0;
    cnt = 0;
    smx = smy = 0;
    rand.setSeed(0);
    foreach (Vector fp; friendPos) {
      fp.x = -rand.nextFloat(field.size.x * 3) + field.size.x * 1.5;
      fp.y = pos.y + rand.nextFloat(field.size.y);
    }
  }

  public void backToHome() {
    endCnt = 0;
    smx = -0.05;
    smy = 0;
    rand.setSeed(0);
    foreach (Vector fp; friendPos) {
      fp.x = -rand.nextFloat(field.size.x * 3) + field.size.x * 1.5;
      fp.y = field.size.y + rand.nextFloat(field.size.y / 2);
    }
  }

  public void destroyed() {
    if (cnt <= 0)
      return;
    flyinStuckEnemies();
    SoundManager.playSe(SoundManager.Se.SHIP_DESTROYED);
    manager.shipDestroyed();
    particles.add(15, pos, 0, PI * 2, 2, 1, Particle.TypeName.SMOKE);
    particles.add(20, pos, 0, PI * 2, 1, 0.6, Particle.TypeName.SPARK);
    particles.add(8, pos, 0, PI * 2, 4, 0.3, Particle.TypeName.SPARK);
    start();
    pos.x = -field.size.x;
    cnt = -RESTART_CNT;
  }

  public void breakStuckEnemies() {
    stuckEnemies.removeAllEnemies();
  }

  public void flyinStuckEnemies() {
    stuckEnemies.flyinAllEnemies();
  }

  public void hitStuckEnemiesPart(StuckEnemy se) {
    stuckEnemies.removeStuckEnemy(se);
  }

  public void move() {
    cnt++;
    if (cnt < -NOBULLET_CNT)
      bullets.clearVisibleEnemy();
    if (cnt < -INVINCIBLE_CNT) {
      if (cnt > -RESPAWN_CNT)
	pos.x += RESPAWN_MOVE;
      return;
    }
    if (cnt == 0)
      restart = false;
    int btn = pad.getButtonState();
    int ps = pad.getPadState();
    vel.x = vel.y = 0;
    if (ps & Pad.PAD_UP)
      vel.y = speed;
    else if (ps & Pad.PAD_DOWN)
      vel.y = -speed;
    if (ps & Pad.PAD_RIGHT)
      vel.x = speed;
    else if (ps & Pad.PAD_LEFT)
      vel.x = -speed;
    if (vel.x != 0 && vel.y != 0) {
      vel.x *= 0.707;
      vel.y *= 0.707;
    }
    pos.x += vel.x;
    pos.y += vel.y;
    if (pos.x < -fieldLimitX)
      pos.x = -fieldLimitX;
    else if (pos.x > fieldLimitX)
      pos.x = fieldLimitX;
    if (pos.y < -fieldLimitY)
      pos.y = -fieldLimitY;
    else if (pos.y > fieldLimitY)
      pos.y = fieldLimitY;
    target.pos.x = pos.x + cos(deg) * TARGET_DISTANCE;
    target.pos.y = pos.y + sin(deg) * TARGET_DISTANCE;
    if ((btn & Pad.PAD_BUTTON1) && fireCnt <= 0) {
      fireCnt = FIRE_INTERVAL + 1;
      int eidx = tumikiSet.addTopBullets(0, bullets, etb, target, BulletInst.Type.SHIP);
      if (eidx > 0) {
	etb[0].actor.unsetTop();
	etb[0].actor.setMorphSeed();
	etb[0].actor.bullet.pos.x = pos.x;
	etb[0].actor.bullet.pos.y = pos.y;
	etb[0].actor.bullet.deg = -deg - PI / 2;
	SoundManager.playSe(SoundManager.Se.SHIP_SHOT);
      }
    }
    if (btn & Pad.PAD_BUTTON2) {
      speed += (SLOW_SPEED - speed) * 0.2;
      if (manager.mode == GameManager.Mode.EXTRA)
	stuckEnemies.pullIn();
    } else {
      speed += (BASE_SPEED - speed) * 0.2;
      deg += (vel.y * BANK_BASE - deg) * 0.05;
      if (manager.mode == GameManager.Mode.EXTRA)
	stuckEnemies.pushOut();
    }
    if (fireCnt > 0)
      fireCnt--;
    stuckEnemies.move();
  }

  public void startMove() {
    if (startCnt < 120) {
      if (startCnt < 80)
	smx += 0.003;
      else
	smx -= 0.006;
      pos.x += smx;
      if (startCnt < 60)
	particles.add(1, pos, PI / 2 + 0.2, 0.4, startCnt * 0.02, 0.5, Particle.TypeName.SMOKE);
    }
    if (startCnt > 60 && startCnt < 180) {
      if (startCnt == 61)
	SoundManager.playSe(SoundManager.Se.PROPELLER);
      if (startCnt < 140)
	smy += 0.003;
      else
	smy -= 0.006;
      pos.y += smy;
      groundY -= 1;
      field.setGroundY(groundY);
      pos.x -= 0.01;
    }
    if (startCnt > 180) {
      pos.x -= 0.1;
      deg -= 0.0026;
      if (startCnt > 256) {
	manager.setInGame();
      }
    }
    startCnt++;
    foreach (Vector fp; friendPos) {
      fp.y += 0.15;
    }
  }

  public void endMove() {
    pos.x += BASE_SPEED * 2;
    deg *= 0.95;
  }

  public void backToHomeMove() {
    int ec = endCnt % 200;
    if (ec < 100)
      smx += 0.001;
    else
      smx -= 0.001;
    if (ec < 50 || ec > 150)
      smy += 0.001;
    else
      smy -= 0.001;
    pos.x += smx;
    pos.y += smy;
    deg *= 0.95;
    if (endCnt <= 60) {
      btnPrsd = true;
    } else {
      if (pad.getButtonState() & (Pad.PAD_BUTTON1 | Pad.PAD_BUTTON2)) {
	if (!btnPrsd) {
	  manager.startGameover();
	  return;
	}
      } else {
	btnPrsd = false;
      }
    }
    if (endCnt > 700) {
      manager.startGameover();
      return;
    } else if (endCnt > 620) {
      endMove();
      foreach (Vector fp; friendPos)
	fp.x += BASE_SPEED * 2;
    }
    endCnt++;
    if (endCnt < 220) {
      foreach (Vector fp; friendPos)
	fp.y -= 0.05;
    } else if (endCnt < 330) {
      foreach (Vector fp; friendPos)
	fp.y -= 0.02;
    }
  }

  public Vector getTargetPos() {
    return pos;
  }

  public void draw() {
    stuckEnemies.draw();
    if (cnt < -RESPAWN_CNT || (cnt < 0 && (-cnt % 32) < 16))
      return;
    tumikiSet.draw(pos, 0, deg);
  }

  public void drawFriendly() {
    float z = -3;
    foreach (Vector fp; friendPos) {
      tumikiSet.drawShade(fp, z, 1, 0.2);
      z -= 1;
    }
  }

  public void drawFriendlyBack() {
    float z = -3;
    foreach (Vector fp; friendPos) {
      tumikiSet.drawShade(fp, z, 1, 0);
      z -= 1;
    }
  }

  public void drawLeft(float x, float y, float z) {
    tumikiSet.draw(x, y, z, false, false);
  }
}
