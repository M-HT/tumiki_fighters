/*
 * $Id: barragemanager.d,v 1.3 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.barragemanager;

private import std.string;
private import std.path;
private import std.file;
private import bulletml;
private import abagames.util.logger;
private import abagames.tf.morphbullet;

/**
 * Barrage manager(BulletMLs' loader).
 */
public class BarrageManager {
 private:
  static BulletMLParserTinyXML *parser[char[]];
  static const char[] BARRAGE_DIR_NAME = "barrage";

  public static void loadBulletMLs() {
    char[][] dirs = listdir(BARRAGE_DIR_NAME);
    foreach (char[] dirName; dirs) {
      char[][] files = listdir(BARRAGE_DIR_NAME ~ "/" ~ dirName);
      foreach (char[] fileName; files) {
	if (getExt(fileName) != "xml")
	  continue;
	char[] barrageName = dirName ~ "/" ~ fileName;
	Logger.info("Load BulletML: " ~ barrageName);
	parser[barrageName] = 
	  BulletMLParserTinyXML_new(std.string.toStringz(BARRAGE_DIR_NAME ~ "/" ~ barrageName));
	BulletMLParserTinyXML_parse(parser[barrageName]);
      }
    }
  }

  public static void unloadBulletMLs() {
    foreach (BulletMLParserTinyXML *p; parser) {
      BulletMLParserTinyXML_delete(p);
    }
  }

  public static BulletMLParserTinyXML* getInstance(char[] fileName) {
    return parser[fileName];
  }
}
