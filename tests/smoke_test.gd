extends SceneTree


func _initialize():
	call_deferred("_run")


func _run():
	var scene = load("res://scenes/main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame

	main.muted = true
	main._start_run()
	if not str(main.font.get_font_name()).contains("DotGothic"):
		push_error("Japanese UI font was not loaded: %s" % main.font.get_font_name())
		main.queue_free()
		await process_frame
		quit(1)
		return
	for i in range(240):
		if main.state == "playing" and main.resolving:
			main.resolve_timer = -1.0
			await process_frame
			continue
		elif main.state == "playing":
			_play_first_usable_card(main)
			main._end_turn()
		elif main.state == "reward":
			main._take_reward(0)
		elif main.state == "remove_card":
			main._remove_deck_card(0)
		elif main.state == "victory" or main.state == "game_over":
			break
		for frame in range(6):
			await process_frame

	if main.state == "title" or main.state == "help":
		push_error("Smoke test ended in a menu state.")
		main.queue_free()
		await process_frame
		quit(1)
		return

	print("Smoke OK: state=%s day=%d score=%d integrity=%d" % [main.state, main.day, main.score, main.integrity])
	main.queue_free()
	await process_frame
	quit(0)


func _play_first_usable_card(main):
	for i in range(main.hand.size()):
		var card_id = main.hand[i]
		var card = main.CARD_DB[card_id]
		if main.sap < int(card["cost"]):
			continue
		if card["target"] == "none":
			main._play_card(i, Vector2i(-1, -1))
			return
		for y in range(main.GRID_H):
			for x in range(main.GRID_W):
				var p = Vector2i(x, y)
				if main._is_valid_target(card_id, p):
					main._play_card(i, p)
					return
