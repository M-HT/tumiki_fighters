/*
 * $Id: stagemanager.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.stagemanager;

private import std.string;
private import std.math;
private import bulletml;
private import abagames.util.logger;
private import abagames.util.rand;
private import abagames.util.vector;
private import abagames.util.csv;
private import abagames.util.iterator;
private import abagames.util.actorpool;
private import abagames.util.logger;
private import abagames.util.bulletml.bullet;
private import abagames.util.sdl.sound;
private import abagames.tf.enemyspec;
private import abagames.tf.barragemanager;
private import abagames.tf.field;
private import abagames.tf.gamemanager;
private import abagames.tf.enemy;
private import abagames.tf.soundmanager;

/**
 * Handle the appearance of enemies.
 */
public class StageManager {
 public:
  static const int STAGE_NUM = 5;
  float rank, speedRank;
 private:
  static const int APPEARANCE_MAX = 8;
  GameManager manager;
  EnemyPool enemies;
  Field field;
  StagePattern[STAGE_NUM] stage;
  alias ArrayIterator!(EnemyAppearancePattern) EAPIterator;
  EAPIterator pattern;
  EnemyAppearancePattern nextApp;
  int cnt;
  EnemyAppearance[APPEARANCE_MAX] appearance;
  int eaIdx;
  Rand rand;
  int warningCnt;
  bool bossComing;

  public this(GameManager manager, EnemyPool enemies, Field field) {
    this.manager = manager;
    this.enemies = enemies;
    this.field = field;
    rand = new Rand;
    foreach (inout EnemyAppearance ea; appearance)
      ea = new EnemyAppearance;
    eaIdx = appearance.length;
    uint sn = 1;
    foreach (inout StagePattern sp; stage) {
      Logger.info("Load stage: " ~ std.string.toString(sn));
      sp = new StagePattern("stg" ~ std.string.toString(sn) ~ ".stg");
      sn++;
    }
    Logger.info("Load stages completed.");
  }

  public void start(int sn) {
    pattern = new EAPIterator(stage[sn].pattern);
    nextApp = pattern.next;
    rand.setSeed(stage[sn].randSeed);
    warningCnt = stage[sn].warningCnt;
    Bullet.setRandSeed(stage[sn].randSeed);
    cnt = 0;
    bossComing = false;
    rank = 0;
    speedRank = 1;
    foreach (EnemyAppearance ea; appearance)
      ea.cnt = -1;
  }

  private void setAppearance(EnemyAppearancePattern eap, bool isBoss) {
    eaIdx--;
    if (eaIdx < 0)
      eaIdx = appearance.length - 1;
    EnemyAppearance ea = appearance[eaIdx];
    ea.pattern = eap;
    ea.cnt = 0;
    ea.wait = eap.waitTillEnemiesDestroyed;
    ea.isBoss = isBoss;
  }

  public void move() {
    if (nextApp) {
      while (nextApp.startTime <= cnt) {
	setAppearance(nextApp, bossComing);
	if (bossComing)
	  bossComing = false;
	if (!pattern.hasNext) {
	  nextApp = null;
	  break;
	}
	nextApp = pattern.next;
      }
    }
    cnt++;
    if (cnt == warningCnt) {
      manager.drawWarning();
      bossComing = true;
      Music.fadeMusic();
    }
    if (cnt >= warningCnt && cnt <= warningCnt + 200 && (cnt - warningCnt) % 100 == 0)
      SoundManager.playSe(SoundManager.Se.WARNING);
    if (cnt == warningCnt + 240) {
      if (manager.stage == STAGE_NUM - 1)
	SoundManager.playBgm(SoundManager.Bgm.LAST_BOSS);
      else
	SoundManager.playBgm(SoundManager.Bgm.BOSS);
    }
    foreach (EnemyAppearance ea; appearance) {
      if (ea.cnt < 0)
	continue;
      if (ea.wait && Enemy.totalNum <= 0)
	ea.wait = false;
      if ((ea.cnt % ea.pattern.interval) == 0) {
	EnemyAppearancePattern p = ea.pattern;
	float x, y;
	switch (p.posType) {
	case EnemyAppearancePattern.AppearancePos.FRONT:
	  x = field.size.x - p.spec.sizeXm * 1.1f;
	  y = field.size.y * (p.pos + rand.nextSignedFloat(p.width));
	  break;
	case EnemyAppearancePattern.AppearancePos.TOP:
	  x = field.size.x * (p.pos + rand.nextSignedFloat(p.width));
	  y = field.size.y - p.spec.sizeYm * 1.1f;
	  break;
	}
	if (!ea.wait)
	  addEnemy(x, y, p.spec, p.move, ea.isBoss);
      }
      ea.cnt++;
      if (ea.cnt >= ea.pattern.duration) {
	ea.cnt = -1;
	continue;
      }
    }
  }

  private void addEnemy(float x, float y, EnemySpec spec, EnemyMovePattern move, bool isBoss) {
    Enemy en = cast(Enemy) enemies.getInstance();
    if (!en)
      return;
    en.set(x, y, spec, move, isBoss);
  }

