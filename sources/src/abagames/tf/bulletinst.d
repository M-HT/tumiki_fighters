/*
 * $Id: bulletinst.d,v 1.4 2004/05/15 07:46:52 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.bulletinst;

private import abagames.tf.morphbullet;
private import abagames.tf.bullettarget;
private import abagames.tf.stagemanager;

/**
 * Bullet with params of sppedRank, shape, color, size, 
 * the horizontal reverse moving, target, type.
 */
public class BulletInst: MorphBullet {
 public:
  int shape, color;
  float bulletSize;
  float xReverse, yReverse;
  BulletTarget target;
  static enum Type {
    ENEMY, SHIP, MOVE
  }
  int type;
  bool deactivated;
 private:
  float speedRankNum;
  StageManager stageManager;

  public this(int id) {
    super(id);
  }

  public void setStageManager(StageManager stageManager) {
    this.stageManager = stageManager;
  }

  public void setParam(float sr, int sh, int cl, float sz, 
		       float xr, float yr, BulletTarget tr, int tp) {
    speedRank = sr;
    shape = sh;
    color = cl;
    bulletSize = sz;
    xReverse = xr;
    yReverse = yr;
    target = tr;
    type = tp;
    deactivated = false;
  }

  public override float rank() {
    if (type == Type.ENEMY) {
      float sr = stageManager.rank / (1 + morphNum * 0.33);
      float r = super.rank + (1 - super.rank) * sr;
      if (r > 1)
	r = 1;
      return r;
    } else {
      return super.rank;
    }
  }

  public float speedRank() {
    if (type == Type.ENEMY) {
      return speedRankNum * stageManager.speedRank;
    } else {
      return speedRankNum;
    }
  }

  public float speedRank(float value) {
    return speedRankNum = value;
  }
}
