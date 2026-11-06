extends RefCounted

# Center and half-axes of shallow basins. The terrain and water share these bounds.
const POOLS := [Vector4(12,-14,5.4,3.4), Vector4(-14,3,4.6,3.1), Vector4(17,-27,3.8,2.7)]
const HABITATS := [Vector2(-5,-4), Vector2(8,-12), Vector2(-9,-21)]
const RADII := [3.4, 3.5, 4.0]

static func relief(x: float, z: float) -> float:
	var ridge := 2.7 * exp(-pow((z + 21.0) / 11.0, 2.0))
	return (ridge + 1.4 * sin(x * 0.075) * sin(z * 0.055)) * smoothstep(7,17,Vector2(x,z).length())

static func pool_distance(p: Vector2, pool: Vector4) -> float:
	var uv := (p - Vector2(pool.x,pool.y)) / Vector2(pool.z,pool.w)
	return uv.length() + 0.045 * sin(uv.angle()*3.0) * minf(uv.length(),1.0)

static func height(x: float, z: float) -> float:
	var natural := relief(x,z)
	for pool: Vector4 in POOLS:
		var d := pool_distance(Vector2(x,z),pool)
		if d < 1.45:
			var bed := relief(pool.x,pool.y) - 0.38 + 0.65 * smoothstep(0.55,1.15,d)
			return lerpf(bed,natural,smoothstep(1.14,1.45,d))
	return natural

static func populate(world: Node3D) -> void:
	for pool: Vector4 in POOLS:
		var water := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(pool.z,pool.w)*2.14
		water.mesh = plane
		water.position = Vector3(pool.x,relief(pool.x,pool.y)-0.035,pool.y)
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/ground/meadow_water.gdshader")
		water.material_override = material
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(water)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21047
	var scattered: Array[Transform3D] = []
	var herbs: Array[Transform3D] = []
	for patch in range(830):
		var center := Vector2(rng.randf_range(-49,49),rng.randf_range(-49,37))
		for tuft in range(12):
			var p := center + Vector2(rng.randfn(0,1.4),rng.randfn(0,1.4))
			var trail_x := 3.0*sin(clampf((3-p.y)/47,0,1)*TAU)
			if (absf(p.x-trail_x)<1.95 and p.y<4 and p.y>-44) or p.distance_to(Vector2(0,3))<4.8:
				continue
			var flooded := false
			for pool: Vector4 in POOLS:
				if pool_distance(p,pool)<0.93:
					flooded = true
					break
			if flooded:
				continue
			var scale_factor := rng.randf_range(0.65,1.55)
			var basis_xf := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_factor)
			var xf := Transform3D(basis_xf,Vector3(p.x,height(p.x,p.y)-0.035,p.y))
			if patch % 6 == 0:
				herbs.append(xf)
			else:
				scattered.append(xf)
	# Taller plants mark the three encounter grounds from the trail.
	for zone in range(HABITATS.size()):
		for i in range(110):
			var offset := Vector2.from_angle(rng.randf()*TAU) * sqrt(rng.randf()) * float(RADII[zone])
			var point: Vector2 = HABITATS[zone] + offset
			if POOLS.any(func(pool): return pool_distance(point,pool)<0.95):
				continue
			var tuft_scale := Vector3(1.4,2.0 if zone == 1 else 1.35,1.4)
			var xf := Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(tuft_scale),Vector3(point.x,height(point.x,point.y)-0.035,point.y))
			herbs.append(xf)
	_batch(world,scattered,false)
	_batch(world,herbs,true)

static func _batch(world: Node3D, transforms: Array[Transform3D], herb: bool) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(5):
		var dir := Vector3(cos(i*2.4),0,sin(i*2.4))
		var foot := dir*0.14
		var half_width := Vector3(-dir.z,0,dir.x)*(0.08 if herb else 0.047)
		var tip := foot+dir*(0.24 if herb else 0.14)+Vector3.UP*(0.37+0.06*sin(i*1.3))
		var middle := foot.lerp(tip,0.54) - dir*0.035
		var left := foot-half_width
		var right := foot+half_width
		var mid_left := middle-half_width*0.58
		var mid_right := middle+half_width*0.58
		for v: Vector3 in [left,mid_left,right,right,mid_left,mid_right,mid_left,tip,mid_right]:
			tool.set_color(Color(v.y/tip.y,1.0 if herb else 0.0,0.0))
			tool.add_vertex(v)
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/ground/meadow_grass.gdshader")
	tool.set_material(material)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = tool.commit()
	batch.instance_count = transforms.size()
	for i in range(transforms.size()):
		batch.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)
