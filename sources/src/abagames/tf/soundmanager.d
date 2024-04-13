/*
 * $Id: soundmanager.d,v 1.3 2004/05/14 14:35:38 kenta Exp $
 *
 * Copyright 2004 Kenta Cho. All rights reserved.
 */
module abagames.tf.soundmanager;

private import abagames.util.sdl.sound;
private import abagames.tf.gamemanager;

/**
 * Manage BGMs/SEs.
 */
public class SoundManager {
 public static:
  enum Bgm {
    STG1, STG2, STG3, BOSS, LAST_BOSS, ENDING
  }
  enum Se {
    SHIP_SHOT, STUCK, STUCK_BONUS, STUCK_DESTROYED, SHIP_DESTROYED,
    ENEMY_DAMAGED, SMALL_ENEMY_DESTROYED, ENEMY_DESTROYED, BOSS_DESTROYED,
    EXTEND, WARNING, PROPELLER, STUCK_BONUS_PUSHIN,
  }
  const int BGM_NUM = 6;
  const int STAGE_BGM_NUM = 3;
  const int SE_NUM = 13;
 private static:
  GameManager manager;
  Music[BGM_NUM] bgm;
  Chunk[SE_NUM] se;
  string[] bgmFileName =
    ["we_are_tumiki_fighters.ogg",
    "just_over_the_horizon.ogg",
    "panic_on_meadow.ogg",
    "here_comes_a_gigantic_toy.ogg",
    "battle_over_the_junk_city.ogg",
    "return_to_home.ogg"];
  string[] seFileName =
    ["ship_shot.wav", "stuck.wav", "stuck_bonus.wav",
    "stuck_destroyed.wav", "ship_destroyed.wav",
    "enemy_damaged.wav", "small_enemy_destroyed.wav", "enemy_destroyed.wav", "boss_destroyed.wav",
    "extend.wav", "warning.wav", "propeller.wav", "stuck_bonus_pushin.wav"];
  const int[] seChannel =
    [0, 1, 2,
    3, 2,
    4, 5, 6, 6,
    7, 7, 7, 2];
 private:

  public static void init(GameManager mng) {
    manager = mng;
    if (Sound.noSound)
      return;
    int i = 0;
    foreach (ref Music b; bgm) {
      b = new Music;
      b.load(bgmFileName[i]);
      i++;
    }
    i = 0;
    foreach (ref Chunk c; se) {
      c = new Chunk;
      c.load(seFileName[i], seChannel[i]);
      i++;
    }
  }

  public static void close() {
    if (Sound.noSound)
      return;
    foreach (Music b; bgm)
      b.free();
    foreach (Chunk c; se)
      c.free();
  }

  public static void playBgm(int n) {
    if (Sound.noSound ||
	(manager.state != GameManager.State.IN_GAME &&
	 manager.state != GameManager.State.START_GAME &&
	 manager.state != GameManager.State.END_GAME))
      return;
    bgm[n].play();
  }

  public static void playBgmOnce(int n) {
    if (Sound.noSound ||
	(manager.state != GameManager.State.IN_GAME &&
	 manager.state != GameManager.State.START_GAME &&
	 manager.state != GameManager.State.END_GAME))
      return;
    bgm[n].playOnce();
  }

  public static void playSe(int n) {
    if (Sound.noSound ||
	(manager.state != GameManager.State.IN_GAME &&
	 manager.state != GameManager.State.START_GAME))
      return;

    if (n >= SE_NUM) return;

    se[n].play();
  }

  public static void haltSe(int n) {
    if (Sound.noSound)
      return;
    se[n].halt();
  }
}
