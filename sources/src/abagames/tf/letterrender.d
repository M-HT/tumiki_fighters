/*
 * $Id: letterrender.d,v 1.4 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.letterrender;

private import opengl;
private import abagames.util.rand;
private import abagames.tf.screen;
private import abagames.tf.tumiki;

/**
 * Letters' renderer.
 */
public class LetterRender {
 public:
  static int displayListIdx;
  static const float LETTER_WIDTH = 2.1f;
  static const float LETTER_HEIGHT = 3.0f;
  static const int COLOR_NUM = 6;
  static const int LETTER_NUM = 43;
 private:
  static const int DISPLAY_LIST_NUM = LETTER_NUM * COLOR_NUM;
  static Rand rand;

  public static float getWidth(int n ,float s) {
    return n * s * LETTER_WIDTH;
  }

  public static float getHeight(float s) {
    return s * LETTER_HEIGHT;
  }

  public static void drawLetter(int n, float x, float y, float s, float d, int c) {
    glPushMatrix();
    glTranslatef(x, y, 0);
    glScalef(s, s, s);
    glRotatef(d, 0, 0, 1);
    glCallList(displayListIdx + n + c * LETTER_NUM);
    glPopMatrix();
  }

  private static void drawLetterRev(int n, float x, float y, float s, float d, int c) {
    glPushMatrix();
    glTranslatef(x, y, 0);
    glScalef(s, -s, s);
    glRotatef(d, 0, 0, 1);
    glCallList(displayListIdx + n + c * LETTER_NUM);
    glPopMatrix();
  }

  public static enum Direction {
    TO_RIGHT, TO_DOWN, TO_LEFT, TO_UP,
  }

  public static int convertCharToInt(char c) {
    int idx;
    if (c >= '0' && c <='9') {
      idx = c - '0';
    } else if (c >= 'A' && c <= 'Z') {
      idx = c - 'A' + 10;
    } else if (c >= 'a' && c <= 'z') {
      idx = c - 'a' + 10;
    } else if (c == '.') {
      idx = 36;
    } else if (c == '-') {
      idx = 38;
    } else if (c == '+') {
      idx = 39;
    } else if (c == '_') {
      idx = 37;
    } else if (c == '!') {
      idx = 42;
    }
    return idx;
  }

  public static void drawString(const char[] str, float lx, float y, float s, int d, int cl,
				bool rev) {
    if (cl < 0)
      rand.setSeed(-cl);
    lx += LETTER_WIDTH * s / 2;
    y += LETTER_HEIGHT * s / 2;
    float x = lx;
    int idx;
    float ld;
    switch (d) {
    case Direction.TO_RIGHT:
      ld = 0;
      break;
    case Direction.TO_DOWN:
      ld = 90;
      break;
    case Direction.TO_LEFT:
      ld = 180;
      break;
    case Direction.TO_UP:
      ld = 270;
      break;
    default:
      break;
    }
    foreach (char c; str) {
      if (c != ' ') {
	idx = convertCharToInt(c);
	if (cl >= 0) {
	  if (rev)
	    drawLetterRev(idx, x, y, s, ld, cl);
	  else
	    drawLetter(idx, x, y, s, ld, cl);
	} else {
	  if (rev)
	    drawLetterRev(idx, x, y, s, ld, rand.nextInt(COLOR_NUM));
	  else
	    drawLetter(idx, x, y, s, ld, rand.nextInt(COLOR_NUM));
	}
      }
      switch(d) {
      case Direction.TO_RIGHT:
	x += s * LETTER_WIDTH;
	break;
      case Direction.TO_DOWN:
	y += s * LETTER_WIDTH;
	break;
      case Direction.TO_LEFT:
	x -= s * LETTER_WIDTH;
	break;
      case Direction.TO_UP:
	y -= s * LETTER_WIDTH;
	break;
      default:
	break;
      }
    }
  }

  public static void drawString(const char[] str, float lx, float y, float s, int d, int cl) {
    drawString(str, lx, y, s, d, cl, false);
  }

