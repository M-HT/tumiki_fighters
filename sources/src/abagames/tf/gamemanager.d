/*
 * $Id: gamemanager.d,v 1.5 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.gamemanager;

private import std.math;
private import std.conv;
private import opengl;
private import SDL;
private import bulletml;
version (PANDORA) {
    import std.conv;
    import std.process;
}
private import abagames.util.rand;
private import abagames.util.actorpool;
private import abagames.util.vector;
private import abagames.util.sdl.gamemanager;
private import abagames.util.sdl.texture;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.sound;
private import abagames.tf.prefmanager;
private import abagames.tf.screen;
private import abagames.tf.ship;
private import abagames.tf.field;
private import abagames.tf.particle;
private import abagames.tf.fragment;
private import abagames.tf.bulletactor;
private import abagames.tf.bulletactorpool;
private import abagames.tf.barragemanager;
private import abagames.tf.soundmanager;
private import abagames.tf.letterrender;
private import abagames.tf.tumiki;
private import abagames.tf.enemy;
private import abagames.tf.stagemanager;
private import abagames.tf.splinter;
private import abagames.tf.scoresign;
private import abagames.tf.damagegauge;
private import abagames.tf.mobileletter;
private import abagames.tf.attractmanager;

/**
 * Manage the game status and actor pools.
 */
public class GameManager: abagames.util.sdl.gamemanager.GameManager {
 public:
  bool nowait = false;
  static enum State {
    START_GAME, IN_GAME, GAMEOVER, PAUSE, TITLE, END_GAME,
  }
  int state;
  int stage;
  static enum Mode {
    NORMAL, EXTRA
  }
  int mode = Mode.EXTRA;
 private:
  Pad pad;
  PrefManager prefManager;
  StageManager stageManager;
  Screen screen;
  Rand rand;
  Field field;
  Ship ship;
  ParticlePool particles;
  ActorPool fragments;
  BulletActorPool bullets;
  EnemyPool enemies;
  SplinterPool splinters;
  ActorPool signs;
  DamageGauge gauge;
  MobileLetterPool letters;
  AttractManager attractManager;
  int cnt;
  int pauseCnt;
  const float SLOWDOWN_START_BULLETS_SPEED = 30;
  float interval;
  int score;
  const int LEFT_BONUS_NORMAL = 10000;
  const int LEFT_BONUS_EXTRA = 30000;
  int leftBonus;
  const int LEFT_NUM = 2;
  int left;
  const int FIRST_EXTEND_NORMAL = 100000;
  const int EVERY_EXTEND_NORMAL = 300000;
  const int FIRST_EXTEND_EXTRA = 200000;
  const int EVERY_EXTEND_EXTRA = 500000;
  int firstExtend, everyExtend;
  int extendScore;
  const int BOSSTIMER_FREEZED = 999999999;
  int bossTimer;
  const int STAGE_END_CNT = 360;
  int bossDstCnt;
  const int CREDIT_NUM = 2;
  int credit;

  // Initialize actor pools, load BGMs/SEfs and textures.
  public override void init() {
    BarrageManager.loadBulletMLs();
    pad = cast(Pad) input;
    prefManager = cast(PrefManager) abstPrefManager;
    screen = cast(Screen) abstScreen;
    interval = mainLoop.INTERVAL_BASE;
    rand = new Rand;
    field = new Field;
    field.init();
    Particle.initRand();
    scope ParticleInitializer pi = new ParticleInitializer;
    particles = new ParticlePool(128, pi);
    Fragment.initRand();
    scope Fragment fragmentClass = new Fragment;
    scope FragmentInitializer fi = new FragmentInitializer;
    fragments = new ActorPool(128, fragmentClass, fi);
    Ship.initRand();
    ship = new Ship;
    ship.init(pad, field, particles, fragments, this);
    Splinter.initRand();
    scope SplinterInitializer si = new SplinterInitializer(ship, field, particles, this);
    splinters = new SplinterPool(144, si);
    scope BulletActorInitializer bi = new BulletActorInitializer(field, ship, particles, splinters);
    bullets = new BulletActorPool(512, bi);
    ship.setBulletActorPool(bullets);
    ship.initStuckEnemies(splinters);
    gauge = new DamageGauge;
    scope EnemyInitializer ei = new EnemyInitializer
      (this, field, bullets, ship, splinters, particles, fragments, gauge);
    enemies = new EnemyPool(64, ei);
    bullets.setEnemies(enemies);
    scope ScoreSignInitializer ssi = new ScoreSignInitializer;
    scope ScoreSign scoreSignClass = new ScoreSign;
    signs = new ActorPool(32, scoreSignClass, ssi);
    MobileLetter.initRand();
    scope MobileLetterInitializer mli = new MobileLetterInitializer;
    letters = new MobileLetterPool(32, mli, field);
    StagePattern.initStr();
    stageManager = new StageManager(this, enemies, field);
    bullets.setStageManager(stageManager);
    attractManager = new AttractManager(pad, prefManager, this);
    SoundManager.init(this);
    Tumiki.createDisplayLists();
    LetterRender.createDisplayLists();
  }

