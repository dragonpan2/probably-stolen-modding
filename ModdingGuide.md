# Probably Stolen: Modding Guide

中文版本：[ModdingGuide.zh-CN.md](ModdingGuide.zh-CN.md)

This guide covers advanced topics for mod development and assumes you have already read the [README.md](README.md) quick start. For modding community rules, see [CodeOfConduct.md](CodeOfConduct.md). Updating a mod after a game update? Check [APIChanges.md](APIChanges.md) for what changed in the modding API.

> **Disclaimer.** This guide was written with AI assistance and reviewed by the developers. Code snippets and API names were checked against the game's source, but mistakes can slip through. If something here does not match what the game does, trust the game and report the discrepancy through the community channels so the guide can be fixed.

## Table of Contents
- [Probably Stolen: Modding Guide](#probably-stolen-modding-guide)
  - [Table of Contents](#table-of-contents)
  - [Example Projects](#example-projects)
  - [Logging with ModLog](#logging-with-modlog)
  - [Dev Tools](#dev-tools)
  - [Save File Responsibility](#save-file-responsibility)
  - [Supported \& Unsupported Modding Features](#supported--unsupported-modding-features)
    - [✅ Natively supported](#-natively-supported)
    - [❌ Not supported at the moment](#-not-supported-at-the-moment)
  - [Mod Assets](#mod-assets)
    - [Item sprites](#item-sprites)
    - [Sounds](#sounds)
    - [Other textures](#other-textures)
    - [Localization](#localization)
    - [Knowing when your assets are ready](#knowing-when-your-assets-are-ready)
  - [Hook Points](#hook-points)
    - [Subscribing to a hook](#subscribing-to-a-hook)
    - [Adding items through the item directory hook](#adding-items-through-the-item-directory-hook)
    - [Available hooks](#available-hooks)
  - [Loot Tables](#loot-tables)
    - [Weights](#weights)
    - [Editing tables from code](#editing-tables-from-code)
    - [Editing tables with JSON files](#editing-tables-with-json-files)
    - [Reacting to rolls](#reacting-to-rolls)
    - [Inspecting tables in the console](#inspecting-tables-in-the-console)
  - [Saving Mod Data](#saving-mod-data)
  - [Custom UI](#custom-ui)
  - [Harmony Patches](#harmony-patches)
    - [Patches are applied automatically](#patches-are-applied-automatically)
    - [Postfix: run code after the original](#postfix-run-code-after-the-original)
    - [Prefix: run code before the original](#prefix-run-code-before-the-original)
    - [Finalizer: run code even when the original throws](#finalizer-run-code-even-when-the-original-throws)
    - [Transpiler: rewrite the original method's IL (advanced)](#transpiler-rewrite-the-original-methods-il-advanced)
  - [Troubleshooting](#troubleshooting)

---

## Example Projects

📁 Full example mod projects are included in this repository alongside the guide. They are complete, buildable mods you can open, study, and adapt. Use them as a reference whenever a snippet here doesn't give you enough context to see how the pieces fit together as a whole project.

---

## Logging with ModLog

Use `ModLog` instead of `Debug.Log` so your messages are automatically prefixed with your mod's name. This makes it easy for players and other mod authors to tell which mod a log line came from when reading the console.

Construct one `ModLog` from the `ModManifest` your mod receives in `Init`, and reuse it:

```csharp
using UnityEngine;

namespace MyMod
{
    public class MyMod : IMod
    {
        private ModLog log;

        public void Init(ModManifest manifest)
        {
            log = new ModLog(manifest);

            log.Log("Mod initialized");           // [My Mod]: Mod initialized
            log.Warning("Something looks odd");   // [My Mod]: Something looks odd  (warning)
            log.Error("Something went wrong");    // [My Mod]: Something went wrong (error)
        }

        public void OnEnable() { }
        public void OnDisable() { }
    }
}
```

The bracketed prefix in console output comes from your manifest's `<Name>`. If you need your mod's ID, version, or other metadata elsewhere in your code, store the `manifest` reference from `Init` and read it from there.

---

## Dev Tools

Probably Stolen ships with two in-game tools that are essential while developing and testing mods.

- 🐛 **Debug Console (`F8`)**: opens a console that displays all log output, including messages from `ModLog`, `Debug.Log`, warnings, and errors. Use this to verify your mod loaded, watch hook points fire, and read stack traces when something goes wrong.
- 🛠️ **Dev Menu (`F9`)**: opens a menu containing many functions useful for mod development and testing, such as spawning items, triggering events, and inspecting game state. Handy for reproducing edge cases without having to play through to them.

---

## Save File Responsibility

Player saves are permanent and belong to the player. As a mod author, you are responsible for how your mod interacts with them.

**Never:**
- Delete save files
- Corrupt saves silently (e.g. writing invalid data that breaks loading)

**If your mod affects saves:**
- Warn players clearly in your mod's description before they install it
- Provide a safe uninstall path: document what the player needs to do before disabling your mod to avoid losing progress

**Rule of thumb:** A player should be able to disable your mod without losing progress unless this is clearly stated upfront.

---

## Supported & Unsupported Modding Features

Not every kind of mod is feasible right now. Before you start a project, check that what you have in mind is on the supported list; otherwise you may hit walls the modding API doesn't currently let you work around.

### ✅ Natively supported

- **Modded items with custom sprites**: add new items to the game, including their artwork
- **Modded customers with custom sprites**: add new customers with their own appearance
- **Modded events**: add new in-game events
- **Loot table edits**: put your items into the game's drop tables, change or remove existing drops, or add whole new tables, from code or from a JSON file ([Loot Tables](#loot-tables))
- **Custom UI**: build your own windows and panels (settings, inspectors, counters) from code, using the game's widgets ([Custom UI](#custom-ui))

### ❌ Not supported at the moment

- **Major changes to existing UI**: restructuring or replacing built-in UI
- **Changes to the store**: modifying the store's behavior or contents
- **Overhaul-style mods**: sweeping reworks that touch many systems at once
- **Modded deals for the Underground Exchange**: adding new deals to the Underground Exchange
- **Special Item**: Inspectable Items and Appraisal Items

Not supported features may be supported in the future.

---

## Mod Assets

Drop image and audio files into named subfolders of your mod folder and the loader picks them up automatically at startup; you don't write any code to load them. Each asset is keyed by its **file name without the extension** (e.g. `health_pack.png` → key `health_pack`).

```
Mods/
└── MyMod/
    ├── manifest.xml
    ├── MyMod.dll
    ├── Textures/
    │   ├── banner.png          → general texture, key "banner"
    │   └── Items/
    │       └── health_pack.png → item sprite, key "health_pack"
    ├── Sounds/
    │   └── ding.wav            → sound, key "ding"
    ├── Localization/
    │   ├── en.csv              → strings for the "en" locale
    │   └── fr.csv              → strings for the "fr" locale
    └── LootTables/
        └── drops.json          → loot table edits, see Loot Tables
```

> ⚠️ **The folder names are exact, and scanning is not recursive.** Item sprites must sit *directly* in `Textures/Items/`; sounds *directly* in `Sounds/`; localization files *directly* in `Localization/`; loot files *directly* in `LootTables/`. A PNG in `Textures/Sprites/` or any nested subfolder is silently ignored. Supported image formats: `.png`, `.jpg`. Supported audio: `.wav`, `.ogg`, `.mp3`. Localization: `.csv`. Loot tables: `.json`.

Each mod logs what it loaded, so you can confirm in the F8 console:

```
[ModLoader] My Mod: 1 texture(s), 1 item sprite(s) loaded
[ModLoader] My Mod: 2 locale(s), 34 localization entries loaded
[ModLoader] My Mod: 1 sound(s) loaded
```

### Item sprites

Item artwork goes in `Textures/Items/` and is imported as pixel art (point filtering, no mip-maps). Bind one to an item with `SetSpriteAndShapeFromMod`, passing your **mod `<ID>`** and the **file-name key**:

```csharp
GameItem item = ItemDirectory.CreateEmptyItem("health_pack");
item.name = "Health Pack";
item.shortDescription = "Restores a bit of health.";
item.SetSpriteAndShapeFromMod("my_mod_id", "health_pack");  // (modId, spriteKey)
```

`SetSpriteAndShapeFromMod` does two things: it sets the item's sprite, and it derives the item's **grid shape** (the cells it occupies in an inventory) from the non-transparent pixels of the image. Transparent areas become empty cells, so an L-shaped drawing yields an L-shaped item. Each inventory cell is `gridSize` pixels square, so size your artwork to the grid (e.g. a 2×1 item at a 64 px grid is a 128×64 image).

> The mod ID is the `<ID>` from your `manifest.xml`, **not** your mod folder name. If the sprite can't be found, you get a console warning and the item falls back to the "unknown" placeholder.

### Sounds

Every file in `Sounds/` is automatically registered with the game's audio system under the identifier **`<modId>:<key>`**, e.g. `ding.wav` in the mod `my_mod_id` becomes `my_mod_id:ding`. Because your sounds go through the game's own audio channels, they respect the player's volume settings and pause state. Never play them through your own `AudioSource`.

Play a sound at any moment (a hook handler, a Harmony patch, your item's logic):

```csharp
ModHelper.PlaySound("my_mod_id", "ding");   // general SFX channel
ModHelper.PlaySound2("my_mod_id", "ding");  // secondary channel (used by verbs like pouring water)
ModHelper.PlaySound3("my_mod_id", "ding");  // third channel (used by gun sounds; stoppable via AudioManager.Instance.StopPlay3())
```

All three return `false` and log a console warning if the sound isn't found. Each channel plays one sound at a time: starting a new sound on a channel cuts off whatever that channel was playing, so use different channels for sounds that may overlap.

You can also give your items their own audio identity. Items carry their sounds as identifier fields (`soundDragStart`, `soundDragEnd`, `soundSelect`, `soundUse`, `soundActivate`, `soundContainerOpen`, `soundContainerClose`, `soundToggle`), and these accept mod identifiers like any built-in one:

```csharp
item.soundDragStart = ModHelper.GetSoundIdentifier("my_mod_id", "leather_drag");
item.soundUse       = ModHelper.GetSoundIdentifier("my_mod_id", "potion_gulp");
```

(To reuse built-in game sounds instead, assign the constants from `AudioHelper`, e.g. `item.soundUse = AudioHelper.EAT`.)

### Other textures

General textures (`Textures/`, outside `Items/`) are loaded into memory, but the game has **no built-in API to display them for you**; they exist for your own code to use. Reach them through `ModLoader.Mods`:

```csharp
var mod = ModLoader.Mods.Find(m => m.Manifest.ID == "my_mod_id");
Texture2D tex = mod.Textures["banner"];
// draw `tex` yourself
```

(The raw `AudioClip`s are also reachable there via `mod.Sounds`, but prefer `ModHelper.PlaySound` so the player's audio settings apply.)

To trigger one at a specific game moment, combine this with a [hook point](#hook-points) or a [Harmony patch](#harmony-patches).

### Localization

Localization is **opt-in**. If your mod is English-only, you can skip this section entirely and assign plain strings (`item.name = "Health Pack";`). A good middle ground: ship just an `en.csv` and use `ModHelper.GetLocalized` anyway; your mod behaves identically, but text tweaks don't need a rebuild and anyone can later contribute a translation by adding one CSV file, with no code changes.

Ship translations as one CSV file per language in `Localization/`, named by **locale code** (`en.csv`, `fr.csv`, ...). The game currently supports these languages, and file names must use these exact codes:

| Language | Code |
|---|---|
| English | `en` |
| French | `fr` |
| German | `de` |
| Russian | `ru` |
| Chinese | `zh` |
| Japanese | `ja` |
| Spanish | `es` |
| Portuguese (Brazil) | `ptBR` |
| Korean | `ko` |
| Italian | `it` |

(A file with any other name is loaded but never resolves. If in doubt, print the current locale code with `ModHelper.GetCurrentLocale().Identifier.Code`.)

Each line is one entry: the key, a comma, then the text. UTF-8, no header row. Blank lines and lines starting with `#` are ignored.

```csv
# en.csv
health_pack_name,Health Pack
health_pack_desc,"Restores health, cures bleeding, and smells faintly of mint."
merchant_line,"She said ""no refunds"" and meant it."
days_left,Expires in {0} day(s)
trade_offer,"{0} offers {1} credits for it."
multi_line,First line\nSecond line
```

Format rules:

- Everything after the **first comma** belongs to the text, so unquoted commas in the text still work. Keys therefore cannot contain commas; stick to letters, digits, and underscores.
- Optionally wrap the text in double quotes (spreadsheet exports do this automatically). Inside quotes, write `""` for a literal `"`.
- Write `\n` for a line break. One entry per line; real line breaks inside a value are not supported.

Read entries with `ModHelper.GetLocalized`. It resolves the current locale first, falls back to `en`, and finally returns the key itself (with a one-time console warning) so a missing translation never crashes or shows blank text:

```csharp
item.name = ModHelper.GetLocalized("my_mod_id", "health_pack_name");
item.shortDescription = ModHelper.GetLocalized("my_mod_id", "health_pack_desc");

// extra arguments are inserted with string.Format: {0} is the first argument, {1} the second, ...
string label = ModHelper.GetLocalized("my_mod_id", "days_left", 3);
// -> "Expires in 3 day(s)"

string offer = ModHelper.GetLocalized("my_mod_id", "trade_offer", clientName, price);
// -> "Vera offers 250 credits for it."
```

> Only numbered `string.Format` placeholders (`{0}`, `{1}`, ...) are supported. Unity's **Smart Strings** (named placeholders, plural rules, `choose()`) are a feature of the game's built-in string tables and are **not** available for mod entries. For plural forms, use separate keys (e.g. `days_left_one` / `days_left_many`) and pick one in code.

Localization files load with the other assets, after `Init`/`OnEnable`. By the time any [hook](#hook-points) fires they are ready, so resolving strings inside your item factories or hook handlers is always safe; calling `GetLocalized` inside `Init`/`OnEnable` is not.

### Knowing when your assets are ready

Assets finish loading **after** `Init`/`OnEnable` run: textures and localization load right after all mods are initialized, and sounds load asynchronously over the following frames. So `mod.Sounds["ding"]` inside `OnEnable` will come up empty. If you need your assets at startup (rather than lazily during gameplay), subscribe to `ModHook.OnModAssetsLoaded`. It fires once per enabled mod when *all* of that mod's textures, item sprites, sounds, and localization entries are in memory:

```csharp
public void OnEnable()  => ModHook.OnModAssetsLoaded += OnAssetsLoaded;
public void OnDisable() => ModHook.OnModAssetsLoaded -= OnAssetsLoaded;

void OnAssetsLoaded(LoadedMod mod)
{
    if (mod.Manifest.ID != "my_mod_id") return; // it fires for every mod, check it's yours
    log.Log($"All assets ready: {mod.Sounds.Count} sound(s), {mod.Sprites.Count} sprite(s)");
}
```

You don't need this for item sprites bound with `SetSpriteAndShapeFromMod` inside `OnModItemDirectoryInit`; sprite lookups there happen during gameplay, long after loading completes.

---

## Hook Points

Hook points are events the game fires at fixed moments: a save loads, a customer is generated, the shutter opens, a tooltip is built, and so on. Subscribing to one lets your code run at that moment **without patching anything**. This is the preferred way to extend the game: it is faster than Harmony and far less likely to break when the game updates. Reach for [Harmony](#harmony-patches) only when no hook covers what you need.

All hooks are C# events on the static `ModHook` class.

### Subscribing to a hook

Subscribe in `OnEnable` and unsubscribe in `OnDisable`. Each handler's signature matches the hook; some pass an argument, some are parameterless:

```csharp
public class MyMod : IMod
{
    private ModLog log;

    public void Init(ModManifest manifest) => log = new ModLog(manifest);

    public void OnEnable()
    {
        ModHook.OnGameLoadedNormal  += OnGameLoaded;
        ModHook.OnShutterOpenedEarly += OnShutterOpened;
    }

    public void OnDisable()
    {
        ModHook.OnGameLoadedNormal  -= OnGameLoaded;
        ModHook.OnShutterOpenedEarly -= OnShutterOpened;
    }

    void OnGameLoaded()    => log.Log("A save just finished loading.");
    void OnShutterOpened() => log.Log("The store just opened.");
}
```

> Unlike `Init`/`OnEnable` (which run at the main menu), hooks fire **during gameplay**: by the time one runs, the game's systems exist, so it is safe to spawn items, read save state, and touch managers.

**Exceptions are isolated.** Each subscriber runs inside its own try/catch: if your handler throws, the error is logged to the console with your mod's name, and other mods' handlers (and the game itself) continue unaffected. This is a safety net, not a license; a logged exception still means your mod is broken, so watch the F8 console for `[ModHook]` errors while developing.

**Ordering tiers.** Many hooks come in tiers so multiple mods can position themselves relative to one another. Pick the tier matching how early or late you need to run:

- Customer generation: `VeryEarly → Early → Normal → Late → VeryLate`
- Game loaded: `Init → Early → Normal → Late`
- Most others: `Early → Late`

If ordering relative to other mods doesn't matter to you, use the `Normal` (or `Early`) tier.

### Adding items through the item directory hook

`OnModItemDirectoryInit` is how you register new items so they can be spawned by ID. It hands you the mod item directory; call `Add(id, factory)` with a function that builds your item:

```csharp
public void OnEnable()  => ModHook.OnModItemDirectoryInit += RegisterItems;
public void OnDisable() => ModHook.OnModItemDirectoryInit -= RegisterItems;

void RegisterItems(ModItemDirectory dir)
{
    dir.Add("health_pack", () =>
    {
        GameItem item = ItemDirectory.CreateEmptyItem("health_pack");
        item.name = "Health Pack";
        item.SetSpriteAndShapeFromMod("my_mod_id", "health_pack");
        return item;
    });
}
```

Once registered, spawn it anywhere with `ModHelper.SpawnItem("health_pack")`.

### Available hooks

Replace `*` with a tier name, e.g. `ModHook.OnGenerateCustomerVeryEarly`, `ModHook.OnShutterClosedLate`.

| Hook | Tiers | Fires when | Handler receives |
|---|---|---|---|
| `OnModItemDirectoryInit` | none | Item directories initialize (register items here) | `ModItemDirectory` |
| `OnGenerateCustomer*` | VeryEarly … VeryLate | A store customer is being generated | `StoreClientManager` |
| `OnGameLoaded*` | Init … Late | A save file finished loading | none |
| `OnShutterOpened*` / `OnShutterClosed*` | Early, Late | The store shutter opens / closes | none |
| `OnGoingSleep*` / `OnWakingUp*` | Early, Late | The player goes to sleep / wakes up | none |
| `OnLeavingStore*` / `OnReturningStore*` | Early, Late | The player leaves / returns to the storefront | none |
| `OnHandlingNightlyServices*` | Early, Late | Nightly upkeep is processed | none |
| `OnPlaceInventorInventoryItem*` | Early, Late | Items are placed into an inventory | `List<GameItem>` |
| `OnCreateTooltip*` / `OnCreateDevTooltip*` | Early, Late | An item tooltip is being built (append your own lines) | `RichTextBuilder`, `GameItem` |
| `OnModAssetsLoaded` | none | A mod's assets (textures, item sprites, sounds, localization) have all finished loading (fires once per enabled mod; check the mod is yours) | `LoadedMod` |
| `OnLootTablesLoaded` | none | The loot tables have loaded and every mod edit has been applied (once per scene load) | none |
| `OnLootRolled` | none | A loot table was rolled; set `context.itemId` to override the result ([details](#reacting-to-rolls)) | `LootRollContext` |

---

## Loot Tables

Random drops (scavenging finds, supplier stock, what some customers bring in) are rolled from named **loot tables**: weighted lists of item IDs. **Table groups** are weighted lists of loot tables; rolling a group first picks a table, then rolls it. Mods can add items to existing tables, change or remove entries, and register new tables and groups, either from code or from a JSON file with no code at all.

Edits are stored separately from the game's data and re-applied every time the tables load, so they survive scene changes, never modify game files, and can be made at any time, including from `OnEnable` before any table exists.

Vanilla IDs (the live list, including other mods' additions, is one `loot-list` away in the [console](#inspecting-tables-in-the-console)):

| Loot table | What it feeds |
|---|---|
| `junkTable` | Scrap and junk finds |
| `materialTable` | Crafting materials |
| `packedFoodTable` | Cheap packaged food (supplier stock, food customers, stocked fridges) |
| `householdTable` | Household goods |
| `medicalTable`, `dumpingGroundMedical` | Medical supplies |
| `toolTable` | Tools |
| `makeshiftWeaponTable` | Improvised weapons |
| `t1moduleTable`, `t2moduleTable`, `allModuleTable` | Modules by tier |
| `accessCardTable` | Access cards |
| `POI_dumpingGround` | Expedition points of interest (IDs are POIs, not items) |

| Table group | What it feeds |
|---|---|
| `dumpingGroundTG` | Scavenging at the dumping grounds |
| `dumpingGroundFreshTG` | Fresh dumping-ground scavenging |

### Weights

Every entry has a weight, and an entry's chance is its weight divided by the total weight of its table. Vanilla tables are scaled so their entries **sum to 1000**, which makes weights easy to read:

| Weight | Chance in an untouched vanilla table |
|---|---|
| `100` | about 10% |
| `10` | about 1% |
| `1` | about 0.1% |
| `0.5` | about 0.05% |

Weights are relative, so adding entries dilutes the others: adding weight `10` to a vanilla table gives your item 10 / 1010, or 0.99%, and shrinks everything else by the same 1%. Decimals are fine. Weight `0` keeps an entry in the table but it never rolls; adding an entry with a weight of 0 or less is rejected.

### Editing tables from code

Call from `OnEnable`; there is nothing to wait for. Pass your manifest `<ID>` as the first argument so the console can show which mod made each edit.

```csharp
public void OnEnable()
{
    // Put your item in the junk pile at about 1% of rolls
    ModHelper.AddLootEntry("my_mod_id", "junkTable", "my_item", 10);

    // Make an existing drop rarer, or remove it entirely
    ModHelper.SetLootWeight("my_mod_id", "packedFoodTable", "cup_noodle", 20);
    ModHelper.RemoveLootEntry("my_mod_id", "packedFoodTable", "zerochew");

    // A new table, then give it a share of dumping-ground scavenging
    ModHelper.RegisterLootTable("my_mod_id", "my_table", ("my_item", 700), ("my_rare_item", 300));
    ModHelper.AddLootGroupEntry("my_mod_id", "dumpingGroundTG", "my_table", 50);
}
```

Rules:

- `AddLootEntry` for an item that is already in the table **replaces its weight** rather than adding a duplicate.
- `RegisterLootTable` fails (with a console warning) if the ID already exists. To rebuild a vanilla table from scratch, call `ClearLootTable` and then add entries.
- Table groups have the same set of calls with `Group` in the name: `RegisterLootGroup`, `AddLootGroupEntry`, `RemoveLootGroupEntry`, `SetLootGroupWeight`, `ClearLootGroup`. Their entries are loot table IDs.
- Item IDs are not checked when you add them. Register your items through [`OnModItemDirectoryInit`](#adding-items-through-the-item-directory-hook); an unknown ID rolls the "unknown" placeholder item.
- Every warning about a bad edit starts with `[LootRegistry]` and names your mod.

To roll or inspect a table yourself: `ModHelper.RollLootTable(id)` returns an item ID, `ModHelper.SpawnFromLootTable(id)` spawns it, and `ModHelper.GetLootEntries(id)` returns a snapshot of the entries with their weights and the mod that added each (`sourceModId` is `null` for vanilla entries). Group versions: `RollLootGroup`, `SpawnFromLootGroup`, `GetLootGroupEntries`.

### Editing tables with JSON files

The same edits can ship as data. Drop one or more `.json` files directly in a `LootTables/` folder in your mod folder; they load with your other assets and every edit is attributed to your mod. Any of the three top-level lists can be left out.

```json
{
  "tables": [
    { "id": "my_table", "entries": [ { "id": "my_item", "weight": 700 }, { "id": "my_rare_item", "weight": 300 } ] }
  ],
  "groups": [
    { "id": "my_group", "entries": [ { "id": "my_table", "weight": 800 }, { "id": "junkTable", "weight": 200 } ] }
  ],
  "patches": [
    {
      "table": "junkTable",
      "add": [ { "id": "my_item", "weight": 10 } ],
      "remove": [ "rusty_can" ],
      "setWeight": [ { "id": "cup_noodle", "weight": 20 } ]
    },
    { "group": "dumpingGroundTG", "add": [ { "id": "my_table", "weight": 50 } ] },
    { "table": "accessCardTable", "clear": true, "add": [ { "id": "my_card", "weight": 1000 } ] }
  ]
}
```

- `tables` and `groups` create new lists; `patches` edit existing ones (vanilla or from any mod, including your own `tables`).
- A patch names exactly one of `table` or `group`. Inside a patch, `clear` runs first, then `add`, `remove`, `setWeight`.
- Within a file the order is tables, then groups, then patches; several files apply in alphabetical order. Register a table before patching or grouping it.
- The loader logs `[ModLoader] My Mod: 1 loot file(s): 1 table(s), 1 group(s), 3 patch(es) loaded`; an unreadable file is skipped with an error naming it.

### Reacting to rolls

`ModHook.OnLootTablesLoaded` fires once the tables exist and every mod edit is in, so it is the moment to read the final state of a table with `GetLootEntries`.

`ModHook.OnLootRolled` fires after every roll, from any table, with a `LootRollContext`: `tableId`, `groupId` (the group that picked the table, or `null` for a direct roll), and `itemId`. Assign `itemId` to replace the result:

```csharp
public void OnEnable()  => ModHook.OnLootRolled += OnLootRolled;
public void OnDisable() => ModHook.OnLootRolled -= OnLootRolled;

void OnLootRolled(LootRollContext context)
{
    // one scavenging find in twenty becomes your item, whatever table it came from
    if (context.groupId == "dumpingGroundTG" && UnityEngine.Random.value < 0.05f)
        context.itemId = "my_item";
}
```

Prefer weights over this hook for ordinary drop changes; it runs on every roll and later mods see the value you set.

### Inspecting tables in the console

The F8 console has two commands. `loot-list` prints every table and group; `loot-list <id>` prints one with its effective percentages and which mod added or changed each entry; `loot-roll <id> [count]` rolls it and tallies the results.

```
> loot-list junkTable
Loot table 'junkTable': 9 entries, total weight 1010 (vanilla tables sum to 1000)
  rusty_can                        weight   250.000   24.752%
  ...
  my_item                          weight    10.000    0.990%  (added by my_mod_id)

> loot-roll junkTable 1000
Loot table 'junkTable', 1000 roll(s):
  rusty_can                            244   24.40%
  ...
```

If your item is missing from `loot-list`, the table ID is wrong or the edit was rejected; look for a `[LootRegistry]` warning in the console.

---

## Saving Mod Data

Mods often need to remember something that is not tied to an item: a quest step, a counter, a flag, a small settings blob. `ModHelper` gives every mod a key/value store that is saved with the player's run.

```csharp
// Write. Keys are namespaced by your mod id, so use whatever names you like.
ModHelper.SetModDataInt("my_mod_id", "deliveries", 3);
ModHelper.SetModDataBool("my_mod_id", "met_courier", true);
ModHelper.SetModData("my_mod_id", "route", JsonUtility.ToJson(routeState));

// Read, with a fallback for when the key was never written.
int deliveries = ModHelper.GetModDataInt("my_mod_id", "deliveries", 0);
bool met = ModHelper.GetModDataBool("my_mod_id", "met_courier");
RouteState route = JsonUtility.FromJson<RouteState>(ModHelper.GetModData("my_mod_id", "route", "{}"));

// Housekeeping
ModHelper.HasModData("my_mod_id", "route");
ModHelper.RemoveModData("my_mod_id", "route");
ModHelper.GetModDataKeys("my_mod_id");   // every key you have stored, without the prefix
ModHelper.ClearModData("my_mod_id");     // wipe everything your mod stored in this run
```

Rules:

- **It is per run.** The data is part of the save slot: written every time the game saves (each night), restored on load, and empty on a new game. Anything you write before the player sleeps is in that night's save. A write after the save has run is kept in memory and lands in the next one.
- **Available while a run is loaded.** Read from `ModHook.OnGameLoadedInit` onward. Calls made in the main menu, or before a run is loaded, do nothing and return the fallback, with a warning for writes.
- **Values are strings.** The game never has to know your types, so the save stays loadable even if your mod is updated or removed. For structured data, serialise to JSON yourself; `JsonUtility` is the easiest. The `Int`, `Float` and `Bool` helpers format and parse for you, culture-invariant.
- **Disabled mods keep their data.** Nothing is pruned when a mod is turned off, so re-enabling restores its state. If your mod wants a clean slate, call `ClearModData` yourself.
- **Keep it small.** The store is written with every save. Kilobytes are fine; do not stash large blobs or per-frame data in it.
- **It is not for items.** Anything that belongs to a specific item goes on that item's tags (`item.ModifyTag` / `GetTagReadonly`), which are saved with the item and travel with it.

---

## Custom UI

Mods can build their own windows at runtime (settings panels, inspectors, counters...) through `CustomUIManager`, a fluent C# builder over the game's UI prefabs. No Unity project, prefabs, or editor work is needed on the mod side; the game supplies the widgets and you compose them from code.

```csharp
CustomUIManager.Window("my_mod_id.settings", "My Mod Settings", CustomUIManager.LAYER_PAPER)
    .SetSize(400, 300)
    .SetDraggable(true)
    .AddLabel("General")
    .AddToggle("Enable feature", true, v => featureOn = v, id: "feature")
    .AddSlider(0f, 100f, 50f, v => amount = v, wholeNumbers: true, id: "amount")
    .AddInput("Enter a name...", "", v => name = v)
    .AddDropdown(new[] { "Low", "Medium", "High" }, 1, i => quality = i)
    .AddProgressBar(0.3f, id: "progress")
    .AddImage("my_mod_id:health_pack")   // an item sprite from Textures/Items
    .BeginRow()
        .AddFlexibleSpace()
        .AddButton("Apply", Apply).WithTooltip("Saves the settings")
        .AddButton("Close", () => CustomUIManager.Instance.CloseWindow("my_mod_id.settings"))
    .End()
    .Show();
```

- `CustomUIManager.Window(id, title, layer)` starts a window and replaces any existing window with the same id. Prefix ids with your mod id to avoid collisions with other mods. `Show()` finishes the chain and returns a `CustomUIWindow`; `GetWindow()` returns it hidden instead.
- Widgets: `AddLabel`, `AddButton`, `AddImage`, `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown`, `AddProgressBar`, `AddSpace`, `AddFlexibleSpace`. Pass an `id` to any widget you want to update later.
- Layout: `BeginRow` / `BeginColumn` / `BeginGrid(columns, cellWidth, cellHeight)` / `BeginScroll(height)`, each closed with `End()`. Tabs: `BeginTabs()`, then one `BeginTab("Name") ... End()` per tab, then `EndTabs()`.
- Window options: `SetSize`, `SetPosition`, `Center`, `SetDraggable`, `SetCloseOnEscape`, `OnClose(callback)`. `WithTooltip(text)` attaches a hover tooltip to the last added element.
- Layers decide which canvas hosts the window: `LAYER_PAPER` (books and documents, most normal UI), `LAYER_FRONT`, `LAYER_REAR`, `LAYER_META` (options and escape menu) in the game scene, `LAYER_MENU` in the main menu, and `LAYER_OVERLAY`, the manager's own canvas that survives scene changes. Windows on a scene layer are destroyed with the scene, so rebuild them when needed, for example from `ModHook.OnGameLoadedNormal`. Targeting a layer that does not exist in the current scene falls back to the overlay with a warning.

Update a window later through the handles:

```csharp
CustomUIWindow window = CustomUIManager.Instance.GetWindow("my_mod_id.settings");
window.Get("progress").SetProgress(0.7f, "70%");
window.Get("feature").SetBool(false);      // silent; pass notify: true to fire the callback
bool on = window.Get("feature").GetBool();
window.Hide(); window.Show(); window.Close(); // Close destroys and unregisters the window
```

Element setters are null-safe: calling a slider method on a label logs a warning and does nothing, so a wrong id never throws into the game's UI loop. `AddImage("key")` and `SetSprite("key")` accept the game's own sprite keys and your mod's item sprites in the `"modId:spriteName"` form (the sprite key is the file name from `Textures/Items/`, see [Item sprites](#item-sprites)).

Rules of thumb:

- Guard with `CustomUIManager.Instance != null` before building.
- Build UI that uses your mod's sprites no earlier than [`ModHook.OnModAssetsLoaded`](#knowing-when-your-assets-are-ready).
- `SetCloseOnEscape` is opt-in because the game also handles Escape globally in the store scene; test for conflicts with your window open.

---

## Harmony Patches

> ⚠️ **Prefer native hooks when they exist.** Harmony has measurable runtime overhead and is more sensitive to game updates than the native modding API. If a [hook point](#hook-points) covers what you need, use that instead. Reach for Harmony only when no hook exposes the moment you want to act on; that's exactly what it's for.

Harmony is a runtime patching library that lets you inject code before, after, or in place of any method in the game. The `0Harmony.dll` reference is already included in the `.csproj` from the [README.md](README.md) quick start.

### Patches are applied automatically

You do not need to call `Harmony.PatchAll()` yourself. The game scans each loaded mod assembly and applies every `[HarmonyPatch]` class it finds. Just declare your patch classes (see below) and they will be active as soon as the mod is enabled.

### Postfix: run code after the original

A **Postfix** runs after the original method completes. Use it to observe results, or, when the method returns a value, to read or change it by adding a `ref` parameter named `__result`. (`GenerateClient` returns `void`, so the example below only observes.)

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class PrintLog
{
    // Postfix runs AFTER the original method.
    static void Postfix()
    {
        Debug.Log("[TestMod] StoreClientManager.GenerateClient called.");
    }
}
```

### Prefix: run code before the original

A **Prefix** runs before the original method. Return `false` to skip the original entirely; return `true` (or `void`) to let it run normally.

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class SkipClient
{
    static bool Prefix()
    {
        Debug.Log("[TestMod] Skipping client generation.");
        return false; // original method will NOT run
    }
}
```

### Finalizer: run code even when the original throws

A **Finalizer** runs after the original method, even if it throws an exception. Use it for cleanup, or to swallow or replace exceptions. Return `null` to swallow the exception; return an `Exception` instance to replace it.

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class SwallowErrors
{
    static Exception Finalizer(Exception __exception)
    {
        if (__exception != null)
        {
            Debug.LogError($"[TestMod] GenerateClient threw: {__exception.Message}");
        }

        return null; // swallow the exception so the game keeps running
    }
}
```

### Transpiler: rewrite the original method's IL (advanced)

A **Transpiler** rewrites the original method's IL instructions before they run. This is the most powerful patch type, but also the most fragile; small game updates can break a transpiler that matches specific opcode patterns. Only use one when Prefix / Postfix / Finalizer can't express what you need.

```csharp
using System.Collections.Generic;
using HarmonyLib;

[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class TweakClient
{
    static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
    {
        foreach (var instr in instructions)
        {
            // Inspect, replace, or insert IL here.
            // This pass-through returns the original IL unchanged.
            yield return instr;
        }
    }
}
```

See the [Harmony documentation](https://harmony.pardeike.net/) for the full reference, including injection parameter names (`__instance`, `__state`, `___privateField`, etc.).

---

## Troubleshooting

Open the **F8 console** first: every mod logs its load result, asset counts, and how many Harmony methods it patched, all prefixed with `[ModLoader]` or your mod's name.

| Symptom | Likely cause |
|---|---|
| Mod doesn't appear in the mod menu | No `manifest.xml` in the mod's root folder, or its `<ID>` is empty; the loader skips the folder. Look for a `[ModLoader]` warning. |
| Mod appears but nothing happens | The mod isn't enabled, or you didn't restart after enabling it. **Enabling, disabling, and reordering only take effect on the next launch.** |
| Code changes don't take effect | You copied an old DLL. Rebuild (`dotnet build -c Release`) and copy the fresh DLL from `bin/Release/netstandard2.1/` into the mod folder. |
| Item shows the "unknown" placeholder sprite | The `spriteKey` or mod ID passed to `SetSpriteAndShapeFromMod` doesn't match. The key is the **file name** (no extension, no folder); the ID is your manifest `<ID>`, **not** the folder name. Check the `item sprite(s) loaded` count in the console. |
| A sprite file is ignored entirely | It isn't *directly* inside `Textures/Items/` (subfolders aren't scanned), or it isn't a `.png`/`.jpg`. |
| `PlaySound` returns false / warning `Audio identifier ... was not found` | The mod ID or sound key doesn't match. The full identifier is `<manifest ID>:<file name without extension>`. Check the `sound(s) loaded` count in the console. Sounds also finish loading a few frames after startup ([wait for them](#knowing-when-your-assets-are-ready) if playing very early). |
| `GetLocalized` returns the key itself | No entry for that key in the current locale's CSV or in `en.csv`, or the file name doesn't match the game's locale code. Look for the one-time `[ModHelper]` warning and check the `localization entries loaded` count in the console. |
| `requires '<id>' which is not loaded/enabled` warning | Your manifest lists a `<Prerequisites>` mod that isn't enabled. Enable it, or drop the dependency. |
| Harmony patch never runs | The target type/method name is wrong, or the mod is disabled; patches are only applied to **enabled** mods, at launch. |
| My item never drops | Run `loot-list <tableId>` in the console. If the entry is missing, the table ID is wrong or the edit was rejected (look for a `[LootRegistry]` warning naming your mod). If it is there, check the percentage: weight `10` in a vanilla table is about 1%. |
| `[LootRegistry] ... which does not exist` warning | The table or group ID in your edit or JSON file does not match any table. `loot-list` prints every ID. When registering your own table, register it before patching or grouping it. |
