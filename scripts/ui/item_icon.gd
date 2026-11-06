extends Control

# Vektor esya ikonlari: her boyutta keskin, tek bir stil (koyu kontur + yumusak golge).
# Cizim 64x64 mantiksal alanda yapilir ve kontrol boyutuna olceklenir.

var item_id := "":
	set(value):
		item_id = value
		queue_redraw()

const OUTLINE := Color(0.05, 0.04, 0.03, 0.9)
const WOOD_DARK := Color("#5a3a22")
const WOOD := Color("#8a5a34")
const WOOD_CUT := Color("#e2b979")
const STONE := Color("#8c8f8a")
const STONE_DARK := Color("#5f625e")
const STONE_LIGHT := Color("#b9bcb5")
const TIER_COLORS := {1: Color("#9a978f"), 2: Color("#d9824a"), 3: Color("#c9d1d6")}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _s() -> float:
	return minf(size.x, size.y) / 64.0

func _p(x: float, y: float) -> Vector2:
	var s := _s()
	var offset := (size - Vector2(64, 64) * s) * 0.5
	return offset + Vector2(x, y) * s

func _poly(points: PackedVector2Array, color: Color, outline := true) -> void:
	var mapped := PackedVector2Array()
	for p in points:
		mapped.append(_p(p.x, p.y))
	draw_colored_polygon(mapped, color)
	if outline:
		var closed := mapped.duplicate()
		closed.append(mapped[0])
		draw_polyline(closed, OUTLINE, 1.6 * _s(), true)

func _line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(_p(a.x, a.y), _p(b.x, b.y), OUTLINE, (width + 2.4) * _s(), true)
	draw_line(_p(a.x, a.y), _p(b.x, b.y), color, width * _s(), true)

func _circle(c: Vector2, r: float, color: Color) -> void:
	draw_circle(_p(c.x, c.y), (r + 1.0) * _s(), OUTLINE)
	draw_circle(_p(c.x, c.y), r * _s(), color)

func _shadow() -> void:
	var center := _p(32, 54)
	var s := _s()
	for i in range(4):
		draw_circle(center, (20.0 - i * 4.0) * s, Color(0, 0, 0, 0.06))

func _draw() -> void:
	if item_id.is_empty():
		return
	_shadow()
	match item_id:
		"wood": _draw_wood()
		"stone": _draw_rock(STONE, STONE_LIGHT, [])
		"copper": _draw_rock(Color("#6f665c"), Color("#958a7c"), [Color("#e0864a"), Color("#f2a46b")])
		"iron": _draw_rock(Color("#3f4247"), Color("#5c6067"), [Color("#c8cdd2"), Color("#e7ebee")])
		"fiber": _draw_fiber()
		"rope": _draw_rope()
		"torch": _draw_torch()
		"campfire": _draw_campfire()
		_:
			if item_id.ends_with("_axe"):
				_draw_axe(TIER_COLORS.get(_tier(), STONE))
			elif item_id.ends_with("_pickaxe"):
				_draw_pickaxe(TIER_COLORS.get(_tier(), STONE))

func _tier() -> int:
	if item_id.begins_with("iron"):
		return 3
	if item_id.begins_with("copper"):
		return 2
	return 1

func _draw_wood() -> void:
	for log_segment in [[Vector2(10, 40), Vector2(48, 30)], [Vector2(16, 48), Vector2(54, 40)]]:
		_line(log_segment[0], log_segment[1], WOOD, 11.0)
		_line(log_segment[0] + Vector2(2, -2), log_segment[1] + Vector2(-2, -2), WOOD_DARK, 2.0)
		_circle(log_segment[1], 5.6, WOOD_CUT)
		draw_arc(_p(log_segment[1].x, log_segment[1].y), 3.0 * _s(), 0, TAU, 16, WOOD, 1.2 * _s(), true)

