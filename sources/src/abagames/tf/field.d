/*
 * $Id: field.d,v 1.3 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.field;

private import std.string;
private import std.conv;
private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
private import abagames.util.vector;
private import abagames.util.actor;
private import abagames.util.actorpool;
private import abagames.util.rand;
private import abagames.util.logger;
private import abagames.util.csv;
private import abagames.util.iterator;
private import abagames.tf.screen;
private import abagames.tf.tumikiset;

/**
 * Stage field.
 */
public class Field {
 public:
  static const float GROUND_LEVEL = -17;
  static const int FIELD_NUM = 5;
  Vector size;
  float eyeZ;
 private:
  ActorPool fieldObjs;
  FieldPattern[FIELD_NUM] fieldPattern;
  FieldPattern pattern;
  Rand rand;
  float mnx;
  float groundY;

  public void init() {
    size = new Vector;
    size.x = 21;
    size.y = 16;
    eyeZ = 20;
    uint sn = 1;
    foreach (ref FieldPattern fp; fieldPattern) {
      Logger.info("Load field: " ~ to!string(sn));
      fp = new FieldPattern("fld" ~ to!string(sn) ~ ".fld");
      sn++;
    }
    Logger.info("Load fields completed.");
    scope FieldObj fieldObjClass = new FieldObj;
    scope FieldObjInitializer foi = new FieldObjInitializer(this);
    fieldObjs = new ActorPool(64, fieldObjClass, foi);
    rand = new Rand;
  }

  private static const float GROUND_Y = 280;
  private Vector[17] backMountPos;

  public void start(int sn) {
    pattern = fieldPattern[sn];
    rand.setSeed(pattern.randSeed);
    Screen.setClearColor(pattern.br, pattern.bg, pattern.bb, 1);
    foreach (FieldLinePattern flp; pattern.line)
      flp.cnt = flp.interval[rand.nextInt(cast(int)(flp.interval.length))];
    fieldObjs.clear();
    float x = 0, nx, tx, ty;
    for (int i = 0; i < 4; i++) {
      tx = i * 160 + 80 + rand.nextSignedFloat(30);
      ty = GROUND_Y - 5 - rand.nextFloat(25);
      nx =  160 + i * 160 + rand.nextSignedFloat(30);
      backMountPos[i * 2] = new Vector(x, GROUND_Y);
      backMountPos[i * 2 + 1] = new Vector(tx, ty);
      x = nx;
    }
    for (int i = 0; i < 8; i++) {
      backMountPos[8 + i] = new Vector(backMountPos[i].x + 640, backMountPos[i].y);
    }
    backMountPos[16] = new Vector(1280, GROUND_Y);
    mnx = 0;
  }

  public void move() {
    fieldObjs.move();
    foreach (FieldLinePattern flp; pattern.line) {
      flp.cnt--;
      if (flp.cnt <= 0) {
	FieldObj fo = cast(FieldObj) fieldObjs.getInstance();
	if (fo) {
	  TumikiSet ts = flp.tumikiSet[rand.nextInt(cast(int)(flp.tumikiSet.length))];
	  if (flp.onGround)
	    fo.setGround(ts, flp.z, pattern.scrollSpeed);
	  else
	    fo.setSky(ts, flp.z, pattern.scrollSpeed / 3 * 2, rand);
	}
	flp.cnt = flp.interval[rand.nextInt(cast(int)(flp.interval.length))];
      }
    }
    mnx += pattern.scrollSpeed;
    if (mnx >= 640)
      mnx -= 640;
  }

  public void draw() {
    fieldObjs.draw();
  }

  public void setGroundY(float y) {
    groundY = y;
  }

