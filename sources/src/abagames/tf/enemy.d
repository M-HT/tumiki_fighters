/*
 * $Id: enemy.d,v 1.3 2004/05/15 07:46:52 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.enemy;

private import std.math;
private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.tf.gamemanager;
private import abagames.tf.field;
private import abagames.tf.bulletactor;
private import abagames.tf.bulletactorpool;
private import abagames.tf.ship;
private import abagames.tf.enemyspec;
private import abagames.tf.stagemanager;
private import abagames.tf.tumiki;
private import abagames.tf.bulletinst;
private import abagames.tf.bullettarget;
private import abagames.tf.splinter;
private import abagames.tf.particle;
private import abagames.tf.damagegauge;
private import abagames.tf.soundmanager;

/**
 * Enemies.
 */
public class Enemy: Actor {
 public:
  static int totalNum;
 private:
  GameManager manager;
  Field field;
  BulletActorPool bullets;
  Ship ship;
  SplinterPool splinters;
  ParticlePool particles;
  ActorPool fragments;
  DamageGauge gauge;
  EnemySpec spec;
  static const int PARTS_MAX_NUM = 8;
  EnemyPart[PARTS_MAX_NUM] parts;
  int partsNum;
  int fireCnt, attackFormIdx, attackPtnIdx, barragePtnIdx;
  Vector pos;
  int cnt;
  EnemyMovement mv;
  bool isBoss;

  public static void resetTotalNum() {
    totalNum = 0;
  }

  public override Actor newActor() {
    return new Enemy;
  }

  public override void init(ActorInitializer ini) {
    EnemyInitializer ei = cast(EnemyInitializer) ini;
    manager = ei.manager;
    field = ei.field;
    bullets = ei.bullets;
    ship = ei.ship;
    splinters = ei.splinters;
    particles = ei.particles;
    fragments = ei.fragments;
    gauge = ei.gauge;
    pos = new Vector;
    mv = new EnemyMovement;
    foreach (inout EnemyPart ep; parts)
      ep = new EnemyPart(ship, bullets, fragments);
  }

  public void set(float x, float y, EnemySpec spec, EnemyMovePattern mp, bool isBoss) {
    pos.x = x;
    pos.y = y;
    this.spec = spec;
    this.isBoss = isBoss;
    partsNum = 0;
    foreach (EnemyPartSpec eps; spec.parts) {
      parts[partsNum].set(eps);
      partsNum++;
    }
    for (int j = 0; j < partsNum - 1; j++)
      for (int i = j + 1; i < partsNum; i++)
	parts[j].addCoverPart(parts[i]);
    fireCnt = 0;
    attackFormIdx = 0;
    attackPtnIdx = 0;
    barragePtnIdx = 0;
    BulletMLMovePattern bm = cast(BulletMLMovePattern) mp;
    if (bm) {
      mv.moveBullet = bullets.addMoveBullet(bm.parser, bm.speed, x, y, bm.deg, ship);
      if (!mv.moveBullet)
	return;
    } else {
      mv.moveBullet = null;
      PointsMovePattern pm = cast(PointsMovePattern) mp;
      mv.pattern = pm;
      mv.movePointIdx = 0;
      mv.deg = pm.deg;
      mv.onRoute = false;
      mv.reachFirstPoint = mv.reachFirstPointFirst = false;
      mv.withdraw = false;
      mv.withdrawPos.x = pos.x;
      mv.withdrawPos.y = pos.y;
    }
    cnt = 0;
    isExist = true;
  }

  private void remove() {
    for (int i = 0 ; i < partsNum; i++) {
      EnemyPart p = parts[i];
      p.remove();
    }
    if (mv.moveBullet)
      mv.moveBullet.removeForced();
    isExist = false;
  }

  private void breakIntoFragments() {
    for (int i = 0 ; i < partsNum; i++) {
      EnemyPart p = parts[i];
      if (p.shield > 0)
	p.breakIntoFragments(pos);
    }
  }

  private void movePatternChanged() {
    mv.movePointIdx = 0;
    mv.reachFirstPoint = false;
  }

  private static float BOSS_MOVE_DEG = 0.04;

