extends Control

const GRID_W = 10
const GRID_H = 7
const MAX_DAY = 7
const START_INTEGRITY = 38
const SAVE_PATH = "user://memory_garden_meta.cfg"
const TITLE_ART_PATH = "res://assets/title_memory_garden.png"

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
	"scout": {"name": "測量係", "hp": 5, "score": 8, "color": Color(0.94, 0.78, 0.46), "core": 4},
	"miner": {"name": "採掘係", "hp": 8, "score": 12, "color": Color(0.88, 0.51, 0.36), "core": 6, "armor": 1},
	"cartographer": {"name": "地図係", "hp": 4, "score": 11, "color": Color(0.52, 0.81, 1.0), "core": 7, "haste": true},
	"carrier": {"name": "運搬係", "hp": 10, "score": 16, "color": Color(0.79, 0.66, 0.95), "core": 8}
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

var meta = {"best_score": 0, "runs": 0, "wins": 0}
var log_lines = []
var hover_pos = Vector2.ZERO
var board_origin = Vector2(48, 86)
var cell_size = 58.0
var card_rects = []
var button_rects = {}
var reward_rects = []
var remove_rects = []
var anim_time = 0.0
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
		Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 2),
		Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3), Vector2i(5, 3),
		Vector2i(6, 3), Vector2i(7, 3), Vector2i(7, 4), Vector2i(8, 4),
		Vector2i(8, 3), Vector2i(9, 3)
	]
	var branches = [
		Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
		Vector2i(5, 2), Vector2i(6, 2), Vector2i(1, 2)
	]
	for p in path + branches:
		board[p.y][p.x]["terrain"] = "path"
	board[3][0]["terrain"] = "entrance"
	board[3][9]["terrain"] = "core"
	_set_feature(Vector2i(4, 3), "spore", 1)


func _begin_day():
	if day > MAX_DAY:
		_finish_run(true)
		return
	state = "playing"
	turn = 1
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
	sap = 3 + int((day - 1) / 3) + income + int(current_omen.get("sap_bonus", 0))
	_draw_cards(5)
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
	if state != "playing":
		return
	if hand.size() > 0:
		discard_pile.append_array(hand)
		hand.clear()
	selected_card = -1
	_feature_phase()
	_spawn_from_queue()
	_advance_intruders()
	_cleanup_intruders()

	if integrity <= 0:
		_finish_run(false)
		return

	if spawn_queue.is_empty() and intruders.is_empty():
		_enter_reward()
		return

	turn += 1
	_start_player_turn()


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
		var offset = _spawn_offset()
		var intruder = {
			"kind": kind,
			"name": data["name"],
			"x": 0,
			"y": 3,
			"hp": data["hp"],
			"max_hp": data["hp"],
			"slow": 0,
			"moved": 0,
			"offset": offset
		}
		intruders.append(intruder)
		_add_log("%sが記憶庭園へ入った。" % data["name"])
	_play_sound("spawn")


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
			var next = _next_step(Vector2i(unit["x"], unit["y"]))
			if next.x == -1:
				break
			unit["x"] = next.x
			unit["y"] = next.y
			_apply_entry_effect(i)
			if i >= intruders.size():
				break
			if Vector2i(unit["x"], unit["y"]) == Vector2i(9, 3):
				var data = INTRUDER_DB[unit["kind"]]
				var damage = int(data["core"]) + max(0, int(unit["hp"]) - 2)
				integrity -= damage
				_add_log("%sが記憶核に触れた。-%d" % [unit["name"], damage])
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
			intruders.remove_at(i)
			_play_sound("down")


func _next_step(start):
	var goal = Vector2i(9, 3)
	if start == goal:
		return goal
	var queue = [start]
	var came = {}
	came[start] = start
	while not queue.is_empty():
		var current = queue[0]
		queue.remove_at(0)
		if current == goal:
			break
		for n in _neighbors(current):
			if not came.has(n) and _is_passable(n):
				came[n] = current
				queue.append(n)
	if not came.has(goal):
		return _fallback_step(start)

	var current = goal
	while came[current] != start:
		current = came[current]
	return current


