/*
 * $Id: stuckenemy.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.stuckenemy;

private import std.math;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.util.vector;
private import abagames.tf.tumikiset;
private import abagames.tf.ship;
private import abagames.tf.enemy;
private import abagames.tf.bulletactorpool;
private import abagames.tf.bullettarget;
private import abagames.tf.bulletinst;
private import abagames.tf.field;
private import abagames.tf.fragment;
private import abagames.tf.gamemanager;
private import abagames.tf.soundmanager;
private import abagames.tf.splinter;

/**
 * Enemies that are stuck to my ship.
 */
public class StuckEnemy: Actor {
 public:
  bool isConnected;
 private:
  Ship ship;
  Field field;
  GameManager manager;
  TumikiSet tumikiSet;
  Vector ofs, lofs;
  float stDeg;
  Vector pos;
  float deg;
  Vector[4] colDatums;
  bool isMyShip;
  static const int TOP_BULLET_MAX = 16;
  EnemyTopBullet[TOP_BULLET_MAX] topBullet;
  int topBulletNum;
  int barragePtnIdx;
  BulletActorPool bullets;
  ActorPool fragments;
  VirtualBulletTarget target;
  int cnt;
  float colSize;
  static const int CONNECTED_ENEMY_MAX = 16;
  StuckEnemy[CONNECTED_ENEMY_MAX] connectedEnemy;
  int connectedEnemyNum;
  StuckEnemyPool stuckEnemies;
  SplinterPool splinters;

  public override Actor newActor() {
    return new StuckEnemy;
  }

  public override void init(ActorInitializer ini) {
    StuckEnemyInitializer sei = cast(StuckEnemyInitializer) ini;
    ship = sei.ship;
    field = sei.field;
    bullets = sei.bullets;
    fragments = sei.fragments;
    splinters = sei.splinters;
    manager = sei.manager;
    ofs = new Vector;
    lofs = new Vector;
    pos = new Vector;
    target = new VirtualBulletTarget;
    foreach (inout Vector cd; colDatums)
      cd = new Vector;
    foreach (inout EnemyTopBullet etb; topBullet)
      etb = new EnemyTopBullet;
  }

  public void setStuckEnemyPool(StuckEnemyPool sep) {
    stuckEnemies = sep;
  }

  public bool set(float x, float y, float d, TumikiSet ts, int bpi) {
    ofs.x = x; ofs.y = y;
    stDeg = d;
    tumikiSet = ts;
    barragePtnIdx = bpi;
    isMyShip = false;
    cnt = 0;
    connectedEnemyNum = 0;
    setColSize();
    if (!stuckEnemies.checkConnected(this))
      return false;
    addTopBullets();
    isExist = true;
    return true;
  }

  private void setColSize() {
    colSize = -tumikiSet.sizeXm;
    if (colSize < tumikiSet.sizeXp)
      colSize = tumikiSet.sizeXp;
    if (colSize < -tumikiSet.sizeYm)
      colSize = -tumikiSet.sizeYm;
    if (colSize < tumikiSet.sizeYp)
      colSize = tumikiSet.sizeYp;
    colSize *= COLLISION_RATIO;
  }

  private void addTopBullets() {
    topBulletNum = tumikiSet.addTopBullets
      (barragePtnIdx, bullets, topBullet, target, BulletInst.Type.SHIP);
  }

  private void removeTopBullets() {
    for (int i = 0 ; i < topBulletNum; i++)
      if (topBullet[i].actor)
	topBullet[i].actor.removeForced();
  }

  public void remove() {
    removeTopBullets();
    isExist = false;
  }

  private void setTopBulletsPos() {
    for (int i = 0 ; i < topBulletNum; i++) {
      EnemyTopBullet etb = topBullet[i];
      if (etb.actor) {
	float stox = etb.tumiki.ofs.x * cos(deg) - etb.tumiki.ofs.y * sin(deg);
	float stoy = etb.tumiki.ofs.x * sin(deg) + etb.tumiki.ofs.y * cos(deg);
	etb.actor.bullet.pos.x = pos.x + stox;
	etb.actor.bullet.pos.y = pos.y + stoy;
	etb.actor.bullet.deg = deg - PI / 2;
      }
    }
  }

  public void setAsMyShip(TumikiSet ts) {
    ofs.x = ofs.y = stDeg = 0;
    tumikiSet = ts;
    isMyShip = true;
    connectedEnemyNum = 0;
    setColSize();
    isExist = true;
  }

  public void breakIntoFragments() {
    if (manager.mode == GameManager.Mode.EXTRA && stuckEnemies.pullInRatio < 1)
      return;
    tumikiSet.breakIntoFragments(fragments, pos, deg);
    bullets.clearStuckEnemyHit(this);
  }

