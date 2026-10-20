# Moria: player manual

You are an adventurer going down through a dungeon that is generated again for every run. You explore, fight,
loot, and keep going until you die or reach the end. There is no going back up.

## The title screen

- **New game** starts a run.
- **Load game** continues a saved game. With several saves it shows a list, newest first.
- **Options** has fullscreen, the volumes, the screen effects switch, the **difficulty** (easy: monsters 25% weaker and 3
  rests, normal, hard: monsters 35% tougher and 1 rest) and the **tips** switch (one-time hints in the log).
- **Morgue** lists your finished runs: character, floor, level, enemies slain, what killed you and when. At the top
  are your totals and the **unlocks**: reach floor 3 for 40 more starting gold, open 8 chests for 3 more lockpicks,
  slay 50 monsters to start with a healing potion, reach floor 10 for one more rest. Unlocks help every new run.
- **Manual** is this manual.
- **Exit** closes the game.

## Starting

1. Choose a class (arrow keys, Enter).
2. Type a name.
3. Choose your first feats and spells if your class has any.

| Class | Starts with | Good at |
|---|---|---|
| Fighter | 10 HP | Combat, armor, physics |
| Paladin | 10 HP | Combat, armor, willpower, divine spells |
| Ranger | 10 HP | Combat, physics, perception, nature spells |
| Thief | 8 HP | Combat, perception, thievery |
| Bard | 8 HP | Enchantment, willpower, thievery |
| Cleric | 8 HP | Evocation, willpower, divine spells |
| Druid | 8 HP | Divination, abjuration, perception, nature spells |
| Mage | 6 HP | Evocation, willpower |

Each class starts with its own kit of weapon, armor, potions and a few other items.

## The screen

- **The map** in the middle. You only see what is near you and in line of sight. Floors are bigger than the
  screen, the view scrolls with you.
