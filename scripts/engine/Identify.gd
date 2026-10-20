extends Reference
class_name Identify

# Unknown potions and scrolls. A potion kind shows as "Murky potion" and a scroll kind as "Scroll labelled
# ZELGO MER" until it is used (or sold by a merchant, or part of the starting kit). Which flavor belongs to
# which kind is shuffled from the run seed, so it is the same all run and different every run.

const POTION_FLAVORS = ["Murky", "Fizzing", "Pink", "Golden", "Cloudy", "Bubbling", "Silver", "Smoky", "Ruby",
	"Emerald", "Violet", "Oily", "Milky", "Amber", "Frothy", "Inky"]
const SCROLL_LABELS = ["ZELGO MER", "FOOBIE BLETCH", "ELBIB YLOH", "VERR YED HORRE", "HACKEM MUCHE", "DAIYEN FOOELS",
	"KERNOD WEL", "ELAM EBOW", "XIXAXA XOXAXA", "THARR", "JUYED AWK", "PRATYAVAYAH", "NR 9", "ABRA KEDABRA", "LEP GEX VEN", "ANDOVA BEGARIN"]

static func reset():
	GLOBAL.known = {"potion": {}, "scroll": {}}

static func learnEverything():
	for idx in Data.potions.keys():
		GLOBAL.known["potion"][idx] = true
	for idx in Data.scrolls.keys():
		GLOBAL.known["scroll"][idx] = true

static func isKnown(kind: String, idx: int) -> bool:
	return GLOBAL.known[kind].has(idx)

static func trueName(kind: String, idx: int) -> String:
	return Data.potions[idx][Data.PO_NAME] if kind == "potion" else Data.scrolls[idx][Data.SC_NAME]

# The flavor of a kind in this run: a shuffle of the pool, seeded by the run seed
static func flavorName(kind: String, idx: int) -> String:
	var pool = (POTION_FLAVORS if kind == "potion" else SCROLL_LABELS).duplicate()
	var rng = RandomNumberGenerator.new()
	rng.seed = int(Ref.game.runSeed) * 31 + (7 if kind == "potion" else 13)
	for i in range(pool.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var swap = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var flavor = pool[idx % pool.size()]
	return flavor + " potion" if kind == "potion" else "Scroll labelled " + flavor

static func displayName(kind: String, idx: int) -> String:
	if isKnown(kind, idx):
		return trueName(kind, idx)
	return flavorName(kind, idx)

# Learn a kind. Every item of that kind that exists gets its real name.
static func learn(kind: String, idx: int, announce: bool = false):
	if isKnown(kind, idx):
		return
	GLOBAL.known[kind][idx] = true
	var itemType = GLOBAL.PO_TYPE if kind == "potion" else GLOBAL.SC_TYPE
	for id in GLOBAL.items.keys():
		var item = GLOBAL.items[id]
		if item[GLOBAL.IT_TYPE] == itemType and item[GLOBAL.IT_BASE] == idx:
			item[GLOBAL.IT_NAME] = trueName(kind, idx)
	if announce and is_instance_valid(Ref.game) and Ref.ui != null and not GeneralEngine.isFaking:
		Ref.ui.write(Ref.ui.color("It was " + Utils.addArticle(trueName(kind, idx)) + "!", "yellow"))
