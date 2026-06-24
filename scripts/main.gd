extends Control

const GRID_W = 9
const GRID_H = 9
const MAX_DAY = 7
const START_INTEGRITY = 38
const SAVE_PATH = "user://memory_garden_meta.cfg"
const TITLE_ART_PATH = "res://assets/title_memory_garden.png"
const CORE_POS = Vector2i(4, 8)
const ENTRANCES = [Vector2i(2, 0), Vector2i(4, 0), Vector2i(6, 0)]

const C_SOIL = Color(0.14, 0.10, 0.06)
const C_PATH = Color(0.12, 0.24, 0.16)
const C_PATH_ALT = Color(0.10, 0.19, 0.15)
const C_GRID = Color(0.36, 0.52, 0.36, 0.35)
const C_TEXT = Color(0.92, 0.88, 0.76)
const C_DIM = Color(0.66, 0.72, 0.64)
const C_GOLD = Color(0.96, 0.72, 0.27)
const C_TEAL = Color(0.26, 0.86, 0.75)
const C_WARN = Color(0.95, 0.37, 0.28)
const C_PANEL = Color(0.055, 0.075, 0.065, 0.92)

const CARD_DB = {
	"rootway": {
		"name": "根道を開く",
		"cost": 1,
		"target": "soil",
		"lines": ["土を通路に変える", "遠回りを作る基本札"],
		"rarity": "basic"
	},
	"spore": {
		"name": "胞子灯",
		"cost": 1,
		"target": "empty_path",
		"lines": ["近くの調査隊へ", "毎ターン小ダメージ"],
		"feature": "spore",
		"rarity": "common"
	},
	"snare": {
		"name": "絡み根",
		"cost": 1,
		"target": "empty_path",
		"lines": ["上を通る相手を", "足止めして削る"],
		"feature": "snare",
		"rarity": "common"
	},
	"thorn": {
		"name": "トゲ芽",
		"cost": 1,
		"target": "empty_path",
		"lines": ["踏んだ相手に", "大きな一撃"],
		"feature": "thorn",
		"rarity": "common"
	},
	"crystal": {
		"name": "記憶水晶",
		"cost": 2,
		"target": "empty_path",
		"lines": ["樹液を増やし", "直線上を撃つ"],
		"feature": "crystal",
		"rarity": "uncommon"
	},
	"mist": {
		"name": "眠り霧",
		"cost": 2,
		"target": "empty_path",
		"lines": ["周囲の相手を", "眠らせて遅らせる"],
		"feature": "mist",
		"rarity": "uncommon"
	},
	"spring": {
		"name": "朝露の泉",
		"cost": 1,
		"target": "empty_path",
		"lines": ["毎ターン樹液+1", "攻撃はしない"],
		"feature": "spring",
		"rarity": "uncommon"
	},
	"nectar": {
		"name": "蜜を集める",
		"cost": 0,
		"target": "none",
		"lines": ["樹液+1", "カードを1枚引く"],
		"rarity": "common"
	},
	"overgrowth": {
		"name": "群生",
		"cost": 2,
		"target": "feature",
		"lines": ["仕掛けを強化", "最大レベル3"],
		"rarity": "uncommon"
	},
	"prune": {
		"name": "剪定",
		"cost": 0,
		"target": "feature",
		"lines": ["仕掛けを取り除き", "樹液+2、1枚引く"],
		"rarity": "common"
	},
	"pulse": {
		"name": "年輪の脈動",
		"cost": 2,
		"target": "none",
		"lines": ["全調査隊に2ダメージ", "仕掛け数で強化"],
		"rarity": "rare"
	},
	"lantern": {
		"name": "迷光ランタン",
		"cost": 1,
		"target": "path",
		"lines": ["そのマスの相手を", "入口側へ押し戻す"],
		"rarity": "rare"
	}
}

const FEATURE_INFO = {
	"spore": {"name": "胞子灯", "short": "胞", "color": Color(0.50, 0.95, 0.47)},
	"snare": {"name": "絡み根", "short": "根", "color": Color(0.32, 0.75, 0.34)},
	"thorn": {"name": "トゲ芽", "short": "芽", "color": Color(0.94, 0.47, 0.36)},
	"crystal": {"name": "記憶水晶", "short": "晶", "color": Color(0.31, 0.90, 0.91)},
	"mist": {"name": "眠り霧", "short": "霧", "color": Color(0.66, 0.78, 0.90)},
	"spring": {"name": "朝露の泉", "short": "泉", "color": Color(0.42, 0.67, 1.0)}
}

const INTRUDER_DB = {
	"scout": {"name": "先触れ", "hp": 5, "score": 8, "color": Color(0.94, 0.78, 0.46), "core": 4, "logic": "direct"},
	"miner": {"name": "採掘係", "hp": 8, "score": 12, "color": Color(0.88, 0.51, 0.36), "core": 6, "armor": 1, "logic": "edge"},
	"cartographer": {"name": "地図係", "hp": 4, "score": 11, "color": Color(0.52, 0.81, 1.0), "core": 7, "haste": true, "logic": "curious"},
	"carrier": {"name": "運搬係", "hp": 10, "score": 16, "color": Color(0.79, 0.66, 0.95), "core": 8, "logic": "cautious"}
}

var state = "title"
var rng = RandomNumberGenerator.new()

var board = []
var intruders = []
var deck = []
var draw_pile = []
var discard_pile = []
var hand = []
var reward_choices = []
var spawn_queue = []
var day = 1
var turn = 1
var sap = 3
var integrity = START_INTEGRITY
var score = 0
var kills = 0
var selected_card = -1
var selected_remove = -1
var run_saved = false
var muted = false
var current_omen = {}
var resolving = false
var resolve_timer = 0.0
var resolve_beats_left = 0
var command_count = 1

var meta = {"best_score": 0, "runs": 0, "wins": 0}
var log_lines = []
var floaters = []
var trails = []
var hover_pos = Vector2.ZERO
var board_origin = Vector2(48, 86)
var cell_size = 58.0
var card_rects = []
var button_rects = {}
var reward_rects = []
var remove_rects = []
var anim_time = 0.0
var phase_flash = 0.0
var screen_shake = 0.0
var font
var font_size = 18
var title_art = null

var sound_players = {}


func _ready():
	rng.randomize()
	DisplayServer.window_set_min_size(Vector2i(960, 540))
	font = get_theme_default_font()
	font_size = get_theme_default_font_size()
	_load_title_art()
	_load_meta()
	_setup_audio()
	set_process(true)
	queue_redraw()


func _process(delta):
	anim_time += delta
	phase_flash = max(0.0, phase_flash - delta * 2.5)
	screen_shake = max(0.0, screen_shake - delta * 16.0)
	_update_motion(delta)
	_update_effects(delta)
	if state == "playing" and resolving:
		resolve_timer -= delta
		if resolve_timer <= 0.0:
			_resolve_next_beat()
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
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_selection()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)
			return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == "help":
				state = "title"
			else:
				_cancel_selection()
			queue_redraw()
		elif event.keycode == KEY_F1:
			state = "help"
			queue_redraw()
		elif event.keycode == KEY_SPACE and state == "playing":
			if resolving:
				resolve_timer = 0.0
			else:
				_end_turn()
		elif event.keycode == KEY_M:
			muted = not muted
			_add_log("音: " + ("OFF" if muted else "ON"))
			queue_redraw()
		elif event.keycode == KEY_R and (state == "game_over" or state == "victory"):
			_start_run()


func _draw():
	button_rects.clear()
	card_rects.clear()
	reward_rects.clear()
	remove_rects.clear()

	if state == "title":
		_draw_title()
	elif state == "help":
		_draw_help()
	elif state == "playing":
		_draw_play()
	elif state == "reward":
		_draw_play()
		_draw_reward_overlay()
	elif state == "remove_card":
		_draw_play()
		_draw_remove_overlay()
	elif state == "game_over":
		_draw_end_screen(false)
	elif state == "victory":
		_draw_end_screen(true)