  public override void start() {
    stage = 0;
    startTitle();
  }

  public override void close() {
    BarrageManager.unloadBulletMLs();
    SoundManager.close();
    LetterRender.deleteDisplayLists();
    Tumiki.deleteDisplayLists();
  }

  private void startTitle() {
    state = State.TITLE;
    Music.haltMusic();
    if (stage >= StageManager.STAGE_NUM)
      stage = StageManager.STAGE_NUM - 1;
    field.start(stage);
    field.setGroundY(0);
    letters.clear();
    signs.clear();
    attractManager.startTitle();
  }

  private void startInGame() {
    state = State.IN_GAME;
    score = 0;
    left = LEFT_NUM;
    if (mode == Mode.NORMAL) {
      firstExtend = FIRST_EXTEND_NORMAL;
      everyExtend = EVERY_EXTEND_NORMAL;
      leftBonus = LEFT_BONUS_NORMAL;
    } else {
      firstExtend = FIRST_EXTEND_EXTRA;
      everyExtend = EVERY_EXTEND_EXTRA;
      leftBonus = LEFT_BONUS_EXTRA;
    }
    extendScore = firstExtend;
    startStage();
    field.setGroundY(0);
    Splinter.setSignNum(0);
    signs.clear();
  }

  public void startInGameFirst() {
    stage = 0;
    startInGame();
    state = State.START_GAME;
    ship.startStage();
    Splinter.setSignNum(2);
    credit = CREDIT_NUM;
  }

  public void startEnding() {
    state = State.END_GAME;
    ship.backToHome();
    addScore(left * leftBonus, ship.pos);
    left = 0;
    credit = 0;
    letters.add("MISSION COMPLETED!", 110, 400, 12, 500, 1);
    SoundManager.playBgmOnce(SoundManager.Bgm.ENDING);
  }

  public void drawWarning() {
    letters.add("WARNING", 132, 210, 32, 250, 0);
    letters.add("HERE COMES A GIGANTIC TOY", 80, 280, 10, 250, -3);
  }

  public void setInGame() {
    state = State.IN_GAME;
  }

  private string[] stageMessage =
    [
     "WE ARE TUMIKI FIGHTERS!",
     "JUST OVER THE HORIZON",
     "PANIC ON MEADOW",
     "COASTLINE UNDER FIRE",
     "JUNK CITY CENTRAL"
    ];
  private void startStage() {
    fragments.clear();
    particles.clear();
    letters.clear();
    enemies.clear();
    bullets.clear();
    splinters.clear();
    ship.start();
    stageManager.start(stage);
    field.start(stage);
    gauge.init();
    bossTimer = BOSSTIMER_FREEZED;
    bossDstCnt = -1;
    letters.add("STAGE " ~ to!string(stage + 1), 180, 150, 24, 240, -4);
    letters.add(stageMessage[stage], 320 - stageMessage[stage].length * 10, 270, 10, 240, -2);
    int si = stage % (SoundManager.STAGE_BGM_NUM * 2 - 1);
    if (si >= SoundManager.STAGE_BGM_NUM)
      si = SoundManager.STAGE_BGM_NUM * 2 - si - 2;
    SoundManager.playBgm(SoundManager.Bgm.STG1 + si);
  }

