/*
 * $Id: bulletsmanager.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.bulletml.bulletsmanager;

private import bulletml;
private import abagames.util.bulletml.bullet;

/**
 * Interface for bullet's instances manager.
 */
public interface BulletsManager {
  public void addBullet(float deg, float speed);
  public void addBullet(BulletMLState *state, float deg, float speed);
  public int getTurn();
  public void killMe(Bullet bullet);
}