func _handle_click(pos):
	for id in button_rects.keys():
		if button_rects[id].has_point(pos):
			_activate_button(id)
			return

	if resolving:
		return

	if state == "playing":
		for i in range(card_rects.size()):
			if card_rects[i].has_point(pos):
				_select_or_play_card(i)
				return
		var cell = _cell_from_point(pos)
		if cell.x != -1:
			_try_use_selected_card(cell)
			return

	if state == "reward":
		for i in range(reward_rects.size()):
			if reward_rects[i].has_point(pos):
				_take_reward(i)
				return

	if state == "remove_card":
		for i in range(remove_rects.size()):
			if remove_rects[i].has_point(pos):
				_remove_deck_card(i)
				return


func _activate_button(id):
	match id:
		"start":
			_start_run()
		"help":
			state = "help"
		"title":
			state = "title"
		"quit":
			get_tree().quit()
		"end_turn":
			if resolving:
				resolve_timer = 0.0
			else:
				_end_turn()
		"restart":
			_start_run()
		"mute":
			muted = not muted
			_add_log("音: " + ("OFF" if muted else "ON"))
		"skip_reward":
			_apply_reward({"type": "heal", "amount": 3, "label": "庭園を整える"})
		"remove_skip":
			state = "reward"
		_:
			pass
	queue_redraw()


func _start_run():
	state = "playing"
	day = 1
	turn = 1
	score = 0
	kills = 0
	integrity = START_INTEGRITY
	selected_card = -1
	selected_remove = -1
	resolving = false
	resolve_timer = 0.0
	resolve_beats_left = 0
	command_count = 1
	run_saved = false
	deck = [
		"rootway", "rootway", "rootway",
		"spore", "spore", "spore",
		"snare", "snare",
		"thorn", "crystal",
		"nectar", "prune"
	]
	discard_pile.clear()
	draw_pile.clear()
	hand.clear()
	intruders.clear()
	log_lines.clear()
	floaters.clear()
	trails.clear()
	_make_board()
	_add_log("記憶庭園が目を覚ました。")
	_begin_day()
	_play_sound("start")


func _make_board():
	board.clear()
	for y in range(GRID_H):
		var row = []
		for x in range(GRID_W):
			row.append({"terrain": "soil", "feature": "", "level": 0, "pulse": 0})
		board.append(row)

	var path = [
		Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4),
		Vector2i(4, 5), Vector2i(4, 6), Vector2i(4, 7), CORE_POS,
		Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2),
		Vector2i(5, 2), Vector2i(6, 2), Vector2i(6, 1), Vector2i(6, 0),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3),
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(5, 4), Vector2i(6, 4),
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5),
		Vector2i(3, 6), Vector2i(5, 6),
		Vector2i(2, 7), Vector2i(3, 7), Vector2i(5, 7), Vector2i(6, 7)
	]
	var branches = [
		Vector2i(1, 6), Vector2i(2, 6), Vector2i(6, 6), Vector2i(7, 6),
		Vector2i(1, 7), Vector2i(7, 7)
	]
	for p in path + branches:
		board[p.y][p.x]["terrain"] = "path"
	for p in ENTRANCES:
		board[p.y][p.x]["terrain"] = "entrance"
	board[CORE_POS.y][CORE_POS.x]["terrain"] = "core"
	_set_feature(Vector2i(4, 5), "spore", 1)


func _begin_day():
	if day > MAX_DAY:
		_finish_run(true)
		return
	state = "playing"
	turn = 1
	command_count = 1
	resolving = false
	selected_card = -1
	hand.clear()
	discard_pile.clear()
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	spawn_queue = _make_wave(day)
	current_omen = _roll_omen(day)
	_add_log("第%d日: %s" % [day, current_omen.get("name", "静かな風")])
	_start_player_turn()


func _make_wave(wave_day):
	var wave = []
	match wave_day:
		1:
			wave = ["scout", "scout", "scout"]
		2:
			wave = ["scout", "miner", "scout", "scout"]
		3:
			wave = ["scout", "cartographer", "miner", "scout", "scout"]
		4:
			wave = ["miner", "scout", "cartographer", "miner", "carrier"]
		5:
			wave = ["cartographer", "miner", "miner", "carrier", "scout", "cartographer"]
		6:
			wave = ["miner", "carrier", "cartographer", "miner", "carrier", "scout", "cartographer"]
		_:
			wave = ["carrier", "miner", "cartographer", "carrier", "miner", "cartographer", "carrier"]
	wave.shuffle()
	return wave


func _roll_omen(wave_day):
	var omens = [
		{"name": "薄い朝霧", "text": "霧の足止め+1", "mist_bonus": 1},
		{"name": "乾いた根鳴り", "text": "胞子灯の射程-1、得点+10%", "spore_range": -1, "score_bonus": 0.1},
		{"name": "琥珀の露", "text": "開始樹液+1", "sap_bonus": 1},
		{"name": "静かな風", "text": "特別な変化なし"}
	]
	if wave_day == 1:
		return omens[3]
	return omens[rng.randi_range(0, omens.size() - 1)]


func _start_player_turn():
	var income = _garden_income()
	sap = 4 + int((day - 1) / 3) + income + int(current_omen.get("sap_bonus", 0))
	_draw_cards(4)
	if income > 0:
		_add_log("庭園の仕掛けから樹液+%d。" % income)
	queue_redraw()


func _garden_income():
	var income = 0
	for y in range(GRID_H):
		for x in range(GRID_W):
			var tile = board[y][x]
			if tile["feature"] == "spring":
				income += tile["level"]
			elif tile["feature"] == "crystal" and (turn + x + y) % 2 == 0:
				income += 1
	return income


func _draw_cards(count):
	for i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			draw_pile.shuffle()
			discard_pile.clear()
		hand.append(draw_pile.pop_back())


func _select_or_play_card(index):
	if index < 0 or index >= hand.size():
		return
	var card_id = hand[index]
	var card = CARD_DB[card_id]
	if sap < int(card["cost"]):
		_add_log("樹液が足りない。")
		_play_sound("deny")
		return
	if card["target"] == "none":
		_play_card(index, Vector2i(-1, -1))
	else:
		selected_card = index
		_play_sound("select")
	queue_redraw()


func _try_use_selected_card(cell):
	if selected_card < 0 or selected_card >= hand.size():
		return
	var card_id = hand[selected_card]
	if _is_valid_target(card_id, cell):
		_play_card(selected_card, cell)
	else:
		_add_log("その場所には使えない。")
		_play_sound("deny")


func _play_card(index, cell):
	if index < 0 or index >= hand.size():
		return
	var card_id = hand[index]
	var card = CARD_DB[card_id]
	var cost = int(card["cost"])
	if sap < cost:
		_add_log("樹液が足りない。")
		_play_sound("deny")
		return
	sap -= cost
	_apply_card_effect(card_id, cell)
	hand.remove_at(index)
	discard_pile.append(card_id)
	selected_card = -1
	_play_sound("play")
	queue_redraw()


func _apply_card_effect(card_id, cell):
	match card_id:
		"rootway":
			board[cell.y][cell.x]["terrain"] = "path"
			_add_log("根道を開いた。")
		"spore", "snare", "thorn", "crystal", "mist", "spring":
			var feature = CARD_DB[card_id]["feature"]
			_set_feature(cell, feature, 1)
			_add_log("%sを植えた。" % FEATURE_INFO[feature]["name"])
		"nectar":
			sap += 1
			_draw_cards(1)
			_add_log("蜜を集め、樹液+1。")
		"overgrowth":
			var tile = board[cell.y][cell.x]
			tile["level"] = min(3, int(tile["level"]) + 1)
			tile["pulse"] = 1.0
			_add_log("%sが群生した。Lv%d" % [FEATURE_INFO[tile["feature"]]["name"], tile["level"]])
		"prune":
			var tile = board[cell.y][cell.x]
			_add_log("%sを剪定し、樹液+2。" % FEATURE_INFO[tile["feature"]]["name"])
			tile["feature"] = ""
			tile["level"] = 0
			sap += 2
			_draw_cards(1)
		"pulse":
			var bonus = int(_feature_count() / 3)
			var damage = 2 + bonus
			for i in range(intruders.size()):
				_damage_intruder(i, damage, "年輪の脈動")
			_cleanup_intruders()
			_add_log("庭園全体が脈動した。")
		"lantern":
			_push_intruders_on(cell)
			_add_log("迷光が足取りを入口側へほどいた。")


