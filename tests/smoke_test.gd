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

	for i in range(900):
		if main.state != "playing":
			break
		if i % 45 == 0:
			_enqueue_reasonable_command(main)
		main._update_game(0.20)
		await process_frame

	if main.state == "title" or main.state == "help":
		push_error("Smoke test ended in a menu state.")
		main.queue_free()
		await process_frame
		quit(1)
		return

	if main.services.is_empty() or main.LOADOUT.is_empty():
		push_error("MVP data was not initialized.")
		main.queue_free()
		await process_frame
		quit(1)
		return

	print("Smoke OK: state=%s score=%d budget=%d incidents=%d actions=%d" % [
		main.state,
		main.score,
		int(main.error_budget),
		main.active_incidents.size(),
		main.actions_completed
	])
	main.queue_free()
	await process_frame
	quit(0)


func _enqueue_reasonable_command(main):
	var inc = main._selected_incident()
	if inc.is_empty() and not main.active_incidents.is_empty():
		var best_i = 0
		var best_severity = -1.0
		for i in range(main.active_incidents.size()):
			var severity = float(main.active_incidents[i]["severity"])
			if severity > best_severity:
				best_severity = severity
				best_i = i
		main.selected_service = int(main.active_incidents[best_i]["service"])
		inc = main.active_incidents[best_i]
	if inc.is_empty():
		main._enqueue_command("log")
		return
	var confidence = float(inc.get("confidence", 0.0))
	if confidence < 70.0:
		main._enqueue_command("log")
		return
	var fix = str(inc.get("fix", "restart"))
	if main.RUNBOOKS.has(fix):
		main._enqueue_command(fix)
	else:
		main._enqueue_command("restart")
