extends Control

const SHIFT_SECONDS = 150.0
const START_ERROR_BUDGET = 100.0
const MAX_ALERTS = 8
const MAX_QUEUE = 6
const SAVE_PATH = "user://alert_stack_meta.cfg"
const UI_FONT_PATH = "res://assets/fonts/DotGothic16-Regular.ttf"

const C_BG = Color(0.025, 0.033, 0.040)
const C_PANEL = Color(0.045, 0.055, 0.064, 0.94)
const C_PANEL_2 = Color(0.060, 0.070, 0.082, 0.96)
const C_LINE = Color(0.21, 0.27, 0.31, 0.84)
const C_TEXT = Color(0.90, 0.93, 0.92)
const C_DIM = Color(0.58, 0.66, 0.68)
const C_MUTED = Color(0.38, 0.45, 0.48)
const C_CYAN = Color(0.10, 0.82, 0.86)
const C_GREEN = Color(0.28, 0.88, 0.50)
const C_AMBER = Color(1.00, 0.64, 0.20)
const C_RED = Color(0.95, 0.22, 0.20)
const C_PURPLE = Color(0.66, 0.52, 1.00)
const C_BLUE = Color(0.26, 0.50, 1.00)

const SERVICES = [
	{"id": "edge", "name": "Edge", "role": "入口", "pos": Vector2(0.12, 0.18), "critical": 0.55, "color": Color(0.13, 0.78, 0.88)},
	{"id": "dns", "name": "DNS", "role": "名前解決", "pos": Vector2(0.26, 0.50), "critical": 0.35, "color": Color(0.38, 0.80, 0.50)},
	{"id": "api", "name": "API", "role": "中核", "pos": Vector2(0.46, 0.34), "critical": 1.20, "color": Color(0.98, 0.50, 0.20)},
	{"id": "auth", "name": "Auth", "role": "認証", "pos": Vector2(0.70, 0.22), "critical": 0.80, "color": Color(0.78, 0.50, 1.00)},
	{"id": "queue", "name": "Queue", "role": "非同期", "pos": Vector2(0.47, 0.68), "critical": 0.70, "color": Color(0.95, 0.70, 0.20)},
	{"id": "db", "name": "DB", "role": "永続化", "pos": Vector2(0.76, 0.66), "critical": 1.10, "color": Color(0.95, 0.28, 0.25)},
	{"id": "worker", "name": "Worker", "role": "処理", "pos": Vector2(0.26, 0.78), "critical": 0.55, "color": Color(0.33, 0.58, 1.00)},
	{"id": "billing", "name": "Billing", "role": "決済", "pos": Vector2(0.90, 0.42), "critical": 1.00, "color": Color(0.94, 0.44, 0.30)}
]

const EDGES = [
	[0, 2], [1, 2], [2, 3], [2, 4], [2, 5], [3, 5],
	[4, 6], [6, 5], [5, 7], [2, 7]
]

const INCIDENT_TEMPLATES = [
	{"kind": "traffic", "name": "Traffic Surge", "service": 0, "fix": "rate", "growth": 4.0, "signal": "req/s急増", "color": Color(1.00, 0.62, 0.18)},
	{"kind": "attack", "name": "Credential Spray", "service": 3, "fix": "rate", "growth": 4.8, "signal": "401急増", "color": Color(0.95, 0.24, 0.22)},
	{"kind": "deploy", "name": "Deploy Regression", "service": 2, "fix": "rollback", "growth": 4.3, "signal": "500 spike", "color": Color(0.95, 0.36, 0.18)},
	{"kind": "db", "name": "DB Connection Spike", "service": 5, "fix": "restart", "growth": 3.8, "signal": "conn pool枯渇", "color": Color(0.90, 0.25, 0.22)},
	{"kind": "queue", "name": "Queue Lag", "service": 4, "fix": "restart", "growth": 3.6, "signal": "lag増加", "color": Color(0.95, 0.72, 0.20)},
	{"kind": "config", "name": "Config Drift", "service": 6, "fix": "rollback", "growth": 3.4, "signal": "worker失敗", "color": Color(0.50, 0.76, 1.00)},
	{"kind": "payment", "name": "Payment API Timeout", "service": 7, "fix": "log", "growth": 3.7, "signal": "決済timeout", "color": Color(0.95, 0.42, 0.34)}
]

const RUNBOOKS = {
	"log": {
		"name": "LOG FOCUS",
		"jp": "ログを絞る",
		"duration": 3.6,
		"color": Color(0.12, 0.78, 0.86),
		"return": "原因確度+",
		"risk": "時間が進む"
	},
	"rate": {
		"name": "RATE LIMIT",
		"jp": "レート制限",
		"duration": 4.2,
		"color": Color(0.15, 0.86, 0.48),
		"return": "負荷/攻撃を抑える",
		"risk": "UXを少し削る"
	},
	"isolate": {
		"name": "ISOLATE",
		"jp": "隔離",
		"duration": 4.8,
		"color": Color(0.95, 0.64, 0.18),
		"return": "伝播を止める",
		"risk": "依存機能停止"
	},
	"rollback": {
		"name": "ROLLBACK",
		"jp": "ロールバック",
		"duration": 5.8,
		"color": Color(0.35, 0.57, 1.00),
		"return": "deploy/configに強い",
		"risk": "違う原因だと空振り"
	},
	"restart": {
		"name": "RESTART",
		"jp": "再起動",
		"duration": 4.5,
		"color": Color(0.72, 0.55, 1.00),
		"return": "ヘルス回復",
		"risk": "瞬間的に不安定"
	},
	"page": {
		"name": "PAGE LEAD",
		"jp": "担当者を呼ぶ",
		"duration": 6.0,
		"color": Color(0.98, 0.48, 0.38),
		"return": "処理速度+",
		"risk": "疲労が増える"
	}
}

const LOADOUT = ["log", "rate", "isolate", "rollback", "restart", "page"]

var state = "title"
var rng = RandomNumberGenerator.new()
var font
var muted = false
var meta = {"best_score": 0, "runs": 0, "wins": 0}

var services = []
var active_incidents = []
var alert_queue = []
var response_queue = []
var current_action = {}
var selected_alert = -1
var selected_service = 2
var interrupt_mode = false

var time_left = SHIFT_SECONDS
var error_budget = START_ERROR_BUDGET
var fatigue = 0.0
var stack_pressure = 0.0
var backup_timer = 0.0
var spawn_timer = 0.0
var telemetry_timer = 0.0
var propagation_timer = 0.0
var incident_seq = 1
var actions_completed = 0
var incidents_resolved = 0
var score = 0
var run_saved = false
var paused = false
var fast_forward = false

var graph_rect = Rect2()
var alert_rects = []
var service_rects = []
var runbook_rects = []
var queue_rects = []
var button_rects = {}
var log_lines = []
var floaters = []
var pulses = []
var hover_pos = Vector2.ZERO
var anim_time = 0.0
var screen_shake = 0.0

var sound_players = {}


func _ready():
	rng.randomize()
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	font = _load_ui_font()
	_load_meta()
	_setup_audio()
	set_process(true)
	queue_redraw()