func _set_feature(cell, feature, level):
	var tile = board[cell.y][cell.x]
	tile["feature"] = feature
	tile["level"] = level
	tile["pulse"] = 1.0


func _is_valid_target(card_id, cell):
	if not _in_bounds(cell):
		return false
	var card = CARD_DB[card_id]
	var target = card["target"]
	var tile = board[cell.y][cell.x]
	match target:
		"none":
			return true
		"soil":
			return tile["terrain"] == "soil"
		"path":
			return _is_passable_tile(tile)
		"empty_path":
			return _is_passable_tile(tile) and tile["feature"] == "" and tile["terrain"] != "core" and tile["terrain"] != "entrance"
		"feature":
			return tile["feature"] != ""
		_:
			return false


func _end_turn():
	if state != "playing" or resolving:
		return
	if hand.size() > 0:
		discard_pile.append_array(hand)
		hand.clear()
	selected_card = -1
	resolving = true
	resolve_beats_left = 2 + int(day >= 3) + int(day >= 6)
	resolve_timer = 0.04
	phase_flash = 0.9
	_add_log("迎撃フェーズ開始。%d拍で侵攻を処理。" % resolve_beats_left)
	_play_sound("start")


func _resolve_next_beat():
	if state != "playing" or not resolving:
		return
	_battle_beat()
	resolve_beats_left -= 1

	if integrity <= 0:
		resolving = false
		_finish_run(false)
		return

	if spawn_queue.is_empty() and intruders.is_empty():
		resolving = false
		_enter_reward()
		return

	if resolve_beats_left <= 0:
		resolving = false
		command_count += 1
		turn += 1
		_start_player_turn()
		return

	resolve_timer = 0.24


func _battle_beat():
	phase_flash = 0.55
	_feature_phase()
	_spawn_from_queue()
	_advance_intruders()
	_cleanup_intruders()


func _feature_phase():
	var acted = 0
	for y in range(GRID_H):
		for x in range(GRID_W):
			var tile = board[y][x]
			var feature = tile["feature"]
			if feature == "":
				continue
			var level = int(tile["level"])
			var p = Vector2i(x, y)
			match feature:
				"spore":
					var radius = max(1, 2 + level - 1 + int(current_omen.get("spore_range", 0)))
					var idx = _nearest_intruder(p, radius)
					if idx != -1:
						_damage_intruder(idx, 1 + level, "胞子灯")
						acted += 1
				"snare":
					for i in range(intruders.size()):
						if _grid_distance(p, _intruder_pos(i)) <= 1:
							intruders[i]["slow"] = max(int(intruders[i]["slow"]), level)
							_damage_intruder(i, 1, "絡み根")
							acted += 1
							break
				"thorn":
					var idx_on = _intruder_at(p)
					if idx_on != -1:
						_damage_intruder(idx_on, 2 + level, "トゲ芽")
						acted += 1
				"crystal":
					var idx_line = _nearest_intruder_in_line(p, 4 + level)
					if idx_line != -1:
						_damage_intruder(idx_line, 2, "記憶水晶")
						acted += 1
				"mist":
					var mist_bonus = int(current_omen.get("mist_bonus", 0))
					for i in range(intruders.size()):
						if _grid_distance(p, _intruder_pos(i)) <= 1 + level:
							intruders[i]["slow"] = max(int(intruders[i]["slow"]), 1 + mist_bonus)
							acted += 1
	if acted > 0:
		_add_log("庭園の仕掛けが%d回反応。" % acted)
		_play_sound("hit")
	_cleanup_intruders()


func _spawn_from_queue():
	if spawn_queue.is_empty():
		return
	var spawn_count = 1
	if day >= 4 and turn % 3 == 0 and spawn_queue.size() >= 2:
		spawn_count = 2
	for i in range(spawn_count):
		if spawn_queue.is_empty():
			break
		var kind = spawn_queue[0]
		spawn_queue.remove_at(0)
		var data = INTRUDER_DB[kind]
		var spawn = _choose_spawn_point(kind)
		var offset = _spawn_offset()
		var intruder = {
			"kind": kind,
			"name": data["name"],
			"x": spawn.x,
			"y": spawn.y,
			"prev_x": spawn.x,
			"prev_y": spawn.y,
			"move_t": 0.0,
			"hp": data["hp"],
			"max_hp": data["hp"],
			"slow": 0,
			"moved": 0,
			"offset": offset,
			"logic": data.get("logic", "direct"),
			"visited": [_cell_key(spawn)],
			"bias": rng.randf_range(-0.75, 0.75)
		}
		intruders.append(intruder)
		_add_log("%sが上層入口から降りてきた。" % data["name"])
		_add_floater(_cell_center(spawn), "IN", data["color"], Vector2(0, -36))
	_play_sound("spawn")


func _choose_spawn_point(kind):
	if day <= 1:
		return ENTRANCES[1]
	if kind == "miner":
		return ENTRANCES[0 if rng.randf() < 0.5 else 2]
	if kind == "carrier":
		return ENTRANCES[1]
	return ENTRANCES[(turn + spawn_queue.size() + rng.randi_range(0, 2)) % ENTRANCES.size()]


func _spawn_offset():
	var offsets = [Vector2(-8, -8), Vector2(8, -7), Vector2(-7, 8), Vector2(7, 7), Vector2.ZERO]
	return offsets[intruders.size() % offsets.size()]


func _advance_intruders():
	for i in range(intruders.size() - 1, -1, -1):
		if i >= intruders.size():
			continue
		var unit = intruders[i]
		if int(unit["slow"]) > 0:
			unit["slow"] = int(unit["slow"]) - 1
			continue
		var steps = 1
		if INTRUDER_DB[unit["kind"]].get("haste", false) and turn % 2 == 0:
			steps = 2
		for step_i in range(steps):
			if i >= intruders.size():
				break
			var current = Vector2i(unit["x"], unit["y"])
			var next = _next_step_for(unit)
			if next.x == -1:
				break
			unit["prev_x"] = current.x
			unit["prev_y"] = current.y
			unit["x"] = next.x
			unit["y"] = next.y
			unit["move_t"] = 1.0
			unit["moved"] = int(unit["moved"]) + 1
			var visited = unit.get("visited", [])
			visited.append(_cell_key(next))
			if visited.size() > 16:
				visited.remove_at(0)
			unit["visited"] = visited
			trails.append({"from": _cell_center(current), "to": _cell_center(next), "life": 0.42, "color": INTRUDER_DB[unit["kind"]]["color"]})
			_apply_entry_effect(i)
			if i >= intruders.size():
				break
			if int(unit["hp"]) <= 0:
				break
			if Vector2i(unit["x"], unit["y"]) == CORE_POS:
				var data = INTRUDER_DB[unit["kind"]]
				var damage = int(data["core"]) + max(0, int(unit["hp"]) - 2)
				integrity -= damage
				_add_log("%sが最深部に到達した。-%d" % [unit["name"], damage])
				_add_floater(_cell_center(CORE_POS), "-%d" % damage, C_WARN, Vector2(0, -42))
				intruders.remove_at(i)
				_play_sound("core")
				break


func _apply_entry_effect(index):
	if index < 0 or index >= intruders.size():
		return
	var unit = intruders[index]
	var p = Vector2i(unit["x"], unit["y"])
	var tile = board[p.y][p.x]
	var feature = tile["feature"]
	var level = int(tile["level"])
	match feature:
		"thorn":
			_damage_intruder(index, 2 + level, "トゲ芽")
		"snare":
			unit["slow"] = max(int(unit["slow"]), 1 + level)
			_damage_intruder(index, 1, "絡み根")
		"mist":
			unit["slow"] = max(int(unit["slow"]), 1)
		"spore":
			_damage_intruder(index, 1, "胞子灯")


func _damage_intruder(index, amount, source):
	if index < 0 or index >= intruders.size():
		return
	var unit = intruders[index]
	var armor = int(INTRUDER_DB[unit["kind"]].get("armor", 0))
	var final_damage = max(1, amount - armor)
	unit["hp"] = int(unit["hp"]) - final_damage
	unit["hit_flash"] = 0.35
	screen_shake = max(screen_shake, 2.0 + float(final_damage) * 0.35)
	_add_floater(_cell_center(_intruder_pos(index)), str(final_damage), C_WARN if final_damage >= 3 else C_GOLD, Vector2(rng.randf_range(-10, 10), -34))


