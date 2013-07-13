/*
 * $Id: tumiki.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.tumiki;

private import std.math;
private import opengl;
private import bulletml;
private import abagames.util.vector;
private import abagames.util.bulletml.bullet;
private import abagames.tf.screen;
private import abagames.tf.barragemanager;
private import abagames.tf.bulletactor;
private import abagames.tf.bulletactorpool;
private import abagames.tf.bullettarget;
private import abagames.tf.bulletinst;

/**
 * Handle a tumiki(Brick).
 */
public class Tumiki {
 public:
  static const int SHAPE_NUM = 10;
  static const int SHADE_NUM = 4;
  static int displayListIdx;
  Vector ofs;
  Vector size, checkHitSize;
  int shape, color;
 private:
  Barrage[] barrage;
  static int propellerCnt = 0;

  private const float CHECK_HIT_SIZE_RETIO = 0.7;

  public this(int shape, int color,
	      float x, float y, float sx, float sy, float sizeRatio) {
    this.shape = shape;
    this.color = color;
    ofs = new Vector(x * sizeRatio, y * sizeRatio);
    size = new Vector(sx * sizeRatio * 0.5 - 0.15, sy * sizeRatio * 0.5 - 0.15);
    checkHitSize = new Vector(size.x + CHECK_HIT_SIZE_RETIO,
			      size.y + CHECK_HIT_SIZE_RETIO);
    barrage = null;
  }

  public void addBarrage(Barrage br) {
    barrage ~= br;
  }

  public BulletActor addTopBullet(int barragePtnIdx, BulletActorPool bullets,
				  BulletTarget target, int type) {
    if (!barrage)
      return null;
    Barrage b = barrage[barragePtnIdx];
    return b.addTopBullet(bullets, target, type);
  }

  public static void move() {
    propellerCnt++;
  }

  static const float PROPELLER_OFFSET = 2.2;
  static const int PROPELLER_SHAPE = 9;
  static const int PROPELLER_SHAPE_FRONT = 14;