func _draw_rock(base: Color, light: Color, specks: Array) -> void:
	_poly(PackedVector2Array([Vector2(12, 46), Vector2(16, 26), Vector2(28, 14), Vector2(44, 16), Vector2(54, 30), Vector2(52, 46), Vector2(32, 52)]), base)
	_poly(PackedVector2Array([Vector2(18, 28), Vector2(28, 17), Vector2(42, 19), Vector2(34, 30)]), light, false)
	if specks.is_empty():
		draw_line(_p(28, 34), _p(40, 44), STONE_DARK, 1.6 * _s(), true)
		return
	_poly(PackedVector2Array([Vector2(22, 36), Vector2(34, 31), Vector2(46, 36), Vector2(40, 40), Vector2(28, 40)]), specks[0], false)
	for c in [Vector2(36, 24), Vector2(24, 44), Vector2(46, 26)]:
		draw_circle(_p(c.x, c.y), 2.4 * _s(), specks[1])

func _draw_fiber() -> void:
	var greens := [Color("#4f7d36"), Color("#6b9c45"), Color("#88b555")]
	for i in range(5):
		var x := 18.0 + i * 7.0
		var pts := PackedVector2Array()
		for k in range(8):
			var t := k / 7.0
			pts.append(_p(x + sin(t * 3.0 + i) * 4.0, 54 - t * 40.0))
		draw_polyline(pts, OUTLINE, 4.4 * _s(), true)
		draw_polyline(pts, greens[i % 3], 2.6 * _s(), true)

func _draw_rope() -> void:
	var rope := Color("#c9a46a")
	for r in [18.0, 13.0, 8.0]:
		draw_arc(_p(32, 34), r * _s(), 0, TAU, 32, OUTLINE, 6.0 * _s(), true)
		draw_arc(_p(32, 34), r * _s(), 0, TAU, 32, rope, 3.8 * _s(), true)
	_line(Vector2(48, 30), Vector2(56, 52), rope, 3.8)

func _draw_axe(head: Color) -> void:
	_line(Vector2(16, 56), Vector2(42, 12), WOOD, 5.0)
	_poly(PackedVector2Array([Vector2(36, 12), Vector2(46, 18), Vector2(56, 10), Vector2(58, 30), Vector2(48, 28), Vector2(32, 20)]), head)
	_poly(PackedVector2Array([Vector2(56, 10), Vector2(58, 30), Vector2(55, 28), Vector2(53, 13)]), head.lightened(0.45), false)
	_line(Vector2(19, 50), Vector2(23, 43), WOOD_DARK, 5.6)

func _draw_pickaxe(head: Color) -> void:
	_line(Vector2(20, 56), Vector2(40, 16), WOOD, 5.0)
	var pts := PackedVector2Array()
	for k in range(13):
		var t := k / 12.0
		var a := lerpf(PI * 1.12, PI * 1.88, t)
		pts.append(Vector2(38 + cos(a) * 26.0, 34 + sin(a) * 22.0))
	var thick := PackedVector2Array()
	for p in pts:
		thick.append(p)
	for k in range(pts.size() - 1, -1, -1):
		thick.append(pts[k] + (Vector2(38, 34) - pts[k]).normalized() * 5.0)
	_poly(thick, head)
	_line(Vector2(23, 50), Vector2(27, 42), WOOD_DARK, 5.6)

func _draw_torch() -> void:
	_line(Vector2(26, 58), Vector2(36, 26), WOOD, 5.0)
	_line(Vector2(34, 31), Vector2(37, 22), Color("#c9a46a"), 7.0)
	_poly(PackedVector2Array([Vector2(37, 4), Vector2(46, 16), Vector2(44, 24), Vector2(37, 27), Vector2(30, 23), Vector2(30, 14)]), Color("#f08a24"))
	_poly(PackedVector2Array([Vector2(37, 12), Vector2(41, 18), Vector2(37, 23), Vector2(33, 19)]), Color("#ffd86b"), false)

func _draw_campfire() -> void:
	for i in range(7):
		var a := i * TAU / 7.0
		_circle(Vector2(32 + cos(a) * 20.0, 48 + sin(a) * 7.0), 4.2, STONE)
	_line(Vector2(16, 50), Vector2(46, 38), WOOD, 6.0)
	_line(Vector2(48, 50), Vector2(18, 38), WOOD_DARK, 6.0)
	_poly(PackedVector2Array([Vector2(32, 8), Vector2(42, 26), Vector2(40, 38), Vector2(32, 42), Vector2(24, 38), Vector2(22, 26)]), Color("#f08a24"))
	_poly(PackedVector2Array([Vector2(32, 20), Vector2(37, 30), Vector2(32, 38), Vector2(27, 30)]), Color("#ffd86b"), false)
