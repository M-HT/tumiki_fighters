/*
 * $Id: logger.d,v 1.3 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.logger;

private import std.stream;
private import std.string;

/**
 * Logger(error/info).
 */
version(Win32_release) {

import std.string;
import std.c.windows.windows;

public class Logger {

  public static void info(char[] msg) {
    // Win32 exe file crashes if it writes something to stderr.
    //stderr.writeLine("Info: " ~ msg);
  }

  public static void info(int n) {
    //stderr.writeLine("Info: " ~ std.string.toString(n));
  }

  public static void info(float n) {
    //stderr.writeLine("Info: -" ~ std.string.toString(n));
  }

  private static void putMessage(char[] msg) {
    MessageBoxA(null, std.string.toStringz(msg), "Error", MB_OK | MB_ICONEXCLAMATION);
  }

  public static void error(char[] msg) {
    putMessage("Error: " ~ msg);
  }

  public static void error(Exception e) {
    putMessage("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    putMessage("Error: " ~ e.toString());
  }
}

} else {

public class Logger {

  public static void info(char[] msg) {
    stderr.writeLine("Info: " ~ msg);
  }

  public static void info(int n) {
    stderr.writeLine("Info: " ~ std.string.toString(n));
  }

  public static void info(float n) {
    stderr.writeLine("Info: -" ~ std.string.toString(n));
  }

  public static void error(char[] msg) {
    stderr.writeLine("Error: " ~ msg);
  }

  public static void error(Exception e) {
    stderr.writeLine("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    stderr.writeLine("Error: " ~ e.toString());
    if (e.next)
      error(e.next);
  }
}

}
