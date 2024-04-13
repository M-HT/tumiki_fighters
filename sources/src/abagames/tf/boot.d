/*
 * $Id: boot.d,v 1.4 2004/05/14 14:35:37 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.boot;

private import std.string;
private import std.conv;
private import core.stdc.stdlib;
private import abagames.util.logger;
private import abagames.util.sdl.mainloop;
private import abagames.util.sdl.pad;
private import abagames.util.sdl.sound;
private import abagames.tf.gamemanager;
private import abagames.tf.screen;
private import abagames.tf.prefmanager;

/**
 * Boot the game.
 */
private:
Screen screen;
Pad input;
GameManager gameManager;
PrefManager prefManager;
MainLoop mainLoop;

private void usage(string args0) {
  Logger.error
    ("Usage: " ~ args0 ~ " [-brightness [0-100]] [-window] [-res x y] [-nosound] [-reverse]");
}

private void parseArgs(string[] args) {
  for (int i = 1; i < args.length; i++) {
    switch (args[i]) {
    case "-brightness":
      if (i >= args.length - 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      i++;
      float b = cast(float) to!int(args[i]) / 100;
      if (b < 0 || b > 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      Screen.brightness = b;
      break;
    case "-window":
      Screen.windowMode = true;
      break;
    case "-res":
      if (i >= args.length - 2) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      i++;
      int w = to!int(args[i]);
      i++;
      int h = to!int(args[i]);
      Screen.width = w;
      Screen.height = h;
      break;
    case "-nosound":
      Sound.noSound = true;
      break;
    case "-reverse":
      (cast(Pad) input).buttonReversed = true;
      break;
    case "-accframe":
      mainLoop.accframe = 1;
      break;
    default:
      usage(args[0]);
      throw new Exception("Invalid options");
    }
  }
}

public int boot(string[] args) {
  screen = new Screen;
  input = new Pad;
  try {
    input.openJoystick();
  } catch (Exception e) {}
  gameManager = new GameManager;
  prefManager = new PrefManager;
  mainLoop = new MainLoop(screen, input, gameManager, prefManager);
  try {
    parseArgs(args);
  } catch (Exception e) {
    return EXIT_FAILURE;
  }
  mainLoop.loop();
  return EXIT_SUCCESS;
}

version (Win32_release) {

// Boot as the Windows executable.
import std.c.windows.windows;
import std.string;

extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();

extern (Windows)
public int WinMain(HINSTANCE hInstance,
	    HINSTANCE hPrevInstance,
	    LPSTR lpCmdLine,
	    int nCmdShow) {
  int result;

  gc_init();
  _minit();
  try {
    _moduleCtor();
    char[4096] exe;
    GetModuleFileNameA(null, exe, 4096);
    string[1] prog;
    prog[0] = to!string(exe);
    result = boot(prog ~ std.string.split(to!string(lpCmdLine)));
  } catch (Exception o) {
    //Logger.error("Exception: " ~ o.toString());
    Logger.info("Exception: " ~ o.toString());
    result = EXIT_FAILURE;
  }
  gc_term();
  return result;
}

} else {

// Boot as the general executable.
public int main(string[] args) {
  return boot(args);
}

}