  public void startGameover() {
    state = State.GAMEOVER;
    setScreenShake(0, 0);
    letters.clear();
    interval = mainLoop.INTERVAL_BASE;
    mainLoop.interval = cast(int) interval;
    cnt = 0;
    prefManager.setHiScore(score, stage);
    Music.fadeMusic();

    version (PANDORA) {
        system(escapeShellCommand("fusilli", "--cache", "push", "tumiki_fighters", to!string(score), "0") ~ " >/dev/null 2>&1");
    }
  }

  private void startPause() {
    state = State.PAUSE;
    pauseCnt = 0;
  }

  private void resumePause() {
    state = State.IN_GAME;
  }

  public void addScore(int sc, Vector pos) {
    if (sc <= 0)
      return;
    score += sc;
    ScoreSign ss = cast(ScoreSign) signs.getInstanceForced();
    float s = 0.3 + cast(float) sc / 3000;
    if (s > 1.2)
      s = 1.2;
    ss.set(pos, sc, s);
    if (score > extendScore) {
      SoundManager.playSe(SoundManager.Se.EXTEND);
      left++;
      if (extendScore <= firstExtend)
	extendScore = everyExtend;
      else
	extendScore += everyExtend;
    }
  }

  public void shipDestroyed() {
    bullets.clearVisible();
    left--;
    if (left < 0)
      startGameover();
  }

  public int bossDestroyed() {
    Music.fadeMusic();
    bullets.clearVisible();
    ship.breakStuckEnemies();
    bullets.clear();
    if (bossDstCnt < 0)
      bossDstCnt = 0;
    // Boss destroyed bonus score.
    int bs = (cast(int) bossTimer / 60) * 10 + 10000;
    if (bs > 20000)
      bs = 20000;
    else if (bs < 10000)
      bs = 10000;
    if (mode == Mode.EXTRA)
      bs *= 3;
    return bs;
  }

  public void bossInAttack(int tm) {
    bossTimer = cast(int) (tm * 16.66667);
  }

  public void setRank(float r) {
    stageManager.setRank(r);
  }

  // Move actors in game(called once per frame).
  public override void move() {
    if (pad.keys[SDLK_ESCAPE] == SDL_PRESSED) {
      mainLoop.breakLoop();
      return;
    }
    switch (state) {
    case State.START_GAME:
    case State.IN_GAME:
    case State.END_GAME:
      moveInGame();
      break;
    case State.GAMEOVER:
      moveGameover();
      break;
    case State.PAUSE:
      movePause();
      break;
    case State.TITLE:
      moveTitle();
      break;
    default:
      break;
    }
    cnt++;
  }

  private bool pPrsd = true;

  private void moveInGame() {
    if (bossDstCnt > STAGE_END_CNT - 120 && stage >= StageManager.STAGE_NUM - 1) {
      stage++;
      bossDstCnt = -1;
      bossTimer = BOSSTIMER_FREEZED;
      startEnding();
      return;
    }
    if (bossDstCnt > STAGE_END_CNT) {
      stage++;
      startStage();
      return;
    } else if (bossDstCnt == STAGE_END_CNT - 119) {
      SoundManager.playSe(SoundManager.Se.PROPELLER);
    }
    if (state == State.IN_GAME)
      stageManager.move();
    field.move();
    splinters.move();
    if (bossDstCnt > STAGE_END_CNT - 120) {
      bullets.clearVisible();
      bullets.clear();
      ship.endMove();
    } else if (state == State.IN_GAME) {
      ship.move();
    } else if (state == State.START_GAME) {
      ship.startMove();
    } else {
      ship.backToHomeMove();
    }
    BulletActor.resetTotalBulletsSpeed();
    bullets.move();
    Enemy.resetTotalNum();
    enemies.move();
    particles.move();
    fragments.move();
    signs.move();
    gauge.move();
    letters.move();
    moveScreenShake();
    Tumiki.move();
    if (bossDstCnt >= 0) {
      bossDstCnt++;
      ship.breakStuckEnemies();
    } else if (bossTimer < BOSSTIMER_FREEZED) {
      bossTimer -= 17;
      if (bossTimer < 0) {
	bullets.clearVisible();
	bullets.clear();
	ship.breakStuckEnemies();
	bossTimer = 0;
	bossDstCnt = 0;
	Music.fadeMusic();
      }
    }
    if (pad.keys[SDLK_p] == SDL_PRESSED) {
      if (!pPrsd) {
	pPrsd = true;
	if (state == State.IN_GAME)
	  startPause();
      }
    } else {
      pPrsd = false;
    }
    /*if (!nowait) {
      // Intentional slowdown when the total speed of bullets is over SLOWDOWN_START_BULLETS_SPEED
      if (BulletActor.totalBulletsSpeed > SLOWDOWN_START_BULLETS_SPEED) {
	float sm = BulletActor.totalBulletsSpeed / SLOWDOWN_START_BULLETS_SPEED;
	if (sm > 1.75)
	  sm = 1.75;
	interval += (sm * mainLoop.INTERVAL_BASE - interval) * 0.1;
	mainLoop.interval = (int) interval;
      } else {
	interval += (mainLoop.INTERVAL_BASE - interval) * 0.08;
	mainLoop.interval = (int) interval;
      }
      }*/
  }