func _fallback_step(start):
	var best = Vector2i(-1, -1)
	var best_dist = 999
	for n in _neighbors(start):
		if not _is_passable(n):
			continue
		var d = _grid_distance(n, Vector2i(9, 3))
		if d < best_dist:
			best_dist = d
			best = n
	return best


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
		var d = _grid_distance(n, Vector2i(0, 3))
		if d < best_dist:
			best_dist = d
			best = n
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
	cell_size = clamp(min((view.x - 440.0) / GRID_W, (view.y - 270.0) / GRID_H), 48.0, 64.0)
	board_origin = Vector2(42.0, 84.0)


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
		"調査隊は左の入口から入り、右の記憶核を目指します。",
		"カードをクリックして選び、盤面の土や通路をクリックして使います。",
		"土には「根道を開く」。通路には胞子灯、絡み根、トゲ芽、記憶水晶などを配置できます。",
		"ターン終了後、仕掛けが反応し、調査隊が進みます。",
		"1日を守り切ると報酬カードを1枚選び、デッキを育てます。",
		"7日目を守り切れば勝利。Spaceでターン終了、右クリック/Escで選択解除、Mでミュートです。"
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
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.035, 0.052, 0.044), true)
	_draw_soft_background(view)
	_draw_top_bar(view)
	_draw_board()
	_draw_side_panel(view)
	_draw_hand(view)
	_draw_hover_tooltip()


func _draw_soft_background(view):
	for i in range(8):
		var x = fmod(anim_time * (8 + i * 2) + i * 177.0, view.x + 160.0) - 80.0
		var y = 70.0 + i * 69.0
		draw_circle(Vector2(x, y), 1.6 + (i % 3), Color(0.78, 0.62, 0.25, 0.12))
	draw_rect(Rect2(0, 0, view.x, 66), Color(0.025, 0.035, 0.03, 0.85), true)


func _draw_top_bar(view):
	_draw_text("記憶庭園の番人", Vector2(30, 42), 25, Color(0.96, 0.88, 0.63))
	_draw_status_pill(Vector2(292, 18), "第%d日 / %d" % [day, MAX_DAY], Color(0.24, 0.43, 0.31))
	_draw_status_pill(Vector2(420, 18), "ターン %d" % turn, Color(0.22, 0.35, 0.38))
	_draw_status_pill(Vector2(535, 18), "樹液 %d" % sap, Color(0.40, 0.31, 0.12))
	_draw_status_pill(Vector2(640, 18), "記憶核 %d" % integrity, Color(0.37, 0.18, 0.16) if integrity < 12 else Color(0.26, 0.34, 0.22))
	_draw_status_pill(Vector2(780, 18), "Score %d" % score, Color(0.22, 0.23, 0.32))
	_draw_button("help", Rect2(view.x - 278, 14, 82, 38), "F1", false)
	_draw_button("mute", Rect2(view.x - 188, 14, 82, 38), "音 " + ("OFF" if muted else "ON"), false)
	_draw_button("title", Rect2(view.x - 98, 14, 82, 38), "戻る", false)


func _draw_status_pill(pos, label, color):
	var rect = Rect2(pos, Vector2(112, 32))
	draw_rect(rect, Color(0, 0, 0, 0.28), true)
	draw_rect(rect.grow(-1), color, true)
	_draw_text(label, pos + Vector2(10, 22), 16, C_TEXT)


func _draw_board():
	var board_rect = Rect2(board_origin, Vector2(cell_size * GRID_W, cell_size * GRID_H))
	draw_rect(board_rect.grow(12), Color(0.015, 0.025, 0.02, 0.72), true)
	draw_rect(board_rect.grow(8), Color(0.17, 0.13, 0.08, 0.82), true)

	for y in range(GRID_H):
		for x in range(GRID_W):
			var p = Vector2i(x, y)
			var rect = Rect2(board_origin + Vector2(x * cell_size, y * cell_size), Vector2(cell_size - 2, cell_size - 2))
			_draw_tile(rect, p)

	_draw_intruders()
	draw_rect(board_rect, C_GRID, false, 2.0)


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
		_draw_text("入口", rect.position + Vector2(10, 34), 16, Color(0.80, 1.0, 0.66))
	if terrain == "core":
		draw_circle(rect.get_center(), cell_size * 0.23, Color(1.0, 0.78, 0.25, 0.82))
		draw_circle(rect.get_center(), cell_size * 0.10, Color(0.30, 0.95, 0.80, 0.95))
		_draw_text("核", rect.position + Vector2(23, 40), 17, Color(0.07, 0.08, 0.06))

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