func _process(delta):
	anim_time += delta
	screen_shake = max(0.0, screen_shake - delta * 18.0)
	_update_effects(delta)
	if state == "playing" and not paused:
		var sim_delta = delta * (2.0 if fast_forward else 1.0)
		_update_game(sim_delta)
	queue_redraw()


func _exit_tree():
	for player in sound_players.values():
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	sound_players.clear()


func _gui_input(event):
	if event is InputEventMouseMotion:
		hover_pos = event.position
		queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed:
		hover_pos = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_selection()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if state == "help":
					state = "title"
				else:
					_cancel_selection()
			KEY_F1:
				state = "help"
			KEY_M:
				muted = not muted
				_add_log("音: " + ("OFF" if muted else "ON"))
			KEY_SPACE:
				if state == "playing":
					fast_forward = not fast_forward
					_add_log("倍速: " + ("ON" if fast_forward else "OFF"))
			KEY_P:
				if state == "playing":
					paused = not paused
			KEY_R:
				if state == "game_over" or state == "victory":
					_start_run()
	queue_redraw()


func _draw():
	button_rects.clear()
	alert_rects.clear()
	service_rects.clear()
	runbook_rects.clear()
	queue_rects.clear()
	if state == "title":
		_draw_title()
	elif state == "help":
		_draw_help()
	elif state == "playing":
		_draw_play()
	elif state == "game_over":
		_draw_end_screen(false)
	elif state == "victory":
		_draw_end_screen(true)


func _handle_click(pos):
	for id in button_rects.keys():
		if button_rects[id].has_point(pos):
			_activate_button(id)
			return
	if state != "playing":
		return
	for i in range(alert_rects.size()):
		if alert_rects[i].has_point(pos):
			_select_alert(i)
			return
	for i in range(service_rects.size()):
		if service_rects[i].has_point(pos):
			selected_service = i
			selected_alert = _first_alert_for_service(i)
			_play_sound("select")
			return
	for i in range(runbook_rects.size()):
		if runbook_rects[i].has_point(pos):
			_enqueue_command(LOADOUT[i])
			return


func _activate_button(id):
	match id:
		"start":
			_start_run()
		"help":
			state = "help"
		"title":
			state = "title"
		"restart":
			_start_run()
		"quit":
			get_tree().quit()
		"mute":
			muted = not muted
			_add_log("音: " + ("OFF" if muted else "ON"))
		"interrupt":
			interrupt_mode = not interrupt_mode
			_add_log("割り込み: " + ("ON" if interrupt_mode else "OFF"))
		"pause":
			paused = not paused
		"speed":
			fast_forward = not fast_forward
		"clear_select":
			_cancel_selection()
	queue_redraw()


func _start_run():
	state = "playing"
	services.clear()
	for data in SERVICES:
		services.append({
			"id": data["id"],
			"name": data["name"],
			"role": data["role"],
			"pos": data["pos"],
			"critical": data["critical"],
			"color": data["color"],
			"health": 100.0,
			"load": 10.0 + rng.randf_range(0.0, 8.0),
			"isolated": 0.0,
			"pulse": 0.0,
			"down_flash": 0.0
		})
	active_incidents.clear()
	alert_queue.clear()
	response_queue.clear()
	current_action.clear()
	selected_alert = -1
	selected_service = 2
	interrupt_mode = false
	time_left = SHIFT_SECONDS
	error_budget = START_ERROR_BUDGET
	fatigue = 0.0
	stack_pressure = 0.0
	backup_timer = 0.0
	spawn_timer = 1.2
	telemetry_timer = 2.0
	propagation_timer = 3.0
	incident_seq = 1
	actions_completed = 0
	incidents_resolved = 0
	score = 0
	run_saved = false
	paused = false
	fast_forward = false
	log_lines.clear()
	floaters.clear()
	pulses.clear()
	_add_log("02:17 NIGHT SHIFT - オンコール開始。")
	_add_log("本番環境に不穏な兆候。Alert Queueを裁け。")
	_spawn_incident(true)
	_play_sound("start")


func _update_game(delta):
	time_left -= delta
	spawn_timer -= delta
	telemetry_timer -= delta
	propagation_timer -= delta
	backup_timer = max(0.0, backup_timer - delta)
	stack_pressure = max(0.0, stack_pressure - delta * 0.08)
	fatigue = max(0.0, fatigue - delta * 0.42)

	if spawn_timer <= 0.0:
		_spawn_incident(false)
		var pressure = 1.0 - clamp(time_left / SHIFT_SECONDS, 0.0, 1.0)
		spawn_timer = rng.randf_range(12.0, 18.0) - pressure * 3.5
		if active_incidents.size() >= 5:
			spawn_timer += 4.0
	if telemetry_timer <= 0.0:
		_emit_telemetry()
		telemetry_timer = rng.randf_range(3.2, 5.4)
	if propagation_timer <= 0.0:
		_propagate_incidents()
		propagation_timer = 3.2

	_update_incidents(delta)
	_update_services(delta)
	_update_response_queue(delta)
	_update_budget(delta)
	_validate_selection()

	if error_budget <= 0.0:
		_finish_run(false)
	elif time_left <= 0.0:
		_finish_run(true)


func _spawn_incident(opening):
	if active_incidents.size() >= 9:
		return
	var template = INCIDENT_TEMPLATES[rng.randi_range(0, INCIDENT_TEMPLATES.size() - 1)].duplicate()
	if opening:
		template = INCIDENT_TEMPLATES[2].duplicate()
	var service_index = int(template["service"])
	if not opening and rng.randf() < 0.30:
		service_index = rng.randi_range(0, SERVICES.size() - 1)
	var severity = rng.randf_range(14.0, 24.0)
	if time_left < SHIFT_SECONDS * 0.42:
		severity += rng.randf_range(4.0, 12.0)
	var incident = {
		"id": incident_seq,
		"kind": template["kind"],
		"name": template["name"],
		"service": service_index,
		"fix": template["fix"],
		"growth": float(template["growth"]),
		"signal": template["signal"],
		"color": template["color"],
		"severity": severity,
		"confidence": 26.0,
		"age": 0.0,
		"propagated": [],
		"contained": 0.0,
		"root_known": false
	}
	incident_seq += 1
	active_incidents.append(incident)
	_push_alert_for_incident(incident, "P2" if severity < 32.0 else "P1")
	selected_alert = alert_queue.size() - 1
	selected_service = service_index
	services[service_index]["pulse"] = 1.0
	_add_log("%sで%sを検知。" % [services[service_index]["name"], template["signal"]])
	_add_floater(_service_pos(service_index), "ALERT", template["color"])
	_play_sound("spawn")


func _push_alert_for_incident(incident, priority):
	var alert = {
		"id": int(incident["id"]) * 10 + rng.randi_range(0, 9),
		"incident_id": int(incident["id"]),
		"service": int(incident["service"]),
		"title": incident["signal"],
		"priority": priority,
		"severity": float(incident["severity"]),
		"noise": false,
		"age": 0.0
	}
	alert_queue.push_front(alert)
	while alert_queue.size() > MAX_ALERTS:
		alert_queue.pop_back()


