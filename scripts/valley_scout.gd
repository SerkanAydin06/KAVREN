extends RefCounted

# One vertex-colored skin on the original Char1 rig. Coordinates below are in
# metres in its reference T-pose, facing +Z. Equipment stays on the hand bones.
const CREAM := Color("#fff0c5")
const TEAL := Color("#287c82")
const JADE := Color("#61b9a5")
const INK := Color("#26384d")
const BOOTS := Color("#384052")
const CORAL := Color("#e86249")
const RED := Color("#aa4142")
const GOLD := Color("#ffc568")
const SKIN := Color("#f6b98e")
const HAIR := Color("#24354c")
const HAIR_LIGHT := Color("#405774")

var surface := SurfaceTool.new()
var rig: Skeleton3D
var origin: Vector3
var scale_factor: float
var bones := {}

func fit(character: Node3D, skeleton: Skeleton3D) -> bool:
	rig = skeleton
	for i in range(rig.get_bone_count()):
		bones[String(rig.get_bone_name(i)).trim_prefix("mixamorig_")] = i
	for required in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "LeftHand", "RightHand", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot"]:
		if not bones.has(required):
			return false
	var hips := rig.get_bone_global_rest(bones.Hips).origin
	scale_factor = (rig.get_bone_global_rest(bones.Head).origin.y - hips.y) / (1.586 - 0.995)
	if scale_factor <= 0:
		return false
	origin = hips - Vector3(0, 0.995, -0.007) * scale_factor
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_outfit()
	_face()
	_hair()
	surface.generate_normals()
	surface.index()
	var skin_mesh := MeshInstance3D.new()
	skin_mesh.name = "ValleyScout"
	skin_mesh.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	skin_mesh.material_override = material
	for old in character.find_children("*", "MeshInstance3D", true, false):
		(old as MeshInstance3D).visible = false
	rig.add_child(skin_mesh)
	skin_mesh.skeleton = NodePath("..")
	skin_mesh.skin = rig.create_skin_from_rest_transforms()
	# Includes arms, crouch, jump and death throughout the full animation range.
	skin_mesh.custom_aabb = AABB(origin + Vector3(-1.25, -0.35, -1.25) * scale_factor, Vector3(2.5, 2.65, 2.5) * scale_factor)
	return true

func _vertex(point: Vector3, bone: String, tint: Color) -> void:
	surface.set_color(tint)
	surface.set_bones(PackedInt32Array([int(bones[bone]), 0, 0, 0]))
	surface.set_weights(PackedFloat32Array([1, 0, 0, 0]))
	surface.add_vertex(origin + point * scale_factor)

# Elliptical cross-sections can be oriented along Y (body) or X (sleeves).
# Each section carries one bone; neighboring rings deform together at joints.
func _rings(rows: Array, tint: Color, across := false, segments := 14) -> void:
	for r in range(rows.size() - 1):
		var lo: Array = rows[r]
		var hi: Array = rows[r + 1]
		for i in range(segments):
			var a := i * TAU / segments
			var b := (i + 1) * TAU / segments
			var v0 := _point(lo, a, across)
			var v1 := _point(lo, b, across)
			var v2 := _point(hi, a, across)
			var v3 := _point(hi, b, across)
			if across and hi[0] > lo[0]:
				_vertex(v0, lo[5], tint)
				_vertex(v2, hi[5], tint)
				_vertex(v1, lo[5], tint)
				_vertex(v1, lo[5], tint)
				_vertex(v2, hi[5], tint)
				_vertex(v3, hi[5], tint)
			else:
				_vertex(v0, lo[5], tint)
				_vertex(v1, lo[5], tint)
				_vertex(v2, hi[5], tint)
				_vertex(v1, lo[5], tint)
				_vertex(v3, hi[5], tint)
				_vertex(v2, hi[5], tint)
	# Closed ends keep the sleeves and coat readable from above.
	for row in [rows.front(), rows.back()]:
		for i in range(segments):
			_vertex(Vector3(row[0], row[1], row[2]), row[5], tint)
			_vertex(_point(row, i * TAU / segments, across), row[5], tint)
			_vertex(_point(row, (i + 1) * TAU / segments, across), row[5], tint)

func _point(row: Array, angle: float, across: bool) -> Vector3:
	var center := Vector3(row[0], row[1], row[2])
	var a: float = row[3] * cos(angle)
	var b: float = row[4] * sin(angle)
	return center + (Vector3(0, a, b) if across else Vector3(a, 0, b))

func _patch(points: Array, bone: String, tint: Color) -> void:
	for i in range(1, points.size() - 1):
		var a: Array = points[0]
		var b: Array = points[i]
		var c: Array = points[i + 1]
		var signed_area: float = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
		var order := [a, c, b] if signed_area * float(a[2]) > 0 else [a, b, c]
		for point in order:
			_vertex(Vector3(point[0], point[1], point[2]), bone, tint)