  private bool btnPrsd, arwPrsd;
  private bool isContinue;

  private void moveGameover() {
    bool gotoNextState = false;
    if (cnt == 48)
      letters.add("GAME OVER", 100, 230, 28, 400, 4);
    if (cnt <= 64) {
      btnPrsd = arwPrsd = true;
      isContinue = false;
    } else {
      if (pad.getButtonState() & (Pad.PAD_BUTTON1 | Pad.PAD_BUTTON2)) {
	if (!btnPrsd)
	  gotoNextState = true;
      } else {
	btnPrsd = false;
      }
      if (credit > 0) {
	int key = (pad.getPadState() & (Pad.PAD_LEFT | Pad.PAD_RIGHT));
	if (key != 0) {
	  if (!arwPrsd) {
	    arwPrsd = true;
	    if ((key & Pad.PAD_LEFT) != 0)
	      isContinue = true;
	    if ((key & Pad.PAD_RIGHT) != 0)
	      isContinue = false;
	  }
	} else {
	  arwPrsd = false;
	}
      }
    }
    if ((cnt > 64 && gotoNextState) || cnt > 700) {
      if (isContinue && cnt <= 700) {
	credit--;
	startInGame();
      } else {
	startTitle();
      }
    }
    field.move();
    bullets.move();
    enemies.move();
    particles.move();
    fragments.move();
    letters.move();
    Tumiki.move();
  }

  private void movePause() {
    pauseCnt++;
    if (pad.keys[SDLK_p] == SDL_PRESSED) {
      if (!pPrsd) {
	pPrsd = true;
	resumePause();
      }
    } else {
      pPrsd = false;
    }
  }

  private void moveTitle() {
    attractManager.moveTitle();
    field.move();
    Tumiki.move();
  }

  // Draw actors in game(called once per frame).
  public override void draw() {
    SDL_Event e = mainLoop.event;
    if (e.type == SDL_VIDEORESIZE) {
      SDL_ResizeEvent re = e.resize;
      if (re.w > 150 && re.h > 100) {
        screen.resized(re.w, re.h);
        screen.clear();
      }
    }
    screen.viewOrthoFixed();
    glDisable(GL_CULL_FACE);
    field.drawBack();
    glEnable(GL_CULL_FACE);
    screen.viewPerspective();

    glPushMatrix();
    setEyepos();
    switch (state) {
    case State.START_GAME:
    case State.IN_GAME:
    case State.PAUSE:
    case State.END_GAME:
      drawInGame();
      break;
    case State.GAMEOVER:
      drawGameover();
      break;
    case State.TITLE:
      drawTitle();
      break;
    default:
      break;
    }
    glPopMatrix();

    screen.viewOrthoFixed();
    glDisable(GL_CULL_FACE);
    letters.draw();
    switch (state) {
    case State.IN_GAME:
      drawStatusInGame();
      break;
    case State.GAMEOVER:
    case State.END_GAME:
      drawStatusGameover();
      break;
    case State.PAUSE:
      drawStatusPause();
      break;
    case State.TITLE:
      drawStatusTitle();
      break;
    case State.START_GAME:
      break;
    default:
      break;
    }
    glEnable(GL_CULL_FACE);
    screen.viewPerspective();
  }

