/*
 * $Id: sdlexception.d,v 1.1.1.1 2004/04/03 10:36:32 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.sdlexception;

/**
 * SDL initialize failed.
 */
public class SDLInitFailedException: Exception {
  public this(char[] msg) {
    super(msg);
  }
}
