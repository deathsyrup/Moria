extends Node

onready var projScene = preload("res://scenes/Projectile.tscn")

func throwAsync(itemId: int):
	MasterInput.setMaster(self)
	var throwing = throwCharacter(itemId)
	if throwing is GDScriptFunctionState:
		yield(throwing, "completed")
	MasterInput.setMaster(Ref.game)

# F: shoot the wielded sling or bow at a target, one stone or arrow a shot
func fireAsync():
	var weapon = Ref.character.inventory.getWeapon()
	if weapon == -1 or not Data.isRanged(GLOBAL.items[weapon][GLOBAL.IT_BASE]):
		Ref.ui.write("You have no sling or bow in your hands. Wield one to fire (F).")
		return
	var base = GLOBAL.items[weapon][GLOBAL.IT_BASE]
	if Supplies.ammoCount() <= 0:
		Ref.ui.write("You are out of " + ("arrows" if base == Data.W_SHORTBOW else "sling stones") + ".")
		return
	if GLOBAL.targets.size() == 0:
		Ref.ui.noTarget()
		return
	MasterInput.setMaster(self)
	Ref.game.set_process_input(false)
	Ref.ui.askForTarget(GLOBAL.targets.keys(), self)
	var coroutineReturn = yield(Ref.ui, "coroutine_signal")
	if coroutineReturn == -1:
		Ref.game.set_process_input(true)
		MasterInput.setMaster(Ref.game)
		return
	var targetId = GLOBAL.targets.keys()[coroutineReturn]
	var entity = instance_from_id(targetId)
	yield(castProjectile(GLOBAL.targets[targetId], Data.throwings[Data.TH_JAVELIN][Data.TH_PROJ]), "completed")
	fireResolve(weapon, base, entity)
	Ref.game.set_process_input(true)
	MasterInput.setMaster(Ref.game)
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	GeneralEngine.newTurn()

func fireResolve(weapon: int, base: int, entity, canRecover: bool = true):
	var inv = Ref.character.inventory
	if Data.ammoFor(base) == Data.SUP_ARROWS:
		inv.arrows -= 1
	else:
		inv.stones -= 1
	inv.refreshSupplies()
	var name = GLOBAL.items[weapon][GLOBAL.IT_NAME]
	Ref.ui.writeCharacterShoot(entity.stats.entityName, name)
	if StatusEngine.getStatusRank(entity, Data.STATUS_REPEL_MISSILES) >= 0 and randf() < 0.15:
		Ref.ui.writeDeflectMonster(entity.stats.entityName)
	else:
		var result = Ref.character.stats.hitDices.roll(Ref.character)
		if result >= entity.stats.ca:
			Ref.ui.writeCharacterStrike(entity.stats.entityName, result, entity.stats.ca)
			entity.takeHit(GLOBAL.items[weapon][GLOBAL.IT_DMG].roll(Ref.character))
		else:
			Ref.ui.writeCharacterMiss(entity.stats.entityName, result, entity.stats.ca)
	# A third of the ammo can be picked up again
	if canRecover and randf() < 0.33:
		if Data.ammoFor(base) == Data.SUP_ARROWS:
			inv.arrows += 1
		else:
			inv.stones += 1
		inv.refreshSupplies()
	Ref.character.fatigue.fightCost()

func throwCharacter(itemId: int):
	var item = Data.throwings[GLOBAL.items[itemId][GLOBAL.IT_BASE]]
	if GLOBAL.targets.size() == 0:
		Ref.ui.noTarget()
		return
	Ref.game.set_process_input(false)
	Ref.ui.askForTarget(GLOBAL.targets.keys(), self)
	var coroutineReturn = yield(Ref.ui, "coroutine_signal")
	if coroutineReturn == -1:
		return
	var targetId = GLOBAL.targets.keys()[coroutineReturn]
	var entity = instance_from_id(targetId)
	yield(castProjectile(GLOBAL.targets[targetId], item[Data.TH_PROJ]), "completed")
	Ref.ui.writeCharacterShoot(entity.stats.entityName, item[Data.TH_NAME])
	if StatusEngine.getStatusRank(entity, Data.STATUS_REPEL_MISSILES) >= 0 and randf() < 0.15:
		Ref.ui.writeDeflectMonster(entity.stats.entityName)
	if item[Data.TH_DMG] != null:
		var result = Ref.character.stats.hitDices.roll(Ref.character)
		if result >= entity.stats.ca:
			Ref.ui.writeCharacterStrike(entity.stats.entityName, result, entity.stats.ca)
			var wpDmg = item[Data.TH_DMG]
			entity.takeHit(GeneralEngine.dmgDice(wpDmg.x, wpDmg.y, 0, Data.DMG_SLASH).roll(Ref.character))
		else:
			Ref.ui.writeCharacterMiss(entity.stats.entityName, result, entity.stats.ca)
	# Was `!= null`: knives, axes and javelins have [] as effect, so applyEffect got an
	# Array and the script error aborted the throw before the turn ended
	if item[Data.TH_EFFECT] is int:
		SpellEngine.applyEffect(Ref.character, instance_from_id(targetId), item[Data.TH_EFFECT], true, 1, 99)
	Ref.character.inventory.throwings.erase(itemId)
	Ref.character.shortcuts.refreshShortcuts(GLOBAL.items[itemId][GLOBAL.IT_STACK])
	Ref.character.fatigue.fightCost()
	Ref.game.set_process_input(true)
	GLOBAL.currentMode = GLOBAL.MODE_NORMAL
	GeneralEngine.newTurn()

func castProjectile(path: Array, projInfo):
	var p = projScene.instance()
	Ref.currentLevel.effects.add_child(p)
	p.init(path, projInfo[Data.PROJ_TYPE], projInfo[Data.PROJ_COLOR])
	yield(p, "end_coroutine")

func castThrowMonster(itemId: int, caster, target, path: Array):
	var item = Data.throwings[itemId]
	if target is Character:
		Ref.ui.writeMonsterShoot(caster.stats.entityName, "you", item[Data.TH_NAME])
	else:
		Ref.ui.writeMonsterShoot(caster.stats.entityName, target.stats.entityName, item[Data.TH_NAME])
	castProjectile(path, item[Data.TH_PROJ])
	if item[Data.TH_DMG] != null:
		if StatusEngine.getStatusRank(target, Data.STATUS_REPEL_MISSILES) >= 0 and randf() < 0.15:
			Ref.ui.writeDeflectCharacter()
		var result = caster.stats.hitDices.roll(caster)
		if result >= target.stats.ca:
			Ref.ui.writeMonsterStrike(caster.stats.entityName, target.stats.entityName, result, target.stats.ca)
			var wpDmg = item[Data.TH_DMG]
			target.takeHit(GeneralEngine.dmgDice(wpDmg.x, wpDmg.y, 0, Data.DMG_SLASH).roll(caster))
		else:
			Ref.ui.writeMonsterMiss(caster.stats.entityName, target.stats.entityName, result, target.stats.ca)
	# Was `!= null`, see throwCharacter
	if item[Data.TH_EFFECT] is int:
		SpellEngine.applyEffect(caster, target, item[Data.TH_EFFECT], true, 1, 99)