func _emit_telemetry():
	for alert in alert_queue:
		alert["age"] = float(alert.get("age", 0.0)) + telemetry_timer
	if rng.randf() < 0.24:
		var service_index = rng.randi_range(0, services.size() - 1)
		alert_queue.push_front({
			"id": incident_seq * 100 + rng.randi_range(10, 99),
			"incident_id": -1,
			"service": service_index,
			"title": ["minor log burst", "slow query?", "synthetic check", "cache miss noise"][rng.randi_range(0, 3)],
			"priority": "P3",
			"severity": rng.randf_range(4.0, 16.0),
			"noise": true,
			"age": 0.0
		})
	for inc in active_incidents:
		if float(inc["severity"]) >= 46.0 and rng.randf() < 0.34:
			_push_alert_for_incident(inc, "P1")
	while alert_queue.size() > MAX_ALERTS:
		alert_queue.pop_back()


func _update_incidents(delta):
	for i in range(active_incidents.size() - 1, -1, -1):
		var inc = active_incidents[i]
		inc["age"] = float(inc["age"]) + delta
		inc["contained"] = max(0.0, float(inc.get("contained", 0.0)) - delta)
		var service_index = int(inc["service"])
		var service = services[service_index]
		var containment = 0.28 if float(inc.get("contained", 0.0)) > 0.0 else 1.0
		var isolated = float(service.get("isolated", 0.0)) > 0.0
		var isolation_factor = 0.48 if isolated else 1.0
		var growth = float(inc["growth"]) * containment * isolation_factor
		inc["severity"] = clamp(float(inc["severity"]) + growth * delta * 0.34, 0.0, 100.0)
		service["load"] = clamp(float(service["load"]) + float(inc["severity"]) * 0.011 * delta, 0.0, 100.0)
		service["health"] = clamp(float(service["health"]) - float(inc["severity"]) * 0.0075 * delta * (0.7 if isolated else 1.0), 0.0, 100.0)
		service["pulse"] = max(float(service.get("pulse", 0.0)), min(1.0, float(inc["severity"]) / 100.0))
		if float(inc["severity"]) <= 1.0:
			_resolve_incident_at(i, "収束")


func _update_services(delta):
	for i in range(services.size()):
		var service = services[i]
		service["isolated"] = max(0.0, float(service.get("isolated", 0.0)) - delta)
		service["pulse"] = max(0.0, float(service.get("pulse", 0.0)) - delta * 1.5)
		service["down_flash"] = max(0.0, float(service.get("down_flash", 0.0)) - delta * 1.4)
		if not _service_has_incident(i):
			service["health"] = min(100.0, float(service["health"]) + delta * 1.2)
			service["load"] = max(4.0, float(service["load"]) - delta * 2.4)
		else:
			service["load"] = max(3.0, float(service["load"]) - delta * 0.25)
		if float(service["health"]) <= 0.5:
			service["down_flash"] = 1.0


func _update_response_queue(delta):
	if current_action.is_empty() and not response_queue.is_empty():
		current_action = response_queue.pop_front()
		current_action["remaining"] = float(current_action["duration"])
		_add_log("%s開始 -> %s" % [current_action["jp"], services[int(current_action["service"])]["name"]])
		_play_sound("start")
	if current_action.is_empty():
		return
	var speed = 1.0 + (0.40 if backup_timer > 0.0 else 0.0)
	speed *= clamp(1.0 - fatigue * 0.006, 0.55, 1.0)
	current_action["remaining"] = float(current_action["remaining"]) - delta * speed
	if float(current_action["remaining"]) <= 0.0:
		_complete_current_action()


func _update_budget(delta):
	var drain = 0.0
	for i in range(services.size()):
		var service = services[i]
		var degraded = max(0.0, 100.0 - float(service["health"])) / 100.0
		var overloaded = max(0.0, float(service["load"]) - 65.0) / 35.0
		drain += (degraded * 0.70 + overloaded * 0.42) * float(service["critical"])
		if float(service["isolated"]) > 0.0:
			drain += 0.07 * float(service["critical"])
	drain += max(0, active_incidents.size() - 4) * 0.18
	drain += stack_pressure * 0.025
	error_budget = clamp(error_budget - drain * delta * 0.38, 0.0, START_ERROR_BUDGET)
	score += int(max(0.0, 0.15 - drain * 0.01) * delta * 10.0)


func _propagate_incidents():
	for inc in active_incidents.duplicate():
		if float(inc["severity"]) < 42.0:
			continue
		var source = int(inc["service"])
		if float(services[source].get("isolated", 0.0)) > 0.0:
			continue
		var propagated = inc.get("propagated", [])
		for edge in EDGES:
			if int(edge[0]) != source:
				continue
			var target = int(edge[1])
			if propagated.has(target):
				continue
			var chance = clamp(float(inc["severity"]) / 145.0, 0.14, 0.68)
			if rng.randf() <= chance and active_incidents.size() < 9:
				propagated.append(target)
				inc["propagated"] = propagated
				var child = {
					"id": incident_seq,
					"kind": inc["kind"],
					"name": "Cascaded " + str(inc["name"]),
					"service": target,
					"fix": inc["fix"],
					"growth": max(2.5, float(inc["growth"]) - 0.8),
					"signal": "cascade risk",
					"color": inc["color"],
					"severity": float(inc["severity"]) * 0.36,
					"confidence": max(18.0, float(inc["confidence"]) - 18.0),
					"age": 0.0,
					"propagated": [],
					"contained": 0.0,
					"root_known": false
				}
				incident_seq += 1
				active_incidents.append(child)
				_push_alert_for_incident(child, "P1")
				pulses.append({"from": _service_pos(source), "to": _service_pos(target), "life": 0.70, "color": inc["color"]})
				_add_log("%sへ障害が伝播。" % services[target]["name"])
				_play_sound("hit")
				break


func _enqueue_command(id):
	if not RUNBOOKS.has(id):
		return false
	if response_queue.size() >= MAX_QUEUE and not interrupt_mode:
		_add_log("Response Queueが詰まっている。割り込みなら可能。")
		_play_sound("deny")
		return false
	var target_service = selected_service
	var target_incident = -1
	var inc = _selected_incident()
	if not inc.is_empty():
		target_incident = int(inc["id"])
		target_service = int(inc["service"])
	elif selected_alert >= 0 and selected_alert < alert_queue.size():
		target_service = int(alert_queue[selected_alert]["service"])
	var data = RUNBOOKS[id]
	var command = {
		"id": id,
		"name": data["name"],
		"jp": data["jp"],
		"service": target_service,
		"incident": target_incident,
		"duration": float(data["duration"]),
		"remaining": float(data["duration"]),
		"color": data["color"],
		"interrupt": interrupt_mode
	}
	if interrupt_mode:
		if not current_action.is_empty():
			response_queue.push_front(current_action)
			current_action = {}
		response_queue.push_front(command)
		stack_pressure += 1.4
		fatigue += 5.5
		error_budget = max(0.0, error_budget - 0.6)
		interrupt_mode = false
		_add_log("割り込み投入: %s" % data["jp"])
	else:
		response_queue.append(command)
		_add_log("キュー投入: %s" % data["jp"])
	_play_sound("play")
	return true