func _cleanup_intruders():
	for i in range(intruders.size() - 1, -1, -1):
		if int(intruders[i]["hp"]) <= 0:
			var unit = intruders[i]
			var points = int(INTRUDER_DB[unit["kind"]]["score"])
			var bonus = float(current_omen.get("score_bonus", 0.0))
			points += int(points * bonus)
			score += points
			kills += 1
			_add_log("%sを眠らせた。+%d" % [unit["name"], points])
			_add_floater(_cell_center(Vector2i(unit["x"], unit["y"])), "+%d" % points, Color(0.72, 1.0, 0.62), Vector2(0, -44))
			intruders.remove_at(i)
			_play_sound("down")


func _next_step_for(unit):
	var start = Vector2i(unit["x"], unit["y"])
	if start == CORE_POS:
		return CORE_POS
	var candidates = []
	for n in _neighbors(start):
		if _is_passable(n):
			candidates.append(n)
	if candidates.is_empty():
		return Vector2i(-1, -1)

	var logic = str(unit.get("logic", "direct"))
	var visited = unit.get("visited", [])
	var best = Vector2i(-1, -1)
	var best_score = 99999.0
	for n in candidates:
		var dist = _distance_to_core(n)
		if dist >= 999:
			continue
		var hazard = _tile_hazard(n)
		var visited_penalty = 0.0
		if visited.has(_cell_key(n)):
			visited_penalty = 2.0
		var score_value = float(dist)
		match logic:
			"direct":
				score_value = float(dist) + hazard * 0.35 + visited_penalty * 0.2
			"edge":
				var edge_pull = min(abs(n.x - 1), abs(n.x - (GRID_W - 2)))
				score_value = float(dist) + float(edge_pull) * 0.38 - float(n.y - start.y) * 0.45 + visited_penalty * 0.35
			"curious":
				var branch_bonus = float(_passable_neighbor_count(n) - 2) * 1.15
				var new_bonus = 1.9 if not visited.has(_cell_key(n)) else -0.6
				score_value = float(dist) * 0.78 - branch_bonus - new_bonus + rng.randf_range(0.0, 1.35)
			"cautious":
				var crowd = float(_intruders_near(n, 1))
				score_value = float(dist) + hazard * 2.6 + crowd * 1.1 + visited_penalty * 0.3
			_:
				score_value = float(dist)
		score_value += float(unit.get("bias", 0.0)) * float(n.x - CORE_POS.x) * 0.08
		if score_value < best_score:
			best_score = score_value
			best = n
	if best.x == -1:
		return _fallback_step(start)
	return best


func _fallback_step(start):
	var best = Vector2i(-1, -1)
	var best_dist = 999
	for n in _neighbors(start):
		if not _is_passable(n):
			continue
		var d = _grid_distance(n, CORE_POS)
		if d < best_dist:
			best_dist = d
			best = n
	return best


func _distance_to_core(start):
	if start == CORE_POS:
		return 0
	var queue = [start]
	var dist = {}
	dist[start] = 0
	while not queue.is_empty():
		var current = queue[0]
		queue.remove_at(0)
		for n in _neighbors(current):
			if not _is_passable(n) or dist.has(n):
				continue
			dist[n] = int(dist[current]) + 1
			if n == CORE_POS:
				return int(dist[n])
			queue.append(n)
	return 999


func _tile_hazard(p):
	if not _in_bounds(p):
		return 0.0
	var tile = board[p.y][p.x]
	var feature = tile["feature"]
	if feature == "":
		return 0.0
	var level = float(tile["level"])
	match feature:
		"thorn":
			return 3.2 + level
		"snare":
			return 2.1 + level
		"spore":
			return 1.5 + level * 0.6
		"crystal":
			return 1.2 + level * 0.4
		"mist":
			return 1.8 + level * 0.8
		_:
			return 0.4


func _passable_neighbor_count(p):
	var count = 0
	for n in _neighbors(p):
		if _is_passable(n):
			count += 1
	return count


func _intruders_near(p, radius):
	var count = 0
	for i in range(intruders.size()):
		if _grid_distance(p, _intruder_pos(i)) <= radius:
			count += 1
	return count


func _neighbors(p):
	return [
		Vector2i(p.x + 1, p.y),
		Vector2i(p.x - 1, p.y),
		Vector2i(p.x, p.y + 1),
		Vector2i(p.x, p.y - 1)
	]


func _is_passable(p):
	if not _in_bounds(p):
		return false
	return _is_passable_tile(board[p.y][p.x])


func _is_passable_tile(tile):
	return tile["terrain"] == "path" or tile["terrain"] == "entrance" or tile["terrain"] == "core"


func _in_bounds(p):
	return p.x >= 0 and p.y >= 0 and p.x < GRID_W and p.y < GRID_H


func _intruder_pos(index):
	return Vector2i(intruders[index]["x"], intruders[index]["y"])


func _intruder_at(p):
	for i in range(intruders.size()):
		if _intruder_pos(i) == p:
			return i
	return -1


func _nearest_intruder(p, radius):
	var best = -1
	var best_dist = 999
	for i in range(intruders.size()):
		var d = _grid_distance(p, _intruder_pos(i))
		if d <= radius and d < best_dist:
			best_dist = d
			best = i
	return best


func _nearest_intruder_in_line(p, radius):
	var best = -1
	var best_dist = 999
	for i in range(intruders.size()):
		var q = _intruder_pos(i)
		if q.x != p.x and q.y != p.y:
			continue
		var d = _grid_distance(p, q)
		if d <= radius and d < best_dist:
			best_dist = d
			best = i
	return best


func _grid_distance(a, b):
	return abs(a.x - b.x) + abs(a.y - b.y)


func _cell_key(p):
	return "%d,%d" % [p.x, p.y]


func _cell_center(p):
	return board_origin + Vector2((float(p.x) + 0.5) * cell_size, (float(p.y) + 0.5) * cell_size)


func _update_motion(delta):
	for unit in intruders:
		unit["move_t"] = max(0.0, float(unit.get("move_t", 0.0)) - delta / 0.22)


func _update_effects(delta):
	for i in range(floaters.size() - 1, -1, -1):
		var fx = floaters[i]
		fx["life"] = float(fx["life"]) - delta
		fx["pos"] = fx["pos"] + fx["vel"] * delta
		if float(fx["life"]) <= 0.0:
			floaters.remove_at(i)
	for i in range(trails.size() - 1, -1, -1):
		trails[i]["life"] = float(trails[i]["life"]) - delta
		if float(trails[i]["life"]) <= 0.0:
			trails.remove_at(i)


func _add_floater(pos, text, color, velocity = Vector2(0, -30)):
	floaters.append({"pos": pos, "text": text, "color": color, "vel": velocity, "life": 0.72})


func _push_intruders_on(cell):
	for i in range(intruders.size()):
		var p = _intruder_pos(i)
		if p == cell:
			var previous = _step_toward_entrance(p)
			if previous.x != -1:
				intruders[i]["x"] = previous.x
				intruders[i]["y"] = previous.y
				intruders[i]["slow"] = max(int(intruders[i]["slow"]), 1)


func _step_toward_entrance(start):
	var best = Vector2i(-1, -1)
	var best_dist = 999
	for n in _neighbors(start):
		if not _is_passable(n):
			continue
		var d = _distance_to_nearest_entrance(n)
		if d < best_dist:
			best_dist = d
			best = n
	return best


func _distance_to_nearest_entrance(p):
	var best = 999
	for entrance in ENTRANCES:
		best = min(best, _grid_distance(p, entrance))
	return best


func _feature_count():
	var count = 0
	for y in range(GRID_H):
		for x in range(GRID_W):
			if board[y][x]["feature"] != "":
				count += 1
	return count


func _enter_reward():
	score += 18 + day * 7 + int(integrity / 4)
	_add_log("第%d日を守り切った。" % day)
	_play_sound("reward")
	if day >= MAX_DAY:
		_finish_run(true)
		return
	state = "reward"
	reward_choices = _make_rewards()