  public void drawBack() {
    const float gy1 = 400 - groundY;
    const float gy2 = GROUND_Y - groundY;
    const int quadNumVertices = 4;
    const GLfloat[3*quadNumVertices][2] quadVertices =
      [[ // first quad
          0, 480, 0,
        640, 480, 0,
        640, gy1, 0,
          0, gy1, 0
       ],
       [ // second quad
          0, gy1, 0,
        640, gy1, 0,
        640, gy2, 0,
          0, gy2, 0
       ]
      ];
    GLfloat[4*quadNumVertices][2] quadColors;
    int trianglesNumTriangles;
    const int trianglesNumVertices = 3 * cast(int)(backMountPos.length / 2);
    GLfloat[3*trianglesNumVertices] trianglesVertices;
    GLfloat[4*trianglesNumVertices] trianglesColors;

    foreach (i; 0..2) {
      foreach (j; 0..quadNumVertices) {
        if ((i == 0) || (j < 2)) {
          quadColors[i][j*4 + 0] = pattern.gr * Screen.brightness;
          quadColors[i][j*4 + 1] = pattern.gg * Screen.brightness;
          quadColors[i][j*4 + 2] = pattern.gb * Screen.brightness;
        } else {
          quadColors[i][j*4 + 0] = pattern.mrr * Screen.brightness;
          quadColors[i][j*4 + 1] = pattern.mrg * Screen.brightness;
          quadColors[i][j*4 + 2] = pattern.mrb * Screen.brightness;
        }
        quadColors[i][j*4 + 3] = 1;
      }
    }

    trianglesNumTriangles = 0;
    int idx = 0;
    foreach (i; 0..trianglesNumVertices) {
      if (idx + 2 >= cast(int)(backMountPos.length))
        break;
      const float x1 = (backMountPos[idx].x - mnx);
      const float x2 = (backMountPos[idx + 1].x - mnx);
      const float x3 = (backMountPos[idx + 2].x - mnx);
      if (x1 >= 640)
        break;
      if (x3 >= 0) {
        trianglesVertices[3*trianglesNumTriangles + 0] = x1;
        trianglesVertices[3*trianglesNumTriangles + 1] = backMountPos[idx].y - groundY;
        trianglesVertices[3*trianglesNumTriangles + 2] = 0;

        trianglesVertices[3*trianglesNumTriangles + 3] = x2;
        trianglesVertices[3*trianglesNumTriangles + 4] = backMountPos[idx + 1].y - groundY;
        trianglesVertices[3*trianglesNumTriangles + 5] = 0;

        trianglesVertices[3*trianglesNumTriangles + 6] = x3;
        trianglesVertices[3*trianglesNumTriangles + 7] = backMountPos[idx + 2].y - groundY;
        trianglesVertices[3*trianglesNumTriangles + 8] = 0;

        trianglesColors[4*trianglesNumTriangles + 0] = pattern.mrr * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 1] = pattern.mrg * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 2] = pattern.mrb * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 3] = 1;

        trianglesColors[4*trianglesNumTriangles + 4] = pattern.mtr * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 5] = pattern.mtg * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 6] = pattern.mtb * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 7] = 1;

        trianglesColors[4*trianglesNumTriangles + 8] = pattern.mrr * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 9] = pattern.mrg * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 10] = pattern.mrb * Screen.brightness;
        trianglesColors[4*trianglesNumTriangles + 11] = 1;

        trianglesNumTriangles += 3;
      }
      idx += 2;
    }

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    foreach (i; 0..2) {
      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(quadVertices[i].ptr));
      glColorPointer(4, GL_FLOAT, 0, cast(void *)(quadColors[i].ptr));
      glDrawArrays(GL_TRIANGLE_FAN, 0, quadNumVertices);
    }

    if (trianglesNumTriangles) {
      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(trianglesVertices.ptr));
      glColorPointer(4, GL_FLOAT, 0, cast(void *)(trianglesColors.ptr));
      glDrawArrays(GL_TRIANGLES, 0, trianglesNumTriangles);
    }

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }

  public bool checkHit(Vector p) {
    if (p.x < -size.x || p.x > size.x || p.y < -size.y || p.y > size.y)
      return true;
    return false;
  }

  public bool checkHit(Vector p, float space) {
    if (p.x < -size.x + space || p.x > size.x - space ||
	p.y < -size.y + space || p.y > size.y - space)
      return true;
    return false;
  }

  public bool checkHit(Vector p, float xm, float xp, float ym, float yp) {
    if (p.x < -size.x - xp || p.x > size.x - xm ||
	p.y < -size.y - yp || p.y > size.y - ym)
      return true;
    return false;
  }
}