func _complete_current_action():
	var action = current_action.duplicate()
	current_action.clear()
	actions_completed += 1
	var id = str(action["id"])
	var service_index = int(action["service"])
	var inc_index = _incident_index_by_id(int(action.get("incident", -1)))
	var inc = active_incidents[inc_index] if inc_index != -1 else {}
	var service = services[service_index]
	var message = ""
	match id:
		"log":
			if _selected_alert_is_noise(action):
				_remove_noise_alert_for_service(service_index)
				message = "ノイズを捨てた。"
				score += 5
			elif not inc.is_empty():
				inc["confidence"] = min(100.0, float(inc["confidence"]) + 46.0)
				inc["severity"] = max(0.0, float(inc["severity"]) - 7.0)
				inc["root_known"] = float(inc["confidence"]) >= 70.0
				message = "原因確度が上がった。推奨: %s" % RUNBOOKS[str(inc["fix"])]["jp"]
				score += 8
			else:
				service["load"] = max(0.0, float(service["load"]) - 5.0)
				message = "ログから異常なしを確認。"
		"rate":
			error_budget = max(0.0, error_budget - 1.8)
			service["load"] = max(0.0, float(service["load"]) - 28.0)
			if not inc.is_empty():
				var amount = 42.0 if str(inc["kind"]) == "traffic" or str(inc["kind"]) == "attack" else 18.0
				inc["severity"] = max(0.0, float(inc["severity"]) - amount)
			message = "負荷を絞った。UXを少し犠牲にした。"
		"isolate":
			service["isolated"] = 14.0
			error_budget = max(0.0, error_budget - 1.2 * float(service["critical"]))
			if not inc.is_empty():
				inc["contained"] = 16.0
				inc["severity"] = max(0.0, float(inc["severity"]) - 24.0)
			message = "%sを隔離。伝播を抑える。" % service["name"]
		"rollback":
			if not inc.is_empty() and (str(inc["fix"]) == "rollback" or float(inc["confidence"]) >= 72.0):
				inc["severity"] = max(0.0, float(inc["severity"]) - 72.0)
				service["health"] = min(100.0, float(service["health"]) + 18.0)
				message = "ロールバックが刺さった。"
				score += 16
			else:
				fatigue += 4.0
				if not inc.is_empty():
					inc["severity"] = max(0.0, float(inc["severity"]) - 5.0)
				message = "空振り気味。時間を失った。"
		"restart":
			service["health"] = min(100.0, float(service["health"]) + 30.0)
			service["load"] = max(0.0, float(service["load"]) - 22.0)
			error_budget = max(0.0, error_budget - 0.8)
			if not inc.is_empty():
				var amount2 = 42.0 if str(inc["fix"]) == "restart" else 22.0
				inc["severity"] = max(0.0, float(inc["severity"]) - amount2)
			message = "%sを再起動。" % service["name"]
		"page":
			backup_timer = 34.0
			fatigue += 9.0
			for active in active_incidents:
				active["confidence"] = min(100.0, float(active["confidence"]) + 9.0)
			message = "担当者が合流。処理速度UP、疲労も増加。"
	if not inc.is_empty() and float(inc.get("severity", 0.0)) <= 1.0:
		var current_index = _incident_index_by_id(int(inc["id"]))
		if current_index != -1:
			_resolve_incident_at(current_index, "対応完了")
	service["pulse"] = 1.0
	_add_log(message)
	_add_floater(_service_pos(service_index), "DONE", C_GREEN)
	_cleanup_alerts()
	_play_sound("reward")


func _resolve_incident_at(index, reason):
	if index < 0 or index >= active_incidents.size():
		return
	var inc = active_incidents[index]
	var svc = int(inc["service"])
	score += 24 + int(float(inc.get("confidence", 0.0)) * 0.12)
	incidents_resolved += 1
	_add_log("%s: %s収束。" % [services[svc]["name"], reason])
	_add_floater(_service_pos(svc), "RESOLVED", C_CYAN)
	active_incidents.remove_at(index)
	_cleanup_alerts()


func _selected_incident():
	if selected_alert >= 0 and selected_alert < alert_queue.size():
		var alert = alert_queue[selected_alert]
		if bool(alert.get("noise", false)):
			return {}
		var idx = _incident_index_by_id(int(alert.get("incident_id", -1)))
		if idx != -1:
			return active_incidents[idx]
	var best_idx = -1
	var best_severity = -1.0
	for i in range(active_incidents.size()):
		var inc = active_incidents[i]
		if int(inc["service"]) == selected_service and float(inc["severity"]) > best_severity:
			best_idx = i
			best_severity = float(inc["severity"])
	if best_idx != -1:
		return active_incidents[best_idx]
	return {}


func _selected_alert_is_noise(action):
	if selected_alert >= 0 and selected_alert < alert_queue.size():
		var alert = alert_queue[selected_alert]
		return bool(alert.get("noise", false)) and int(alert["service"]) == int(action["service"])
	return false


func _remove_noise_alert_for_service(service_index):
	for i in range(alert_queue.size() - 1, -1, -1):
		if bool(alert_queue[i].get("noise", false)) and int(alert_queue[i]["service"]) == service_index:
			alert_queue.remove_at(i)
			return


func _cleanup_alerts():
	for i in range(alert_queue.size() - 1, -1, -1):
		var alert = alert_queue[i]
		if bool(alert.get("noise", false)):
			continue
		if _incident_index_by_id(int(alert.get("incident_id", -1))) == -1:
			alert_queue.remove_at(i)
	if selected_alert >= alert_queue.size():
		selected_alert = alert_queue.size() - 1


func _validate_selection():
	if selected_service < 0 or selected_service >= services.size():
		selected_service = 2
	if selected_alert >= alert_queue.size():
		selected_alert = alert_queue.size() - 1


func _incident_index_by_id(id):
	for i in range(active_incidents.size()):
		if int(active_incidents[i]["id"]) == id:
			return i
	return -1


func _service_has_incident(service_index):
	for inc in active_incidents:
		if int(inc["service"]) == service_index:
			return true
	return false


func _first_alert_for_service(service_index):
	for i in range(alert_queue.size()):
		if int(alert_queue[i]["service"]) == service_index:
			return i
	return -1


func _select_alert(index):
	if index < 0 or index >= alert_queue.size():
		return
	selected_alert = index
	selected_service = int(alert_queue[index]["service"])
	_play_sound("select")


func _finish_run(won):
	if run_saved:
		return
	run_saved = true
	if won:
		score += 300 + int(error_budget * 4.0) + incidents_resolved * 20 - int(fatigue)
		state = "victory"
		_play_sound("victory")
	else:
		score += incidents_resolved * 12 + actions_completed * 3
		state = "game_over"
		_play_sound("core")
	meta["runs"] = int(meta.get("runs", 0)) + 1
	if won:
		meta["wins"] = int(meta.get("wins", 0)) + 1
	meta["best_score"] = max(int(meta.get("best_score", 0)), score)
	_save_meta()


func _cancel_selection():
	selected_alert = -1
	interrupt_mode = false


