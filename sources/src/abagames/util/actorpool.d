/*
 * $Id: actorpool.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.actorpool;

private import abagames.util.actor;

/**
 * Object pooling for actors.
 */
public class ActorPool {
 public:
  Actor[] actor;
 protected:
  int actorIdx;

  public this(int n, Actor act, ActorInitializer ini) {
    actor = new Actor[n];
    foreach (inout Actor a; actor) {
      a = act.newActor();
      a.isExist = false;
      a.init(ini);
    }
    actorIdx = n;
  }

  public Actor getInstance() {
    for (int i = 0; i < actor.length; i++) {
      actorIdx--;
      if (actorIdx < 0)
	actorIdx = actor.length - 1;
      if (!actor[actorIdx].isExist) 
	return actor[actorIdx];
    }
    return null;
  }

  public Actor getInstanceForced() {
    actorIdx--;
    if (actorIdx < 0)
      actorIdx = actor.length - 1;
    return actor[actorIdx];
  }

  public void move() {
    foreach (Actor ac; actor) {
      if (ac.isExist)
	ac.move();
    }
  }

  public void draw() {
    foreach (Actor ac; actor) {
      if (ac.isExist)
	ac.draw();
    }
  }

  public void clear() {
    foreach (Actor ac; actor) {
      ac.isExist = false;
    }
  }
}
