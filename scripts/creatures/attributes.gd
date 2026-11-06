extends RefCounted

const CREATURE := preload("res://scripts/creatures/companion.gd")
const TREE := preload("res://scripts/creatures/development.gd")
enum { LIFE, ESSENCE, FORCE, FINESSE, SHELL }
const NAMES := ["Dirim", "Öz", "Kudret", "Sezgi", "Direnç"]
const HINT := ["Azami can", "Teknik kaynağı", "Temel vuruş gücü", "Kritik birikimi", "Hasar azaltma"]
const SPECIAL_COST := 4
const ACTIVE_COST := 6
const GUARD_RESTORE := 4
const UNTUNED := [0,0,0,0,0]
const RESERVE := [10,15,9]
const INSTINCT := [26,21,17]
const HIDE := [2,1,5]

static func remaining(level: int, spent: Array) -> int:
	var points := 2*level
	for amount: int in spent:
		points -= amount
	return points

static func valid(level: int, spent: Variant) -> bool:
	if not spent is Array or spent.size() != NAMES.size():
		return false
	for value in spent:
		if not (value is float or value is int):
			return false
		if not is_finite(float(value)) or value < 0 or value > 2*level or value != int(value):
			return false
	return remaining(level,spent) >= 0

# Derived values are shared by the journal, encounter setup and the damage resolver.
static func profile(species: int, level: int, spent: Array, known: Array) -> Dictionary:
	var hp := CREATURE.max_hp(species,level)+4*int(spent[LIFE])+TREE.bonus(species,known,"hp")
	var essence := int(RESERVE[species])+level+2*int(spent[ESSENCE])
	var force := CREATURE.damage(species,level,species,false)+int(spent[FORCE])+TREE.bonus(species,known,"power")
	var finesse := int(INSTINCT[species])+2*int(spent[FINESSE])
	var shell := int(HIDE[species])+int(spent[SHELL])
	var reduction := 100.0*shell/(25.0+shell)
	var score := roundi(hp*0.45+essence*0.7+force*2.2+finesse*0.5+shell*1.3+known.size()*2)
	return {"hp":hp,"essence":essence,"force":force,"finesse":finesse,"reduction":reduction,"score":score}

static func strike_damage(profile_data: Dictionary, element: int, defender: int, bonus: int) -> int:
	return maxi(1,roundi((int(profile_data.force)+bonus)*CREATURE.potency(element,defender)))

static func mitigate(damage: int, profile_data: Dictionary) -> int:
	return maxi(1,roundi(damage*(1.0-float(profile_data.reduction)/100.0)))

# Excess charge carries forward. Multiple thresholds still reward high-Sezgi builds.
static func critical(damage: int, charge: int) -> int:
	return damage + roundi(damage*0.5*floori(charge/100.0))