  private const float SPLINTER_FLYIN_RATIO_X = 0.03;
  private const float SPLINTER_FLYIN_RATIO_Y = 0.01;
  private const float SPLINTER_FLYIN_DEG_RATIO = -0.03;
  private const float SPLINTER_FLYIN_MOVE_Y = 0.36;
  private const float SPLINTER_FLYIN_MOVE_DEG_MAX = 0.2;

  public void breakIntoSplinter() {
    Splinter sp = cast(Splinter) splinters.getInstance();
    if (!sp)
      return;
    float md = lofs.x * SPLINTER_FLYIN_DEG_RATIO;
    if (md > SPLINTER_FLYIN_MOVE_DEG_MAX)
      md = SPLINTER_FLYIN_MOVE_DEG_MAX;
    else if (md < -SPLINTER_FLYIN_MOVE_DEG_MAX)
      md = -SPLINTER_FLYIN_MOVE_DEG_MAX;
    sp.set(pos, 
	   lofs.x * SPLINTER_FLYIN_RATIO_X,
	   lofs.y * SPLINTER_FLYIN_RATIO_Y + SPLINTER_FLYIN_MOVE_Y,
	   deg, md, tumikiSet, barragePtnIdx);
  }

  static private const float COLLISION_RATIO = 0.8;
  static private const float COLLISION_RATIO_WIDE = 3.3;

  public void setNormalCollision() {
    float sd = sin(deg) * COLLISION_RATIO, cd = cos(deg) * COLLISION_RATIO;
    setCollision(sd, cd);
  }

  public void setWideCollision() {
    float sd = sin(deg) * COLLISION_RATIO_WIDE, cd = cos(deg) * COLLISION_RATIO_WIDE;
    setCollision(sd, cd);
  }

  private void setCollision(float sd, float cd) {
    colDatums[0].x = pos.x + tumikiSet.sizeXm * cd;
    colDatums[0].y = pos.y + tumikiSet.sizeXm * sd;
    colDatums[1].x = pos.x - tumikiSet.sizeYm * sd;
    colDatums[1].y = pos.y + tumikiSet.sizeYm * cd;
    colDatums[2].x = pos.x + tumikiSet.sizeXp * cd;
    colDatums[2].y = pos.y + tumikiSet.sizeXp * sd;
    colDatums[3].x = pos.x - tumikiSet.sizeYp * sd;
    colDatums[3].y = pos.y + tumikiSet.sizeYp * cd;
  }

  public override void move() {
    deg = stDeg + ship.deg;
    float osd, ocd;
    osd = sin(ship.deg);
    ocd = cos(ship.deg);
    lofs.x = ofs.x * ocd - ofs.y * osd;
    lofs.y = ofs.x * osd + ofs.y * ocd;
    if (manager.mode == GameManager.Mode.EXTRA) {
      pos.x = ship.pos.x + lofs.x * stuckEnemies.pullInRatio;
      pos.y = ship.pos.y + lofs.y * stuckEnemies.pullInRatio;
    } else {
      pos.x = ship.pos.x + lofs.x;
      pos.y = ship.pos.y + lofs.y;
    }
    setNormalCollision();
    target.pos.x = pos.x - cos(deg) * Ship.TARGET_DISTANCE;
    target.pos.y = pos.y - sin(deg) * Ship.TARGET_DISTANCE;
    setTopBulletsPos();
    cnt++;
    int mp = 1;
    int sen = SoundManager.Se.STUCK_BONUS;
    if (manager.mode == GameManager.Mode.EXTRA)
      if (stuckEnemies.pullInRatio >= 1)
	mp = 5;
      else
	sen = SoundManager.Se.STUCK_BONUS_PUSHIN;
    if (tumikiSet.fireScoreInterval > 0 &&
	(cnt % tumikiSet.fireScoreInterval) == 0 &&
	!field.checkHit(pos)) {
      manager.addScore(tumikiSet.fireScore * mp, pos);
      SoundManager.playSe(sen);
    }
    if (!isMyShip) {
      stuckEnemies.totalSize += tumikiSet.size;
    } else {
      for (int i = 0; i < connectedEnemyNum; i++) {
	if (!connectedEnemy[i].isExist) {
	  connectedEnemyNum--;
	  for (int j = i; j < connectedEnemyNum; j++)
	    connectedEnemy[j] = connectedEnemy[j + 1];
	}
      }
    }
  }

  public override void draw() {
    if (!isMyShip) {
      if (manager.mode == GameManager.Mode.EXTRA && stuckEnemies.pullInRatio < 1)
	tumikiSet.drawShade(pos, 0.2, 1, deg, stuckEnemies.pullInRatio);
      else
	tumikiSet.draw(pos, 0.2, deg);
    }  
  }

  public bool checkHit(Vector pos) {
    if (pos.checkSide(colDatums[0], colDatums[1]) * 
	pos.checkSide(colDatums[3], colDatums[2]) < 0 &&
	pos.checkSide(colDatums[1], colDatums[2]) * 
	pos.checkSide(colDatums[0], colDatums[3]) < 0)
      return true;
    else
      return false;
  }

