# Where to put your own music

The game plays one track per biome. Right now they are three songs made with Suno from the prompts in
`SUNO_PROMPTS.md` (modern glitch / artcore synth). To use other music, put files here, in this folder:

| Biome | File name |
|---|---|
| Dungeon (floors 1 to 10, and the way back from the troll) | `dungeon.ogg` or `dungeon.mp3` |
| Cavern | `cavern.ogg` or `cavern.mp3` |
| Troll boss | `boss.ogg` or `boss.mp3` |

- A file with the same name replaces the song that is there. Godot imports it the next time you open the project.
- If a biome has no file here, the built-in SID track from `sid/` plays (`python3 tools/sid_audio.py sounds` makes them).
- Want several songs per biome? Add `dungeon_2.ogg`, `dungeon_3.ogg` ... up to `_9`. One is picked at random
  every time you reach a new floor of that biome.
- The track loops by itself, so end it on a bar line or a quiet moment. OGG loops without a gap, MP3 has a
  few milliseconds of silence at the loop point, so prefer OGG.
- Convert a Suno download: `ffmpeg -i song.mp3 -c:a libvorbis -q:a 4 dungeon.ogg` or `sox song.mp3 -C 4 dungeon.ogg`.
- Keep the loudness around -14 LUFS (about -3 dB peak). The player controls the volume in the options menu.

## Without touching the project (per player)

Players can also drop the same file names into the game's user data folder, which wins over everything above
and needs no rebuild:

| System | Folder |
|---|---|
| macOS | `~/Library/Application Support/Godot/app_userdata/Moria/music/` |
| Windows | `%APPDATA%\Godot\app_userdata\Moria\music\` |
| Linux | `~/.local/share/godot/app_userdata/Moria/music/` |

(Create the `music` folder if it does not exist. The folder is read when a floor starts, so a new file is
played from the next floor on.)

Suno prompts for three tracks (dungeon, cavern, boss) are in `SUNO_PROMPTS.md`.
