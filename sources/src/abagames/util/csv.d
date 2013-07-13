/*
 * $Id: csv.d,v 1.2 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.util.csv;

private import std.stdio;
private import std.string;

/**
 * CSV format Tokenizer.
 */
public class CSVTokenizer {
 private:

  public static char[][] readFile(string fileName) {
    char[][] result;
    scope File fd;
    fd.open(fileName);
    for (;;) {
      char[] line;
      if (!fd.readln(line))
	break;
      char[][] spl = split(line.stripRight(), ",");
      foreach (char[] s; spl) {
	char[] r = strip(s);
	if (r.length > 0)
	  result ~= r;
      }
    }
    fd.close();
    return result;
  }
}