  private void drawPropeller(float deg, int shade) {
    float d = (shape - PROPELLER_SHAPE) * PI / 4 + deg;
    glRotatef(propellerCnt * 17 / size.x, -sin(d), cos(d), 0);
    glRotatef(rtod(d), 0, 0, 1);
    glPushMatrix();
    glTranslatef(-size.x * PROPELLER_OFFSET, 0, 0);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET, 0, 0);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
  }

  private void drawPropellerFront(float deg, int shade) {
    float d = deg;
    glRotatef(90, 1, 0, 0);
    glRotatef(propellerCnt * 17 / size.x, -sin(d), cos(d), 0);
    glRotatef(rtod(d), 0, 0, 1);
    glPushMatrix();
    glTranslatef(-size.x * PROPELLER_OFFSET, (size.x  + size.y) / 2, (size.x  + size.y) / 2);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET, (size.x  + size.y) / 2, (size.x  + size.y) / 2);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
  }

  private void drawPropeller(float deg, int shade, float sz) {
    float d = (shape - PROPELLER_SHAPE) * PI / 4 + deg;
    glRotatef(propellerCnt * 17 / size.x, -sin(d), cos(d), 0);
    glRotatef(rtod(d), 0, 0, 1);
    glPushMatrix();
    glTranslatef(-size.x * PROPELLER_OFFSET * sz, 0, 0);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET * sz, 0, 0);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
  }

  private void drawPropellerFront(float deg, int shade, float sz) {
    float d = deg;
    glRotatef(90, 1, 0, 0);
    glRotatef(propellerCnt * 17 / size.x, -sin(d), cos(d), 0);
    glRotatef(rtod(d), 0, 0, 1);
    glPushMatrix();
    glTranslatef(-size.x * PROPELLER_OFFSET * sz,
		 (size.x  + size.y) / 2 * sz, (size.x  + size.y) / 2 * sz);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET * sz,
		 (size.x  + size.y) / 2 * sz, (size.x  + size.y) / 2 * sz);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    glCallList(displayListIdx + PROPELLER_SHAPE +
	       color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    glPopMatrix();
  }

  public void draw(Vector pos, float z, int shade, float deg) {
    glPushMatrix();
    float ox = ofs.x * cos(deg) - ofs.y * sin(deg);
    float oy = ofs.x * sin(deg) + ofs.y * cos(deg);
    glTranslatef(pos.x + ox, pos.y + oy, z);
    if (shape < PROPELLER_SHAPE) {
      glRotatef(rtod(deg), 0, 0, 1);
      glScalef(size.x, size.y, (size.x  + size.y) / 2);
      glCallList(displayListIdx + shape + color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    } else if (shape == PROPELLER_SHAPE_FRONT) {
      drawPropellerFront(deg, shade);
    } else {
      drawPropeller(deg, shade);
    }
    glPopMatrix();
  }

  public void draw(Vector pos, float z, int shade, float deg, float sz) {
    glPushMatrix();
    float ox = ofs.x * cos(deg) - ofs.y * sin(deg);
    float oy = ofs.x * sin(deg) + ofs.y * cos(deg);
    ox *= sz;
    oy *= sz;
    glTranslatef(pos.x + ox, pos.y + oy, z);
    if (shape < PROPELLER_SHAPE) {
      glRotatef(rtod(deg), 0, 0, 1);
      glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
      glCallList(displayListIdx + shape + color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    } else if (shape == PROPELLER_SHAPE_FRONT) {
      drawPropellerFront(deg, shade, sz);
    } else {
      drawPropeller(deg, shade, sz);
    }
    glPopMatrix();
  }

  public void draw(Vector pos, float z, int shade) {
    draw(pos.x, pos.y, z, shade, false, false);
  }

  public void draw(float x, float y, float z, int shade, bool damaged, bool wounded) {
    glPushMatrix();
    glTranslatef(x + ofs.x, y + ofs.y, z);
    if (shape < PROPELLER_SHAPE) {
      glScalef(size.x, size.y, (size.x  + size.y) / 2);
      if (damaged)
	glCallList
	  (displayListIdx + shape + DAMAGED_COLOR * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
      else if (wounded)
	glCallList
	  (displayListIdx + shape + WOUNDED_COLOR * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
      else
	glCallList
	  (displayListIdx + shape + color * SHAPE_NUM + shade * SHAPE_NUM * COLOR_NUM);
    } else if (shape == PROPELLER_SHAPE_FRONT) {
      drawPropellerFront(0, shade);
    } else {
      drawPropeller(0, shade);
    }
    glPopMatrix();
  }

  private bool checkDistHit(float x, float y, Vector ofs, Vector size) {
    float ox = x - ofs.x;
    float oy = y - ofs.y;
    if (ox > -checkHitSize.x && ox < checkHitSize.x &&
	oy > -checkHitSize.y && oy < checkHitSize.y)
      return true;
    return false;
  }

  public bool checkHit(Vector p, float px, float py) {
    if (shape != 0)
      return false;
    return checkDistHit(p.x - px, p.y - py, ofs, size);
  }

  public static const int COLOR_NUM = 12;
  private static const int DISPLAY_LIST_NUM = SHAPE_NUM * COLOR_NUM * SHADE_NUM;
  public static const int DAMAGED_COLOR = 6;
  public static const int WOUNDED_COLOR = 0;
  private static const float[3][COLOR_NUM] colorParams =
    [
     [0.9, 0.6, 0.6], [0.6, 0.9, 0.6], [0.6, 0.6, 0.9],
     [0.8, 0.8, 0.6], [0.8, 0.6, 0.8], [0.6, 0.8, 0.8],
     [0.8, 0.8, 0.8], [0.5, 0.5, 0.5],
     [1, 0.7, 0.5], [0.7, 0.9, 1], [1, 0.5, 0.8],
     [0.6, 0.6, 0.3],
    ];
  private static const float DEPTH = -2;
  private static const float LINE_PADDING = 0.03;

  private static void setFrontColor(int j, int i) {
    switch (i) {
    case 1:
      Screen.setColor
	(colorParams[j][0] * 0.8, colorParams[j][1] * 0.8, colorParams[j][2] * 0.8);
      break;
    case 2:
      Screen.setColor
	(colorParams[j][0] * 0.5, colorParams[j][1] * 0.5, colorParams[j][2] * 0.5);
      break;
    default:
      Screen.setColor
	(colorParams[j][0] * 0.9, colorParams[j][1] * 0.9, colorParams[j][2] * 0.9);
      break;
    }
  }

  private static void setSideColor(int j, int i) {
    switch (i) {
    case 0:
      Screen.setColor
	(colorParams[j][0] * 0.7, colorParams[j][1] * 0.7, colorParams[j][2] * 0.7);
      break;
    case 1:
      Screen.setColor
	(colorParams[j][0] * 0.6, colorParams[j][1] * 0.6, colorParams[j][2] * 0.6);
      break;
    case 2:
      Screen.setColor
	(colorParams[j][0] * 0.4, colorParams[j][1] * 0.4, colorParams[j][2] * 0.4);
      break;
    default:
      break;
    }
  }

  public static void createDisplayLists() {
    displayListIdx = glGenLists(DISPLAY_LIST_NUM);
    int di = displayListIdx;
    for (int i = 0; i < SHADE_NUM; i++) {
      for (int j = 0; j < COLOR_NUM; j++) {
	glNewList(di, GL_COMPILE);
	setFrontColor(j, i);
	glBegin(GL_QUADS);
	glVertex3f(1, 1, 0);
	glVertex3f(-1, 1, 0);
	glVertex3f(-1, -1, 0);
	glVertex3f(1, -1, 0);
	if (i < 3) {
	  setSideColor(j, i);
	  glVertex3f(-1, 1, 0);
	  glVertex3f(1, 1, 0);
	  glVertex3f(1, 1, DEPTH);
	  glVertex3f(-1, 1, DEPTH);
	  glVertex3f(-1, -1, 0);
	  glVertex3f(-1, 1, 0);
	  glVertex3f(-1, 1, DEPTH);
	  glVertex3f(-1, -1, DEPTH);
	  glVertex3f(1, -1, 0);
	  glVertex3f(-1, -1, 0);
	  glVertex3f(-1, -1, DEPTH);
	  glVertex3f(1, -1, DEPTH);
	  glVertex3f(1, 1, 0);
	  glVertex3f(1, -1, 0);
	  glVertex3f(1, -1, DEPTH);
	  glVertex3f(1, 1, DEPTH);
	}
	glEnd();
	if (i == 0 || i == 3) {
	  Screen.setColor
	    (colorParams[j][0], colorParams[j][1], colorParams[j][2]);
	  glBegin(GL_LINE_STRIP);
	  if (i == 0) {
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glVertex3f(1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	  } else {
	    glVertex3f(1, 1, 0);
	    glVertex3f(-1, 1, 0);
	    glVertex3f(-1, -1, 0);
	    glVertex3f(1, -1, 0);
	    glVertex3f(1, 1, 0);
	  }
	  glEnd();
	  if (i == 0) {
	    Screen.setColor
	      (colorParams[j][0] * 0.8, colorParams[j][1] * 0.8, colorParams[j][2] * 0.8);
	    glBegin(GL_LINES);
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, DEPTH);
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, DEPTH);
	    glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH);
	    glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glVertex3f(1 + LINE_PADDING, -1 - LINE_PADDING, DEPTH);
	    glVertex3f(1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glEnd();
	  }
	}
	glEndList();
	di++;
	for (int k = 0; k < 4; k++) {
	  glNewList(di, GL_COMPILE);
	  glRotatef(-90 * k, 0, 0, 1);
	  setFrontColor(j, i);
	  glBegin(GL_TRIANGLE_STRIP);
	  glVertex3f(1, 1, 0);
	  glVertex3f(-1, 1, 0);
	  glVertex3f(-1, -1, 0);
	  glEnd();
	  if (i < 3) {
	    setSideColor(j, i);
	    glBegin(GL_QUADS);
	    glVertex3f(-1, 1, 0);
	    glVertex3f(1, 1, 0);
	    glVertex3f(1, 1, DEPTH);
	    glVertex3f(-1, 1, DEPTH);
	    glVertex3f(-1, -1, 0);
	    glVertex3f(-1, 1, 0);
	    glVertex3f(-1, 1, DEPTH);
	    glVertex3f(-1, -1, DEPTH);
	    glVertex3f(1, 1, 0);
	    glVertex3f(-1, -1, 0);
	    glVertex3f(-1, -1, DEPTH);
	    glVertex3f(1, 1, DEPTH);
	    glEnd();
	  }
	  if (i == 0 || i == 3) {
	    Screen.setColor
	      (colorParams[j][0], colorParams[j][1], colorParams[j][2]);
	    glBegin(GL_LINE_STRIP);
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	    glEnd();
	    if (i == 0) {
	      Screen.setColor
		(colorParams[j][0] * 0.8, colorParams[j][1] * 0.8, colorParams[j][2] * 0.8);
	      glBegin(GL_LINES);
	      glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, DEPTH);
	      glVertex3f(1 + LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	      glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, DEPTH);
	      glVertex3f(-1 - LINE_PADDING, 1 + LINE_PADDING, LINE_PADDING);
	      glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH);
	      glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	      glEnd();
	    }
	  }
	  glEndList();
	  di++;
	}
	for (int k = 0; k < 4; k++) {
	  glNewList(di, GL_COMPILE);
	  glRotatef(-90 * k, 0, 0, 1);
	  setFrontColor(j, i);
	  glBegin(GL_TRIANGLE_STRIP);
	  glVertex3f(1, -1, 0);
	  glVertex3f(0, 1, 0);
	  glVertex3f(-1, -1, 0);
	  glEnd();
	  if (i < 3) {
	    setSideColor(j, i);
	    glBegin(GL_QUADS);
	    glVertex3f(0, 1, 0);
	    glVertex3f(1, -1, 0);
	    glVertex3f(1, -1, DEPTH);
	    glVertex3f(0, 1, DEPTH);
	    glVertex3f(-1, -1, 0);
	    glVertex3f(0, 1, 0);
	    glVertex3f(0, 1, DEPTH);
	    glVertex3f(-1, -1, DEPTH);
	    glVertex3f(1, -1, 0);
	    glVertex3f(-1, -1, 0);
	    glVertex3f(-1, -1, DEPTH);
	    glVertex3f(1, -1, DEPTH);
	    glEnd();
	  }
	  if (i == 0 || i == 3) {
	    Screen.setColor
	      (colorParams[j][0], colorParams[j][1], colorParams[j][2]);
	    glBegin(GL_LINE_STRIP);
	    glVertex3f(1 + LINE_PADDING, -1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(0, 1 + LINE_PADDING, LINE_PADDING);
	    glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glVertex3f(1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	    glEnd();
	    if (i == 0) {
	      Screen.setColor
		(colorParams[j][0] * 0.8, colorParams[j][1] * 0.8, colorParams[j][2] * 0.8);
	      glBegin(GL_LINES);
	      glVertex3f(1 + LINE_PADDING, -1 - LINE_PADDING, DEPTH);
	      glVertex3f(1 + LINE_PADDING, -1 + LINE_PADDING, LINE_PADDING);
	      glVertex3f(0, 1 + LINE_PADDING, DEPTH);
	      glVertex3f(0, 1 + LINE_PADDING, LINE_PADDING);
	      glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH);
	      glVertex3f(-1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING);
	      glEnd();
	    }
	  }
	  glEndList();
	  di++;
	}
	glNewList(di, GL_COMPILE);
	setFrontColor(j, i);
	glBegin(GL_QUADS);
	glVertex3f(1, 1, 0);
	glVertex3f(-1, 1, 0);
	glVertex3f(-1, -1, 0);
	glVertex3f(1, -1, 0);
	glVertex3f(1, 1, DEPTH);
	glVertex3f(1, -1, DEPTH);
	glVertex3f(-1, -1, DEPTH);
	glVertex3f(-1, 1, DEPTH);
	if (i < 3) {
	  setSideColor(j, i);
	  glVertex3f(-1, 1, 0);
	  glVertex3f(1, 1, 0);
	  glVertex3f(1, 1, DEPTH);
	  glVertex3f(-1, 1, DEPTH);
	  glVertex3f(-1, -1, 0);
	  glVertex3f(-1, 1, 0);
	  glVertex3f(-1, 1, DEPTH);
	  glVertex3f(-1, -1, DEPTH);
	  glVertex3f(1, -1, 0);
	  glVertex3f(-1, -1, 0);
	  glVertex3f(-1, -1, DEPTH);
	  glVertex3f(1, -1, DEPTH);
	  glVertex3f(1, 1, 0);
	  glVertex3f(1, -1, 0);
	  glVertex3f(1, -1, DEPTH);
	  glVertex3f(1, 1, DEPTH);
	}
	glEnd();
	glEndList();
	di++;
      }
    }
  }

  public static void deleteDisplayLists() {
    glDeleteLists(displayListIdx, DISPLAY_LIST_NUM);
  }
}

/**
 * Barrage pattern.
 */
public class Barrage {
 public:
  BulletMLParser *parser[];
  float[] rank;
  float[] speed;
  int shape, color;
  float size;
  float yReverse;
  int prevWait, postWait;
 private:

  // Create a empty barrage.
  public this() {
    size = 0;
  }

  public this(int shape, int color, float size, float yReverse, int prevWait, int postWait) {
    this.shape = shape;
    this.color = color;
    this.size = size;
    this.yReverse = yReverse;
    this.prevWait = prevWait;
    this.postWait = postWait;
  }

  public void addBml(string bmlFileName, float r, float s) {
    BulletMLParser *p = BarrageManager.getInstance(bmlFileName);
    if (!p)
      throw new Error("File not found: " ~ bmlFileName);
    parser ~= p;
    rank ~= r;
    speed ~= s;
  }

  private static const int SHOT_COLOR = 3;

  public BulletActor addTopBullet(BulletActorPool bullets,
				  BulletTarget target, int type) {
    if (size <= 0)
      return null;
    int cl;
    float xrev, yrev;
    switch (type) {
    case BulletInst.Type.ENEMY:
      cl = color;
      xrev = yrev = 1;
      break;
    case BulletInst.Type.SHIP:
      cl = SHOT_COLOR;
      xrev = yrev = -1;
      break;
    default:
      break;
    }
    return bullets.addTopBullet(parser, rank, speed,
				0, 0, PI / 2 * 3, 0,
				shape, cl, size, xrev, yReverse * yrev, target, type,
				prevWait, postWait);
  }
}