  public static void drawNum(int num, float lx, float y, float s, int d, int cl) {
    lx += LETTER_WIDTH * s / 2;
    y += LETTER_HEIGHT * s / 2;
    int n = num;
    float x = lx;
    float ld;
    switch (d) {
    case Direction.TO_RIGHT:
      ld = 0;
      break;
    case Direction.TO_DOWN:
      ld = 90;
      break;
    case Direction.TO_LEFT:
      ld = 180;
      break;
    case Direction.TO_UP:
      ld = 270;
      break;
    default:
      break;
    }
    for (;;) {
      drawLetter(n % 10, x, y, s, ld, cl);
      switch(d) {
      case Direction.TO_RIGHT:
	x -= s * LETTER_WIDTH;
	break;
      case Direction.TO_DOWN:
	y -= s * LETTER_WIDTH;
	break;
      case Direction.TO_LEFT:
	x += s * LETTER_WIDTH;
	break;
      case Direction.TO_UP:
	y += s * LETTER_WIDTH;
	break;
      default:
	break;
      }
      n /= 10;
      if (n <= 0) break;
    }
  }

  public static void drawNumSign(int num, float lx, float ly, float s, int cl) {
    float dg;
    if (num < 100)
      dg = 2;
    else if (num < 1000)
      dg = 3;
    else if (num < 10000)
      dg = 4;
    else
      dg = 5;
    float x = lx + LETTER_WIDTH * s * dg / 2;
    float y = ly + LETTER_HEIGHT * s / 2;
    int n = num;
    for (;;) {
      drawLetterRev(n % 10, x, y, s, 0, cl);
      x -= s * LETTER_WIDTH;
      n /= 10;
      if (n <= 0) break;
    }
  }

  public static void drawTime(int time, float lx, float y, float s, int cl) {
    int n = time;
    float x = lx;
    for (int i = 0; i < 7; i++) {
      if (i != 4) {
	drawLetter(n % 10, x, y, s, Direction.TO_RIGHT, cl);
	n /= 10;
      } else {
	drawLetter(n % 6, x, y, s, Direction.TO_RIGHT, cl);
	n /= 6;
      }
      if ((i & 1) == 1 || i == 0) {
	switch (i) {
	case 3:
	  drawLetter(41, x + s * 1.16f, y, s, Direction.TO_RIGHT, cl);
	  break;
	case 5:
	  drawLetter(40, x + s * 1.16f, y, s, Direction.TO_RIGHT, cl);
	  break;
	default:
	  break;
	}
	x -= s * LETTER_WIDTH;
      } else {
	x -= s * LETTER_WIDTH * 1.3f;
      }
      if (n <= 0) break;
    }
  }

  private static const int LETTER_SHADE = 3;

  private static void drawBox(float x, float y, float width, float height, float deg, int col) {
    glPushMatrix();
    glTranslatef(x - width / 2, y - height / 2, 0);
    glRotatef(deg, 0, 0, 1);
    glScalef(width, height, 0.3);
    glCallList(Tumiki.displayListIdx +
	       col * Tumiki.SHAPE_NUM +
	       LETTER_SHADE * Tumiki.COLOR_NUM * Tumiki.SHAPE_NUM);
    glPopMatrix();
  }

  private static void drawLetter(int idx, int c) {
    float x, y, length, size, t;
    float deg;
    for (int i = 0;; i++) {
      deg = cast(int) spData[idx][i][4];
      if (deg > 99990) break;
      x = -spData[idx][i][0];
      y = -spData[idx][i][1];
      size = spData[idx][i][2];
      length = spData[idx][i][3];
      x *= 1.2f;
      y *= 0.9f;
      size *= 0.5f;
      length *= 0.7f;
      if (size > length) {
	size *= 1.1f;
	length *= 0.7f;
      } else {
	size *= 0.7f;
	length *= 1.1f;
      }
      x = -x;
      y = y;
      deg %= 180;
      deg += rand.nextSignedFloat(16);
      drawBox(x, y, size, length, deg, c);
      /*if (deg <= 45 || deg > 135)
	drawBox(x, y, size, length);
      else
      drawBox(x, y, length, size);*/
    }
  }