func _outfit() -> void:
	_rings([[0,0.90,-0.01,0.18,0.13,"Hips"],[0,1.02,-0.01,0.16,0.12,"Hips"],[0,1.16,-0.025,0.148,0.118,"Spine"],[0,1.34,-0.03,0.205,0.142,"Spine2"],[0,1.43,-0.035,0.202,0.124,"Spine2"],[0,1.49,-0.025,0.096,0.085,"Spine2"]],TEAL)
	_rings([[0,0.86,-0.018,0.205,0.155,"Hips"],[0,0.89,-0.018,0.202,0.152,"Hips"]],GOLD)
	_rings([[0,0.89,-0.018,0.204,0.154,"Hips"],[0,1.09,-0.019,0.151,0.122,"Spine"]],JADE)
	_rings([[0,1.035,-0.016,0.168,0.136,"Hips"],[0,1.095,-0.017,0.163,0.131,"Spine"]],BOOTS)
	_patch([[-0.045,1.04,0.123],[0.045,1.04,0.123],[0.045,1.095,0.123],[-0.045,1.095,0.123]],"Hips",GOLD)
	# Folded neckerchief and two contrasting tails on the player's camera side.
	_rings([[0,1.423,-0.029,0.177,0.142,"Spine2"],[0,1.473,-0.012,0.16,0.123,"Spine2"],[0,1.519,-0.009,0.109,0.105,"Neck"]],CORAL)
	_patch([[-0.124,1.465,0.110],[0.132,1.465,0.110],[0.045,1.30,0.157],[0.00,1.325,0.160]],"Spine2",CORAL)
	_patch([[-0.095,1.465,-0.14],[0.04,1.46,-0.147],[-0.04,1.17,-0.201],[-0.152,1.215,-0.19]],"Spine2",RED)
	_patch([[-0.052,1.46,-0.15],[0.068,1.455,-0.145],[0.155,1.26,-0.197],[0.063,1.28,-0.202]],"Spine2",CORAL)
	# Small ochre field pouch is visible while travelling away from the camera.
	_rings([[-0.121,1.03,-0.13,0.046,0.040,"Hips"],[-0.121,1.055,-0.142,0.073,0.052,"Hips"],[-0.121,1.153,-0.14,0.068,0.05,"Hips"]],Color("#aa6943"))
	_patch([[-0.189,1.15,-0.163],[-0.059,1.15,-0.171],[-0.109,1.092,-0.198],[-0.164,1.101,-0.194]],"Hips",GOLD)
	for sign_value in [-1.0,1.0]:
		var side := "Left" if sign_value > 0 else "Right"
		var x: float = sign_value * 0.09
		var thigh := side + "UpLeg"
		var shin := side + "Leg"
		var foot := side + "Foot"
		var upper := side + "Arm"
		var fore := side + "ForeArm"
		var hand := side + "Hand"
		_rings([[x,0.39,0,0.062,0.069,shin],[x,0.53,0,0.071,0.077,shin],[x,0.72,0.002,0.087,0.093,thigh],[x,0.94,-0.003,0.091,0.102,thigh]],INK)
		_rings([[x,0.095,-0.018,0.057,0.071,foot],[x,0.20,-0.014,0.063,0.073,shin],[x,0.43,0,0.071,0.078,shin]],BOOTS)
		_rings([[x,0.392,0,0.073,0.081,shin],[x,0.442,0,0.078,0.084,shin]],GOLD)
		_rings([[x,0.018,0.044,0.07,0.132,foot],[x,0.077,0.052,0.076,0.135,foot],[x,0.145,0,0.059,0.08,foot]],BOOTS)
		_rings([[sign_value*0.15,1.422,-0.044,0.091,0.105,upper],[sign_value*0.235,1.416,-0.047,0.103,0.103,upper],[sign_value*0.37,1.425,-0.05,0.075,0.08,upper]],JADE,true)
		_rings([[sign_value*0.35,1.425,-0.05,0.078,0.081,upper],[sign_value*0.38,1.425,-0.05,0.075,0.079,upper]],CREAM,true)
		_rings([[sign_value*0.366,1.425,-0.05,0.061,0.064,upper],[sign_value*0.45,1.426,-0.052,0.057,0.058,fore],[sign_value*0.66,1.426,-0.052,0.041,0.045,fore]],SKIN,true)
		_rings([[sign_value*0.57,1.426,-0.055,0.057,0.06,fore],[sign_value*0.69,1.426,-0.055,0.046,0.053,fore]],BOOTS,true)
		_rings([[sign_value*0.68,1.426,-0.051,0.043,0.052,hand],[sign_value*0.75,1.426,-0.048,0.047,0.057,hand],[sign_value*0.827,1.424,-0.052,0.024,0.051,hand]],BOOTS,true)

		for finger in ["Thumb", "Index", "Middle", "Ring", "Pinky"]:
			var rows: Array = []
			for segment in range(1, 5):
				var name := "%sHand%s%d" % [side, finger, segment]
				if not bones.has(name):
					break
				var joint := (rig.get_bone_global_rest(bones[name]).origin - origin) / scale_factor
				var radius := lerpf(0.014, 0.008, float(segment-1) / 3.0)
				rows.append([joint.x, joint.y, joint.z, radius, radius, name])
			if rows.size() >= 2:
				_rings(rows, BOOTS, true, 6)