func _draw_intruders():
	var stacked = {}
	for i in range(intruders.size()):
		var unit = intruders[i]
		var p = Vector2i(unit["x"], unit["y"])
		var key = "%d,%d" % [p.x, p.y]
		stacked[key] = int(stacked.get(key, 0)) + 1
		var index_on_tile = int(stacked[key]) - 1
		var base = board_origin + Vector2(p.x * cell_size, p.y * cell_size) + Vector2(cell_size / 2, cell_size / 2)
		var offset = unit.get("offset", Vector2.ZERO) + Vector2((index_on_tile % 2) * 8, int(index_on_tile / 2) * 8)
		var pos = base + offset
		var data = INTRUDER_DB[unit["kind"]]
		var flash = float(unit.get("hit_flash", 0.0))
		unit["hit_flash"] = max(0.0, flash - 0.04)
		var color = data["color"].lerp(Color(1, 1, 1), min(1.0, flash * 2.8))
		draw_circle(pos + Vector2(2, 3), cell_size * 0.20, Color(0, 0, 0, 0.36))
		draw_circle(pos, cell_size * 0.19, color)
		draw_circle(pos + Vector2(-4, -4), cell_size * 0.06, Color(1, 1, 1, 0.35))
		var hp_ratio = clamp(float(unit["hp"]) / float(unit["max_hp"]), 0.0, 1.0)
		var bar = Rect2(pos + Vector2(-20, 20), Vector2(40, 5))
		draw_rect(bar, Color(0.13, 0.05, 0.04), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), Color(0.78, 0.18, 0.14), true)
		if int(unit["slow"]) > 0:
			_draw_text("z", pos + Vector2(14, -12), 17, Color(0.66, 0.88, 1.0))


func _draw_side_panel(view):
	var x = board_origin.x + cell_size * GRID_W + 24
	var rect = Rect2(x, 84, view.x - x - 28, view.y - 214)
	draw_rect(rect, C_PANEL, true)
	draw_rect(rect, Color(0.34, 0.52, 0.37, 0.4), false, 1.5)
	_draw_text("庭園の状況", rect.position + Vector2(18, 34), 24, Color(0.96, 0.88, 0.63))
	_draw_text(current_omen.get("name", "静かな風"), rect.position + Vector2(18, 68), 18, Color(0.70, 0.95, 0.78))
	_draw_text(current_omen.get("text", "特別な変化なし"), rect.position + Vector2(18, 94), 15, C_DIM)

	_draw_text("残り調査隊: %d   盤上: %d" % [spawn_queue.size(), intruders.size()], rect.position + Vector2(18, 132), 18, C_TEXT)
	_draw_text("デッキ %d / 山札 %d / 捨札 %d" % [deck.size(), draw_pile.size(), discard_pile.size()], rect.position + Vector2(18, 160), 16, C_DIM)

	var y = rect.position.y + 202
	_draw_text("仕掛け", Vector2(x + 18, y), 18, Color(0.96, 0.88, 0.63))
	y += 28
	for feature in FEATURE_INFO.keys():
		var info = FEATURE_INFO[feature]
		draw_circle(Vector2(x + 28, y - 6), 8, info["color"])
		_draw_text("%s  %s" % [info["short"], info["name"]], Vector2(x + 44, y), 15, C_TEXT)
		y += 23

	y += 12
	_draw_text("ログ", Vector2(x + 18, y), 18, Color(0.96, 0.88, 0.63))
	y += 28
	var start = max(0, log_lines.size() - 7)
	for i in range(start, log_lines.size()):
		_draw_text(log_lines[i], Vector2(x + 18, y), 15, C_DIM)
		y += 23

	_draw_button("end_turn", Rect2(rect.position.x + 18, rect.end.y - 62, rect.size.x - 36, 46), "ターン終了  Space", true)


func _draw_hand(view):
	var n = max(1, hand.size())
	var gap = 10.0
	var card_h = 150.0
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
	draw_rect(rect, Color(1.0, 0.80, 0.28, 0.95) if selected else Color(0.56, 0.68, 0.48, 0.5), false, 2.0 if selected else 1.0)
	draw_circle(rect.position + Vector2(22, 24), 16, C_GOLD if can_pay else Color(0.32, 0.27, 0.20))
	_draw_text(str(card["cost"]), rect.position + Vector2(16, 31), 20, Color(0.08, 0.07, 0.04) if can_pay else C_DIM)
	_draw_text(card["name"], rect.position + Vector2(44, 32), 18, C_TEXT)
	var line_y = rect.position.y + 70
	for line in card["lines"]:
		_draw_text(line, Vector2(rect.position.x + 16, line_y), 15, C_DIM if can_pay else Color(0.42, 0.45, 0.40))
		line_y += 22
	var target_text = _target_label(card["target"])
	_draw_text(target_text, rect.position + Vector2(16, rect.size.y - 16), 13, Color(0.75, 0.88, 0.68))


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
		lines.append("入口: 調査隊が来ます")
	elif tile["terrain"] == "core":
		lines.append("記憶核: 守るべき中心")
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