  private void movePointsMove() {
    Vector aim;
    float ax, ay;
    float speed;
    Vector[] pt;
    if (!mv.withdraw) {
      pt = mv.pattern.point[barragePtnIdx];
      if (!pt) {
	pt = mv.pattern.point[PointsMovePattern.BASIC_PATTERN_IDX];
	speed = mv.pattern.speed[PointsMovePattern.BASIC_PATTERN_IDX];
      } else {
	speed = mv.pattern.speed[barragePtnIdx];
      }
      if (!mv.reachFirstPointFirst)
	speed *= 3;
      else if (!mv.reachFirstPoint)
	speed *= 2;
      if (mv.movePointIdx >= pt.length)
	mv.movePointIdx = 0;
      aim = pt[mv.movePointIdx];
      if (cnt >= mv.pattern.withdrawCnt) {
	mv.withdraw = true;
	mv.onRoute = false;
      }
    }
    if (mv.withdraw) {
      ax = mv.withdrawPos.x;
      ay = mv.withdrawPos.y;
      speed = mv.pattern.speed[PointsMovePattern.BASIC_PATTERN_IDX] * 2;
    } else {
      ax = aim.x * field.size.x;
      ay = aim.y * field.size.x;
    }
    float d = atan2(ax - pos.x, ay - pos.y);
    float od = d - mv.deg;
    if (od > PI)
      od -= PI * 2;
    else if (od < -PI) 
      od += PI * 2;
    float aod = fabs(od);
    if (aod < BOSS_MOVE_DEG) {
      mv.deg = d;
    } else if (od > 0) {
      mv.deg += BOSS_MOVE_DEG;
      if (mv.deg >= std.math.PI * 2)
	mv.deg -= PI * 2;
    } else {
      mv.deg -= BOSS_MOVE_DEG;
      if (mv.deg < 0)
	mv.deg += PI * 2;
    }
    pos.x += sin(mv.deg) * speed;
    pos.y += cos(mv.deg) * speed;
    if (!mv.onRoute) {
      if (aod < PI / 2) {
	mv.onRoute = true;
      }
    } else {
      if (aod > PI / 2) {
	if (mv.withdraw) {
	  remove();
	  return;
	}
	if (isBoss && !mv.reachFirstPointFirst)
	  manager.bossInAttack(mv.pattern.withdrawCnt);
	mv.reachFirstPoint = mv.reachFirstPointFirst = true;
	mv.onRoute = false;
	mv.movePointIdx++;
	if (mv.movePointIdx >= pt.length)
	  mv.movePointIdx = 0;
      }
    }
  }
  
  private void addTopBullets() {
    for (int i = 0 ; i < partsNum; i++)
      parts[i].addTopBullets(barragePtnIdx);
    setTopBulletsPos();
  }

  private void removeTopBullets() {
    for (int i = 0 ; i < partsNum; i++)
      parts[i].removeTopBullets();
  }

  private void setTopBulletsPos() {
    for (int i = 0 ; i < partsNum; i++)
      parts[i].setTopBulletsPos(pos.x, pos.y);
  }

  private void checkWoundedParts() {
    for (int i = 0 ; i < partsNum; i++) {
      if (parts[i].shield > 0) {
	EnemyPart ep = parts[i];
	ep.wounded = false;
	if (ep.shield < ep.firstShield / 2) {
	  if ((cnt & 15) < 3)
	    ep.wounded = true;
	} else if (ep.shield < ep.firstShield / 3) {
	  if ((cnt & 7) < 3)
	    ep.wounded = true;
	} else if (ep.shield < ep.firstShield / 4) {
	  if ((cnt & 3) < 3)
	    ep.wounded = true;
	}
      }
    }
  }

  public override void move() {
    if (mv.moveBullet) {
      pos.x = mv.moveBullet.bullet.pos.x;
      pos.y = mv.moveBullet.bullet.pos.y;
      if (field.checkHit(pos, 
			 spec.sizeXm * 2, spec.sizeXp * 2, spec.sizeYm * 2, spec.sizeYp * 2)) {
	remove();
	return;
      }
    } else {
      movePointsMove();
      if (!mv.reachFirstPoint) {
	cnt++;
	totalNum++;
	return;
      }
    }
    fireCnt--;
    AttackForm af = spec.attackForm[attackFormIdx];
    if (fireCnt < 0) {
      fireCnt = af.attackPeriod[attackPtnIdx] + af.breakPeriod[attackPtnIdx];
      barragePtnIdx = af.barragePtnStartIdx + attackPtnIdx;
      addTopBullets();
      attackPtnIdx++;
      if (attackPtnIdx >= af.attackPeriod.length)
	attackPtnIdx = 0;
      if (!mv.moveBullet) {
	if (mv.pattern.point[barragePtnIdx])
	  movePatternChanged();
      }
    } else if (fireCnt < af.breakPeriod[attackPtnIdx]) {
      removeTopBullets();
    }
    setTopBulletsPos();
    checkWoundedParts();
    cnt++;
    totalNum++;
  }

