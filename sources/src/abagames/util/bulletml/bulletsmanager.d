/*
 * $Id: bulletsmanager.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.bulletml.bulletsmanager;

private import bulletml;
private import abagames.util.bulletml.bullet;
private import abagames.util.actor;
private import abagames.util.actorpool;

/**
 * Interface for bullet's instances manager.
 */
//public interface BulletsManager {
public class BulletsManager: ActorPool {
  public this(int n, Actor act, ActorInitializer ini) {
    super(n, act, ini);
  }
  public abstract void addBullet(float deg, float speed);
  public abstract void addBullet(BulletMLState *state, float deg, float speed);
  public abstract int getTurn();
  public abstract void killMe(Bullet bullet);
}