public class FieldObj: Actor {
 private:
  Field field;
  Vector pos;
  float speed;
  float z;
  float fx;
  TumikiSet tumikiSet;

  public override Actor newActor() {
    return new FieldObj;
  }

  public override void init(ActorInitializer ini) {
    FieldObjInitializer foi = cast(FieldObjInitializer) ini;
    field = foi.field;
    pos = new Vector;
  }

  private float calcXLimit() {
    float sz = field.eyeZ - z;
    float x = field.size.x / field.eyeZ * sz * 1.3f;
    return x;
  }

  private float calcHeight() {
    return Field.GROUND_LEVEL - tumikiSet.sizeYm;
  }

  private float calcSkyHeight(Rand rand) {
    float sz = field.eyeZ - z;
    float y = field.size.y / field.eyeZ * sz * 0.8f;
    return rand.nextFloat(y);
  }

  private void set(TumikiSet ts, float z, float s) {
    tumikiSet = ts;
    this.z = z;
    pos.x = calcXLimit();
    fx = -pos.x;
    speed = s;
    isExist = true;
  }

  public void setGround(TumikiSet ts, float z, float s) {
    set(ts, z, s);
    pos.y = calcHeight();
  }

  public void setSky(TumikiSet ts, float z, float s, Rand rand) {
    set(ts, z, s);
    pos.y = calcSkyHeight(rand);
  }

  public override void move() {
    pos.x -= speed;
    if (pos.x < fx)
      isExist = false;
  }

  public override void draw() {
    tumikiSet.drawShade(pos, z, 2);
  }
}

public class FieldObjInitializer: ActorInitializer {
 private:
  Field field;

  public this(Field field) {
    this.field = field;
  }
}

public class FieldPattern {
 public:
  FieldLinePattern[] line;
  long randSeed;
  float scrollSpeed;
  float br, bg, bb;
  float gr, gg, gb;
  float mtr, mtg, mtb;
  float mrr, mrg, mrb;
 private:
  static string FIELD_DIR_NAME = "field";

  // Initialize FieldPattern with the array.
  // randSeed, scrollSpeed,
  // [z, [interval], [TumikiSetName]]
  // (end when interval == "e", TumikiSetName == "e")
  public this(char[][] data) {
    StringIterator si = new StringIterator(data);
    randSeed = to!int(si.next);
    scrollSpeed = to!float(si.next);
    br = to!float(si.next); bg = to!float(si.next); bb = to!float(si.next);
    gr = to!float(si.next); gg = to!float(si.next); gb = to!float(si.next);
    mtr = to!float(si.next); mtg = to!float(si.next); mtb = to!float(si.next);
    mrr = (br * 2+ gr) / 3;
    mrg = (bg * 2+ gg) / 3;
    mrb = (bb * 2+ gb) / 3;
    for (;;) {
      if (!si.hasNext)
	break;
      float z = to!float(si.next);
      FieldLinePattern flp = new FieldLinePattern;
      if (z > 0) {
	flp.z = -z;
	flp.onGround = true;
      } else {
	flp.z = z;
	flp.onGround = false;
      }
      for (;;) {
	char[] v = si.next;
	if (v == "e")
	  break;
	flp.addInterval(to!int(v));
      }
      for (;;) {
	char[] v = si.next;
	if (v == "e")
	  break;
	flp.addTumikiSet(TumikiSet.getInstance(v.idup));
      }
      line ~= flp;
    }
  }

  public this(string fileName) {
    char[][] data = CSVTokenizer.readFile(FIELD_DIR_NAME ~ "/" ~ fileName);
    this(data);
  }
}

public class FieldLinePattern {
 public:
  TumikiSet[] tumikiSet;
  int[] interval;
  float z;
  int cnt;
  bool onGround;
 private:

  public void addTumikiSet(TumikiSet ts) {
    tumikiSet ~= ts;
  }

  public void addInterval(int it) {
    interval ~= it;
  }
}