  public override void draw() {
    float z = -0.5;
    for (int i = 0 ; i < partsNum; i++) {
      EnemyPart p = parts[i];
      if (p.shield > 0)
	p.draw(pos, z);
      if (i == 0)
	z += 0.2;
      else
	z += 0.05;
    }
  }

  private void checkAttackFormChange() {
    int ai = attackFormIdx + 1;
    if (ai >= spec.attackForm.length)
      return;
    if (spec.attackForm[ai].shield < parts[0].shield)
      return;
    attackFormIdx++;
    removeTopBullets();
    foreach (EnemyPart ep; parts) {
      if (ep.shield > 0)
	if (ep.spec.destroyedFormIdx >= 0 && attackFormIdx >= ep.spec.destroyedFormIdx) {
	  ep.breakIntoFragments(pos);
	  ep.remove();
	}
    }
    particles.add(8, pos, 0, PI * 2, 0.3, 3, Particle.TypeName.SMOKE);
    SoundManager.playSe(SoundManager.Se.ENEMY_DESTROYED);
    fireCnt = 100;
    attackPtnIdx = 0;
    barragePtnIdx = 0;
  }

  public bool checkHit(Vector p, float damage) {
    float dm = damage;
    if (!mv.moveBullet && !mv.reachFirstPointFirst)
      dm = 0;
    for (int i = 0 ; i < partsNum; i++) {
      EnemyPart ep = parts[i];
      if (ep.checkHit(p, dm, pos)) {
	if (ep.shield <= 0) {
	  if (ep.spec.damageToMainBody > 0) {
	    parts[0].shield -= ep.spec.damageToMainBody;
	    particles.add(5, pos, 0, PI * 2, 0.1, parts[0].spec.size / 4, Particle.TypeName.SMOKE);
	  }
	  manager.addScore(ep.spec.tumikiSet.score, p);
	  if (ep.firstShield <= 1)
	    SoundManager.playSe(SoundManager.Se.SMALL_ENEMY_DESTROYED);
	  else
	    SoundManager.playSe(SoundManager.Se.ENEMY_DESTROYED);
	  ep.remove();
	  particles.add(8, p, 0, PI * 2, 1, 0.5, Particle.TypeName.SPARK);
	  Splinter sp = cast(Splinter) splinters.getInstance();
	  if (sp) {
	    bool bs = isBoss;
	    if (i != 0)
	      bs = false;
	    sp.set
	      (pos.x + ep.spec.ofs.x, pos.y + ep.spec.ofs.y, ep.spec.tumikiSet, barragePtnIdx, bs);
	  }
	  if (parts[0].shield <= 0) {
	    if (i != 0)
	      parts[0].spec.tumikiSet.breakIntoFragments(fragments, pos, 0);
	    breakIntoFragments();
	    if (isBoss) {
	      int sc = manager.bossDestroyed();
	      manager.addScore(sc, p);
	    }
	    remove();
	  } else {
	    for (int j = 0; j < i; j++)
	      parts[j].activateCoveredTopBullets(barragePtnIdx);
	  }
	}
	setTopBulletsPos();
	checkAttackFormChange();
	gauge.add(ep);
	return true;
      }
    }
    return false;
  }
}

public class EnemyInitializer: ActorInitializer {
 public:
  GameManager manager;
  Field field;
  BulletActorPool bullets;
  Ship ship;
  SplinterPool splinters;
  ActorPool fragments;
  ParticlePool particles;
  DamageGauge gauge;

  public this(GameManager manager, Field field, BulletActorPool bullets, Ship ship,
	      SplinterPool splinters, ParticlePool particles, ActorPool fragments,
	      DamageGauge gauge) {
    this.manager = manager;
    this.field = field;
    this.bullets = bullets;
    this.ship = ship;
    this.splinters = splinters;
    this.particles = particles;
    this.fragments = fragments;
    this.gauge = gauge;
  }
}

public class EnemyPool: ActorPool {
 private:

  public this(int n, ActorInitializer ini) {
    auto Enemy enemyClass = new Enemy;
    super(n, enemyClass, ini);
  }

  public bool checkHit(Vector pos, float damage) {
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	Enemy en = cast(Enemy) ac;
	if (en.checkHit(pos, damage))
	  return true;
      }
    }
    return false;
  }

}

public class EnemyPart {
 public:
  static const int TOP_BULLET_MAX = 16;
  EnemyTopBullet[TOP_BULLET_MAX] topBullet;
  int topBulletNum;
  float shield;
  float firstShield;
  bool damaged;
  bool wounded;
  EnemyPartSpec spec;
 private:
  EnemyPart[Enemy.PARTS_MAX_NUM] coverParts;
  int coverPartsNum;
  BulletTarget target;
  BulletActorPool bullets;
  ActorPool fragments;

