extends Node

# What each potion does. Was an embedded script that only knew the potion of healing: the other six
# potions were named and described but did nothing when drunk.

func applyEffect(entity, potion):
	match potion:
		Data.PO_HEALING:
			healingPotion(entity)
		Data.PO_ANTIDOTE:
			StatusEngine.removeStatusType(entity, Data.STATUS_POISON)
			addStatus(entity, Data.STATUS_PROTECT_POISON, 0, 10)
		Data.PO_STONESKIN_1:
			addStatus(entity, Data.STATUS_PROTECTED, 2, 15)
		Data.PO_INVISIBILITY:
			addStatus(entity, Data.STATUS_INVISIBLE, 0, 25)
		Data.PO_WOUNDS:
			entity.heal(entity.stats.hpMax)
		Data.PO_MIGHT:
			addStatus(entity, Data.STATUS_MIGHT, 0, 10)
		Data.PO_BRILLANCE_1:
			addStatus(entity, Data.STATUS_BRILLIANCE, 0, 3)
		Data.PO_POISON:
			addStatus(entity, Data.STATUS_POISON, 0, 8)
		Data.PO_CLUMSINESS:
			addStatus(entity, Data.STATUS_FUMBLE, 0, 10)
		Data.PO_DARKNESS:
			addStatus(entity, Data.STATUS_BLIND, 0, 8)
		Data.PO_REGENERATION:
			addStatus(entity, Data.STATUS_REGENERATE, 0, 20)
		Data.PO_INSIGHT:
			addStatus(entity, Data.STATUS_REVEAL_TRAPS, 0, 40)
		Data.PO_FIRE_WARD:
			addStatus(entity, Data.STATUS_PROTECT_FIRE, 0, 30)

func addStatus(entity, type: int, rank: int, turns: int):
	StatusEngine.addStatus(entity, SpellEngine.createSpellStatus(type, rank, turns))

func healingPotion(entity):
	var result: float = entity.stats.hpMax * 0.5
	if entity is Character:
		if Skills.hasImprovedPotions():
			result = entity.stats.hpMax * 0.75
	entity.heal(ceil(result))