func _make_rewards():
	var pool = ["spore", "snare", "thorn", "nectar", "rootway", "crystal", "mist", "spring", "overgrowth", "prune", "pulse", "lantern"]
	pool.shuffle()
	var choices = []
	for i in range(3):
		choices.append({"type": "card", "id": pool[i]})
	if rng.randf() < 0.35:
		choices[rng.randi_range(0, 2)] = {"type": "heal", "amount": 7, "label": "樹皮を癒やす"}
	if rng.randf() < 0.25 and deck.size() > 8:
		choices[rng.randi_range(0, 2)] = {"type": "remove", "label": "古い札を堆肥へ"}
	return choices


func _take_reward(index):
	if index < 0 or index >= reward_choices.size():
		return
	_apply_reward(reward_choices[index])


func _apply_reward(choice):
	match choice["type"]:
		"card":
			deck.append(choice["id"])
			_add_log("%sをデッキに加えた。" % CARD_DB[choice["id"]]["name"])
			day += 1
			_begin_day()
		"heal":
			integrity = min(START_INTEGRITY, integrity + int(choice["amount"]))
			_add_log("記憶核を%d回復。" % int(choice["amount"]))
			day += 1
			_begin_day()
		"remove":
			state = "remove_card"
			selected_remove = -1
	_play_sound("play")
	queue_redraw()


func _remove_deck_card(index):
	if index < 0 or index >= deck.size():
		return
	var card_id = deck[index]
	deck.remove_at(index)
	_add_log("%sを堆肥にした。" % CARD_DB[card_id]["name"])
	day += 1
	_begin_day()


func _finish_run(won):
	if run_saved:
		return
	run_saved = true
	if won:
		score += 120 + integrity * 3 + kills * 2
		state = "victory"
		_play_sound("victory")
	else:
		state = "game_over"
		_play_sound("core")
	meta["runs"] = int(meta.get("runs", 0)) + 1
	if won:
		meta["wins"] = int(meta.get("wins", 0)) + 1
	meta["best_score"] = max(int(meta.get("best_score", 0)), score)
	_save_meta()
	queue_redraw()


func _cancel_selection():
	selected_card = -1
	selected_remove = -1
	queue_redraw()


func _cell_from_point(pos):
	var local = pos - board_origin
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	var x = int(floor(local.x / cell_size))
	var y = int(floor(local.y / cell_size))
	var p = Vector2i(x, y)
	if not _in_bounds(p):
		return Vector2i(-1, -1)
	return p


func _update_layout():
	var view = get_viewport_rect().size
	var side_width = clamp(view.x * 0.28, 285.0, 360.0)
	var bottom_space = 158.0 if view.y >= 650.0 else 122.0
	cell_size = clamp(min((view.x - side_width - 96.0) / GRID_W, (view.y - bottom_space - 86.0) / GRID_H), 34.0, 56.0)
	board_origin = Vector2(42.0, 74.0)


func _draw_title():
	var view = get_viewport_rect().size
	_draw_cover(title_art, Rect2(Vector2.ZERO, view), Color(1, 1, 1, 0.86))
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.04, 0.035, 0.45), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(view.x * 0.48, view.y)), Color(0.02, 0.045, 0.04, 0.45), true)

	var title_pos = Vector2(54, 92)
	_draw_text("記憶庭園の番人", title_pos, 48, Color(0.97, 0.92, 0.70))
	_draw_text("逆ローグライク・デッキ構築", title_pos + Vector2(4, 54), 21, Color(0.70, 0.95, 0.78))
	_draw_text("根道を伸ばし、胞子と結晶を植え、記憶を採掘する調査隊を眠らせる。", title_pos + Vector2(4, 94), 18, C_TEXT)
	_draw_text("魔王でも勇者でもない、眠る巨大樹の防衛戦。", title_pos + Vector2(4, 122), 18, C_DIM)

	var bx = 58
	var by = 280
	_draw_button("start", Rect2(bx, by, 230, 52), "はじめる", true)
	_draw_button("help", Rect2(bx, by + 66, 230, 46), "遊び方", false)
	_draw_button("quit", Rect2(bx, by + 124, 230, 46), "終了", false)

	_draw_text("Best Score  %d" % int(meta.get("best_score", 0)), Vector2(58, view.y - 88), 18, C_TEXT)
	_draw_text("Runs %d   Wins %d" % [int(meta.get("runs", 0)), int(meta.get("wins", 0))], Vector2(58, view.y - 58), 16, C_DIM)


func _draw_help():
	var view = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.035, 0.055, 0.045), true)
	_draw_text("遊び方", Vector2(58, 76), 42, Color(0.97, 0.92, 0.70))
	var y = 142
	var lines = [
		"あなたは、眠る巨大樹の記憶庭園を守る番人です。",
		"調査隊は上層入口から降り、最深部の記憶核を目指します。",
		"カードをクリックして選び、盤面の土や通路をクリックして使います。",
		"土には「根道を開く」。通路には胞子灯、絡み根、トゲ芽、記憶水晶などを配置できます。",
		"迎撃開始後、複数拍がテンポよく進み、仕掛けと調査隊が連続で動きます。",
		"調査隊には直進、外周、未探索、罠回避の探索ロジックがあります。",
		"1日を守り切ると報酬カードを1枚選び、デッキを育てます。",
		"7日目を守り切れば勝利。Spaceで迎撃開始/早送り、右クリック/Escで選択解除、Mでミュートです。"
	]
	for line in lines:
		_draw_text(line, Vector2(70, y), 21, C_TEXT)
		y += 40
	_draw_button("title", Rect2(64, view.y - 92, 190, 48), "タイトルへ", true)
	if state != "title":
		_draw_button("start", Rect2(270, view.y - 92, 190, 48), "新しく始める", false)


func _draw_play():
	_update_layout()
	var view = get_viewport_rect().size
	_draw_cover(title_art, Rect2(Vector2.ZERO, view), Color(1, 1, 1, 0.22))
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.015, 0.026, 0.022, 0.78), true)
	_draw_soft_background(view)
	_draw_top_bar(view)
	_draw_board()
	_draw_side_panel(view)
	_draw_hand(view)
	_draw_effects()
	if phase_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.95, 0.70, 0.22, 0.06 * phase_flash), true)
	_draw_hover_tooltip()


func _draw_soft_background(view):
	for i in range(11):
		var x = fmod(anim_time * (12 + i * 3) + i * 151.0, view.x + 160.0) - 80.0
		var y = 58.0 + fmod(i * 67.0, view.y - 90.0)
		draw_circle(Vector2(x, y), 1.7 + (i % 3), Color(0.94, 0.68, 0.25, 0.14))
	for i in range(7):
		var y2 = 96.0 + i * 74.0
		draw_line(Vector2(0, y2), Vector2(view.x, y2 + sin(anim_time + i) * 24.0), Color(0.24, 0.42, 0.28, 0.10), 2.0)
	draw_rect(Rect2(0, 0, view.x, 62), Color(0.02, 0.032, 0.028, 0.92), true)
	draw_rect(Rect2(0, view.y - 154, view.x, 154), Color(0.018, 0.026, 0.022, 0.86), true)


func _draw_top_bar(view):
	_draw_text("記憶庭園の番人", Vector2(30, 40), 23, Color(0.98, 0.88, 0.61))
	_draw_status_pill(Vector2(262, 15), "DAY %d/%d" % [day, MAX_DAY], Color(0.18, 0.38, 0.24))
	_draw_status_pill(Vector2(378, 15), "BEAT %d" % turn, Color(0.18, 0.32, 0.36))
	_draw_status_pill(Vector2(490, 15), "樹液 %d" % sap, Color(0.40, 0.30, 0.12))
	_draw_status_pill(Vector2(600, 15), "最深部 %d" % integrity, Color(0.42, 0.18, 0.15) if integrity < 12 else Color(0.22, 0.34, 0.20))
	_draw_status_pill(Vector2(730, 15), "SCORE %d" % score, Color(0.20, 0.22, 0.30))
	_draw_button("help", Rect2(view.x - 270, 12, 76, 36), "F1", false)
	_draw_button("mute", Rect2(view.x - 186, 12, 80, 36), "音 " + ("OFF" if muted else "ON"), false)
	_draw_button("title", Rect2(view.x - 98, 12, 80, 36), "戻る", false)


