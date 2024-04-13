/*
 * $Id: texture.d,v 1.2 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.texture;

private import std.string;
private import opengl;
private import bindbc.sdl;
private import abagames.util.sdl.sdlexception;

/**
 * Manage OpenGL textures.
 */
public class Texture {
 public:
  static string imagesDir = "images/";

 private:
  GLuint num;

  public this(const char[] name) {
    const char[] fileName = imagesDir ~ name;
    SDL_Surface *surface;
    surface = SDL_LoadBMP(std.string.toStringz(fileName));
    if (!surface) {
      throw new SDLInitFailedException("Unable to load: " ~ fileName);
    }
    glGenTextures(1, &num);
    glBindTexture(GL_TEXTURE_2D, num);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, surface.w, surface.h, 0,
		 GL_RGB, GL_UNSIGNED_BYTE, surface.pixels);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    /*gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB, surface.w, surface.h,
      GL_RGB, GL_UNSIGNED_BYTE, surface.pixels);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);*/
  }

  public void deleteTexture() {
    glDeleteTextures(1, &num);
  }

  public void bind() {
    glBindTexture(GL_TEXTURE_2D, num);
  }
}
