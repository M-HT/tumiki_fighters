/*
 * $Id: screen.d,v 1.2 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.screen;

/**
 * SDL screen handler interface.
 */
public interface Screen {
  public void initSDL();
  public void closeSDL();
  public void flip();
  public void clear();
}