  public bool checkConnected(StuckEnemy se) {
    if (se.ofs.dist(ofs) > se.colSize + colSize)
      return false;
    se.addConnected(this);
    addConnected(se);
    return true;
  }

  public void addConnected(StuckEnemy se) {
    if (connectedEnemyNum >= CONNECTED_ENEMY_MAX)
      return;
    connectedEnemy[connectedEnemyNum] = se;
    connectedEnemyNum++;
    return;
  }

  public void scanConnected() {
    isConnected = true;
    for (int i = 0; i < connectedEnemyNum; i++) {
      if (connectedEnemy[i].isExist)
	if(!connectedEnemy[i].isConnected)
	  connectedEnemy[i].scanConnected();
    }
  }

  private void activateTopBullets() {
    for (int i = 0 ; i < topBulletNum; i++)
      if (topBullet[i].actor)
	topBullet[i].actor.bullet.deactivated = false;
  }

  private void deactivateTopBullets() {
    for (int i = 0 ; i < topBulletNum; i++)
      if (topBullet[i].actor)
	topBullet[i].actor.bullet.deactivated = true;
  }
}

public class StuckEnemyInitializer: ActorInitializer {
 private:
  Ship ship;
  Field field;
  BulletActorPool bullets;
  ActorPool fragments;
  SplinterPool splinters;
  GameManager manager;

  public this(Ship ship, Field field, BulletActorPool bullets, ActorPool fragments,
	      SplinterPool splinters, GameManager manager) {
    this.ship = ship;
    this.field = field;
    this.bullets = bullets;
    this.fragments = fragments;
    this.splinters = splinters;
    this.manager = manager;
  }
}

public class StuckEnemyPool: ActorPool {
 public:
  float pullInRatio;
  float totalSize;
 private:
  static const int PULLIN_CNT_MAX = 16;
  int pullInCnt;
  GameManager manager;

  public this(int n, ActorInitializer ini) {
    auto StuckEnemy seClass = new StuckEnemy;
    super(n, seClass, ini);
    manager = (cast(StuckEnemyInitializer) ini).manager;
  }

  public void init() {
    foreach (Actor ac; actor) {
      StuckEnemy se = cast(StuckEnemy) ac;
      se.setStuckEnemyPool(this);
    }
    initPullIn();
  }

  private void initPullIn() {
    pullInCnt = 0;
    pullInRatio = 1;
  }

  public bool checkHit(Vector pos) {
    if (pullInCnt > 0)
      return false;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (se.checkHit(pos))
	  return true;
      }
    }
    return false;
  }

  public StuckEnemy checkHitWithoutMyShip(Vector pos) {
    if (pullInCnt > 0)
      return null;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip && se.checkHit(pos))
	  return se;
      }
    }
    return null;
  }

  public void removeAllEnemies() {
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip) {
	  se.breakIntoFragments();
	  se.remove();
	}
      }
    }
    initPullIn();
  }

  public void flyinAllEnemies() {
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip) {
	  se.breakIntoSplinter();
	  se.remove();
	}
      }
    }
    initPullIn();
  }

  public bool checkConnected(StuckEnemy nse) {
    bool connected = false;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (se.checkConnected(nse))
	  connected = true;
      }
    }
    return connected;
  }

  public void removeStuckEnemy(StuckEnemy hse) {
    hse.breakIntoFragments();
    hse.remove();
    scanConnected();
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip && !se.isConnected) {
	  se.breakIntoFragments();
	  se.remove();
	}
      }
    }
  }

  private void scanConnected() {
    StuckEnemy myShip;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (se.isMyShip)
	  myShip = se;
	se.isConnected = false;
      }
    }
    myShip.scanConnected();
  }

  public void pullIn() {
    if (pullInCnt == 0)
      deactivateTopBullets();
    if (pullInCnt < PULLIN_CNT_MAX)
      pullInCnt++;
    pullInRatio = 1 - (cast(float) pullInCnt) / PULLIN_CNT_MAX;
  }

  public void pushOut() {
    if (pullInCnt > 0)
      pullInCnt--;
    if (pullInCnt == 0)
      activateTopBullets();
    pullInRatio = 1 - (cast(float) pullInCnt) / PULLIN_CNT_MAX;
  }

  private void activateTopBullets() {
    StuckEnemy myShip;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip)
	  se.activateTopBullets();
      }
    }
  }

  private void deactivateTopBullets() {
    StuckEnemy myShip;
    foreach (Actor ac; actor) {
      if (ac.isExist) {
	StuckEnemy se = cast(StuckEnemy) ac;
	if (!se.isMyShip)
	  se.deactivateTopBullets();
      }
    }
  }

  public override void move() {
    totalSize = 0;
    foreach (Actor ac; actor) {
      if (ac.isExist)
	ac.move();
    }
    if (manager.mode == GameManager.Mode.EXTRA)
      manager.setRank(totalSize * 0.02);
  }
}
