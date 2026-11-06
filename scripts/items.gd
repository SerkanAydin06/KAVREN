extends RefCounted

# Ashvale esya veritabani ve uretim tarifleri.
# Alet "power": bir darbede verilen hasar. Agac 3, kaya 3, bakir cevheri 4,
# demir cevheri 5 dayaniklilikta. "tier": kazilabilecek en sert cevher.

const ITEMS := {
	"wood": {"name": "Odun", "category": "Malzeme", "stack": 50, "description": "Ağaç keserek elde edilir. Alet sapları ve ateş için temel malzeme."},
	"stone": {"name": "Taş", "category": "Malzeme", "stack": 50, "description": "Kayalardan kazılır. Taş aletler ve kamp ateşi için."},
	"copper": {"name": "Bakır Cevheri", "category": "Malzeme", "stack": 50, "description": "Turuncu damarlı kayalardan kazılır. Bakır aletler için."},
	"iron": {"name": "Demir Cevheri", "category": "Malzeme", "stack": 50, "description": "Koyu cevher kayalarından kazılır. En az Bakır Kazma gerekir."},
	"fiber": {"name": "Bitki Lifi", "category": "Malzeme", "stack": 50, "description": "Eğrelti otlarından [E] ile toplanır. İp ve meşale için."},
	"rope": {"name": "İp", "category": "Malzeme", "stack": 20, "description": "Liflerden örülür. Alet başlarını sapa bağlar."},
	"stone_axe": {"name": "Taş Balta", "category": "Alet", "stack": 1, "tool": "axe", "tier": 1, "power": 1.0, "tint": Color(0.72, 0.7, 0.66), "description": "Basit bir balta. Ağacı 3 darbede keser."},
	"copper_axe": {"name": "Bakır Balta", "category": "Alet", "stack": 1, "tool": "axe", "tier": 2, "power": 1.5, "tint": Color(1.0, 0.68, 0.45), "description": "Keskin bakır ağız. Ağacı 2 darbede keser."},
	"iron_axe": {"name": "Demir Balta", "category": "Alet", "stack": 1, "tool": "axe", "tier": 3, "power": 3.0, "tint": Color(1.0, 1.0, 1.0), "description": "Usta işi demir balta. Ağacı tek darbede keser."},
	"stone_pickaxe": {"name": "Taş Kazma", "category": "Alet", "stack": 1, "tool": "pickaxe", "tier": 1, "power": 1.0, "tint": Color(0.72, 0.7, 0.66), "description": "Taş ve bakır cevherini kazar. Demir için yetersiz."},
	"copper_pickaxe": {"name": "Bakır Kazma", "category": "Alet", "stack": 1, "tool": "pickaxe", "tier": 2, "power": 1.5, "tint": Color(1.0, 0.68, 0.45), "description": "Demir cevherini kazabilir. Daha az darbe."},
	"iron_pickaxe": {"name": "Demir Kazma", "category": "Alet", "stack": 1, "tool": "pickaxe", "tier": 3, "power": 2.5, "tint": Color(1.0, 1.0, 1.0), "description": "Her kayayı iki darbede kırar."},
	"torch": {"name": "Meşale", "category": "Alet", "stack": 10, "tool": "torch", "description": "Elde tutulunca etrafı aydınlatır. Geceleri vazgeçilmez."},
	"campfire": {"name": "Kamp Ateşi", "category": "Yapı", "stack": 5, "tool": "place", "description": "Seç ve [Sol Tık] ile kur. Işık verir; içine basma!"},
}

# Kazilabilir kaynaklarin gerektirdigi en dusuk kazma seviyesi.
const MINE_TIER := {"stone": 1, "copper": 1, "iron": 2}

const RECIPES := [
	{"result": "rope", "count": 1, "cost": {"fiber": 3}, "time": 0.8},
	{"result": "torch", "count": 2, "cost": {"wood": 1, "fiber": 2}, "time": 1.0},
	{"result": "campfire", "count": 1, "cost": {"wood": 5, "stone": 6}, "time": 1.6},
	{"result": "stone_axe", "count": 1, "cost": {"wood": 3, "stone": 3, "rope": 1}, "time": 1.4},
	{"result": "stone_pickaxe", "count": 1, "cost": {"wood": 3, "stone": 3, "rope": 1}, "time": 1.4},
	{"result": "copper_axe", "count": 1, "cost": {"wood": 3, "copper": 5, "rope": 1}, "time": 2.0},
	{"result": "copper_pickaxe", "count": 1, "cost": {"wood": 3, "copper": 5, "rope": 1}, "time": 2.0},
	{"result": "iron_axe", "count": 1, "cost": {"wood": 3, "iron": 5, "rope": 2}, "time": 2.6},
	{"result": "iron_pickaxe", "count": 1, "cost": {"wood": 3, "iron": 5, "rope": 2}, "time": 2.6},
]

static func exists(id: String) -> bool:
	return ITEMS.has(id)

static func info(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func display_name(id: String) -> String:
	return String(info(id).get("name", id))

static func stack_size(id: String) -> int:
	return int(info(id).get("stack", 1))

static func tool_kind(id: String) -> String:
	return String(info(id).get("tool", ""))

static func tool_power(id: String) -> float:
	return float(info(id).get("power", 1.0))

static func tool_tier(id: String) -> int:
	return int(info(id).get("tier", 0))

static func recipe_for(result: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["result"] == result:
			return recipe
	return {}