func _face() -> void:
	_rings([[0,1.465,0,0.066,0.061,"Neck"],[0,1.59,0,0.072,0.072,"Neck"]],SKIN)
	_rings([[0,1.526,0.037,0.043,0.054,"Head"],[0,1.566,0.028,0.102,0.10,"Head"],[0,1.635,0.017,0.138,0.132,"Head"],[0,1.705,0.006,0.145,0.137,"Head"],[0,1.77,-0.006,0.132,0.12,"Head"],[0,1.806,-0.016,0.062,0.068,"Head"]],SKIN,false,24)
	for side in [-1.0,1.0]:
		var x: float = side
		_rings([[x*0.132,1.60,0.006,0.013,0.019,"Head"],[x*0.143,1.641,0.005,0.025,0.025,"Head"],[x*0.136,1.668,-0.001,0.017,0.018,"Head"]],SKIN,false,8)
		# Curved eye panels follow the cheek, with dark upper lashes and a pinpoint catchlight.
		_patch([[x*0.023,1.665,0.151],[x*0.041,1.688,0.148],[x*0.078,1.686,0.131],[x*0.102,1.677,0.113],[x*0.083,1.649,0.128],[x*0.043,1.648,0.147]],"Head",CREAM)
		_patch([[x*0.046,1.681,0.151],[x*0.074,1.68,0.139],[x*0.075,1.654,0.139],[x*0.058,1.649,0.148],[x*0.044,1.658,0.154]],"Head",TEAL)
		_patch([[x*0.055,1.681,0.153],[x*0.066,1.679,0.149],[x*0.066,1.658,0.150],[x*0.054,1.657,0.155]],"Head",INK)
		_patch([[x*0.052,1.679,0.156],[x*0.061,1.679,0.155],[x*0.061,1.672,0.156],[x*0.052,1.672,0.157]],"Head",Color.WHITE)
		_patch([[x*0.021,1.666,0.154],[x*0.040,1.694,0.151],[x*0.082,1.692,0.131],[x*0.111,1.685,0.108],[x*0.097,1.673,0.119],[x*0.077,1.684,0.137],[x*0.041,1.685,0.152]],"Head",HAIR)
		_patch([[x*0.03,1.71,0.145],[x*0.081,1.715,0.124],[x*0.096,1.708,0.111],[x*0.034,1.704,0.145]],"Head",HAIR)
	_patch([[-0.014,1.622,0.146],[0,1.645,0.146],[0.009,1.62,0.161]],"Head",Color("#e59e79"))
	_patch([[-0.030,1.583,0.141],[0.0,1.576,0.150],[0.031,1.585,0.141],[0.012,1.571,0.150],[-0.006,1.570,0.149]],"Head",Color("#a25756"))

func _hair() -> void:
	# Ink-blue layered cap. The fringe stays above the irises; longer locks frame the cheeks.
	var ends := []
	for i in range(24):
		var a := i*TAU/24
		var front := maxf(0, sin(a))
		ends.append(Vector3(0.154*cos(a),1.55+0.183*front,-0.008+0.15*sin(a)))
	for i in range(24):
		var a: float = i*TAU/24
		var b: float = (i+1)*TAU/24
		var e: Vector3 = ends[i]
		var next: Vector3 = ends[(i+1)%24]
		var hi := Vector3(0.149*cos(a),1.776+0.016*cos(a),-0.009+0.141*sin(a))
		var hi_next := Vector3(0.149*cos(b),1.776+0.016*cos(b),-0.009+0.141*sin(b))
		var mid := (e+next)*0.5 + Vector3(0.014*cos(a),-0.027-0.019*absf(cos(i)),0.012*sin(a))
		var top := Vector3(-0.032,1.859,-0.002)
		for pt in [hi,hi_next,top,hi,e,mid,hi,mid,hi_next,hi_next,mid,next]:
			_vertex(pt,"Head",HAIR_LIGHT if i in [3,4,7,8] else HAIR)
	_patch([[-0.11,1.78,0.109],[-0.044,1.823,0.08],[0.08,1.766,0.115],[0.037,1.696,0.154],[-0.013,1.738,0.151],[-0.062,1.704,0.148]],"Head",HAIR)
	_patch([[-0.04,1.83,0.047],[-0.086,1.904,-0.027],[0.007,1.851,0.003],[0.034,1.818,0.045]],"Head",HAIR_LIGHT)
