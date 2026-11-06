extends RefCounted

# A path's order defines its prerequisites. The final mastery excludes the other mastery.
const TITLES := [["Pusu","Kökbağı"],["Taşkın","Gelgit"],["Kırıcı","Hisar"]]
const PATHS := [
	[
		[
			{"id":"claw","name":"Bileyli Pençe","detail":"Tüm saldırılara +3 hasar.","power":3},
			{"id":"pounce","name":"Hilal Pençesi","detail":"Element vuruşu. Rakip yarı candaysa +8 hasar.","strike":4,"execute":8},
			{"id":"ambush","name":"Pusu Ustası","detail":"Her savaşın ilk turunda +10 saldırı hasarı.","opener":10}
		],[
			{"id":"bark","name":"Canlı Kabuk","detail":"Azami can +9.","hp":9},
			{"id":"sap","name":"Öz Sömürüsü","detail":"Element vuruşu. Verilen hasarın yarısı kadar iyileş.","strike":1,"drain":0.5},
			{"id":"bloom","name":"Yenilenme","detail":"Her rakip saldırısından önce 4 can yenile.","regen":4}
		]
	],[
		[
			{"id":"current","name":"Hızlı Akıntı","detail":"Her savaşın ilk turunda +6 saldırı hasarı.","opener":6},
			{"id":"torrent","name":"Dalga Kıranı","detail":"Element vuruşu. Ağır saldırı turunda +10 hasar.","strike":4,"counter":10},
			{"id":"undertow","name":"Dip Akıntısı","detail":"Her element saldırısına +5 hasar.","power":5}
		],[
			{"id":"dew","name":"Çiy Örtüsü","detail":"Savunma kullandığında 5 ek can yenile.","guard_heal":5},
			{"id":"tide","name":"Gelgit Örtüsü","detail":"10 can yenile ve bu tur gelecek hasarı 6 azalt.","heal":10,"shield":6},
			{"id":"ocean","name":"Derin Su","detail":"Azami can +14. Alınan hasar 2 azalır.","hp":14,"armor":2}
		]
	],[
		[
			{"id":"fault","name":"Fay Hattı","detail":"Tüm saldırılara +2 hasar.","power":2},
			{"id":"quake","name":"Sismik Kırılma","detail":"Element vuruşu. Güçlü darbe +9, geri tepme 3 can.","strike":9,"recoil":3},
			{"id":"pressure","name":"Basınç Çekirdeği","detail":"Yarı can ve altında saldırı hasarı +9.","last_stand":9}
		],[
			{"id":"granite","name":"Granit Deri","detail":"Alınan hasar 2 azalır (en az 1).","armor":2},
			{"id":"bastion","name":"Bazalt Siper","detail":"Bu tur gelen hasarı 8 azalt, rakibe 7 hasar yansıt.","shield":8,"reflect":7},
			{"id":"citadel","name":"Dağ Yüreği","detail":"Azami can +18. Savunmada 3 ek can yenile.","hp":18,"guard_heal":3}
		]
	]
]
const COST := [1,2,2]

static func points(level: int, learned: Array, species: int) -> int:
	var earned := mini(level,8)
	for branch: Array in PATHS[species]:
		for depth in range(branch.size()):
			if branch[depth].id in learned:
				earned -= COST[depth]
	return earned

static func available(species: int, level: int, learned: Array, path: int, depth: int) -> bool:
	var branch: Array = PATHS[species][path]
	if branch[depth].id in learned or points(level,learned,species) < COST[depth]:
		return false
	if depth > 0 and branch[depth-1].id not in learned:
		return false
	return depth < 2 or PATHS[species][1-path][2].id not in learned

static func bonus(species: int, learned: Array, stat: String) -> int:
	var amount := 0
	for branch: Array in PATHS[species]:
		for item: Dictionary in branch:
			if item.id in learned:
				amount += int(item.get(stat,0))
	return amount

static func valid_history(species: int, level: int, history: Variant) -> bool:
	if not history is Array or history.size() > 5:
		return false
	var acquired: Array = []
	for entry in history:
		var accepted := false
		for path in range(2):
			for depth in range(3):
				if PATHS[species][path][depth].id == entry and available(species,level,acquired,path,depth):
					acquired.append(entry)
					accepted = true
		if not accepted:
			return false
	return true
