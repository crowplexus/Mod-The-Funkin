## Chart Support

The engine can open charts from the following engines

- Friday Night Funkin' (Legacy Base Game)
- Friday Night Funkin' (New Base Game / V-Slice)
- Psych Engine (it _does_ load the events)
- Troll Engine (Work in Progress)

---

## How to add new songs

---

To add songs, make sure to modify the file at `assets/resources/freeplay_playlist.tres`, that file contains data for songs that show up in freeplay.

The folder structure **must** look like this:

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

If you don't have any variations, you _CAN_ still have the "default" folder of course, but its optional.

Songs may also have a custom `assets.tres` file which can override things such as HUD used in the song, and audio files.

`assets.tres` can go in any of the variation folders _OR_ the root directory for the song in case you want it to be the fallback.

If `assets.tres` exists in a variation folder, when playing on that variation (i.e: Erect), *that* file will be used to load the assets, rather than the one on the root directory .

If you wanna see what's in `assets.tres`, read `assets/resources/chart_assets.tres`.