- **The log** at the bottom left tells you what happens, turn by turn.
- **The side panel** on the right: level and experience, **HP** (health), **Stam** (stamina), **CA** (armor class,
  how hard you are to hit), **Prot** (damage taken off every hit), **Dmg** and **Hit** (your weapon's damage dice and your attack roll), **Lock**
  (lockpicks), **Gold**, and your resistances.
- A red frame and the words LOW HEALTH appear when you are under 30% health.

## Controls

The game shows the real list on the **H** screen. The usual ones:

| Key | Does |
|---|---|
| Arrow keys | Move one step, walk into an enemy to attack it. **Hold** a key to keep walking (it stops at walls, doors, items and when an enemy is in view) |
| Left click | Walk to a visible cell (stops if an enemy appears) |
| S | Search for hidden doors and traps around you |
| P | Pick up loot under you |
| I | Inventory (equip, wear, drop) |
| K | Character sheet (spend skill points and feats) |
| M / C | Spell list / cast a spell |
| A | Drink a potion |
| R | Read a scroll |
| F | Fire the wielded sling or bow at a target |
| T | Throw a knife, axe, bomb... |
| D | Drop an item |
| Z | Rest |
| O | Auto-explore (any key stops it) |
| Q | Give an item a quick slot, then press 1 to 0 to use it |
| F1 / F5 | Save / load |
| Esc | Options menu |
| F11 or Alt+Enter | Fullscreen |
| H | Controls |
| Tab | Map of the whole floor as far as you have explored it |
| L | Message history (scroll back through the log) |
| Mouse over | A tooltip for monsters, loot, chests and doors you can see |
| F12 | Save a screenshot |

## Gamepad

D-pad or left stick move (hold to keep walking), A confirms, B or Start goes back and opens the menu, X picks up,
Y opens the inventory, LB the character sheet, RB searches, Select the map. Left trigger drinks a potion and
right trigger casts a spell.

## Exploring

- Doors open when you walk into them. Some are **locked** and need a lockpick (you can fail, and picks run out).
- **Hidden doors and traps** are found by searching (S), and sometimes by luck as you walk. Searching costs a turn.
  Traps come in six kinds, tinted differently once revealed: spike (damage), pit (more damage), poison gas (poison),
  alarm (wakes every monster on the floor), snare (roots you for 3 turns) and fire (fire damage). Each area has its own mix.
- **Chests** hold loot. Some are locked and need lockpicks.
- **Stairs**: the game asks if you want to go to the next floor. After you do, a shadow force blocks the way back.
  The game saves for you on every new floor, and when you close the window. The next floor's title card tells
  you what you did on the last one.
- **Gold and lockpicks** are picked up when you walk onto them.
- **Seeds**: every run has a seed (Esc shows it). Start the game with `--seed=12345` to play the same dungeon
  again, or `--seed=daily` for the one everybody gets that day.
- **Vaults** are small sealed rooms behind a hidden or a locked door (search along dead ends and long walls), with a locked
  chest and better loot. Sometimes a trap waits outside the door.
- **Lairs** are rooms with an ordinary door and a sleeping crowd of monsters guarding a chest and loot, with a trap at the door.
- **Merchants** sell things for gold.
- A trip goes through six areas: the Dungeon (10 floors), the Caverns (10), the Troll (1), the Crypt (8, undead), the Mine
  (8, goblins and orcs, spiders) and the Volcano (8, fire imps and magma oozes), then the Dungeon starts again, harder.
  Every area has its own monsters, tint and trap mix.
- The last floor of each area has a **champion**: a guardian that is far tougher than anything before it. It sleeps
  far from where you arrive, and it leaves a hoard of good loot when it falls.

## Fighting

- Monsters are asleep until they come into your view, then they wake up and come for you.
- Armor class (CA) decides if you get hit, Prot reduces the damage that gets through. A hit always does at least 1.
- Fighting, casting and searching spend stamina (Stam).
- Monsters will also attack the creatures you summon, not only you.
- Killing monsters gives experience. A level up gives **skill points** and **feat points**: open the character
  sheet (K) to spend them.

## Food, light and ammo

- Food runs down every turn. When you get hungry a ration is eaten for you (600 turns of food). With no food left you
  starve, one point of damage every few turns. Resting costs 150 food and some torch. Easy hunger is slower, Hard faster.
- A torch burns 400 turns and is replaced from your spare torches. It dims near the end, and with none left you only
  see four steps around you.
- The side panel shows `Food` (turns left, spare rations), `Light` (torch turns left, spare torches) and `Ammo`.
- Every floor holds rations and torches, and sometimes arrows or sling stones. Walk over them to take them.
- A sling (1d6) or shortbow (1d8) is fired with F: it asks for a target and uses one stone or arrow, a third of which
  you get back. In melee they only bash for 1d2. Rangers start with a shortbow and 20 arrows.

## Magic, scrolls and potions

- Spells come in schools: Evocation, Enchantment, Divination, Abjuration and Conjuration. Your class decides
  which school you are good at and which spell list you use (arcane, divine or nature).
- A spell has a few uses until you rest.
- Scrolls are single-use spells and potions are drunk once. Both are listed in your inventory.
- Unknown potions and scrolls: a potion you have not tried shows as, say, a "Murky potion", and a scroll as
  "Scroll labelled ZELGO MER". Drinking or reading one teaches you that kind for the rest of the run, and every
  one you carry gets its real name. The flavors are reshuffled every run. Your class kit and anything a merchant
  sells are already known. Some potions are bad (poison, clumsiness, darkness), so try new ones when you are safe.
- Potions: healing, antidote, stoneskin, invisibility, wounds (full heal), might (double weapon damage), brilliance
  (level 1 spells cost no use), regeneration (1 HP a turn), insight (shows traps), fire ward.
- Throwing items (knives, axes, javelins, bombs, holy water) hit from a distance. Pick a target with the left and
  right arrow keys, Enter to throw, Esc to cancel.

## Resting

You start with **2 rests**. Resting (Z) restores your health, stamina and spell uses and clears statuses, but it
sends your summoned allies away, and you cannot rest while hostile creatures are on the floor.

## Death

When your health reaches zero the game shows what killed you and how far you got (floor, level, enemies slain, turns,
gold), adds the run to the **Morgue**, and returns to the title screen. Your last save is still there: choose
**Load game** on the title screen.

## Options (Esc)

Fullscreen, music volume, sound effects volume, screen effects (damage numbers, hit flash, screen shake, low health
frame: turn them off if you prefer calm), controls, save, and quit to title (asks twice).
