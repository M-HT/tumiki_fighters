/*
 * $Id: iterator.d,v 1.1.1.1 2004/04/03 10:36:32 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.util.iterator;

/**
 * Simple iterator for array.
 */
public template ArrayIterator(T) {
public class ArrayIterator {
 private:
  T[] array;
  int idx;

  public this(T[] a) {
    array = a;
    idx = 0;
  }

  public bool hasNext() {
    if (idx >= array.length)
      return false;
    else
      return true;
  }

  public T next() {
    if (idx >= array.length)
      throw new Error("No more items");
    T result = array[idx];
    idx++;
    return result;
  }
}
}

alias ArrayIterator!(char[]) StringIterator;
