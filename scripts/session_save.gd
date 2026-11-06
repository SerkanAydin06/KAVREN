extends RefCounted

const PATH := "user://ashvale-session-v1.save"
const INVENTORY := preload("res://scripts/inventory.gd")
const ITEMS := preload("res://scripts/items.gd")

static func capture(game: Node) -> Dictionary:
	var spent := {}
	var ferns := {}
	for path in game.harvested:
		spent[path] = []
	for node in game.resource_nodes:
		if not is_instance_valid(node):
			continue
		if not node.visible and node.has_meta("regrow_end"):
			ferns[str(game.get_path_to(node))] = maxf(0, (int(node.get_meta("regrow_end")) - Time.get_ticks_msec()) / 1000.0)
		if node.has_meta("harvest_source"):
			var path: String = node.get_meta("harvest_source")
			spent[path].append(node.global_position)
	return {
		"version": 1, "slots": game.inventory.slots.duplicate(true),
		"selected": game.selected_slot, "position": game.player.global_position,
		"yaw": game.yaw, "pitch": game.pitch, "health": game.health,
		"stamina": game.stamina, "hour": game.atmosphere.hour,
		"fires": game.fire_positions.slice(1), "spent": spent, "ferns": ferns,
	}

static func write_state(data: Dictionary, path := PATH) -> bool:
	# Keep the last completed save until the replacement is fully on disk.
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	var success := file.store_var(data)
	file.flush()
	success = success and file.get_error() == OK
	file.close()
	return success and DirAccess.rename_absolute(path + ".tmp", path) == OK

static func read_state(path := PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 4 * 1024 * 1024:
		return {}
	var data: Variant = file.get_var(false)
	if not data is Dictionary or data.get("version") != 1:
		return {}
	if not data.get("slots") is Array or data.slots.size() != INVENTORY.SLOT_COUNT:
		return {}
	for slot in data.slots:
		if slot == null:
			continue
		if not slot is Dictionary or not slot.get("id") is String or not ITEMS.exists(slot.id):
			return {}
		if not slot.get("count") is int or slot.count < 1 or slot.count > ITEMS.stack_size(slot.id):
			return {}
	if not data.get("selected") is int or data.selected < 0 or data.selected >= INVENTORY.HOTBAR_SIZE:
		return {}
	for key in ["yaw", "pitch", "hour", "health", "stamina"]:
		if not data.get(key) is float or not is_finite(data[key]):
			return {}
	if not _valid_point(data.get("position")) or not data.get("fires") is Array or not data.get("spent") is Dictionary:
		return {}
	if not data.get("ferns") is Dictionary:
		return {}
	for key in data.ferns:
		if not key is String or not data.ferns[key] is float or not is_finite(data.ferns[key]):
			return {}
	for point in data.fires:
		if not _valid_point(point):
			return {}
	for path_key in data.spent:
		if not path_key is String or not data.spent[path_key] is Array:
			return {}
		for point in data.spent[path_key]:
			if not _valid_point(point):
				return {}
	return data

static func _valid_point(value: Variant) -> bool:
	return value is Vector3 and value.is_finite()

static func restore(game: Node, data: Dictionary) -> void:
	game.inventory.slots = data.slots.duplicate(true)
	game.inventory.changed.emit()
	game._select_slot(data.selected)
	game.player.global_position = data.position
	game.yaw = data.yaw
	game.pitch = data.pitch
	game.camera_pivot.rotation = Vector3(game.pitch, game.yaw, 0)
	game.health = clampf(data.health, 0, game.MAX_HEALTH)
	game.stamina = clampf(data.stamina, 0, 100)
	game.atmosphere.set_hour(data.hour)
	for spot in data.fires:
		game._add_placed_fire(spot)
	# Match only resource nodes in this fresh world, including the showcase oak.
	for source in game.resource_nodes.duplicate():
		var key: String = str(game.get_path_to(source))
		if data.ferns.has(key) and source.get_meta("resource_type", "") == "fern":
			game._regrow_fern(source, clampf(data.ferns[key], 0, game.FERN_REGROW_SECONDS))
		if not data.spent.has(key):
			continue
		var tree: bool = source.has_method("take_axe_hit")
		if not tree and not source.has_method("take_pickaxe_hit"):
			continue
		var drops := []
		if tree:
			source._add_stump()
		for point in data.spent[key]:
			var drop: Node3D = source._make_wood_piece(drops.size()) if tree else source._make_chunk(drops.size())
			game.add_child(drop)
			drop.global_position = point
			drops.append(drop)
		game._register_drops(drops, source)
		game.resource_nodes.erase(source)
		source.queue_free()
	if game.health <= 0:
		game._die()
	game._update_hud()
