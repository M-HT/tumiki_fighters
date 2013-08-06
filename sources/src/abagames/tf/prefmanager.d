/*
 * $Id: prefmanager.d,v 1.3 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.prefmanager;

private import std.stdio;
private import abagames.util.prefmanager;

/**
 * Save/Load the high score.
 */
public class PrefManager: abagames.util.prefmanager.PrefManager {
 public:
  static const int VERSION_NUM = 20;
  static string PREF_FILE = "tf.prf";
  static const int RANKING_NUM = 10;
  static const int DEFAULT_HISCORE = 10000;
  RankingItem[RANKING_NUM] ranking;

  public this() {
    foreach (ref RankingItem ri; ranking)
      ri = new RankingItem;
  }

  private void init() {
    int sc = DEFAULT_HISCORE * RANKING_NUM;
    foreach (RankingItem ri; ranking) {
      ri.score = sc;
      ri.stage = 0;
      sc -= DEFAULT_HISCORE;
    }
  }

  public override void load() {
    scope File fd;
    try {
      int read_data[1];
      fd.open(PREF_FILE);
      fd.rawRead(read_data);
      if (read_data[0] != VERSION_NUM)
	throw new Exception("Wrong version num");
      foreach (RankingItem ri; ranking)
	ri.load(fd);
    } catch (Exception e) {
      init();
    } finally {
      fd.close();
    }
  }

  public override void save() {
    scope File fd;
    try {
      fd.open(PREF_FILE, "wb");
      const int write_data[1] = [VERSION_NUM];
      fd.rawWrite(write_data);
      foreach (RankingItem ri; ranking)
        ri.save(fd);
    } finally {
      fd.close();
    }
  }

  public void setHiScore(int sc, int st) {
    int i = 0;
    for (; i < RANKING_NUM; i++)
      if (ranking[i].score < sc)
	break;
    if (i >= RANKING_NUM)
      return;
    for (int j = RANKING_NUM - 1; j > i; j--)
      ranking[j] = ranking[j - 1];
    ranking[i] = new RankingItem(sc, st);
  }
}

public class RankingItem {
 public:
  int score;
  int stage;

  public this() {
    score = stage = 0;
  }

  public this(int sc, int st) {
    score = sc;
    stage = st;
  }

  public void save(File fd) {
    const int write_data[2] = [score, stage];
    fd.rawWrite(write_data);
  }

  public void load(File fd) {
    int read_data[2];
    fd.rawRead(read_data);
    score = read_data[0];
    stage = read_data[1];
  }
}
