extends Reference
class_name Supplies

# Food and light. Both run down one step per turn: a hungry or dark dungeon is what makes resting and
# dawdling cost something. Rations and torches are found on the floors (and in the starting kit).

const FOOD_MAX = 1500
const FOOD_START = 1000
const RATION_FOOD = 600
const HUNGRY = 200
const WEAK = 60
const REST_FOOD_COST = 150
const LIGHT_MAX = 400
const DARK_RADIUS = 4
const DIM_RADIUS = 6
const DIM_BELOW = 80

# How fast the hunger runs by difficulty (easy, normal, hard)
const HUNGER_RATE = [0.6, 1.0, 1.3]

static func reset():
	var inv = Ref.character.inventory
	inv.food = FOOD_START
	inv.hungerTick = 0.0
	inv.light = LIGHT_MAX
	inv.rations = 2
	inv.torches = 2
	inv.arrows = 0
	inv.stones = 0

# The view radius: a fresh torch lights the full range, a dying one dims, no torch leaves a small circle
static func lightRadius() -> int:
	var inv = Ref.character.inventory
	if inv.light <= 0:
		return DARK_RADIUS
	if inv.light < DIM_BELOW:
		return DIM_RADIUS
	return GLOBAL.VIEW_RANGE

static func tick():
	var c = Ref.character
	var inv = c.inventory
	var before = lightRadius()
	# Light
	if inv.light > 0:
		inv.light -= 1
		if inv.light == DIM_BELOW:
			say("Your torch is burning low.")
		if inv.light <= 0:
			if inv.torches > 0:
				inv.torches -= 1
				inv.light = LIGHT_MAX
				say("Your torch goes out. You light a fresh one.")
			else:
				say("Your torch goes out. You can only see a few steps ahead now.")
	# Food
	inv.hungerTick += HUNGER_RATE[Settings.difficulty]
	while inv.hungerTick >= 1.0:
		inv.hungerTick -= 1.0
		burnFood(1)
	if before != lightRadius():
		Ref.currentLevel.refresh_view()

static func burnFood(amount: int):
	var c = Ref.character
	var inv = c.inventory
	var wasHungry = inv.food <= HUNGRY
	inv.food = int(max(0, inv.food - amount))
	if inv.food <= HUNGRY and inv.rations > 0:
		eat()
		return
	if inv.food <= HUNGRY and not wasHungry:
		say("You are hungry. Find something to eat.")
		Tips.show("hungry", "Rations are eaten for you when you get hungry. Starving hurts. Resting also costs food.")
	if inv.food == WEAK:
		say("You are weak with hunger.")
	if inv.food <= 0:
		# Starving: a point of damage every fifth turn (never kills in the test harness)
		inv.starveTick += 1
		if inv.starveTick >= 5:
			inv.starveTick = 0
			if not GeneralEngine.isFaking:
				c.hitBy = "starvation"
				say("You are starving.")
				c.takeHit(1, 99)

static func eat():
	var inv = Ref.character.inventory
	inv.rations -= 1
	inv.food = int(min(FOOD_MAX, inv.food + RATION_FOOD))
	inv.starveTick = 0
	say("You eat a ration.")

# Resting is a lot of hours: it burns food (and light, the torch is kept lit)
static func rest():
	var inv = Ref.character.inventory
	burnFood(REST_FOOD_COST)
	inv.light = int(max(0, inv.light - 60))

static func say(msg: String):
	if is_instance_valid(Ref.ui) and not GeneralEngine.isFaking:
		Ref.ui.write(Ref.ui.color(msg, "yellow"))

static func ammoCount() -> int:
	var inv = Ref.character.inventory
	var weapon = inv.getWeapon()
	if weapon == -1 or not Data.isRanged(GLOBAL.items[weapon][GLOBAL.IT_BASE]):
		return -1
	return inv.arrows if Data.ammoFor(GLOBAL.items[weapon][GLOBAL.IT_BASE]) == Data.SUP_ARROWS else inv.stones