func _draw_status_pill(pos, label, color):
	var rect = Rect2(pos, Vector2(104, 32))
	draw_rect(rect, Color(0, 0, 0, 0.34), true)
	draw_rect(rect.grow(-1), color, true)
	draw_line(rect.position + Vector2(8, rect.size.y - 5), rect.end - Vector2(8, 5), Color(0.96, 0.76, 0.30, 0.52), 1.0)
	_draw_text(label, pos + Vector2(10, 22), 15, C_TEXT)


func _draw_board():
	var board_rect = Rect2(board_origin, Vector2(cell_size * GRID_W, cell_size * GRID_H))
	draw_rect(board_rect.grow(18), Color(0.01, 0.017, 0.014, 0.68), true)
	draw_rect(board_rect.grow(11), Color(0.18, 0.115, 0.055, 0.82), true)
	draw_rect(board_rect.grow(7), Color(0.035, 0.065, 0.046, 0.94), true)
	for i in range(5):
		var y = board_rect.position.y + 14.0 + i * (board_rect.size.y - 28.0) / 4.0
		draw_line(Vector2(board_rect.position.x - 12, y), Vector2(board_rect.end.x + 12, y + sin(anim_time + i) * 4.0), Color(0.76, 0.55, 0.24, 0.18), 1.5)

	for y in range(GRID_H):
		for x in range(GRID_W):
			var p = Vector2i(x, y)
			var rect = Rect2(board_origin + Vector2(x * cell_size, y * cell_size), Vector2(cell_size - 2, cell_size - 2))
			_draw_tile(rect, p)

	_draw_trails()
	_draw_intruders()
	draw_rect(board_rect, Color(0.77, 0.63, 0.30, 0.45), false, 2.0)
	_draw_text("上層入口", board_rect.position + Vector2(4, -14), 15, Color(0.80, 1.0, 0.66))
	_draw_text("最深部", board_rect.position + Vector2(board_rect.size.x - 58, board_rect.size.y + 20), 15, Color(1.0, 0.78, 0.30))


func _draw_tile(rect, p):
	var tile = board[p.y][p.x]
	var terrain = tile["terrain"]
	var color = C_SOIL
	if terrain == "path":
		color = C_PATH if (p.x + p.y) % 2 == 0 else C_PATH_ALT
	elif terrain == "entrance":
		color = Color(0.24, 0.40, 0.23)
	elif terrain == "core":
		color = Color(0.42, 0.31, 0.11)
	draw_rect(rect, color, true)

	if terrain == "soil":
		var fleck = Color(0.33, 0.24, 0.13, 0.55)
		draw_line(rect.position + Vector2(8, 18), rect.position + Vector2(rect.size.x - 12, 10), fleck, 1.0)
		draw_line(rect.position + Vector2(12, rect.size.y - 12), rect.position + Vector2(rect.size.x - 10, rect.size.y - 22), fleck, 1.0)
	else:
		draw_line(rect.position + Vector2(0, rect.size.y - 1), rect.position + Vector2(rect.size.x, rect.size.y - 1), Color(0.02, 0.03, 0.025, 0.35), 1.0)

	if selected_card >= 0 and selected_card < hand.size():
		var card_id = hand[selected_card]
		if _is_valid_target(card_id, p):
			draw_rect(rect.grow(-3), Color(0.98, 0.82, 0.31, 0.18), true)
			draw_rect(rect.grow(-3), Color(1.0, 0.78, 0.25, 0.82), false, 2.0)

	if terrain == "entrance":
		draw_circle(rect.get_center(), cell_size * 0.24, Color(0.52, 0.90, 0.42, 0.30 + sin(anim_time * 4.0 + p.x) * 0.08))
		_draw_text("門", rect.position + Vector2(cell_size * 0.34, cell_size * 0.62), 16, Color(0.80, 1.0, 0.66))
	if terrain == "core":
		draw_circle(rect.get_center(), cell_size * (0.26 + sin(anim_time * 5.0) * 0.02), Color(1.0, 0.74, 0.22, 0.88))
		draw_circle(rect.get_center(), cell_size * 0.12, Color(0.30, 0.95, 0.80, 0.95))
		_draw_text("核", rect.position + Vector2(cell_size * 0.38, cell_size * 0.66), 17, Color(0.07, 0.08, 0.06))

	if tile["feature"] != "":
		_draw_feature(rect, tile)


func _draw_feature(rect, tile):
	var feature = tile["feature"]
	var info = FEATURE_INFO[feature]
	var level = int(tile["level"])
	var pulse = float(tile.get("pulse", 0.0))
	tile["pulse"] = max(0.0, pulse - 0.035)
	var center = rect.get_center()
	var radius = cell_size * (0.21 + pulse * 0.04)
	draw_circle(center, radius + 4.0, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, info["color"])
	draw_circle(center, radius * 0.55, Color(1, 1, 1, 0.18))
	_draw_text(info["short"], center + Vector2(-12, 8), 18, Color(0.04, 0.06, 0.04))
	if level > 1:
		_draw_text("Lv%d" % level, rect.position + Vector2(5, rect.size.y - 7), 13, Color(0.98, 0.90, 0.58))


func _draw_trails():
	for trail in trails:
		var alpha = clamp(float(trail["life"]) / 0.42, 0.0, 1.0)
		var color = trail["color"]
		color.a = 0.34 * alpha
		draw_line(trail["from"], trail["to"], color, 4.0)


func _draw_intruders():
	var stacked = {}
	for i in range(intruders.size()):
		var unit = intruders[i]
		var p = Vector2i(unit["x"], unit["y"])
		var key = "%d,%d" % [p.x, p.y]
		stacked[key] = int(stacked.get(key, 0)) + 1
		var index_on_tile = int(stacked[key]) - 1
		var prev = Vector2(float(unit.get("prev_x", unit["x"])), float(unit.get("prev_y", unit["y"])))
		var current = Vector2(float(unit["x"]), float(unit["y"]))
		var move_t = float(unit.get("move_t", 0.0))
		var interp = prev.lerp(current, 1.0 - move_t)
		var base = board_origin + Vector2((interp.x + 0.5) * cell_size, (interp.y + 0.5) * cell_size)
		var offset = unit.get("offset", Vector2.ZERO) + Vector2((index_on_tile % 2) * 8, int(index_on_tile / 2) * 8)
		var pos = base + offset
		var data = INTRUDER_DB[unit["kind"]]
		var flash = float(unit.get("hit_flash", 0.0))
		unit["hit_flash"] = max(0.0, flash - 0.04)
		var color = data["color"].lerp(Color(1, 1, 1), min(1.0, flash * 2.8))
		draw_circle(pos + Vector2(2, 3), cell_size * 0.20, Color(0, 0, 0, 0.36))
		draw_circle(pos, cell_size * 0.19, color)
		draw_circle(pos + Vector2(-4, -4), cell_size * 0.06, Color(1, 1, 1, 0.35))
		_draw_text(_logic_mark(str(unit.get("logic", "direct"))), pos + Vector2(-7, 6), 12, Color(0.06, 0.05, 0.04))
		var hp_ratio = clamp(float(unit["hp"]) / float(unit["max_hp"]), 0.0, 1.0)
		var bar = Rect2(pos + Vector2(-20, 20), Vector2(40, 5))
		draw_rect(bar, Color(0.13, 0.05, 0.04), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), Color(0.78, 0.18, 0.14), true)
		if int(unit["slow"]) > 0:
			_draw_text("z", pos + Vector2(14, -12), 17, Color(0.66, 0.88, 1.0))


func _logic_mark(logic):
	match logic:
		"direct":
			return "直"
		"edge":
			return "端"
		"curious":
			return "探"
		"cautious":
			return "避"
		_:
			return "?"


func _draw_effects():
	for fx in floaters:
		var alpha = clamp(float(fx["life"]) / 0.72, 0.0, 1.0)
		var color = fx["color"]
		color.a = alpha
		_draw_text(str(fx["text"]), fx["pos"], 18, color)


