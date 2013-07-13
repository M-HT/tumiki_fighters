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

/**
 * Barrage manager(BulletMLs' loader).
 */
public class BarrageManager {
 private:
  static BulletMLParserTinyXML *parser[string];
  static string BARRAGE_DIR_NAME = "barrage";

  public static void loadBulletMLs() {
    auto dirs = dirEntries(BARRAGE_DIR_NAME, SpanMode.shallow);
    foreach (string dirName; dirs) {
      auto files = dirEntries(dirName, SpanMode.shallow);
      foreach (string fileName; files) {
	if (extension(fileName) != ".xml")
	  continue;
	string barrageName = baseName(dirName) ~ "/" ~ baseName(fileName);
	Logger.info("Load BulletML: " ~ barrageName);
	parser[barrageName] =
	  BulletMLParserTinyXML_new(std.string.toStringz(fileName));
	BulletMLParserTinyXML_parse(parser[barrageName]);
      }
    }
  }

  public static void unloadBulletMLs() {
    foreach (BulletMLParserTinyXML *p; parser) {
      BulletMLParserTinyXML_delete(p);
    }
  }

  public static BulletMLParserTinyXML* getInstance(string fileName) {
    return parser[fileName];
  }
}
