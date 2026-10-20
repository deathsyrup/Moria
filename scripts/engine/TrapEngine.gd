extends Node

func trigger(trap: Trap, entity):
	if entity is Character:
		entity.hitBy = trap.trapName
	Ref.ui.writeTriggerTrap(trap.trapName)
	match trap.type:
		Data.TR_DART:
			entity.takeHit(GeneralEngine.dice(1, 4, 0).roll())
		Data.TR_PIT:
			Ref.ui.write("The floor gives way and you fall into a pit.")
			entity.takeHit(GeneralEngine.dice(2, 4, 0).roll())
		Data.TR_GAS:
			Ref.ui.write("A cloud of poison gas hisses out of the floor.")
			addStatus(entity, Data.STATUS_POISON, 6)
		Data.TR_ALARM:
			Ref.ui.write("A shrill alarm rings through the floor, everything wakes up!")
			for m in Ref.currentLevel.monsters.get_children():
				m.awake()
		Data.TR_SNARE:
			Ref.ui.write("A snare closes around your leg.")
			addStatus(entity, Data.STATUS_IMMOBILE, 3)
		Data.TR_FIRE:
			Ref.ui.write("Flames burst out of the wall.")
			var dice = [GeneralEngine.dmgDice(1, 6, 0, Data.DMG_FIRE)]
			entity.takeHit(GeneralEngine.computeDamages(null, dice, entity.stats.resists))
	GLOBAL.trapsByPos.erase(trap.pos)
	trap.disable()

func addStatus(entity, type: int, turns: int):
	StatusEngine.addStatus(entity, SpellEngine.createSpellStatus(type, 0, turns))

func reveal(cell: Vector2):
	if !GLOBAL.trapsByPos.has(cell):
		return
	var trap = GLOBAL.getTrapByPos(cell)
	if !trap.hidden:
		return
	trap.reveal()
	Ref.ui.writeHiddenTrapDetected(trap.trapName)
