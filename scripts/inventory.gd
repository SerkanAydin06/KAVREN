extends RefCounted

# Yuva tabanli envanter. Ilk HOTBAR_SIZE yuva alt bardaki hizli secim cubugudur.
# Her yuva null ya da {"id": String, "count": int}.

signal changed
signal item_added(id: String, amount: int)

const ITEMS := preload("res://scripts/items.gd")
const SLOT_COUNT := 24
const HOTBAR_SIZE := 6

var slots: Array = []

func _init() -> void:
	slots.resize(SLOT_COUNT)

func get_slot(index: int) -> Variant:
	return slots[index] if index >= 0 and index < SLOT_COUNT else null

func item_at(index: int) -> String:
	var slot: Variant = get_slot(index)
	return String(slot["id"]) if slot != null else ""

func count(id: String) -> int:
	var total := 0
	for slot in slots:
		if slot != null and slot["id"] == id:
			total += int(slot["count"])
	return total

func space_for(id: String) -> int:
	var stack := ITEMS.stack_size(id)
	var room := 0
	for slot in slots:
		if slot == null:
			room += stack
		elif slot["id"] == id:
			room += stack - int(slot["count"])
	return room

# Doner: sigmayan miktar (0 = hepsi eklendi).
func add(id: String, amount: int) -> int:
	if amount <= 0 or not ITEMS.exists(id):
		return amount
	var remaining := amount
	var stack := ITEMS.stack_size(id)
	# Once mevcut yigınlari doldur, sonra bos yuvalar (hotbar once).
	for i in range(SLOT_COUNT):
		var slot: Variant = slots[i]
		if remaining > 0 and slot != null and slot["id"] == id and int(slot["count"]) < stack:
			var put := mini(stack - int(slot["count"]), remaining)
			slot["count"] = int(slot["count"]) + put
			remaining -= put
	for i in range(SLOT_COUNT):
		if remaining <= 0:
			break
		if slots[i] == null:
			var put := mini(stack, remaining)
			slots[i] = {"id": id, "count": put}
			remaining -= put
	var added := amount - remaining
	if added > 0:
		item_added.emit(id, added)
		changed.emit()
	return remaining

func remove(id: String, amount: int) -> bool:
	if count(id) < amount:
		return false
	var remaining := amount
	# Arka yuvalardan baslayarak al: hotbar'daki yigınlar en son azalir.
	for i in range(SLOT_COUNT - 1, -1, -1):
		var slot: Variant = slots[i]
		if remaining > 0 and slot != null and slot["id"] == id:
			var take := mini(int(slot["count"]), remaining)
			slot["count"] = int(slot["count"]) - take
			remaining -= take
			if int(slot["count"]) <= 0:
				slots[i] = null
	changed.emit()
	return true

func remove_from_slot(index: int, amount: int = 1) -> bool:
	var slot: Variant = get_slot(index)
	if slot == null or int(slot["count"]) < amount:
		return false
	slot["count"] = int(slot["count"]) - amount
	if int(slot["count"]) <= 0:
		slots[index] = null
	changed.emit()
	return true

func set_count(id: String, amount: int) -> void:
	var current := count(id)
	if amount > current:
		add(id, amount - current)
	elif amount < current:
		remove(id, current - amount)

func has_all(cost: Dictionary) -> bool:
	for id in cost:
		if count(String(id)) < int(cost[id]):
			return false
	return true

# Surukle-birak: ayni esya ise birlestir, degilse yer degistir.
func move(from_index: int, to_index: int) -> void:
	if from_index == to_index or from_index < 0 or to_index < 0 or from_index >= SLOT_COUNT or to_index >= SLOT_COUNT:
		return
	var source: Variant = slots[from_index]
	var target: Variant = slots[to_index]
	if source == null:
		return
	if target != null and target["id"] == source["id"]:
		var stack := ITEMS.stack_size(String(source["id"]))
		var put := mini(stack - int(target["count"]), int(source["count"]))
		target["count"] = int(target["count"]) + put
		source["count"] = int(source["count"]) - put
		if int(source["count"]) <= 0:
			slots[from_index] = null
	else:
		slots[from_index] = target
		slots[to_index] = source
	changed.emit()

# Preview and commit use the same back-to-front consumption order.
func _crafted_slots(recipe: Dictionary) -> Array:
	if not has_all(recipe["cost"]):
		return []
	var preview: RefCounted = get_script().new()
	preview.slots = slots.duplicate(true)
	for id in recipe["cost"]:
		preview.remove(String(id), int(recipe["cost"][id]))
	if preview.add(String(recipe["result"]), int(recipe["count"])) != 0:
		return []
	return preview.slots

func can_craft(recipe: Dictionary) -> bool:
	return not _crafted_slots(recipe).is_empty()

func craft(recipe: Dictionary) -> bool:
	var result := _crafted_slots(recipe)
	if result.is_empty():
		return false
	slots = result
	item_added.emit(String(recipe["result"]), int(recipe["count"]))
	changed.emit()
	return true
