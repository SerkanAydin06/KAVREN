extends SceneTree

# Envanter, uretim ve alet ilerlemesi: yiginlama, dolu envanter, surukle-birak,
# tarif, alet gucu/seviyesi, demir kilidi, egrelti lifi, mesale, kamp atesi kurma.
const ITEMS := preload("res://scripts/items.gd")
const INVENTORY := preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> int:
	if not ok:
		print("AshvaleInventoryTest FAIL ", label)
	return 0 if ok else 1

func _run() -> void:
	var failures := 0
	# --- saf envanter ---
	var inv: RefCounted = INVENTORY.new()
	failures += _check(inv.add("wood", 120) == 0 and inv.count("wood") == 120, "stack add")
	failures += _check(inv.get_slot(0)["count"] == 50 and inv.get_slot(2)["count"] == 20, "stack split")
	failures += _check(inv.remove("wood", 70) and inv.count("wood") == 50, "remove")
	failures += _check(not inv.remove("wood", 999), "remove too many")
	inv.add("stone", 3)
	var stone_slot := -1
	for i in range(inv.SLOT_COUNT):
		if inv.item_at(i) == "stone":
			stone_slot = i
	inv.move(stone_slot, 10)
	failures += _check(inv.item_at(10) == "stone" and inv.item_at(stone_slot) != "stone", "drag move")
	var full: RefCounted = INVENTORY.new()
	for i in range(full.SLOT_COUNT):
		full.add("stone_axe", 1)
	failures += _check(full.add("wood", 5) == 5, "full inventory rejects")
	full.slots[0] = {"id": "fiber", "count": 3}
	full.slots[23] = {"id": "fiber", "count": 50}
	var before: Array = full.slots.duplicate(true)
	var full_bag_recipe := ITEMS.recipe_for("rope")
	failures += _check(not full.can_craft(full_bag_recipe) and not full.craft(full_bag_recipe) and full.slots == before, "full split stacks preserve inputs")
	full.slots[23]["count"] = 3
	failures += _check(full.craft(full_bag_recipe) and full.item_at(23) == "rope", "consumed stack frees result slot")
	# --- tarif ---
	var crafter: RefCounted = INVENTORY.new()
	crafter.add("fiber", 3)
	var rope: Dictionary = ITEMS.recipe_for("rope")
	failures += _check(crafter.can_craft(rope) and crafter.craft(rope), "craft rope")
	failures += _check(crafter.count("rope") == 1 and crafter.count("fiber") == 0, "rope consumed")
	failures += _check(not crafter.craft(ITEMS.recipe_for("copper_axe")), "cannot craft without materials")
	for recipe in ITEMS.RECIPES:
		failures += _check(ITEMS.exists(recipe["result"]), "recipe result exists " + String(recipe["result"]))
		for id in recipe["cost"]:
			failures += _check(ITEMS.exists(String(id)), "recipe cost exists " + String(id))

	# --- oyun ici ---
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	failures += _check(game.inventory.item_at(0) == "stone_axe" and game.inventory.item_at(1) == "stone_pickaxe", "starting tools")
	failures += _check(game.active_tool == "axe" and game.equipped_axe.visible and not game.equipped_pickaxe.visible, "slot 0 equips axe")
	failures += _check(game.ui != null and game.ui.get_node_or_null("UIRoot/Hotbar") != null, "hud hotbar")
	# Bakir balta uret ve kusan: agac 2 darbede devrilmeli.
	game.inventory.add("wood", 3)
	game.inventory.add("copper", 5)
	game.inventory.add("rope", 1)
	failures += _check(game.inventory.craft(ITEMS.recipe_for("copper_axe")), "craft copper axe")
	var copper_slot := -1
	for i in range(game.inventory.HOTBAR_SIZE):
		if game.inventory.item_at(i) == "copper_axe":
			copper_slot = i
	failures += _check(copper_slot >= 0, "copper axe in hotbar")
	game._select_slot(copper_slot)
	failures += _check(game.equipped_item == "copper_axe" and game.active_tool == "axe", "equip copper axe")
	var tree: Node3D = null
	for node in game.get_children():
		if String(node.get_meta("tree_species", "")) == "Pine":
			tree = node
			break
	tree.position = Vector3(0, 0, -(game._target_radius(tree) + 0.5))
	game.player.position = Vector3.ZERO
	game.yaw = 0.0
	for hit in range(2):
		game.attack_remaining = 0.0
		game._start_attack()
		game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
	failures += _check(tree.is_falling and tree.hits_taken == 2, "copper axe fells in 2 hits")
	# Demir cevheri: tas kazma yetersiz, bakir kazma kazar.
	var iron_rock: Node3D = null
	for node in game.resource_nodes:
		if is_instance_valid(node) and String(node.get_meta("resource_type", "")) == "mineable" and node.resource_kind == "iron":
			iron_rock = node
			break
	iron_rock.position = Vector3(0, 0, -(game._target_radius(iron_rock) + 0.5))
	game._select_tool("pickaxe")
	game.attack_remaining = 0.0
	game._start_attack()
	game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
	failures += _check(iron_rock.hits_taken == 0, "stone pickaxe cannot mine iron")
	game.inventory.add("copper", 5)
	game.inventory.add("wood", 3)
	game.inventory.add("rope", 1)
	game.inventory.craft(ITEMS.recipe_for("copper_pickaxe"))
	game.attack_remaining = 0.0
	for i in range(game.inventory.HOTBAR_SIZE):
		if game.inventory.item_at(i) == "copper_pickaxe":
			game._select_slot(i)
	game.attack_remaining = 0.0
	game._start_attack()
	game._advance_axe_impact(game.CHOP_IMPACT_DELAY + 0.01)
	failures += _check(game.equipped_item == "copper_pickaxe" and iron_rock.hits_taken == 1, "copper pickaxe mines iron")
	# Egrelti: E ile lif, egrelti gizlenir.
	var fern: Node3D = null
	for node in game.resource_nodes:
		if is_instance_valid(node) and String(node.get_meta("resource_type", "")) == "fern":
			fern = node
			break
	game.player.global_position = fern.global_position + Vector3(0.5, 0, 0)
	for drop in game.resource_nodes.duplicate():
		if is_instance_valid(drop) and String(drop.get_meta("resource_type", "")).ends_with("_drop"):
			drop.global_position += Vector3(50, 0, 50)
	var fiber_before: int = game.inventory.count("fiber")
	game._collect_resource()
	failures += _check(game.inventory.count("fiber") == fiber_before + game.FERN_FIBER and not fern.visible, "fern fiber harvest")
	# Savurma bitmeden alet degismez; darbe sonrasi degisir.
	game.inventory.add("torch", 1)
	var torch_slot := -1
	for i in range(game.inventory.HOTBAR_SIZE):
		if game.inventory.item_at(i) == "torch":
			torch_slot = i
	game.attack_remaining = 0.5
	game._select_slot(torch_slot)
	failures += _check(game.active_tool == "pickaxe" and torch_slot >= 0, "no tool switch mid-swing")
	game.attack_remaining = 0.0
	# Mesale: secilince isik acik.
	for i in range(game.inventory.HOTBAR_SIZE):
		if game.inventory.item_at(i) == "torch":
			game._select_slot(i)
	failures += _check(game.active_tool == "torch" and game.torch.visible and game.torch.light.visible and not game.equipped_axe.visible, "torch equip")
	# Kamp atesi kur: bos bir alana.
	game.inventory.add("campfire", 1)
	# Hotbar dolu: kamp atesi cantaya dustu. Oyuncu gibi surukleyip 5. yuvaya koy.
	var bag_slot := -1
	for i in range(game.inventory.SLOT_COUNT):
		if game.inventory.item_at(i) == "campfire":
			bag_slot = i
	failures += _check(bag_slot >= game.inventory.HOTBAR_SIZE, "full hotbar sends item to bag")
	game.inventory.move(bag_slot, 4)
	game._select_slot(4)
	game.player.global_position = Vector3(30, 0.1, -60)
	game.yaw = 0.0
	var fires_before: int = game.fire_positions.size()
	game._update_placement()
	var placed: bool = game._place_campfire()
	failures += _check(placed and game.fire_positions.size() == fires_before + 1 and game.inventory.count("campfire") == 0, "place campfire")
	failures += _check(game.active_tool == "", "campfire slot emptied")
	# Exercise durable storage using a separate file, then load into a fresh scene.
	var save_path := "user://ashvale-test-only.save"
	iron_rock.take_pickaxe_hit(game.player.global_position, 10)
	var state: Dictionary = game.SAVE.capture(game)
	failures += _check(game.SAVE.write_state(state, save_path), "write save")
	var saved: Dictionary = game.SAVE.read_state(save_path)
	failures += _check(saved == state, "read save")
	var restored: Node = load("res://main.tscn").instantiate()
	root.add_child(restored)
	restored.set_physics_process(false)
	if not saved.is_empty():
		game.SAVE.restore(restored, saved)
		failures += _check(game.SAVE.capture(restored).spent == saved.spent and not saved.spent.is_empty(), "harvest and remaining drops restored")
		failures += _check(restored.inventory.slots == game.inventory.slots and restored.fire_positions == game.fire_positions, "inventory and placed fires restored")
		failures += _check(restored.player.position == game.player.position and restored.selected_slot == game.selected_slot, "player restored")
	DirAccess.remove_absolute(save_path)
	game.player.position = Vector3(game.GROUND_SIZE, 1, 0)
	game._physics_process(0.016)
	failures += _check(game.player.position.x <= game.WORLD_LIMIT, "terrain boundary")
	game.player.position = Vector3(0, -10, 0)
	game._physics_process(0.016)
	failures += _check(game.player.position.is_equal_approx(game.SPAWN_POSITION), "void recovery")
	game._toggle_inventory()
	var select_key := InputEventKey.new()
	select_key.keycode = KEY_1
	select_key.pressed = true
	game._unhandled_input(select_key)
	failures += _check(game.selected_slot == 4, "bag blocks world shortcut")
	print("AshvaleInventoryTest wood=", game.wood, " fiber=", game.inventory.count("fiber"), " fires=", game.fire_positions.size(), " failures=", failures)
	quit(1 if failures > 0 else 0)
