/*
 * $Id: sound.d,v 1.3 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.sound;

private import std.string;
private import SDL;
private import SDL_mixer;
private import abagames.util.sdl.sdlexception;

/**
 * BGM/SE.
 */
public abstract class Sound {
 public:
  static bool noSound = false;
 private:

  public static void init() {
    if (noSound)
      return;
    int audio_rate;
    Uint16 audio_format;
    int audio_channels;
    int audio_buffers;
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
      noSound = 1;
      throw new SDLInitFailedException
	("Unable to initialize SDL_AUDIO: " ~ std.string.toString(SDL_GetError()));
    }
    audio_rate = 44100;
    audio_format = AUDIO_S16;
    audio_channels = 1;
    audio_buffers = 4096;
    if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0) {
      noSound = 1;
      throw new SDLInitFailedException
	("Couldn't open audio: " ~ std.string.toString(SDL_GetError()));
    }
    Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
  }

  public static void close() {
    if (noSound)
      return;
    if (Mix_PlayingMusic()) {
      Mix_HaltMusic();
    }
    Mix_CloseAudio();
  }

  public abstract void load(char[] name);
  public abstract void load(char[] name, int ch);
  public abstract void free();
  public abstract void play();
  public abstract void fade();
  public abstract void halt();
}

public class Music: Sound {
 public:
  static int fadeOutSpeed = 1280;
  static char[] dir = "sounds/";
 private:
  Mix_Music* music;

  public void load(char[] name) {
    if (noSound)
      return;
    char[] fileName = dir ~ name;
    music = Mix_LoadMUS(std.string.toStringz(fileName));
    if (!music) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~ 
				       " (" ~ std.string.toString(Mix_GetError()) ~ ")");
    }
  }
  
  public void load(char[] name, int ch) {
    load(name);
  }

  public void free() {
    if (music) {
      halt();
      Mix_FreeMusic(music);
    }
  }

  public void play() {
    if (noSound) return;
    Mix_PlayMusic(music, -1);
  }

  public void playOnce() {
    if (noSound) return;
    Mix_PlayMusic(music, 1);
  }

  public void fade() {
    Music.fadeMusic();
  }

  public void halt() {
    Music.haltMusic();
  }

  public static void fadeMusic() {
    if (noSound) return;
    Mix_FadeOutMusic(fadeOutSpeed);
  }

  public static void haltMusic() {
    if (noSound) return;
    if (Mix_PlayingMusic()) {
      Mix_HaltMusic();
    }
  }
}

public class Chunk: Sound {
 public:
  static char[] dir = "sounds/";
 private:
  Mix_Chunk* chunk;
  int chunkChannel;

  public void load(char[] name) {
    load(name, 0);
  }
  
  public void load(char[] name, int ch) {
    if (noSound)
      return;
    char[] fileName = dir ~ name;
    chunk = Mix_LoadWAV(std.string.toStringz(fileName));
    if (!chunk) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~ 
				       " (" ~ std.string.toString(Mix_GetError()) ~ ")");
    }
    chunkChannel = ch;
  }

  public void free() {
    if (chunk) {
      halt();
      Mix_FreeChunk(chunk);
    }
  }

  public void play() {
    if (noSound) return;
    Mix_PlayChannel(chunkChannel, chunk, 0);
  }

  public void halt() {
    if (noSound) return;
    Mix_HaltChannel(chunkChannel);
  }

  public void fade() {
    halt();
  }
}
