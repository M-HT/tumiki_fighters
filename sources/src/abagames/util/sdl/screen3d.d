/*
 * $Id: screen3d.d,v 1.2 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.screen3d;

private import std.string;
private import std.conv;
private import bindbc.sdl;
private import opengl;
private import abagames.util.logger;
private import abagames.util.sdl.screen;
private import abagames.util.sdl.sdlexception;

/**
 * SDL screen handler(3D, OpenGL).
 */
public class Screen3D: Screen {
 public:
  static float brightness = 1;
  static int width = 640;
  static int height = 480;
  static int screenWidth = 640;
  static int screenHeight = 480;
  static int screenStartX = 0;
  static int screenStartY = 0;
  static string name = "";
  static SDL_Window* window;
  static SDL_GLContext context;
  static bool windowMode = false;
  static float nearPlane = 0.1;
  static float farPlane = 1000;

 private:

  protected abstract void init();
  protected abstract void close();

  public override void initSDL() {
    // Initialize SDL.
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      throw new SDLInitFailedException(
	"Unable to initialize SDL: " ~ to!string(SDL_GetError()));
    }
    // Create an OpenGL screen.
    uint videoFlags;
    if (windowMode) {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    } else {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN_DESKTOP;
    }
    window = SDL_CreateWindow(std.string.toStringz(name), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, videoFlags);
    if (window == null) {
      throw new SDLInitFailedException(
        "Unable to create SDL window: " ~ to!string(SDL_GetError()));
    }
    context = SDL_GL_CreateContext(window);
    if (context == null) {
      SDL_DestroyWindow(window);
      window = null;
      throw new SDLInitFailedException(
        "Unable to initialize OpenGL context: " ~ to!string(SDL_GetError()));
    }
    SDL_GetWindowSize(window, &screenWidth, &screenHeight);
    glViewport(screenStartX, screenStartY, screenWidth, screenHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    resized(screenWidth, screenHeight);
    SDL_ShowCursor(SDL_DISABLE);
    init();
  }

  // Reset viewport when the screen is resized.

  private void screenResized() {
    static if (SDL_VERSION_ATLEAST(2, 0, 1)) {
      SDL_version linked;
      SDL_GetVersion(&linked);
      if (SDL_version(linked.major, linked.minor, linked.patch) >= SDL_version(2, 0, 1)) {
        SDL_GL_GetDrawableSize(window, &screenWidth, &screenHeight);
      }
    }
    glViewport(screenStartX, screenStartY, screenWidth, screenHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    //gluPerspective(45.0f, cast(GLfloat) width / cast(GLfloat) height, nearPlane, farPlane);
    /*glFrustum(-nearPlane,
	      nearPlane,
	      -nearPlane * cast(GLfloat)height / cast(GLfloat)width,
	      nearPlane * cast(GLfloat)height / cast(GLfloat)width,
	      0.1f, farPlane);*/
    glFrustum(-nearPlane,
	      nearPlane,
	      -nearPlane * cast(GLfloat)480 / cast(GLfloat)640,
	      nearPlane * cast(GLfloat)480 / cast(GLfloat)640,
	      0.1f, farPlane);
    glMatrixMode(GL_MODELVIEW);
  }

  public override void resized(int width, int height) {
    this.screenWidth = width; this.screenHeight = height;
    screenResized();
  }

  public override void closeSDL() {
    close();
    SDL_ShowCursor(SDL_ENABLE);
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
  }

  public override void flip() {
    handleError();
    SDL_GL_SwapWindow(window);
  }

  public override void clear() {
    glClear(GL_COLOR_BUFFER_BIT);
  }

  public void handleError() {
    GLenum error = glGetError();
    if (error == GL_NO_ERROR) return;
    closeSDL();
    throw new Exception("OpenGL error");
  }

  protected void setCaption(const char[] name) {
    this.name = name.idup;
    if (window != null) {
      SDL_SetWindowTitle(window, std.string.toStringz(name));
    }
  }

  public static void setColor(float r, float g, float b) {
    glColor3f(r * brightness, g * brightness, b * brightness);
  }

  public static void setColor(float r, float g, float b, float a) {
    glColor4f(r * brightness, g * brightness, b * brightness, a);
  }

  public static void setClearColor(float r, float g, float b, float a) {
    glClearColor(r * brightness, g * brightness, b * brightness, a);
  }
}