  private void drawInGame() {
    glEnable(GL_DEPTH_TEST);
    field.draw();
    enemies.draw();
    splinters.draw();
    if (state == State.START_GAME)
      ship.drawFriendly();
    else if (state == State.END_GAME)
      ship.drawFriendlyBack();
    ship.draw();
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBegin(GL_QUADS);
    particles.draw();
    glEnd();
    glDisable(GL_BLEND);
    fragments.draw();
    bullets.drawShots();
    signs.draw();
    glEnable(GL_DEPTH_TEST);
    gauge.draw();
    drawLeft();
    glDisable(GL_DEPTH_TEST);
    glLineWidth(2);
    bullets.drawBullets();
    glLineWidth(1);
  }

  private void drawGameover() {
    glEnable(GL_DEPTH_TEST);
    field.draw();
    enemies.draw();
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBegin(GL_QUADS);
    particles.draw();
    glEnd();
    glDisable(GL_BLEND);
    fragments.draw();
    bullets.drawShots();
  }

  private void drawTitle() {
    glEnable(GL_DEPTH_TEST);
    field.draw();
    glDisable(GL_DEPTH_TEST);
  }

  private void drawInfo() {
    LetterRender.drawString("SCORE", 4, 4, 12, LetterRender.Direction.TO_RIGHT, -3);
    LetterRender.drawNum(score, 300, 4, 12, LetterRender.Direction.TO_RIGHT, 3);
    if (bossTimer < BOSSTIMER_FREEZED && (bossDstCnt & 31) > 8) {
      LetterRender.drawTime(bossTimer, 600, 32, 10, 3);
    }
  }

  private void drawLeft() {
    float x = -field.size.x * 0.85, sz = 0.4;
    for (int i = 0; i < left; i++, x += 2) {
      glPushMatrix();
      glScalef(sz, sz, sz);
      ship.drawLeft(x / sz, -field.size.y * 0.82 / sz, 1 / sz);
      glPopMatrix();
    }
  }

  private void drawStatusInGame() {
    drawInfo();
  }

  private void drawStatusGameover() {
    drawInfo();
    if (credit > 0 && cnt > 64) {
      LetterRender.drawString("CONTINUE", 280, 400, 10, LetterRender.Direction.TO_RIGHT, 1);
      if (isContinue) {
	LetterRender.drawString("YES", 480, 400, 12, LetterRender.Direction.TO_RIGHT, 0);
	LetterRender.drawString("NO", 562, 402, 8, LetterRender.Direction.TO_RIGHT, 2);
      } else {
	LetterRender.drawString("YES", 483, 402, 8, LetterRender.Direction.TO_RIGHT, 2);
	LetterRender.drawString("NO", 560, 400, 12, LetterRender.Direction.TO_RIGHT, 0);
      }
      LetterRender.drawString("CREDIT " ~ to!string(credit), 32, 420, 8,
			      LetterRender.Direction.TO_RIGHT, 3);
    }
  }

  private void drawStatusPause() {
    drawInfo();
    if ((pauseCnt % 60) < 30)
      LetterRender.drawString("PAUSE", 280, 220, 12, LetterRender.Direction.TO_RIGHT, -5);
  }

  private void drawStatusTitle() {
    attractManager.drawTitle();
  }

  private int screenShakeCnt;
  private float screenShakeIntense;

  public void setScreenShake(int cnt, float intense) {
    screenShakeCnt = cnt;
    screenShakeIntense = intense;
  }

  private void moveScreenShake() {
    if (screenShakeCnt > 0)
      screenShakeCnt--;
  }

  private void setEyepos() {
    float x = 0, y = 0;
    if (screenShakeCnt > 0) {
      x = rand.nextSignedFloat(screenShakeIntense * (screenShakeCnt + 10));
      y = rand.nextSignedFloat(screenShakeIntense * (screenShakeCnt + 10));
    }
    glTranslatef(x, y, -field.eyeZ);
  }
}
