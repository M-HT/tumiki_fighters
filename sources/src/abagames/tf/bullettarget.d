/*
 * $Id: bullettarget.d,v 1.2 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.bullettaget;

private import abagames.util.vector;

/**
 * Target that is aimed by bullets.
 */
public interface BulletTarget {
 public:
  Vector getTargetPos();
}

public class VirtualBulletTarget: BulletTarget {
 public:
  Vector pos;
 private:

  public this() {
    pos = new Vector;
  }

  public Vector getTargetPos() {
    return pos;
  }
}