func _draw_side_panel(view):
	var x = board_origin.x + cell_size * GRID_W + 24
	var rect = Rect2(x, 84, view.x - x - 28, view.y - 214)
	draw_rect(rect.grow(5), Color(0, 0, 0, 0.26), true)
	draw_rect(rect, Color(0.035, 0.056, 0.046, 0.90), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color(0.94, 0.70, 0.26, 0.72), true)
	draw_rect(rect, Color(0.43, 0.62, 0.38, 0.34), false, 1.5)
	_draw_text("降下予測", rect.position + Vector2(18, 34), 24, Color(0.96, 0.88, 0.63))
	_draw_text(current_omen.get("name", "静かな風"), rect.position + Vector2(18, 66), 18, Color(0.70, 0.95, 0.78))
	_draw_text(current_omen.get("text", "特別な変化なし"), rect.position + Vector2(18, 91), 15, C_DIM)

	_draw_text("残り %d   盤上 %d   拍 %d" % [spawn_queue.size(), intruders.size(), resolve_beats_left], rect.position + Vector2(18, 126), 17, C_TEXT)
	_draw_text("デッキ %d / 山札 %d / 捨札 %d" % [deck.size(), draw_pile.size(), discard_pile.size()], rect.position + Vector2(18, 151), 15, C_DIM)
	var progress = 1.0 - clamp(float(integrity) / float(START_INTEGRITY), 0.0, 1.0)
	var alarm_rect = Rect2(rect.position + Vector2(18, 166), Vector2(rect.size.x - 36, 7))
	draw_rect(alarm_rect, Color(0.12, 0.06, 0.04, 0.72), true)
	draw_rect(Rect2(alarm_rect.position, Vector2(alarm_rect.size.x * progress, alarm_rect.size.y)), Color(0.95, 0.32, 0.22, 0.82), true)

	var y = rect.position.y + 194
	_draw_text("探索ロジック", Vector2(x + 18, y), 17, Color(0.96, 0.88, 0.63))
	y += 25
	var logic_lines = ["直  最短寄り", "端  外周寄り", "探  未探索優先", "避  罠回避"]
	for i in range(logic_lines.size()):
		var col = i % 2
		var row = int(i / 2)
		_draw_text(logic_lines[i], Vector2(x + 22 + col * 118, y + row * 20), 14, C_DIM)

	y += 54
	_draw_text("仕掛け", Vector2(x + 18, y), 17, Color(0.96, 0.88, 0.63))
	y += 25
	var features = FEATURE_INFO.keys()
	for i in range(features.size()):
		var feature = features[i]
		var col = i % 2
		var row = int(i / 2)
		var info = FEATURE_INFO[feature]
		var px = x + 28 + col * 118
		var py = y + row * 20
		draw_circle(Vector2(px, py - 6), 8, info["color"])
		_draw_text("%s %s" % [info["short"], info["name"]], Vector2(px + 15, py), 13, C_TEXT)

	y = rect.end.y - 142
	_draw_text("ログ", Vector2(x + 18, y), 17, Color(0.96, 0.88, 0.63))
	y += 23
	var start = max(0, log_lines.size() - 4)
	for i in range(start, log_lines.size()):
		_draw_text(log_lines[i], Vector2(x + 18, y), 14, C_DIM)
		y += 18

	var button_label = "迎撃中... Spaceで早送り" if resolving else "迎撃開始  Space"
	_draw_button("end_turn", Rect2(rect.position.x + 18, rect.end.y - 58, rect.size.x - 36, 44), button_label, true)


func _draw_hand(view):
	var tray_y = view.y - (150.0 if view.y >= 650.0 else 118.0) - 24.0
	draw_line(Vector2(38, tray_y - 10), Vector2(view.x - 38, tray_y - 10), Color(0.86, 0.65, 0.28, 0.35), 1.5)
	_draw_text("種子札", Vector2(44, tray_y - 18), 16, Color(0.96, 0.82, 0.46))
	if resolving:
		_draw_text("迎撃中。Spaceまたはボタンで早送り。", Vector2(128, tray_y - 18), 15, C_DIM)
	var n = max(1, hand.size())
	var gap = 10.0
	var card_h = 150.0 if view.y >= 650.0 else 112.0
	var card_w = min(164.0, (view.x - 84.0 - gap * (n - 1)) / n)
	var start_x = 42.0
	var y = view.y - card_h - 20.0
	for i in range(hand.size()):
		var rect = Rect2(start_x + i * (card_w + gap), y, card_w, card_h)
		card_rects.append(rect)
		_draw_card(rect, hand[i], i == selected_card)


func _draw_card(rect, card_id, selected):
	var card = CARD_DB[card_id]
	var can_pay = sap >= int(card["cost"])
	var rarity = card.get("rarity", "common")
	var base = Color(0.18, 0.25, 0.18)
	if rarity == "uncommon":
		base = Color(0.15, 0.24, 0.28)
	elif rarity == "rare":
		base = Color(0.28, 0.20, 0.32)
	elif rarity == "basic":
		base = Color(0.18, 0.19, 0.15)
	if not can_pay:
		base = base.darkened(0.35)
	draw_rect(rect.grow(3), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, base, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color(0.90, 0.70, 0.30, 0.55), true)
	draw_rect(rect, Color(1.0, 0.80, 0.28, 0.95) if selected else Color(0.56, 0.68, 0.48, 0.5), false, 2.0 if selected else 1.0)
	draw_circle(rect.position + Vector2(24, 27), 15, C_GOLD if can_pay else Color(0.32, 0.27, 0.20))
	draw_circle(rect.position + Vector2(rect.size.x - 22, rect.size.y - 23), 18, Color(0.05, 0.08, 0.06, 0.38))
	_draw_text(str(card["cost"]), rect.position + Vector2(18, 33), 19, Color(0.08, 0.07, 0.04) if can_pay else C_DIM)
	_draw_text(card["name"], rect.position + Vector2(46, 33), 17, C_TEXT)
	var line_y = rect.position.y + 66
	for line in card["lines"]:
		if line_y < rect.end.y - 28:
			_draw_text(line, Vector2(rect.position.x + 16, line_y), 14, C_DIM if can_pay else Color(0.42, 0.45, 0.40))
		line_y += 20
	var target_text = _target_label(card["target"])
	_draw_text(target_text, rect.position + Vector2(16, rect.size.y - 15), 13, Color(0.75, 0.88, 0.68))


func _target_label(target):
	match target:
		"none":
			return "即時"
		"soil":
			return "対象: 土"
		"empty_path":
			return "対象: 空いた通路"
		"feature":
			return "対象: 仕掛け"
		"path":
			return "対象: 通路"
		_:
			return "対象あり"


func _draw_hover_tooltip():
	if state != "playing":
		return
	var p = _cell_from_point(hover_pos)
	if p.x == -1:
		return
	var tile = board[p.y][p.x]
	var lines = []
	if tile["terrain"] == "soil":
		lines.append("土: 根道を開けます")
	elif tile["terrain"] == "entrance":
		lines.append("上層入口: 調査隊が降ります")
	elif tile["terrain"] == "core":
		lines.append("最深部: 守るべき記憶核")
	else:
		lines.append("通路")
	if tile["feature"] != "":
		lines.append("%s Lv%d" % [FEATURE_INFO[tile["feature"]]["name"], int(tile["level"])])
	var idx = _intruder_at(p)
	if idx != -1:
		lines.append("%s HP %d/%d" % [intruders[idx]["name"], int(intruders[idx]["hp"]), int(intruders[idx]["max_hp"])])
	var w = 220.0
	var h = 28.0 + lines.size() * 22.0
	var rect = Rect2(hover_pos + Vector2(16, 18), Vector2(w, h))
	var view = get_viewport_rect().size
	if rect.end.x > view.x:
		rect.position.x = hover_pos.x - w - 16
	if rect.end.y > view.y:
		rect.position.y = hover_pos.y - h - 16
	draw_rect(rect, Color(0.02, 0.03, 0.025, 0.94), true)
	draw_rect(rect, Color(0.54, 0.70, 0.48, 0.65), false, 1.0)
	var y = rect.position.y + 26
	for line in lines:
		_draw_text(line, Vector2(rect.position.x + 12, y), 15, C_TEXT)
		y += 22


