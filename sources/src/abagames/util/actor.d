/*
 * $Id: actor.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.actor;

/**
 * Actor in the game that has the interface to move and draw.
 */
public class Actor {
 private:
  bool isExistOrNot;

  public bool isExist() {
    return isExistOrNot;
  }

  public bool isExist(bool value) {
    return isExistOrNot = value;
  }

  public abstract Actor newActor();
  public abstract void init(ActorInitializer ini);
  public abstract void move();
  public abstract void draw();
}

/**
 * Pass initial parameters to the actor.
 */
public interface ActorInitializer {
}
