/*
 * $Id: sound.d,v 1.3 2004/05/14 14:35:39 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.sound;

private import std.string;
private import std.conv;
private import bindbc.sdl;
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
    ushort audio_format;
    int audio_channels;
    int audio_buffers;
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
      noSound = 1;
      throw new SDLInitFailedException
	("Unable to initialize SDL_AUDIO: " ~ to!string(SDL_GetError()));
    }
    audio_rate = 44100;
    audio_format = AUDIO_S16;
    audio_channels = 1;
    audio_buffers = 4096;
    bool sound_opened = false;
    static if (SDL_MIXER_VERSION_ATLEAST(2, 0, 2)) {
      const SDL_version *link_version = Mix_Linked_Version();
      if (SDL_version(link_version.major, link_version.minor, link_version.patch) >= SDL_version(2, 0, 2)) {
        sound_opened = true;
        if (Mix_OpenAudioDevice(audio_rate, audio_format, audio_channels, audio_buffers, null, 0xff) < 0) {
          noSound = 1;
          throw new SDLInitFailedException
            ("Couldn't open audio: " ~ to!string(SDL_GetError()));
        }
      }
    }
    if (!sound_opened) {
      if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0) {
        noSound = 1;
        throw new SDLInitFailedException
          ("Couldn't open audio: " ~ to!string(SDL_GetError()));
      }
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

  public abstract void load(const char[] name);
  public abstract void load(const char[] name, int ch);
  public abstract void free();
  public abstract void play();
  public abstract void fade();
  public abstract void halt();
}

public class Music: Sound {
 public:
  static int fadeOutSpeed = 1280;
  static string dir = "sounds/";
 private:
  Mix_Music* music;

  public override void load(const char[] name) {
    if (noSound)
      return;
    const char[] fileName = dir ~ name;
    music = Mix_LoadMUS(std.string.toStringz(fileName));
    if (!music) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~
				       " (" ~ to!string(Mix_GetError()) ~ ")");
    }
  }

  public override void load(const char[] name, int ch) {
    load(name);
  }

  public override void free() {
    if (music) {
      halt();
      Mix_FreeMusic(music);
    }
  }

  public override void play() {
    if (noSound) return;
    Mix_PlayMusic(music, -1);
  }

  public void playOnce() {
    if (noSound) return;
    Mix_PlayMusic(music, 1);
  }

  public override void fade() {
    Music.fadeMusic();
  }

  public override void halt() {
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
  static string dir = "sounds/";
 private:
  Mix_Chunk* chunk;
  int chunkChannel;

  public override void load(const char[] name) {
    load(name, 0);
  }

  public override void load(const char[] name, int ch) {
    if (noSound)
      return;
    const char[] fileName = dir ~ name;
    chunk = Mix_LoadWAV(std.string.toStringz(fileName));
    if (!chunk) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~
				       " (" ~ to!string(Mix_GetError()) ~ ")");
    }
    chunkChannel = ch;
  }

  public override void free() {
    if (chunk) {
      halt();
      Mix_FreeChunk(chunk);
    }
  }

  public override void play() {
    if (noSound) return;
    Mix_PlayChannel(chunkChannel, chunk, 0);
  }

  public override void halt() {
    if (noSound) return;
    Mix_HaltChannel(chunkChannel);
  }

  public override void fade() {
    halt();
  }
}
