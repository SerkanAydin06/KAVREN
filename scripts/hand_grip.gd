extends SkeletonModifier3D

# Sag eli alet sapinin etrafinda yumruk yapar. Hangi animasyon oynarsa oynasin
# (Idle, Run, AxeChop) parmak kemiklerine animasyondan SONRA kivrilma eklenir.
# Mixamo el kemiklerinde +Y parmak yonu, avuc ise +Z tarafidir; +X etrafinda
# pozitif donus parmak ucunu avuca dogru kapatir.

# Kemik adi soneki -> derece. 1 = koke yakin bogum, 3 = uc bogum.
const FINGER_CURL := {
	"righthandindex1": 62.0, "righthandindex2": 78.0, "righthandindex3": 52.0,
	"righthandmiddle1": 68.0, "righthandmiddle2": 82.0, "righthandmiddle3": 52.0,
	"righthandring1": 72.0, "righthandring2": 84.0, "righthandring3": 52.0,
	"righthandpinky1": 76.0, "righthandpinky2": 84.0, "righthandpinky3": 50.0,
}
# Basparmak sapin uzerinden diger parmaklara dogru kapanir.
const THUMB_CURL := {
	"righthandthumb1": Vector3(10.0, 0.0, -18.0),
	"righthandthumb2": Vector3(28.0, 0.0, -10.0),
	"righthandthumb3": Vector3(30.0, 0.0, 0.0),
}

var _bones: Array[int] = []
var _rotations: Array[Quaternion] = []

func _ready() -> void:
	_cache_bones()

func _cache_bones() -> void:
	_bones.clear()
	_rotations.clear()
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for bone_index in range(skeleton.get_bone_count()):
		var key := _compact(String(skeleton.get_bone_name(bone_index)))
		var degrees := Vector3.ZERO
		if FINGER_CURL.has(key):
			degrees = Vector3(float(FINGER_CURL[key]), 0.0, 0.0)
		elif THUMB_CURL.has(key):
			degrees = THUMB_CURL[key]
		else:
			continue
		_bones.append(bone_index)
		_rotations.append(Quaternion.from_euler(degrees * (PI / 180.0)))

func curled_bone_count() -> int:
	return _bones.size()

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _bones.is_empty():
		_cache_bones()
	for i in range(_bones.size()):
		var bone_index := _bones[i]
		skeleton.set_bone_pose_rotation(bone_index, skeleton.get_bone_pose_rotation(bone_index) * _rotations[i])

static func _compact(bone_name: String) -> String:
	var cleaned := bone_name.to_lower().replace(":", "").replace("_", "").replace("-", "").replace(".", "").replace(" ", "")
	return cleaned.trim_prefix("mixamorig")