func _draw_title():
	var view = get_viewport_rect().size
	_draw_ops_background(view)
	var left = max(44.0, view.x * 0.07)
	var top = view.y * 0.16
	_draw_text("REALTIME INCIDENT ROGUELITE", Vector2(left, top), 17, C_DIM)
	_draw_text("Alert Stack", Vector2(left, top + 70), 66, C_TEXT)
	_draw_text("本番環境は眠らない", Vector2(left + 3, top + 126), 32, C_AMBER)
	_draw_text("キュー、スタック、依存グラフ、割り込み判断で、深夜シフトを生き延びる。", Vector2(left + 3, top + 184), 20, C_TEXT)
	_draw_text("止めて考える防衛ではなく、壊れ続ける状況を裁くMVP。", Vector2(left + 3, top + 216), 18, C_DIM)
	var bx = left + 3
	var by = top + 292
	_draw_button("start", Rect2(bx, by, 246, 56), "SHIFT START", true)
	_draw_button("help", Rect2(bx, by + 70, 246, 48), "遊び方", false)
	_draw_button("quit", Rect2(bx, by + 130, 246, 48), "終了", false)
	_draw_text("Best Score  %d" % int(meta.get("best_score", 0)), Vector2(left + 4, view.y - 86), 18, C_TEXT)
	_draw_text("Runs %d   Wins %d" % [int(meta.get("runs", 0)), int(meta.get("wins", 0))], Vector2(left + 4, view.y - 56), 16, C_DIM)
	_draw_title_graph(Rect2(Vector2(view.x * 0.56, view.y * 0.13), Vector2(view.x * 0.35, view.y * 0.62)))


func _draw_help():
	var view = get_viewport_rect().size
	_draw_ops_background(view)
	var panel = Rect2(Vector2(54, 54), view - Vector2(108, 108))
	draw_rect(panel, C_PANEL, true)
	draw_rect(panel, C_LINE, false, 1.5)
	_draw_text("遊び方", panel.position + Vector2(34, 54), 38, C_TEXT)
	var y = panel.position.y + 112
	var lines = [
		"あなたはインシデントコマンダーです。ゲームはリアルタイムで進み、Spaceは倍速であって進行条件ではありません。",
		"左のAlert Queueからアラートを選ぶか、中央のService Graphで対象サービスを選びます。",
		"下のRunbookをクリックするとResponse Queueへ投入。処理は順番に実行され、完了まで数秒かかります。",
		"割り込みをONにすると次のRunbookを先頭に積めます。ただしStack Pressureと疲労が増え、後で苦しくなります。",
		"Log Focusで原因確度を上げ、Rate Limit / Isolate / Rollback / Restartを状況に合わせて使います。",
		"障害は依存グラフを上から下へ伝播します。全部を救うより、何を遅らせ、何を諦めるかが勝負です。",
		"Error Budgetが0になると敗北。シフト終了まで耐えれば勝利です。"
	]
	for line in lines:
		y = _draw_wrapped_text(line, Vector2(panel.position.x + 40, y), panel.size.x - 80, 19, C_TEXT, 30) + 18
	_draw_button("title", Rect2(panel.position.x + 40, panel.end.y - 78, 190, 48), "タイトルへ", true)
	_draw_button("start", Rect2(panel.position.x + 250, panel.end.y - 78, 190, 48), "開始", false)


func _draw_play():
	var view = get_viewport_rect().size
	_draw_ops_background(view)
	var shake = Vector2(rng.randf_range(-screen_shake, screen_shake), rng.randf_range(-screen_shake, screen_shake)) if screen_shake > 0.1 else Vector2.ZERO
	draw_set_transform(shake, 0.0, Vector2.ONE)
	_draw_top_bar(view)
	var top = 72.0
	var bottom_h = 150.0
	var left_w = clamp(view.x * 0.22, 238.0, 288.0)
	var right_w = clamp(view.x * 0.27, 300.0, 358.0)
	var gap = 18.0
	var graph_w = view.x - left_w - right_w - gap * 4.0
	var graph_h = view.y - top - bottom_h - 34.0
	graph_rect = Rect2(Vector2(left_w + gap * 2.0, top), Vector2(graph_w, graph_h))
	_draw_alert_panel(Rect2(Vector2(gap, top), Vector2(left_w, graph_h)))
	_draw_graph_panel(graph_rect)
	_draw_response_panel(Rect2(Vector2(graph_rect.end.x + gap, top), Vector2(right_w, graph_h)))
	_draw_runbooks(Rect2(Vector2(gap, view.y - bottom_h + 14.0), Vector2(view.x - gap * 2.0, bottom_h - 28.0)))
	_draw_effects()
	_draw_hover()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if paused:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.45), true)
		_draw_text("PAUSED", view * 0.5 + Vector2(-74, 0), 36, C_TEXT)


func _draw_top_bar(view):
	draw_rect(Rect2(0, 0, view.x, 58), Color(0.020, 0.027, 0.034, 0.98), true)
	draw_line(Vector2(0, 57), Vector2(view.x, 57), Color(0.16, 0.28, 0.32, 0.9), 1.0)
	_draw_text("Alert Stack", Vector2(24, 37), 24, C_TEXT)
	_draw_status("SHIFT", _time_label(time_left), Vector2(184, 13), C_CYAN)
	_draw_status("ERROR BUDGET", "%d%%" % int(round(error_budget)), Vector2(316, 13), C_GREEN if error_budget > 45.0 else C_RED)
	_draw_status("INCIDENTS", "%d" % active_incidents.size(), Vector2(500, 13), C_AMBER)
	_draw_status("FATIGUE", "%d" % int(round(fatigue)), Vector2(626, 13), C_PURPLE)
	_draw_status("STACK", "%.1f" % stack_pressure, Vector2(744, 13), C_RED if stack_pressure > 3.0 else C_DIM)
	_draw_button("speed", Rect2(view.x - 318, 12, 80, 34), "x2 " + ("ON" if fast_forward else "OFF"), false)
	_draw_button("pause", Rect2(view.x - 230, 12, 70, 34), "PAUSE" if not paused else "PLAY", false)
	_draw_button("mute", Rect2(view.x - 152, 12, 64, 34), "音" + ("OFF" if muted else "ON"), false)
	_draw_button("title", Rect2(view.x - 80, 12, 58, 34), "戻る", false)


func _draw_status(label, value, pos, color):
	_draw_text(label, pos + Vector2(0, 9), 10, C_DIM)
	_draw_text(value, pos + Vector2(0, 30), 20, color)


func _draw_alert_panel(rect):
	_panel(rect, "ALERT QUEUE")
	var y = rect.position.y + 48
	if alert_queue.is_empty():
		_draw_wrapped_text("静かすぎる。次の兆候を待て。", rect.position + Vector2(16, y), rect.size.x - 32, 15, C_DIM, 21)
	for i in range(alert_queue.size()):
		var alert = alert_queue[i]
		var h = 54.0
		var item = Rect2(rect.position + Vector2(12, y), Vector2(rect.size.x - 24, h))
		alert_rects.append(item)
		var selected = i == selected_alert
		var severity = float(alert["severity"])
		var priority_color = _priority_color(str(alert["priority"]))
		draw_rect(item, Color(0.07, 0.085, 0.095, 0.96), true)
		draw_rect(item, priority_color if selected else Color(0.15, 0.20, 0.22, 0.85), false, 2.0 if selected else 1.0)
		draw_rect(Rect2(item.position, Vector2(4, item.size.y)), priority_color, true)
		_draw_text(str(alert["priority"]), item.position + Vector2(12, 18), 13, priority_color)
		_draw_text(services[int(alert["service"])]["name"], item.position + Vector2(46, 18), 13, C_TEXT)
		_draw_text(str(alert["title"]), item.position + Vector2(12, 39), 12, C_DIM if not bool(alert["noise"]) else C_MUTED)
		var bw = item.size.x - 20
		var bar = Rect2(item.position + Vector2(10, item.size.y - 7), Vector2(bw, 3))
		draw_rect(bar, Color(0.13, 0.15, 0.16), true)
		draw_rect(Rect2(bar.position, Vector2(bw * clamp(severity / 100.0, 0.0, 1.0), 3)), priority_color, true)
		y += h + 8
	var footer_y = rect.end.y - 42
	_draw_text("選択: " + services[selected_service]["name"], Vector2(rect.position.x + 16, footer_y), 14, C_CYAN)
	_draw_button("clear_select", Rect2(rect.end.x - 86, rect.end.y - 48, 70, 32), "解除", false)


