/*
 * $Id: input.d,v 1.2 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.input;

private import SDL;

/**
 * Input device interface.
 */
public interface Input {
  public void handleEvent(SDL_Event *event);
}