  public void setRank(float r) {
    rank = r * 0.24;
  }
}

public class EnemyAppearance {
 public:
  EnemyAppearancePattern pattern;
  int cnt;
  bool wait;
  bool isBoss;
}

public class StagePattern {
 public:
  EnemyAppearancePattern[] pattern;
  long randSeed;
  int warningCnt;
 private:
  static const char[] STAGE_DIR_NAME = "stage";
  static int[char[]] posTypeStr;

  public static this() {
    posTypeStr["f"] = 0;
    posTypeStr["u"] = 1;
  }

  // Initialize StagePattern with the array.
  // randSeed, warningCnt
  // [startTime, duration, interval, posType(f(front), u(up)), pos, width,
  // waitTillAllEnemiesDestoryed,
  // EnemySpec file name,
  // move BulletML file name, {speedRank}/{withdrawCnt, speed, [x, y], [idx, speed, [x, y]]}],
  // (use PointsMovePattern when moveBulletML == "p", end when x == "e", idx == "e")
  public this(char[][] data) {
    StringIterator si = new StringIterator(data);
    randSeed = atoi(si.next);
    warningCnt = atoi(si.next);
    for (;;) {
      if (!si.hasNext)
	break;
      int startTime = atoi(si.next);
      int duration = atoi(si.next);
      int interval = atoi(si.next);
      char[] v = si.next;
      int posType = posTypeStr[v];
      float pos = atof(si.next);
      float width = atof(si.next);
      v = si.next;
      bool wted;
      if (v == "y")
	wted = true;
      else
	wted = false;
      v = si.next;
      EnemySpec es = EnemySpec.getInstance(v);
      EnemyAppearancePattern eap = new EnemyAppearancePattern
	(startTime, duration, interval, posType, pos, width, wted, es);
      float d;
      v = si.next;
      if (v == "p") {
	eap.startSetPointsMove();
	eap.setWithdrawCnt(atoi(si.next));
	int atIdx = PointsMovePattern.BASIC_PATTERN_IDX;
	for (;;) {
	  float speed = atof(si.next);
	  eap.setMoveSpeed(atIdx, speed);
	  for (;;) {
	    v = si.next;
	    if (v == "e")
	      break;
	    float x = atof(v);
	    float y = atof(si.next);
	    eap.addMovePoint(atIdx, x, y);
	  }
	  v = si.next;
	  if (v == "e")
	    break;
	  atIdx = atoi(v);
	}
      } else {
	eap.setMoveBulletML(v);
	eap.setSpeedRank(atof(si.next));
      }
      switch (posType) {
      case EnemyAppearancePattern.AppearancePos.FRONT:
	d = PI / 2 * 3;
	break;
      case EnemyAppearancePattern.AppearancePos.TOP:
	d = PI;
	break;
      }
      eap.setInitialDeg(d);
      pattern ~= eap;
    }
  }

  public this(char[] fileName) {
    char[][] data = CSVTokenizer.readFile(STAGE_DIR_NAME ~ "/" ~ fileName);
    this(data);
  }
}

public class EnemyAppearancePattern {
 public:
  static enum AppearancePos {
    FRONT, TOP,
  }
  int startTime, duration, interval;
  int posType;
  float pos, width;
  bool waitTillEnemiesDestroyed;
  EnemySpec spec;
  EnemyMovePattern move;

  public this(int st, int dr, int it, int pt, float p, float wt, bool wted, EnemySpec es) {
    startTime = st;
    duration = dr;
    interval = it;
    posType = pt;
    pos = p;
    width = wt;
    waitTillEnemiesDestroyed = wted;
    spec = es;
  }

  public void setInitialDeg(float d) {
    move.deg = d;
  }

  public void startSetPointsMove() {
    move = new PointsMovePattern;
  }

  public void setWithdrawCnt(int c) {
    (cast(PointsMovePattern) move).withdrawCnt = c;
  }

  public void setMoveSpeed(int idx, float s) {
    (cast(PointsMovePattern) move).speed[idx] = s;
  }

  public void addMovePoint(int idx, float x, float y) {
    (cast(PointsMovePattern) move).point[idx] ~= new Vector(x, y);
  }

  public void setMoveBulletML(char[] fn) {
    move = new BulletMLMovePattern;
    (cast(BulletMLMovePattern) move).parser = BarrageManager.getInstance(fn);
    if (!(cast(BulletMLMovePattern) move).parser)
      throw new Error("File not found: " ~ fn);
  }

  public void setSpeedRank(float s) {
    (cast(BulletMLMovePattern) move).speed = s;
  }
}

public abstract class EnemyMovePattern {
 public:
  float deg;
}

public class BulletMLMovePattern: EnemyMovePattern {
 public:
  BulletMLParser *parser;
  float speed;
}

public class PointsMovePattern: EnemyMovePattern {
 public:
  static const int BASIC_PATTERN_IDX = -1;
  Vector[][int] point;
  float[int] speed;
  int withdrawCnt;
}
