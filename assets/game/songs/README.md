## How to add new songs

---

To add songs, make sure to modify the file at assets/resources/song_list.tres, that file contains data for songs that show up in freeplay.

The folder structure must look like this

```
assets/
    game/
        songs/
            Ballistic/
                default/
                    chart.json
                    Inst.ogg
                    Voices-Player.ogg
                    Voices-Opponent.ogg
                    Voices.ogg (this one is used if Voices-Player.ogg and Voices-Opponent.ogg are both missing)
                erect/ (erect/nightmare are the same)
                    chart.json
                    Inst.ogg
                    Voices-Player.ogg
                    Voices-Opponent.ogg
                    Voices.ogg
```

or

```
assets/
    game/
        songs/
            Ballistic/
                chart.json
                Inst.ogg
                Voices-Player.ogg
                Voices-Opponent.ogg
                Voices.ogg
```

if you don't have any variations, you CAN still have the "default" folder of course, but its optional.

songs may also have a custom assets.tres file which can override things such as HUD used in the song, noteskin, and audio files.

if you wanna see what's in assets.tres, read `assets/resources/chart_assets.tres`.