func _draw_reward_overlay():
	var view = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.62), true)
	var panel = Rect2(Vector2(view.x * 0.5 - 380, 98), Vector2(760, 486))
	draw_rect(panel, Color(0.045, 0.065, 0.055, 0.98), true)
	draw_rect(panel, Color(0.58, 0.72, 0.46, 0.55), false, 2.0)
	_draw_text("一日をしのいだ", panel.position + Vector2(34, 52), 32, Color(0.96, 0.88, 0.63))
	_draw_text("記憶庭園に加える恵みを1つ選んでください。", panel.position + Vector2(36, 86), 18, C_TEXT)
	var x = panel.position.x + 36
	var y = panel.position.y + 132
	for i in range(reward_choices.size()):
		var rect = Rect2(x + i * 236, y, 214, 250)
		reward_rects.append(rect)
		_draw_reward_choice(rect, reward_choices[i])
	_draw_button("skip_reward", Rect2(panel.position.x + panel.size.x - 230, panel.end.y - 72, 190, 42), "回復だけ選ぶ", false)


func _draw_reward_choice(rect, choice):
	draw_rect(rect.grow(4), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, Color(0.14, 0.20, 0.16), true)
	draw_rect(rect, Color(0.93, 0.78, 0.32, 0.75), false, 2.0)
	if choice["type"] == "card":
		var card_id = choice["id"]
		var card = CARD_DB[card_id]
		_draw_text(card["name"], rect.position + Vector2(18, 38), 21, C_TEXT)
		_draw_text("コスト %d" % int(card["cost"]), rect.position + Vector2(18, 70), 16, C_GOLD)
		var y = rect.position.y + 114
		for line in card["lines"]:
			_draw_text(line, Vector2(rect.position.x + 18, y), 16, C_DIM)
			y += 26
		_draw_text("デッキに追加", rect.position + Vector2(18, rect.size.y - 24), 15, Color(0.72, 0.94, 0.70))
	elif choice["type"] == "heal":
		_draw_text(choice["label"], rect.position + Vector2(18, 42), 22, C_TEXT)
		_draw_text("記憶核 +%d" % int(choice["amount"]), rect.position + Vector2(18, 90), 20, C_TEAL)
		_draw_text("デッキは増えません", rect.position + Vector2(18, 128), 16, C_DIM)
	elif choice["type"] == "remove":
		_draw_text(choice["label"], rect.position + Vector2(18, 42), 22, C_TEXT)
		_draw_text("デッキから1枚削除", rect.position + Vector2(18, 90), 18, C_TEAL)
		_draw_text("手札の回りが良くなる", rect.position + Vector2(18, 128), 16, C_DIM)


func _draw_remove_overlay():
	var view = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.64), true)
	var panel = Rect2(Vector2(view.x * 0.5 - 455, 80), Vector2(910, 550))
	draw_rect(panel, Color(0.045, 0.065, 0.055, 0.98), true)
	draw_rect(panel, Color(0.58, 0.72, 0.46, 0.55), false, 2.0)
	_draw_text("堆肥にする札を選ぶ", panel.position + Vector2(30, 46), 30, Color(0.96, 0.88, 0.63))
	_draw_text("クリックしたカードをデッキから取り除きます。", panel.position + Vector2(32, 78), 17, C_TEXT)
	var cols = 5
	var w = 160.0
	var h = 108.0
	var gap = 14.0
	var start = panel.position + Vector2(30, 118)
	for i in range(deck.size()):
		var col = i % cols
		var row = int(i / cols)
		var rect = Rect2(start + Vector2(col * (w + gap), row * (h + gap)), Vector2(w, h))
		remove_rects.append(rect)
		var card = CARD_DB[deck[i]]
		draw_rect(rect, Color(0.15, 0.20, 0.16), true)
		draw_rect(rect, Color(0.55, 0.68, 0.46, 0.52), false, 1.0)
		_draw_text(card["name"], rect.position + Vector2(12, 30), 17, C_TEXT)
		_draw_text("コスト %d" % int(card["cost"]), rect.position + Vector2(12, 58), 14, C_GOLD)
		_draw_text(_target_label(card["target"]), rect.position + Vector2(12, 86), 13, C_DIM)
	_draw_button("remove_skip", Rect2(panel.end.x - 206, panel.end.y - 62, 168, 40), "やめる", false)


func _draw_end_screen(won):
	var view = get_viewport_rect().size
	_draw_cover(title_art, Rect2(Vector2.ZERO, view), Color(1, 1, 1, 0.64))
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.02, 0.035, 0.03, 0.74), true)
	var title = "記憶庭園は朝を迎えた" if won else "記憶核がほどけた"
	var subtitle = "7日間、防衛成功。" if won else "調査隊に記憶を採掘されてしまった。"
	_draw_text(title, Vector2(72, 122), 44, Color(0.97, 0.90, 0.64))
	_draw_text(subtitle, Vector2(76, 174), 21, C_TEXT)
	var y = 244
	_draw_text("Score: %d" % score, Vector2(82, y), 28, C_GOLD)
	_draw_text("眠らせた調査隊: %d" % kills, Vector2(82, y + 44), 20, C_TEXT)
	_draw_text("残った記憶核: %d" % max(0, integrity), Vector2(82, y + 78), 20, C_TEXT)
	_draw_text("Best Score: %d" % int(meta.get("best_score", 0)), Vector2(82, y + 112), 20, C_DIM)
	_draw_button("restart", Rect2(82, y + 172, 220, 50), "もう一度", true)
	_draw_button("title", Rect2(318, y + 172, 220, 50), "タイトルへ", false)


func _draw_cover(texture, target_rect, modulate):
	if texture == null:
		draw_rect(target_rect, Color(0.04, 0.07, 0.055), true)
		for i in range(18):
			var px = target_rect.position.x + fmod(i * 173.0 + anim_time * 9.0, target_rect.size.x)
			var py = target_rect.position.y + 60.0 + fmod(i * 89.0, target_rect.size.y - 80.0)
			draw_circle(Vector2(px, py), 3.0 + float(i % 4), Color(0.57, 0.82, 0.48, 0.16))
		return
	var tex_size = texture.get_size()
	var scale = max(target_rect.size.x / tex_size.x, target_rect.size.y / tex_size.y)
	var draw_size = tex_size * scale
	var pos = target_rect.position + (target_rect.size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(pos, draw_size), false, modulate)


func _draw_button(id, rect, label, primary):
	button_rects[id] = rect
	var hover = rect.has_point(hover_pos)
	var color = Color(0.67, 0.52, 0.18) if primary else Color(0.12, 0.18, 0.15)
	if hover:
		color = color.lightened(0.16)
	draw_rect(rect.grow(3), Color(0, 0, 0, 0.32), true)
	draw_rect(rect, color, true)
	draw_rect(rect, Color(0.92, 0.78, 0.34, 0.85) if primary else Color(0.46, 0.62, 0.43, 0.6), false, 1.5)
	var text_size = 18
	var text_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	while text_width > rect.size.x - 18 and text_size > 12:
		text_size -= 1
		text_width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	_draw_text(label, rect.position + Vector2((rect.size.x - text_width) * 0.5, rect.size.y * 0.62), text_size, Color(0.06, 0.06, 0.04) if primary else C_TEXT)


func _draw_text(text, pos, size, color):
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _add_log(line):
	log_lines.append(line)
	if log_lines.size() > 60:
		log_lines.remove_at(0)


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


func _load_title_art():
	var imported = load(TITLE_ART_PATH)
	if imported is Texture2D:
		title_art = imported
		return
	var image = Image.new()
	var err = image.load(TITLE_ART_PATH)
	if err == OK:
		title_art = ImageTexture.create_from_image(image)
	else:
		title_art = null


func _setup_audio():
	sound_players["play"] = _make_player(420.0, 0.07, 0.16)
	sound_players["select"] = _make_player(560.0, 0.04, 0.10)
	sound_players["deny"] = _make_player(130.0, 0.08, 0.14)
	sound_players["hit"] = _make_player(240.0, 0.05, 0.13)
	sound_players["down"] = _make_player(680.0, 0.09, 0.14)
	sound_players["spawn"] = _make_player(180.0, 0.08, 0.10)
	sound_players["core"] = _make_player(95.0, 0.18, 0.18)
	sound_players["reward"] = _make_player(760.0, 0.10, 0.13)
	sound_players["victory"] = _make_player(880.0, 0.14, 0.16)
	sound_players["start"] = _make_player(520.0, 0.10, 0.13)


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
