/*
 * $Id: tumiki.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.tumiki;

version (PANDORA) {
  private import std.conv;
}
private import std.math;
version (USE_GLES) {
  private import opengles;
} else {
  private import opengl;
}
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
  static const int COLOR_NUM = 12;
  static const int DAMAGED_COLOR = 6;
  static const int WOUNDED_COLOR = 0;
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
    drawShape(PROPELLER_SHAPE, color, shade);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET, 0, 0);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    drawShape(PROPELLER_SHAPE, color, shade);
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
    drawShape(PROPELLER_SHAPE, color, shade);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET, (size.x  + size.y) / 2, (size.x  + size.y) / 2);
    glScalef(size.x, size.y, (size.x  + size.y) / 2);
    drawShape(PROPELLER_SHAPE, color, shade);
    glPopMatrix();
  }

  private void drawPropeller(float deg, int shade, float sz) {
    float d = (shape - PROPELLER_SHAPE) * PI / 4 + deg;
    glRotatef(propellerCnt * 17 / size.x, -sin(d), cos(d), 0);
    glRotatef(rtod(d), 0, 0, 1);
    glPushMatrix();
    glTranslatef(-size.x * PROPELLER_OFFSET * sz, 0, 0);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    drawShape(PROPELLER_SHAPE, color, shade);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET * sz, 0, 0);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    drawShape(PROPELLER_SHAPE, color, shade);
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
    drawShape(PROPELLER_SHAPE, color, shade);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(size.x * PROPELLER_OFFSET * sz,
		 (size.x  + size.y) / 2 * sz, (size.x  + size.y) / 2 * sz);
    glScalef(size.x * sz, size.y * sz, (size.x  + size.y) / 2 * sz);
    drawShape(PROPELLER_SHAPE, color, shade);
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
      drawShape(shape, color, shade);
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
      drawShape(shape, color, shade);
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
	drawShape(shape, DAMAGED_COLOR, shade);
      else if (wounded)
	drawShape(shape, WOUNDED_COLOR, shade);
      else
	drawShape(shape, color, shade);
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

  private static const int DISPLAY_LIST_NUM = SHAPE_NUM * COLOR_NUM * SHADE_NUM;
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
  private static GLenum[][SHAPE_NUM][COLOR_NUM][SHADE_NUM] shapeDrawMode;
  private static GLfloat[][][SHAPE_NUM][COLOR_NUM][SHADE_NUM] shapeVertices;
  private static GLfloat[][][SHAPE_NUM][COLOR_NUM][SHADE_NUM] shapeColors;

  public static void drawShape(int shape, int color, int shade) {
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    foreach (i; 0..shapeDrawMode[shade][color][shape].length) {
      glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices[shade][color][shape][i].ptr));
      glColorPointer(4, GL_FLOAT, 0, cast(void *)(shapeColors[shade][color][shape][i].ptr));
      glDrawArrays(shapeDrawMode[shade][color][shape][i], 0, cast(int)(shapeColors[shade][color][shape][i].length / 4));
    }

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }

  public static void setColor(int j, float m, ref GLfloat[4] color) {
    color[0] = colorParams[j][0] * m * Screen.brightness;
    color[1] = colorParams[j][1] * m * Screen.brightness;
    color[2] = colorParams[j][2] * m * Screen.brightness;
    color[3] = 1;
  }

  public static void setFrontColor(int j, int i, ref GLfloat[4] color) {
    switch (i) {
    case 1:
      color[0] = colorParams[j][0] * 0.8 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.8 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.8 * Screen.brightness;
      color[3] = 1;
      break;
    case 2:
      color[0] = colorParams[j][0] * 0.5 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.5 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.5 * Screen.brightness;
      color[3] = 1;
      break;
    default:
      color[0] = colorParams[j][0] * 0.9 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.9 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.9 * Screen.brightness;
      color[3] = 1;
      break;
    }
  }

  private static void setSideColor(int j, int i, ref GLfloat[4] color) {
    switch (i) {
    case 0:
      color[0] = colorParams[j][0] * 0.7 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.7 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.7 * Screen.brightness;
      color[3] = 1;
      break;
    case 1:
      color[0] = colorParams[j][0] * 0.6 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.6 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.6 * Screen.brightness;
      color[3] = 1;
      break;
    case 2:
      color[0] = colorParams[j][0] * 0.4 * Screen.brightness;
      color[1] = colorParams[j][1] * 0.4 * Screen.brightness;
      color[2] = colorParams[j][2] * 0.4 * Screen.brightness;
      color[3] = 1;
      break;
    default:
      break;
    }
  }

  private static void prepareShapes1(int i, int j, int shape) {
    GLfloat[4] currentColor;
    int currentIdx;

    if (i < 3) {
      shapeDrawMode[i][j][shape].length = 1 + 4;
      shapeVertices[i][j][shape].length = 1 + 4;
      shapeColors[i][j][shape].length = 1 + 4;
    } else {
      shapeDrawMode[i][j][shape].length = 1;
      shapeVertices[i][j][shape].length = 1;
      shapeColors[i][j][shape].length = 1;
    }

    setFrontColor(j, i, currentColor);

    currentIdx = 0;
    shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
    shapeVertices[i][j][shape][currentIdx] = [
       1,  1, 0,
      -1,  1, 0,
      -1, -1, 0,
       1, -1, 0
    ];
    shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

    if (i < 3) {
      setSideColor(j, i, currentColor);

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, 1, 0,
         1, 1, 0,
         1, 1, DEPTH,
        -1, 1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, -1, 0,
        -1,  1, 0,
        -1,  1, DEPTH,
        -1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
         1, -1, 0,
        -1, -1, 0,
        -1, -1, DEPTH,
         1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        1,  1, 0,
        1, -1, 0,
        1, -1, DEPTH,
        1,  1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0 || i == 3) {
      setColor(j, 1, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINE_STRIP;
      if (i == 0) {
        shapeVertices[i][j][shape][currentIdx] = [
           1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
          -1 - LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
          -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING,
           1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING,
           1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING
        ];
      } else {
        shapeVertices[i][j][shape][currentIdx] = [
           1,  1, 0,
          -1,  1, 0,
          -1, -1, 0,
           1, -1, 0,
           1,  1, 0
        ];
      }
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0) {
      setColor(j, 0.8, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINES;
      shapeVertices[i][j][shape][currentIdx] = [
         1 + LINE_PADDING,  1 + LINE_PADDING, DEPTH,
         1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING,  1 + LINE_PADDING, DEPTH,
        -1 - LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH,
        -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING,
         1 + LINE_PADDING, -1 - LINE_PADDING, DEPTH,
         1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor
                                             ~ currentColor ~ currentColor
                                             ~ currentColor ~ currentColor
                                             ~ currentColor ~ currentColor;
    }
  }

  private static void prepareShapes2(int i, int j, int k, int shape) {
    GLfloat[4] currentColor;
    int currentIdx;

    if (i < 3) {
      shapeDrawMode[i][j][shape].length = 1 + 3;
      shapeVertices[i][j][shape].length = 1 + 3;
      shapeColors[i][j][shape].length = 1 + 3;
    } else {
      shapeDrawMode[i][j][shape].length = 1;
      shapeVertices[i][j][shape].length = 1;
      shapeColors[i][j][shape].length = 1;
    }

    setFrontColor(j, i, currentColor);

    currentIdx = 0;
    shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_STRIP;
    shapeVertices[i][j][shape][currentIdx] = [
       1,  1, 0,
      -1,  1, 0,
      -1, -1, 0
    ];
    shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor;

    if (i < 3) {
      setSideColor(j, i, currentColor);

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, 1, 0,
         1, 1, 0,
         1, 1, DEPTH,
        -1, 1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, -1, 0,
        -1,  1, 0,
        -1,  1, DEPTH,
        -1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
         1,  1, 0,
        -1, -1, 0,
        -1, -1, DEPTH,
         1,  1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0 || i == 3) {
      setColor(j, 1, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINE_STRIP;
      shapeVertices[i][j][shape][currentIdx] = [
         1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING,
         1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0) {
      setColor(j, 0.8, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINES;
      shapeVertices[i][j][shape][currentIdx] = [
         1 + LINE_PADDING,  1 + LINE_PADDING, DEPTH,
         1 + LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING,  1 + LINE_PADDING, DEPTH,
        -1 - LINE_PADDING,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH,
        -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor
                                             ~ currentColor ~ currentColor
                                             ~ currentColor ~ currentColor;
    }

    if (k != 0) {
      float a, b, c, d;
      if (k == 1) {
        // glRotatef(-90, 0, 0, 1);
        a = 0;
        b = 1;
        c = -1;
        d = 0;
      } else if (k == 2) {
        // glRotatef(-180, 0, 0, 1);
        a = -1;
        b = 0;
        c = 0;
        d = -1;
      } else if (k == 3) {
        // glRotatef(-270, 0, 0, 1);
        a = 0;
        b = -1;
        c = 1;
        d = 0;
      }

      foreach (m; 0..shapeVertices[i][j][shape].length) {
        const int numVertices = cast(int)(shapeVertices[i][j][shape][m].length / 3);
        foreach (n; 0..numVertices) {
          const float x = shapeVertices[i][j][shape][m][3*n + 0];
          const float y = shapeVertices[i][j][shape][m][3*n + 1];

          shapeVertices[i][j][shape][m][3*n + 0] = a*x + b*y;
          shapeVertices[i][j][shape][m][3*n + 1] = c*x + d*y;
        }
      }
    }
  }

  private static void prepareShapes3(int i, int j, int k, int shape) {
    GLfloat[4] currentColor;
    int currentIdx;

    if (i < 3) {
      shapeDrawMode[i][j][shape].length = 1 + 3;
      shapeVertices[i][j][shape].length = 1 + 3;
      shapeColors[i][j][shape].length = 1 + 3;
    } else {
      shapeDrawMode[i][j][shape].length = 1;
      shapeVertices[i][j][shape].length = 1;
      shapeColors[i][j][shape].length = 1;
    }

    setFrontColor(j, i, currentColor);

    currentIdx = 0;
    shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_STRIP;
    shapeVertices[i][j][shape][currentIdx] = [
       1, -1, 0,
       0,  1, 0,
      -1, -1, 0
    ];
    shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor;

    if (i < 3) {
      setSideColor(j, i, currentColor);

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
         0,  1, 0,
         1, -1, 0,
         1, -1, DEPTH,
         0,  1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, -1, 0,
         0,  1, 0,
         0,  1, DEPTH,
        -1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
         1, -1, 0,
        -1, -1, 0,
        -1, -1, DEPTH,
         1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0 || i == 3) {
      setColor(j, 1, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINE_STRIP;
      shapeVertices[i][j][shape][currentIdx] = [
         1 + LINE_PADDING, -1 + LINE_PADDING, LINE_PADDING,
         0               ,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING,
         1 + LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }

    if (i == 0) {
      setColor(j, 0.8, currentColor);

      ++shapeDrawMode[i][j][shape].length;
      ++shapeVertices[i][j][shape].length;
      ++shapeColors[i][j][shape].length;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_LINES;
      shapeVertices[i][j][shape][currentIdx] = [
         1 + LINE_PADDING, -1 - LINE_PADDING, DEPTH,
         1 + LINE_PADDING, -1 + LINE_PADDING, LINE_PADDING,
         0               ,  1 + LINE_PADDING, DEPTH,
         0               ,  1 + LINE_PADDING, LINE_PADDING,
        -1 - LINE_PADDING, -1 - LINE_PADDING, DEPTH,
        -1 - LINE_PADDING, -1 - LINE_PADDING, LINE_PADDING
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor
                                             ~ currentColor ~ currentColor
                                             ~ currentColor ~ currentColor;
    }

    if (k != 0) {
      float a, b, c, d;
      if (k == 1) {
        // glRotatef(-90, 0, 0, 1);
        a = 0;
        b = 1;
        c = -1;
        d = 0;
      } else if (k == 2) {
        // glRotatef(-180, 0, 0, 1);
        a = -1;
        b = 0;
        c = 0;
        d = -1;
      } else if (k == 3) {
        // glRotatef(-270, 0, 0, 1);
        a = 0;
        b = -1;
        c = 1;
        d = 0;
      }

      foreach (m; 0..shapeVertices[i][j][shape].length) {
        const int numVertices = cast(int)(shapeVertices[i][j][shape][m].length / 3);
        foreach (n; 0..numVertices) {
          const float x = shapeVertices[i][j][shape][m][3*n + 0];
          const float y = shapeVertices[i][j][shape][m][3*n + 1];

          shapeVertices[i][j][shape][m][3*n + 0] = a*x + b*y;
          shapeVertices[i][j][shape][m][3*n + 1] = c*x + d*y;
        }
      }
    }
  }

  private static void prepareShapes4(int i, int j, int shape) {
    GLfloat[4] currentColor;
    int currentIdx;

    if (i < 3) {
      shapeDrawMode[i][j][shape].length = 2 + 4;
      shapeVertices[i][j][shape].length = 2 + 4;
      shapeColors[i][j][shape].length = 2 + 4;
    } else {
      shapeDrawMode[i][j][shape].length = 2;
      shapeVertices[i][j][shape].length = 2;
      shapeColors[i][j][shape].length = 2;
    }

    setFrontColor(j, i, currentColor);

    currentIdx = 0;
    shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
    shapeVertices[i][j][shape][currentIdx] = [
       1,  1, 0,
      -1,  1, 0,
      -1, -1, 0,
       1, -1, 0
    ];
    shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

    currentIdx++;
    shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
    shapeVertices[i][j][shape][currentIdx] = [
       1,  1, DEPTH,
       1, -1, DEPTH,
      -1, -1, DEPTH,
      -1,  1, DEPTH
    ];
    shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

    if (i < 3) {
      setSideColor(j, i, currentColor);

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, 1, 0,
         1, 1, 0,
         1, 1, DEPTH,
        -1, 1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        -1, -1, 0,
        -1,  1, 0,
        -1,  1, DEPTH,
        -1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
         1, -1, 0,
        -1, -1, 0,
        -1, -1, DEPTH,
         1, -1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;

      currentIdx++;
      shapeDrawMode[i][j][shape][currentIdx] = GL_TRIANGLE_FAN;
      shapeVertices[i][j][shape][currentIdx] = [
        1,  1, 0,
        1, -1, 0,
        1, -1, DEPTH,
        1,  1, DEPTH
      ];
      shapeColors[i][j][shape][currentIdx] = currentColor ~ currentColor ~ currentColor ~ currentColor;
    }
  }

  public static void prepareShapes() {
    foreach (i; 0..SHADE_NUM) {
      foreach (j; 0..COLOR_NUM) {
        int shape = 0;

        prepareShapes1(i, j, shape);
        shape++;

        foreach (k; 0..4) {
          prepareShapes2(i, j, k, shape);
          shape++;
        }

        foreach (k; 0..4) {
          prepareShapes3(i, j, k, shape);
          shape++;
        }

        prepareShapes4(i, j, shape);
        shape++;
      }
    }

    version (PANDORA) {
      // hack: for some reason, without this (somewhere in this file), the glDrawArrays function segfaults when bullet hits an enemy
      string hack_str = to!string(shapeDrawMode.ptr);
    }
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