  public this(BulletTarget target, BulletActorPool bullets, ActorPool fragments) {
    this.target = target;
    this.bullets = bullets;
    this.fragments = fragments;
    foreach (inout EnemyTopBullet etb; topBullet)
      etb = new EnemyTopBullet;
  }

  public void set(EnemyPartSpec s) {
    spec = s;
    firstShield = shield = s.shield;
    wounded = damaged = false;
    topBulletNum = 0;
    coverPartsNum = 0;
  }

  public void remove() {
    removeTopBullets();
    shield = -1;
  }
  
  public void addTopBullets(int barragePtnIdx) {
    if (shield <= 0)
      return;
    topBulletNum = spec.tumikiSet.addTopBullets
      (barragePtnIdx, bullets, topBullet, target, BulletInst.Type.ENEMY);
    for (int i = 0 ; i < topBulletNum; i++) {
      topBullet[i].coverChecked = false;
    }
  }

  public void activateCoveredTopBullets(int barragePtnIdx) {
    if (shield <= 0)
      return;
    for (int i = 0 ; i < topBulletNum; i++) {
      EnemyTopBullet etb = topBullet[i];
      if (etb.deactivated) {
	etb.actor = etb.tumiki.addTopBullet
	  (barragePtnIdx, bullets, target, BulletInst.Type.ENEMY);
	etb.deactivated = false;
	etb.coverChecked = false;
      }
    }
  }

  public void removeTopBullets() {
    for (int i = 0 ; i < topBulletNum; i++)
      if (topBullet[i].actor) {
	topBullet[i].actor.removeForced();
	topBullet[i].actor = null;
      }
  }

  public void setTopBulletsPos(float x, float y) {
    if (shield <= 0)
      return;
    for (int i = 0 ; i < topBulletNum; i++) {
      EnemyTopBullet etb = topBullet[i];
      if (etb.actor) {
	float ofsx = spec.ofs.x + etb.tumiki.ofs.x;
	float ofsy = spec.ofs.y + etb.tumiki.ofs.y;
	etb.actor.bullet.pos.x = x + ofsx;
	etb.actor.bullet.pos.y = y + ofsy;
	if (coverPartsNum > 0 && !etb.coverChecked) {
	  for (int i = 0; i < coverPartsNum; i++) {
	    if (coverParts[i].shield > 0 && coverParts[i].covers(ofsx, ofsy)) {
	      etb.actor.removeForced();
	      etb.actor = null;
	      etb.deactivated = true;
	      break;
	    }
	  }
	  etb.coverChecked = true;
	}
      }
    }
  }

  public void addCoverPart(EnemyPart part) {
    coverParts[coverPartsNum] = part;
    coverPartsNum++;
  }
  
  public bool covers(float x, float y) {
    float ox = x - spec.ofs.x;
    float oy = y - spec.ofs.y;
    if (spec.tumikiSet.sizeXm <= ox && ox <= spec.tumikiSet.sizeXp &&
	spec.tumikiSet.sizeYm <= oy && oy <= spec.tumikiSet.sizeYp)
      return true;
    else
      return false;
  }

  public bool checkHit(Vector pos, float damage, Vector pPos) {
    if (shield <= 0)
      return false;
    bool f;
    f = spec.tumikiSet.checkHit(pos, pPos.x + spec.ofs.x, pPos.y + spec.ofs.y);
    if (f && damage > 0) {
      shield -= damage;
      damaged = true;
      SoundManager.playSe(SoundManager.Se.ENEMY_DAMAGED);
    }
    return f;
  }

  public void breakIntoFragments(Vector pos) {
    spec.tumikiSet.breakIntoFragments(fragments, pos.x + spec.ofs.x, pos.y + spec.ofs.y, 0);
  }

  public void draw(Vector pos, float z) {
    spec.tumikiSet.draw(pos.x + spec.ofs.x, pos.y + spec.ofs.y, z, damaged, wounded);
    damaged = false;
  }
}

public class EnemyTopBullet {
 public:
  BulletActor actor;
  Tumiki tumiki;
  bool deactivated;
  bool coverChecked;
}

public class EnemyMovement {
 public:
  BulletActor moveBullet;
  PointsMovePattern pattern;
  int movePointIdx;
  float deg;
  bool onRoute;
  bool reachFirstPoint;
  bool reachFirstPointFirst;
  bool withdraw;
  Vector withdrawPos;

  public this() {
    withdrawPos = new Vector;
  }
}