func _draw_graph_panel(rect):
	_panel(rect, "SERVICE GRAPH")
	var inner = rect.grow(-18)
	for i in range(10):
		var x = inner.position.x + float(i) * inner.size.x / 9.0
		draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(0.08, 0.14, 0.16, 0.45), 1.0)
	for i in range(6):
		var y = inner.position.y + float(i) * inner.size.y / 5.0
		draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), Color(0.08, 0.14, 0.16, 0.45), 1.0)
	for edge in EDGES:
		var from = _service_pos(int(edge[0]))
		var to = _service_pos(int(edge[1]))
		var hot = _edge_is_hot(int(edge[0]), int(edge[1]))
		draw_line(from, to, C_RED if hot else Color(0.32, 0.52, 0.56, 0.54), 3.2 if hot else 1.6)
		var dir = (to - from).normalized()
		draw_circle(from.lerp(to, 0.72), 3.5, C_RED if hot else Color(0.34, 0.70, 0.75, 0.55))
		draw_line(to - dir * 12.0, to - dir * 22.0 + dir.rotated(0.55) * 8.0, C_RED if hot else Color(0.34, 0.70, 0.75, 0.55), 1.2)
	for pulse in pulses:
		var alpha = clamp(float(pulse["life"]) / 0.70, 0.0, 1.0)
		var color = pulse["color"]
		color.a = alpha
		draw_line(pulse["from"], pulse["to"], color, 6.0)
	for i in range(services.size()):
		_draw_service_node(i)
	_draw_graph_legend(rect)


func _draw_service_node(index):
	var svc = services[index]
	var pos = _service_pos(index)
	var health = float(svc["health"])
	var load = float(svc["load"])
	var radius = 29.0 + float(svc.get("pulse", 0.0)) * 5.0
	var selected = index == selected_service
	var danger = _service_danger(index)
	var color = svc["color"].lerp(C_RED, danger * 0.65)
	service_rects.append(Rect2(pos - Vector2(radius + 8, radius + 8), Vector2((radius + 8) * 2.0, (radius + 8) * 2.0)))
	draw_circle(pos + Vector2(3, 4), radius + 5, Color(0, 0, 0, 0.38))
	draw_circle(pos, radius + 7, Color(color.r, color.g, color.b, 0.18 + danger * 0.20))
	draw_circle(pos, radius, Color(0.030, 0.046, 0.055))
	draw_arc(pos, radius - 3, -PI * 0.5, -PI * 0.5 + TAU * clamp(health / 100.0, 0.0, 1.0), 48, color, 5.0)
	draw_arc(pos, radius - 10, -PI * 0.5, -PI * 0.5 + TAU * clamp(load / 100.0, 0.0, 1.0), 48, C_AMBER, 3.0)
	if selected:
		draw_circle(pos, radius + 11, Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.20))
		draw_arc(pos, radius + 11, 0, TAU, 64, C_CYAN, 2.4)
	if float(svc["isolated"]) > 0.0:
		draw_arc(pos, radius + 15, -PI * 0.5, -PI * 0.5 + TAU * clamp(float(svc["isolated"]) / 14.0, 0.0, 1.0), 40, C_AMBER, 3.0)
		_draw_text("ISO", pos + Vector2(-16, radius + 28), 12, C_AMBER)
	_draw_text(str(svc["name"]), pos + Vector2(-24, 5), 14, C_TEXT)
	_draw_text("%d%%" % int(round(health)), pos + Vector2(-18, 23), 12, C_DIM)


func _draw_graph_legend(rect):
	var legend = Rect2(rect.position + Vector2(16, rect.size.y - 82), Vector2(210, 62))
	draw_rect(legend, Color(0.025, 0.034, 0.040, 0.78), true)
	draw_rect(legend, C_LINE, false, 1.0)
	_draw_text("外周: Health  内周: Load", legend.position + Vector2(12, 23), 13, C_DIM)
	_draw_text("障害は上流から下流へ伝播", legend.position + Vector2(12, 45), 13, C_DIM)


func _draw_response_panel(rect):
	_panel(rect, "RESPONSE STACK")
	var y = rect.position.y + 48
	if not current_action.is_empty():
		var box = Rect2(rect.position + Vector2(14, y), Vector2(rect.size.x - 28, 78))
		var color = current_action["color"]
		draw_rect(box, Color(0.075, 0.087, 0.10), true)
		draw_rect(box, color, false, 1.6)
		_draw_text("RUNNING", box.position + Vector2(12, 18), 11, C_DIM)
		_draw_text(current_action["jp"], box.position + Vector2(12, 44), 19, C_TEXT)
		_draw_text(services[int(current_action["service"])]["name"], box.position + Vector2(12, 67), 13, C_DIM)
		var ratio = 1.0 - clamp(float(current_action["remaining"]) / float(current_action["duration"]), 0.0, 1.0)
		var bar = Rect2(box.position + Vector2(116, 52), Vector2(box.size.x - 132, 7))
		draw_rect(bar, Color(0.12, 0.14, 0.16), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), color, true)
		y += 94
	else:
		_draw_text("実行中なし", rect.position + Vector2(18, y + 20), 16, C_DIM)
		y += 58
	_draw_text("QUEUE %d/%d" % [response_queue.size(), MAX_QUEUE], Vector2(rect.position.x + 18, y), 14, C_DIM)
	y += 16
	for i in range(min(response_queue.size(), 5)):
		var action = response_queue[i]
		var item = Rect2(rect.position + Vector2(14, y + i * 44), Vector2(rect.size.x - 28, 36))
		draw_rect(item, Color(0.06, 0.072, 0.083, 0.90), true)
		draw_rect(item, Color(0.18, 0.24, 0.26, 0.88), false, 1.0)
		draw_rect(Rect2(item.position, Vector2(5, item.size.y)), action["color"], true)
		_draw_text(action["jp"], item.position + Vector2(14, 23), 13, C_TEXT)
		_draw_text(services[int(action["service"])]["name"], item.position + Vector2(item.size.x - 92, 23), 12, C_DIM)
	var btn_y = rect.position.y + 318
	_draw_button("interrupt", Rect2(rect.position.x + 14, btn_y, rect.size.x - 28, 42), "割り込み " + ("ON" if interrupt_mode else "OFF"), interrupt_mode)
	var status_y = btn_y + 70
	_draw_text("SYSTEM STATUS", Vector2(rect.position.x + 18, status_y), 15, C_TEXT)
	status_y += 24
	for i in range(services.size()):
		var svc = services[i]
		var line_y = status_y + i * 18
		var color = _danger_color(_service_danger(i))
		draw_circle(Vector2(rect.position.x + 24, line_y - 5), 5, color)
		_draw_text("%s %d%%  L%d" % [svc["name"], int(round(float(svc["health"]))), int(round(float(svc["load"])))], Vector2(rect.position.x + 36, line_y), 12, C_DIM)
	var log_y = rect.end.y - 92
	_draw_text("TIMELINE", Vector2(rect.position.x + 18, log_y), 15, C_TEXT)
	log_y += 22
	var start = max(0, log_lines.size() - 4)
	for i in range(start, log_lines.size()):
		_draw_text(log_lines[i], Vector2(rect.position.x + 18, log_y), 12, C_DIM)
		log_y += 17