  public static void createDisplayLists() {
    rand = new Rand();
    rand.setSeed(0);
    displayListIdx = glGenLists(DISPLAY_LIST_NUM);
    int di = displayListIdx;
    for (int j = 0; j < COLOR_NUM; j++) {
      for (int i = 0; i < LETTER_NUM; i++) {
	glNewList(di, GL_COMPILE);
	drawLetter(i, j);
	glEndList();
	di++;
      }
    }
  }

  public static void deleteDisplayLists() {
    glDeleteLists(displayListIdx, DISPLAY_LIST_NUM);
  }

  private static float[5][16][] spData =
    [[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.6f, 0.55f, 0.65f, 0.3f, 90], [0.6f, 0.55f, 0.65f, 0.3f, 90],
     [-0.6f, -0.55f, 0.65f, 0.3f, 90], [0.6f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     //A
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.1f, 1.15f, 0.45f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.45f, 0.55f, 0.65f, 0.3f, 90],
     [-0.1f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.1f, 1.15f, 0.45f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.45f, 0.4f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[// F
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.25f, 0, 0.25f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0.65f, -0.55f, 0.65f, 0.3f, 90], [-0.6f, -0.75f, 0.25f, 0.3f, 0],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//K
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.45f, 0.55f, 0.65f, 0.3f, 90],
     [-0.1f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.3f, 1.15f, 0.25f, 0.3f, 90], [0.3f, 1.15f, 0.25f, 0.3f, 90],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//P
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0.2f, -0.6f, 0.45f, 0.3f, 360-300],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.1f, 0, 0.45f, 0.3f, 0],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.45f, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [-0.65f, 0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0.65f, 0.3f, 0],
     [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.4f, 1.15f, 0.45f, 0.3f, 0], [0.4f, 1.15f, 0.45f, 0.3f, 0],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[//U
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.5f, -0.55f, 0.65f, 0.3f, 90], [0.5f, -0.55f, 0.65f, 0.3f, 90],
     [0, -1.15f, 0.45f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.65f, 0.55f, 0.65f, 0.3f, 90], [0.65f, 0.55f, 0.65f, 0.3f, 90],
     [-0.65f, -0.55f, 0.65f, 0.3f, 90], [0.65f, -0.55f, 0.65f, 0.3f, 90],
     [-0.3f, -1.15f, 0.25f, 0.3f, 90], [0.3f, -1.15f, 0.25f, 0.3f, 90],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.4f, 0.6f, 0.85f, 0.3f, 360-120],
     [0.4f, 0.6f, 0.85f, 0.3f, 360-60],
     [-0.4f, -0.6f, 0.85f, 0.3f, 360-240],
     [0.4f, -0.6f, 0.85f, 0.3f, 360-300],
     [0, 0, 0, 0, 99999],
    ],[
     [-0.4f, 0.6f, 0.85f, 0.3f, 360-120],
     [0.4f, 0.6f, 0.85f, 0.3f, 360-60],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[
     [0, 1.15f, 0.65f, 0.3f, 0],
     [0.35f, 0.5f, 0.65f, 0.3f, 360-60],
     [-0.35f, -0.5f, 0.65f, 0.3f, 360-240],
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//.
     [0, -1.15f, 0.05f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//_
     [0, -1.15f, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//-
     [0, 0, 0.65f, 0.3f, 0],
     [0, 0, 0, 0, 99999],
    ],[//+
     [-0.4f, 0, 0.45f, 0.3f, 0], [0.4f, 0, 0.45f, 0.3f, 0],
     [0, 0.55f, 0.65f, 0.3f, 90],
     [0, -0.55f, 0.65f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ],[//'
     [0, 1.0f, 0.4f, 0.2f, 90],
     [0, 0, 0, 0, 99999],
    ],[//''
     [-0.19f, 1.0f, 0.4f, 0.2f, 90],
     [0.2f, 1.0f, 0.4f, 0.2f, 90],
     [0, 0, 0, 0, 99999],
    ],[//!
     [0, 0.25f, 1.1f, 0.3f, 90],
     [0, -1.0f, 0.3f, 0.3f, 90],
     [0, 0, 0, 0, 99999],
    ]];
}
