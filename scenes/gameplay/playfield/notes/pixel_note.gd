extends "res://scenes/gameplay/playfield/notes/normal_note.gd"

func display_splash() -> Node2D:
	if not strumline or column == -1:
		return null
	var dip: AnimatedSprite2D = strumline.get_splash(column)
	var strum: StrumNote = strumline.get_strum(column)
	if not dip:
		dip = splash.duplicate()
		dip.name = "splash_%s" % strum.get_child_count()
		dip.animation_finished.connect(dip.hide)
		dip.top_level = true
		strum.add_child(dip)
	dip.global_position = strum.global_position
	dip.modulate.a = (game.local_settings.note_splash_alpha if Gameplay.current else Global.settings.note_splash_alpha) * 0.01
	dip.scale = splash_scale * (1.5 if judgement.splash_type == Judgement.SplashType.FULL else 1.0)
	dip.frame = 0
	dip.show()
	dip.play(str(Note.COLORS[column].to_lower(), randi_range(1, 3)), 1.0)
	return dip
