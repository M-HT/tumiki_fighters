/*
 * $Id: prefmanager.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.prefmanager;

/**
 * Save/load the game preference(ex) high-score).
 */
public interface PrefManager {
  public void save();
  public void load();
}