func _draw_runbooks(rect):
	draw_rect(rect, Color(0.024, 0.031, 0.038, 0.96), true)
	draw_rect(rect, C_LINE, false, 1.0)
	_draw_text("RUNBOOK COMMANDS", rect.position + Vector2(16, 24), 14, C_DIM)
	var card_gap = 10.0
	var card_w = (rect.size.x - 32.0 - card_gap * (LOADOUT.size() - 1)) / LOADOUT.size()
	var card_h = rect.size.y - 42.0
	for i in range(LOADOUT.size()):
		var id = LOADOUT[i]
		var data = RUNBOOKS[id]
		var item = Rect2(rect.position + Vector2(16 + i * (card_w + card_gap), 34), Vector2(card_w, card_h))
		runbook_rects.append(item)
		var can_queue = response_queue.size() < MAX_QUEUE or interrupt_mode
		var base = Color(0.050, 0.068, 0.078) if can_queue else Color(0.032, 0.038, 0.043)
		draw_rect(item, base, true)
		draw_rect(item, data["color"] if interrupt_mode else Color(0.18, 0.25, 0.28, 0.92), false, 1.5)
		draw_rect(Rect2(item.position, Vector2(item.size.x, 5)), data["color"], true)
		_draw_text(data["jp"], item.position + Vector2(12, 28), 16, C_TEXT if can_queue else C_MUTED)
		_draw_text(data["name"], item.position + Vector2(12, 48), 10, C_DIM)
		_draw_text("RET: " + data["return"], item.position + Vector2(12, item.size.y - 31), 11, C_DIM)
		_draw_text("RISK: " + data["risk"], item.position + Vector2(12, item.size.y - 13), 11, C_AMBER if can_queue else C_MUTED)


func _draw_end_screen(won):
	var view = get_viewport_rect().size
	_draw_ops_background(view)
	var panel = Rect2(Vector2(view.x * 0.5 - 330, view.y * 0.5 - 220), Vector2(660, 430))
	draw_rect(panel, C_PANEL, true)
	draw_rect(panel, C_GREEN if won else C_RED, false, 2.4)
	var title = "SHIFT SURVIVED" if won else "STACK OVERFLOW"
	var subtitle = "本番環境は朝を迎えた。" if won else "Error Budgetが尽きた。"
	_draw_text(title, panel.position + Vector2(36, 70), 42, C_GREEN if won else C_RED)
	_draw_text(subtitle, panel.position + Vector2(38, 108), 20, C_TEXT)
	_draw_text("Score: %d" % score, panel.position + Vector2(42, 170), 26, C_AMBER)
	_draw_text("Resolved Incidents: %d" % incidents_resolved, panel.position + Vector2(42, 214), 19, C_TEXT)
	_draw_text("Completed Runbooks: %d" % actions_completed, panel.position + Vector2(42, 246), 19, C_TEXT)
	_draw_text("Remaining Error Budget: %d%%" % int(round(max(0.0, error_budget))), panel.position + Vector2(42, 278), 19, C_TEXT)
	_draw_text("Best Score: %d" % int(meta.get("best_score", 0)), panel.position + Vector2(42, 310), 17, C_DIM)
	_draw_button("restart", Rect2(panel.position.x + 42, panel.end.y - 76, 190, 46), "もう一度", true)
	_draw_button("title", Rect2(panel.position.x + 250, panel.end.y - 76, 190, 46), "タイトルへ", false)


func _draw_ops_background(view):
	draw_rect(Rect2(Vector2.ZERO, view), C_BG, true)
	for i in range(18):
		var y = fmod(anim_time * (9.0 + i) + i * 53.0, view.y)
		draw_line(Vector2(0, y), Vector2(view.x, y + sin(anim_time + i) * 18.0), Color(0.05, 0.12, 0.14, 0.16), 1.0)
	for i in range(42):
		var x = fmod(i * 97.0 + anim_time * (18.0 + i % 5), view.x + 60.0) - 30.0
		var y2 = fmod(i * 43.0 + sin(anim_time + i) * 12.0, view.y)
		draw_circle(Vector2(x, y2), 1.4, Color(0.16, 0.92, 0.94, 0.12))
	draw_rect(Rect2(0, 0, view.x, view.y), Color(0, 0, 0, 0.08), true)


func _draw_title_graph(rect):
	draw_rect(rect, Color(0.018, 0.026, 0.033, 0.92), true)
	draw_rect(rect, Color(0.14, 0.30, 0.34, 0.65), false, 1.5)
	var pts = [
		Vector2(0.13, 0.24), Vector2(0.30, 0.52), Vector2(0.48, 0.32), Vector2(0.69, 0.22),
		Vector2(0.50, 0.72), Vector2(0.78, 0.68), Vector2(0.28, 0.82), Vector2(0.90, 0.46)
	]
	for edge in EDGES:
		var a = rect.position + pts[int(edge[0])] * rect.size
		var b = rect.position + pts[int(edge[1])] * rect.size
		draw_line(a, b, Color(0.16, 0.80, 0.85, 0.42), 2.0)
	for i in range(pts.size()):
		var p = rect.position + pts[i] * rect.size
		var hot = 0.5 + sin(anim_time * 2.0 + i) * 0.5
		draw_circle(p, 24, SERVICES[i]["color"].lerp(C_RED, hot * 0.28))
		draw_circle(p, 15, Color(0.025, 0.033, 0.040))
		_draw_text(SERVICES[i]["name"], p + Vector2(-20, 42), 13, C_TEXT)
	_draw_text("LIVE INCIDENT MAP", rect.position + Vector2(18, 28), 15, C_DIM)
	_draw_text("Response Stack  4/6", rect.position + Vector2(18, rect.size.y - 24), 14, C_AMBER)


func _panel(rect, title):
	draw_rect(rect, C_PANEL, true)
	draw_rect(rect, C_LINE, false, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), C_CYAN, true)
	_draw_text(title, rect.position + Vector2(16, 27), 15, C_TEXT)


