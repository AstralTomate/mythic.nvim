<div align="center">

# mythic.nvim

[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-%3E=0.8-57A143?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue?style=flat-square&logo=lua)](https://lua.org)

**Mythic Game Master Emulator for Neovim** — on-the-fly RPG improvisation tools at your fingertips.

[Overview](#overview) • [Commands](#commands) • [Installation](#installation) • [Quick start](#quick-start) • [Examples](#examples) • [Tables reference](#tables-reference) • [Acknowledgments](#acknowledgments)

</div>

A Neovim plugin that brings the [Mythic Game Master Emulator 2nd Edition](https://www.drivethrurpg.com/en/product/422929/mythic-game-master-emulator-second-edition) by Tana Pigeon into your editor. Designed for tabletop RPG game masters who want randomized story elements, NPC actions, scene outcomes, and dice resolution without leaving their terminal.

## Overview

Mythic is a game master emulator that lets you run RPGs without a prepared scenario. It uses randomized tables and dice rolls to generate story elements, NPC actions, and scene outcomes on the fly. Perfect for one-shots, creative brainstorming, or when you need to improvise.

This plugin implements the core systems from the rulebook:

- **Fate Check** — 2d10 resolution with odds modifiers and Chaos Factor
- **Fate Chart** — 1d100 percentile alternative resolution
- **Scene Test** — Determines if a scene is Expected, Altered, or Interrupted
- **Random Event Focus** — Generates context for random events
- **Scene Adjustment** — Modifies the current scene
- **Random Tables** — 45+ themed tables for locations, characters, creatures, items, and more
- **Chaos Factor** — Manages session randomness (1–9)

## Features

- **Zero dependencies** — Pure Lua, works with any plugin manager.
- **Floating window output** — Results displayed in a centered window with clipboard and paste support.
- **Tab completion** — Built-in completions for odds levels and table names.
- **Random Event detection** — Automatic detection when doubles trigger random events per Mythic rules.

## Installation

<details open>
<summary><b>lazy.nvim</b></summary>

```lua
{ 'Django0033/mythic.nvim' }
```

</details>

<details>
<summary><b> packer.nvim</b></summary>

```lua
use 'Django0033/mythic.nvim'
```

</details>

<details>
<summary><b>vim-plug</b></summary>

```vim
Plug 'Django0033/mythic.nvim'
```

</details>

## Quick start

```vim
" Set the Chaos Factor to start your session
:MythicChaos 5

" Test a scene
:MythicSceneTest

" Roll a fate check
:MythicFateCheck 50/50

" Generate random table content
:MythicTables Locations
```

All commands display results in both the message area and a centered floating window.

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| `y` | Copy result to clipboard and close |
| `<CR>` / `<Enter>` | Copy to clipboard, paste at cursor, and close |
| `q` / `Esc` | Close window |

> [!TIP]
> Pressing `y` copies to both the system clipboard (`+` register) and Vim's default register (`"` register).

### Characters & Threads list window keys

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate entries |
| `a` | Add a new entry (prompts for name/text) |
| `d` | Duplicate selected entry (up to ×3) |
| `r` | Roulette roll — animated weighted random pick |
| `x` | Remove one count from the selected entry (deletes at ×1) |
| `q` / `Esc` | Close window |

Entries can appear up to three times, reflecting Mythic's weight mechanic for random NPC/thread selection. The `[x2]` / `[x3]` suffix shows the current count.

### Where the lists live

The two lists are stored in a plain markdown document called `Mythic Lists.md`, which sits in the same folder as the campaign's journal:

```
1. Journals/
└── Aino the singing mage/
    ├── Aino - Journal.md
    ├── Mythic Lists.md      ← ## Threads / ## Characters
    └── Bestiary.md
```

The document is the single source of truth — edit it by hand in Neovim, Obsidian or anything else, and the list windows pick the change up on the next open:

```markdown
## Threads

- Find out who poisoned the well (x2)
- Escape the sunken city

## Characters

- Sister Vell (x3)
- The Tinker
```

A missing `(xN)` means ×1, and only the last bracket group counts — so `- Doctor Strange (Mentor, mostly absent) (x2)` keeps the note and reads as ×2. `{x2}` and `[x2]` are accepted on read as well. Repeating a line has the same effect as a weight, mirroring Mythic's physical lists where you write a name three times — `- The Tinker` three times is read as `- The Tinker (x3)`. Weights are clamped to ×3.

> [!NOTE]
> **Campaign scope:** The campaign is simply the folder of the file you are editing. If that folder or one above it already has a `Mythic Lists.md`, that document is used — so notes in subfolders share their campaign's lists, and each campaign folder keeps its own.
>
> **Starting a new campaign:** Run `:MythicLists` to create the document with empty sections and open it. Adding a character or thread creates it too, so there is nothing to initialize up front.
>
> **Other content is safe:** Only the `## Threads` and `## Characters` sections are rewritten. Frontmatter, other headings and prose inside those sections are preserved, so `Mythic Lists.md` can hold your own notes as well.
>
> To use a different file name, set `vim.g.mythic_lists_file = "Mythic.md"`.
>
> Use `:MythicCharacterRoll` / `:MythicThreadRoll` to roll without opening the list window.

## Commands

| Command | Description |
|---------|-------------|
| `:MythicTables <table>` | Random entries from a table (e.g. `:MythicTables Locations`) |
| `:MythicChaos` | Show current Chaos Factor |
| `:MythicChaos +` | Increase Chaos Factor by 1 |
| `:MythicChaos -` | Decrease Chaos Factor by 1 |
| `:MythicChaos <n>` | Set Chaos Factor to n (1–9) |
| `:MythicFateCheck [odds]` | 2d10 fate check (default: 50/50) |
| `:MythicFateChart [odds]` | 1d100 percentile fate chart |
| `:MythicSceneTest` | Scene continuity test |
| `:MythicEventFocus` | Random event focus |
| `:MythicSceneAdjustment` | Scene adjustment |
| `:MythicLists [dir]` | Open the campaign's `Mythic Lists.md`, creating it if needed |
| `:MythicCharacterAdd <name>` | Add a character to the Characters list |
| `:MythicCharacterList` | Open the Characters list window |
| `:MythicCharacterRoll` | Weighted random pick from the Characters list |
| `:MythicThreadAdd <text>` | Add a thread to the Threads list |
| `:MythicThreadList` | Open the Threads list window |
| `:MythicThreadRoll` | Weighted random pick from the Threads list |

## Examples

### Running a Fate Check

```vim
:MythicFateCheck Likely
" Output: Yes [8+2+2=12]
```

Results include the dice breakdown and automatic random event detection when doubles occur.

### Testing Scene Continuity

```vim
:MythicSceneTest
" Output: Expected Scene [7 vs CF 5]
```

### Generating Scene Details

```vim
:MythicTables Locations
" Output: Locations -> 15 Abandoned / 42 Dangerous

:MythicTables Descriptors
" Output: Descriptors -> 33 Dark / 87 Foreboding
```

### Handling a Random Event

```vim
:MythicEventFocus
" Output: Dice roll: 35 - NPC Action

:MythicSceneAdjustment
" Output: Dice roll: 4 - Increase an Activity
```

### Floating Window

When you run any command, a floating window appears with the result:

```
┌────────────────── Mythic GME ──────────────────┐
│                                                  │
│  Exceptional Yes [8+2+2=12]                     │
│  Random Event!                                   │
│                                                  │
│  [y] Copy [CR] Paste [q] Close                  │
└──────────────────────────────────────────────────┘
```

Press `q` or `Esc` to close the window.

## Chaos Factor

The Chaos Factor (CF) represents the level of randomness in your game. Higher CF means more random events and scene interruptions.

| CF | Effect | Modifier |
|----|--------|----------|
| 1 | Very Predictable | –5 |
| 2–3 | Predictable | –4 to –1 |
| 4–6 | Normal (default: 5) | 0 |
| 7–8 | Unpredictable | +1 to +2 |
| 9 | Chaotic | +5 |

## Odds Reference

When using `:MythicFateCheck` or `:MythicFateChart`, you can specify the odds level:

| Odds | Modifier |
|------|----------|
| Impossible | –5 |
| Nearly Impossible | –4 |
| Very Unlikely | –2 |
| Unlikely | –1 |
| 50/50 | 0 |
| Likely | +1 |
| Very Likely | +2 |
| Nearly Certain | +4 |
| Certain | +5 |

> [!TIP]
> Tab completion is available for all odds levels. Type `:MythicFateCheck ` and press `<Tab>` to cycle through options.

## Tables reference

Use `:MythicTables <name>` to access themed random tables. Each table contains 100 entries in two randomly selected elements.

| Table | Description |
|-------|-------------|
| `Actions` | Action verbs (2 elements) |
| `Descriptors` | Descriptive words (2 elements) |
| `AdventureTone` | Adventure themes and moods |
| `AlienSpecies` | Alien species types |
| `AnimalActions` | Animal/creature behaviors |
| `ArmyDescriptors` | Army/military descriptors |
| `CavernDescriptors` | Cave/cavern attributes |
| `Characters` | Character types and traits |
| `CharacterActionsCombat` | Combat actions |
| `CharacterActionsGeneral` | General actions |
| `CharacterAppearance` | Physical appearance |
| `CharacterBackground` | Backstory elements |
| `CharacterConversations` | Conversation types |
| `CharacterDescriptors` | Character traits |
| `CharacterIdentity` | Identity/role |
| `CharacterMotivations` | NPC motivations |
| `CharacterPersonality` | Personality traits |
| `CharacterSkills` | Skill types |
| `CharacterTraitsFlaws` | Traits and flaws |
| `CityDescriptors` | City attributes |
| `CivilizationDescriptors` | Civilization types |
| `CreatureAbilities` | Creature abilities |
| `CreatureDescriptors` | Creature traits |
| `CrypticMessage` | Mysterious messages |
| `Curses` | Curse types |
| `DomicileDescriptors` | Home/dwelling descriptors |
| `DungeonDescriptors` | Dungeon attributes |
| `DungeonTraps` | Trap types |
| `ForestDescriptors` | Forest/woods attributes |
| `Gods` | Deity types |
| `Legends` | Legendary elements |
| `Locations` | Location descriptors |
| `MagicItemDescriptors` | Magic item traits |
| `MutationDescriptors` | Mutation types |
| `Names` | Name syllables |
| `NobleHouse` | Noble house attributes |
| `Objects` | Object/item types |
| `PlotTwists` | Plot twist ideas |
| `Powers` | Supernatural powers |
| `ScavengingResults` | Loot/scavenging results |
| `Smells` | Smell descriptors |
| `Sounds` | Sound descriptors |
| `SpellEffects` | Magic effect types |
| `StarshipDescriptors` | Sci-fi ship attributes |
| `TerrainDescriptors` | Terrain types |
| `UndeadDescriptors` | Undead creature traits |
| `VisionsDreams` | Dream/vision content |

> [!TIP]
> Tab completion is also available for table names. Type `:MythicTables ` and press `<Tab>` to see all options.

## TODO

Features planned based on the [Mythic GME 2 rulebook](https://www.drivethrurpg.com/en/product/422929/mythic-game-master-emulator-second-edition):

- [ ] **NPC Tools** — NPC stat generation, behavior tables, identity, motivations
- [x] **Adventure Journal** — Characters and Threads lists with interactive floating window (add, duplicate ×3, remove)
- [ ] **Keyed Scenes** — Trigger-based scene events (counter, random, timer, conditional)
- [ ] **Prepared Adventures** — Scaling tools for running published modules solo with Diminisher Value
- [ ] **Thread Progress Track** — Progress tracking toward thread resolution
- [ ] **Peril Points** — Narrative risk counter for travel/investigation
- [ ] **Chaos Flavors** — Mid-Chaos, Low-Chaos, and No-Chaos variants
- [ ] **Initial Scene Generator** — 4W (Who, What, Where, Why) with Meaning Tables

## Acknowledgments

- **Tana Pigeon** — Creator of the [Mythic Game Master Emulator](https://www.drivethrurpg.com/en/product/422929/mythic-game-master-emulator-second-edition), the system this plugin brings to Neovim. Check out her work and support her on [Patreon](https://www.patreon.com/mythicgme).
- **John Stephens** — For contributing the `MythicChaos`, `MythicFateCheck`, and `MythicSceneTest` commands.
- **All contributors** — For helping improve this plugin.