func _draw_button(id, rect, label, primary):
	button_rects[id] = rect
	var hover = rect.has_point(hover_pos)
	var fill = C_AMBER if primary else Color(0.065, 0.082, 0.092)
	if hover:
		fill = fill.lightened(0.13)
	draw_rect(rect, fill, true)
	draw_rect(rect, C_AMBER if primary else C_LINE, false, 1.2)
	var color = Color(0.03, 0.035, 0.035) if primary else C_TEXT
	_draw_text_center(label, rect, 15 if rect.size.y < 40 else 17, color)


func _draw_text(text, pos, size, color):
	draw_string(font, pos, str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_text_center(text, rect, size, color):
	var label = str(text)
	var text_size = size
	var text_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	while text_width > rect.size.x - 12.0 and text_size > 10:
		text_size -= 1
		text_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var pos = rect.position + Vector2((rect.size.x - text_width) * 0.5, rect.size.y * 0.62)
	_draw_text(label, pos, text_size, color)


func _draw_wrapped_text(text, pos, max_width, size, color, line_height):
	var x = pos.x
	var y = pos.y
	var line = ""
	for ch in str(text):
		var candidate = line + ch
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_width and line != "":
			_draw_text(line, Vector2(x, y), size, color)
			y += line_height
			line = ch
		else:
			line = candidate
	if line != "":
		_draw_text(line, Vector2(x, y), size, color)
		y += line_height
	return y


func _draw_effects():
	for fx in floaters:
		var alpha = clamp(float(fx["life"]) / 0.9, 0.0, 1.0)
		var color = fx["color"]
		color.a = alpha
		_draw_text(str(fx["text"]), fx["pos"], 17, color)


func _draw_hover():
	if state != "playing":
		return
	for i in range(service_rects.size()):
		if service_rects[i].has_point(hover_pos):
			var svc = services[i]
			var lines = [
				"%s / %s" % [svc["name"], svc["role"]],
				"Health %d%%  Load %d" % [int(round(float(svc["health"]))), int(round(float(svc["load"])))],
				"Critical %.1f" % float(svc["critical"])
			]
			if float(svc["isolated"]) > 0.0:
				lines.append("Isolated %.0fs" % float(svc["isolated"]))
			_draw_tooltip(lines)
			return


func _draw_tooltip(lines):
	var w = 220.0
	var h = 20.0 + lines.size() * 22.0
	var rect = Rect2(hover_pos + Vector2(16, 16), Vector2(w, h))
	var view = get_viewport_rect().size
	if rect.end.x > view.x:
		rect.position.x = hover_pos.x - w - 16
	if rect.end.y > view.y:
		rect.position.y = hover_pos.y - h - 16
	draw_rect(rect, Color(0.018, 0.024, 0.030, 0.96), true)
	draw_rect(rect, C_LINE, false, 1.0)
	var y = rect.position.y + 24
	for line in lines:
		_draw_text(line, Vector2(rect.position.x + 12, y), 14, C_TEXT)
		y += 22


func _time_label(seconds):
	var s = max(0, int(ceil(seconds)))
	return "%02d:%02d" % [int(s / 60), s % 60]


func _priority_color(priority):
	match priority:
		"P1":
			return C_RED
		"P2":
			return C_AMBER
		_:
			return C_CYAN


func _danger_color(value):
	if value > 0.72:
		return C_RED
	if value > 0.42:
		return C_AMBER
	return C_GREEN


func _service_danger(index):
	var svc = services[index]
	var health_risk = 1.0 - clamp(float(svc["health"]) / 100.0, 0.0, 1.0)
	var load_risk = clamp((float(svc["load"]) - 55.0) / 45.0, 0.0, 1.0)
	var incident_risk = 0.0
	for inc in active_incidents:
		if int(inc["service"]) == index:
			incident_risk = max(incident_risk, float(inc["severity"]) / 100.0)
	return clamp(max(health_risk, load_risk * 0.8, incident_risk), 0.0, 1.0)


func _edge_is_hot(from, to):
	for inc in active_incidents:
		if int(inc["service"]) == from and float(inc["severity"]) > 45.0:
			return true
		if int(inc["service"]) == to and float(inc["severity"]) > 65.0:
			return true
	return false


func _service_pos(index):
	var p = SERVICES[index]["pos"]
	return graph_rect.position + Vector2(float(p.x) * graph_rect.size.x, float(p.y) * graph_rect.size.y)


func _add_log(line):
	log_lines.append(str(line))
	if log_lines.size() > 80:
		log_lines.remove_at(0)


func _add_floater(pos, text, color):
	floaters.append({"pos": pos + Vector2(rng.randf_range(-14, 14), -12), "text": text, "color": color, "vel": Vector2(rng.randf_range(-8, 8), -30), "life": 0.9})


func _update_effects(delta):
	for i in range(floaters.size() - 1, -1, -1):
		var fx = floaters[i]
		fx["life"] = float(fx["life"]) - delta
		fx["pos"] = fx["pos"] + fx["vel"] * delta
		if float(fx["life"]) <= 0.0:
			floaters.remove_at(i)
	for i in range(pulses.size() - 1, -1, -1):
		pulses[i]["life"] = float(pulses[i]["life"]) - delta
		if float(pulses[i]["life"]) <= 0.0:
			pulses.remove_at(i)


func _load_meta():
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		return
	meta["best_score"] = int(cfg.get_value("meta", "best_score", 0))
	meta["runs"] = int(cfg.get_value("meta", "runs", 0))
	meta["wins"] = int(cfg.get_value("meta", "wins", 0))


func _save_meta():
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "best_score", int(meta.get("best_score", 0)))
	cfg.set_value("meta", "runs", int(meta.get("runs", 0)))
	cfg.set_value("meta", "wins", int(meta.get("wins", 0)))
	cfg.save(SAVE_PATH)


func _load_ui_font():
	var imported = load(UI_FONT_PATH)
	if imported is Font:
		return imported
	var loaded = FontFile.new()
	var err = loaded.load_dynamic_font(UI_FONT_PATH)
	if err == OK:
		return loaded
	return get_theme_default_font()


func _setup_audio():
	sound_players["play"] = _make_player(520.0, 0.07, 0.13)
	sound_players["select"] = _make_player(680.0, 0.04, 0.10)
	sound_players["deny"] = _make_player(120.0, 0.08, 0.14)
	sound_players["hit"] = _make_player(260.0, 0.06, 0.13)
	sound_players["spawn"] = _make_player(180.0, 0.08, 0.12)
	sound_players["core"] = _make_player(88.0, 0.20, 0.18)
	sound_players["reward"] = _make_player(760.0, 0.10, 0.13)
	sound_players["victory"] = _make_player(920.0, 0.16, 0.15)
	sound_players["start"] = _make_player(430.0, 0.10, 0.12)


func _make_player(freq, duration, volume):
	var player = AudioStreamPlayer.new()
	player.stream = _make_tone(freq, duration, volume)
	add_child(player)
	return player


func _make_tone(freq, duration, volume):
	var mix_rate = 22050
	var sample_count = int(mix_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(mix_rate)
		var env = 1.0 - float(i) / float(sample_count)
		var sample = int(sin(t * TAU * freq) * 32767.0 * volume * env)
		data.encode_s16(i * 2, sample)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav


func _play_sound(id):
	if muted:
		return
	if not sound_players.has(id):
		return
	var player = sound_players[id]
	player.stop()
	player.play()
