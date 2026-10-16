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
    - [Adding your own debug buttons](#adding-your-own-debug-buttons)
  - [Save File Responsibility](#save-file-responsibility)
  - [Supported \& Unsupported Modding Features](#supported--unsupported-modding-features)
    - [✅ Natively supported](#-natively-supported)
    - [❌ Not supported at the moment](#-not-supported-at-the-moment)
  - [Mod Assets](#mod-assets)
    - [Item sprites](#item-sprites)
    - [Sounds](#sounds)
    - [Other textures](#other-textures)
    - [Paper textures](#paper-textures)
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
  - [Paper Books](#paper-books)
    - [Making a book with the editor](#making-a-book-with-the-editor)
    - [The book file](#the-book-file)
    - [Binding code to a book](#binding-code-to-a-book)
    - [Books in code](#books-in-code)
    - [Vanilla art and your own](#vanilla-art-and-your-own)
  - [Machine Windows](#machine-windows)
  - [Game Options](#game-options)
  - [Network Upgrades](#network-upgrades)
  - [Starting Scenarios](#starting-scenarios)
  - [Starting Perks](#starting-perks)
  - [Difficulties](#difficulties)
  - [Afterhour Locations](#afterhour-locations)
  - [Mod Configuration](#mod-configuration)
  - [Capabilities and the Scanner](#capabilities-and-the-scanner)
    - [Declaring capabilities](#declaring-capabilities)
    - [Hard refusals](#hard-refusals)
    - [Checking before you publish](#checking-before-you-publish)
    - [What players see](#what-players-see)
    - [Developer mode](#developer-mode)
    - [Reading and writing files without the capability](#reading-and-writing-files-without-the-capability)
  - [Steam Workshop](#steam-workshop)
    - [Publishing with steamcmd](#publishing-with-steamcmd)
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
- 🛠️ **Dev Menu (`F9`)**: opens a menu containing many functions useful for mod development and testing, such as spawning items, triggering events, and inspecting game state. Handy for reproducing edge cases without having to play through to them. The buttons sit in five columns: Store, Command, Spawn, Special, and Modding (the paper editor, book reload, asset viewers; see [Paper Books](#paper-books)).

### Adding your own debug buttons

Your mod can put its own buttons on the F9 menu, next to the built-in ones. Register them from `OnEnable`; the menu picks them up when it opens (or rebuilds itself if it is already open). Each button shows your mod id as a tooltip so testers know where it came from.

```csharp
public void OnEnable()
{
    ModHelper.AddDebugFunction("my_mod_id", ModHelper.DEBUG_CATEGORY_SPAWN, "Spawn My Widget", () =>
    {
        ModHelper.MoveItemToInventory(ModHelper.SpawnItem("my_mod_id.widget"));
    });

    // tall: true gives the button twice the normal height, for the one you press most.
    ModHelper.AddDebugFunction("my_mod_id", ModHelper.DEBUG_CATEGORY_COMMAND, "Reset My Mod State", ResetState, tall: true);
}

public void OnDisable()
{
    ModHelper.RemoveDebugFunctions("my_mod_id");
}
```

- `AddDebugFunction(modId, category, name, action, tall = false)`: `category` is one of `ModHelper.DEBUG_CATEGORY_STORE / COMMAND / SPAWN / SPECIAL / MODDING / MARKETING` (anything else lands in Special with a warning). The first four are columns of the main F9 panel; `MODDING` and `MARKETING` are separate windows, opened from the main panel's Special column ("Modding Panel", "Marketing Panel"). Keep `name` to three or four words; longer names shrink to fit the button.
- `RemoveDebugFunctions(modId)` drops every button your mod registered and returns how many.
- Exceptions thrown by your action are caught and logged to the F8 console, so a broken button never takes the menu down with it.
- The F9 menu does not exist in limited builds, where both calls are no-ops.

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
- **Paper books**: guides, cards and sheets in the game's paper look, laid out with the in-game editor and saved as JSON, with an item that opens them ([Paper Books](#paper-books))

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
    ├── preview.png             → optional, shown in the Mods menu when your mod is selected (Workshop items show their Workshop preview image instead)
    ├── Textures/
    │   ├── banner.png          → general texture, key "banner"
    │   ├── Items/
    │   │   └── health_pack.png → item sprite, key "health_pack"
    │   └── Paper/
    │       └── my_page.png     → paper book art (backgrounds, illustrations), key "my_page"
    ├── Sounds/
    │   └── ding.wav            → sound, key "ding"
    ├── Localization/
    │   ├── en.csv              → strings for the "en" locale
    │   └── fr.csv              → strings for the "fr" locale
    ├── LootTables/
    │   └── drops.json          → loot table edits, see Loot Tables
    └── Books/
        └── fuel_guide.json     → a paper book, see Paper Books
```

> ⚠️ **Every mod needs a DLL, and the manifest lists it.** Besides `manifest.xml`, the folder must contain at least one DLL (in the mod folder or an `Assemblies/` subfolder) with a class implementing `IMod`, and every DLL to load must appear under `<Assemblies>` in the manifest; DLLs that are not listed are never loaded. Assets alone do not make a mod: a folder without such a DLL is not listed in the Mods menu, and the console logs `[Your Mod Name] Error: ...` instead. The manifest also needs a `<Capabilities>` element, see [Capabilities and the Scanner](#capabilities-and-the-scanner).

> ⚠️ **The folder names are exact, and scanning is not recursive.** Item sprites must sit *directly* in `Textures/Items/`; paper art *directly* in `Textures/Paper/`; sounds *directly* in `Sounds/`; localization files *directly* in `Localization/`; loot files *directly* in `LootTables/`; books *directly* in `Books/`. A PNG in `Textures/Sprites/` or any nested subfolder is silently ignored. Supported image formats: `.png`, `.jpg`. Supported audio: `.wav`, `.ogg`, `.mp3`. Localization: `.csv`. Loot tables and books: `.json`.

Each mod logs what it loaded, so you can confirm in the F8 console:

```
[ModLoader] My Mod: 1 texture(s), 1 item sprite(s), 1 paper sprite(s) loaded
[ModLoader] My Mod: 2 locale(s), 34 localization entries loaded
[PaperUI] My Mod: 1 book(s) loaded
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

### Paper textures

Art for [paper books](#paper-books) goes in `Textures/Paper/`: backgrounds, illustrations, button icons. Files are loaded as smooth UI sprites (bilinear filtering, no mip-maps, 100 pixels per unit like the vanilla paper art) and keyed by file name, so a book of your mod names them directly (`"background": "my_page"`, `"sprite": "cartridge_clean"`) and a book of another mod as `"my_mod_id:my_page"`. The same keys work in the Custom UI builder (`AddImage("my_mod_id:my_page")`). A 9-slice border for a stretched background is declared in the book file, not on the image. Draw the art at half the size you want on screen: paper books show their art at 2x by default, like the vanilla guides.

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
| `OnModConfigApplied` | none | The player pressed Apply in a mod's configuration panel and something changed ([details](#mod-configuration)); check the id is yours | `string` (mod id) |
| `OnNetworkUpgradeUnlocked` | none | A Wild's Network upgrade was bought (or a repeatable one used), after its effect ran ([details](#network-upgrades)) | `string` (upgrade id) |
| `OnNewGameStarted` | none | A new run began: the chosen scenario's starting items and the starting perks are placed ([details](#starting-scenarios)); not fired when a save is loaded | `string` (scenario id) |
| `OnDifficultyApplied` | none | A run started or a save loaded with a difficulty; apply a difficulty's custom effects here ([details](#difficulties)) | `string` (difficulty id) |
| `OnAfterhourArrive*` / `OnAfterhourLeave*` | Early, Late | The player arrives at / leaves an afterhour location, vanilla or mod ([details](#afterhour-locations)) | `string` (location id) |
| `OnAfterhourEventStarted` / `OnAfterhourEventEnded` | none | A temporary event on an afterhour location started / ended | `string` (location id), `string` (event id) |
| `OnPaperOpened` | none | A paper book's panel was built: on its first open and after every reload or rebuild; bind actions and element handles here ([details](#paper-books)). `ModHelper.OnPaperOpened(modId, bookId, callback)` is the per-book form | `string` ("modId:bookId"), `PaperUI` |

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
- Widgets: `AddLabel`, `AddButton`, `AddImage`, `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown`, `AddProgressBar`, `AddSpace`, `AddFlexibleSpace`. Pass an `id` to any widget you want to update later. `AddInput` calls `onChanged` on enter or focus loss; pass `onTyping` for a per-keystroke callback. To filter a list live, do not recreate the window from that callback (it drops focus from the field): grab `builder.CurrentContainer` after the `Begin` call that made the list host, then `CustomUIBuilder.ClearContainer(host)` and refill it with `new CustomUIBuilder(CustomUIManager.Instance, window, host)`.
- Layout: `BeginRow` / `BeginColumn` / `BeginGrid(columns, cellWidth, cellHeight)` / `BeginScroll(height)`, each closed with `End()`. `BeginRow(spacing, alignment)` and `BeginColumn(spacing, alignment)` accept a `TextAnchor` for their children (default `UpperLeft`; `UpperCenter` centers an icon over its label). Tabs: `BeginTabs()`, then one `BeginTab("Name") ... End()` per tab, then `EndTabs()`.
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

## Paper Books

Paper books are the game's paper-style panels: the appraisal guides, cards and sheets you open from the inventory. A book is a fixed background with texts, images and buttons placed exactly where you want them, one or more pages, and the vanilla paper chrome (close and zoom buttons, page flip buttons, page indicator, paper sounds). Your mod adds books as JSON files in `Books/`, made with the in-game paper editor; code is only needed for behavior (a button that does something, a value filled at runtime). A book can declare the document item that opens it, so a pure guide mod needs no item code at all.

### Making a book with the editor

1. Start the game with your mod enabled (a local folder under `Mods/` with its `manifest.xml` and DLL) and load a save: paper books live on the store scene.
2. Press `F9`, column **Modding**, **Paper Editor**. In the **Book** tab, under *New book*, pick your mod, type an id (letters, digits, underscores), choose a starter (blank notebook, appraisal guide, tutorial sheet or business card) and, if you want your own art, pick a background from `Textures/Paper/` of your mod. **Create and edit** writes `Mods/<yourMod>/Books/<id>.json` and opens it.
3. Build the pages. **Palette** adds texts in every vanilla text style, images from any sprite (the picker lists the vanilla paper art and your own), text and icon buttons, flow regions that stack their children, and chrome parts. On the book itself: click selects, drag moves, the corner and edge handles resize, drag on empty paper draws a marquee, Shift adds to the selection, arrows nudge (Shift for 10), Alt-drag moves the panel. Elements snap to the grid, to other elements' edges and centers and to the page center (hold Ctrl to skip). **Inspector** edits the selected element's fields; **Elements** lists them in draw order with lock and visibility toggles; **Tools** has align, distribute, match size, z-order, undo and redo, zoom, a language preview and the shortcut list.
4. Every change is saved into the JSON file within a second and the panel updates at once. Editing the file in a text editor works the same way: the game picks up the change and rebuilds the open book. The **Check** tab lists problems (missing sprites, overflowing texts, duplicate ids...), **Screenshot page** saves a PNG next to the file for your Workshop preview.
5. **Pages** adds and reorders pages, and manages templates: a shared layout with named slots that each page fills (title, body, an illustration). The starters ship with the vanilla guide, tutorial sheet and business card layouts as built-in templates; *Create from the selected page elements* makes your own.
6. To reuse vanilla looks, switch on **Inspect mode** in the Palette, open any vanilla guide or card from your inventory, hover it: the editor names the sprite, the text style, the size and colour, and **Add like this** drops an equivalent element into your book.

Coordinates are *design units*: the pixels of the background image, origin at the top-left corner, y going down. Measure positions in your image editor and type them in, or just drag. The vanilla paper art is drawn at half size and shown at 2x on screen (the notebook background is 314x402 pixels shown at 628x804); your own backgrounds in `Textures/Paper/` default to the same 2x. Font sizes are design units too, so a body text is about 7.5.

### The book file

```json
{
  "id": "fuel_guide",
  "title": "Fuel Guide",
  "background": "notebook_manual",
  "width": 628, "height": 804,
  "chrome": [
    { "type": "button", "id": "close", "action": "close", "x": 297, "y": 2.5, "w": 14, "h": 15 },
    { "type": "button", "id": "flip_left", "action": "flip_left", "x": 124, "y": 380, "w": 16, "h": 16 },
    { "type": "button", "id": "flip_right", "action": "flip_right", "x": 176, "y": 380.5, "w": 14, "h": 15 },
    { "type": "text", "id": "page_indicator", "action": "page_indicator", "style": "page_number", "align": "center", "valign": "middle", "x": 140.5, "y": 374, "w": 33, "h": 25 }
  ],
  "pages": [
    {
      "name": "Page 1",
      "template": "guide_page",
      "slots": { "title": "Plasma Cartridge Appraisal Guide", "body": "Plasma cartridges are the standard fuel..." }
    },
    {
      "name": "Page 2",
      "elements": [
        { "type": "text", "x": 28, "y": 49, "w": 262, "h": 21, "text": "Cartridge Condition", "style": "title", "align": "center" },
        { "type": "image", "x": 80, "y": 90, "w": 160, "h": 62, "sprite": "my_mod_id:cartridge_clean" },
        { "type": "text", "id": "price", "x": 80, "y": 156, "w": 160, "h": 12, "text": "", "preview": "150 Credits", "style": "caption", "align": "center" },
        { "type": "button", "x": 120, "y": 340, "w": 80, "h": 18, "text": "Refresh", "action": "refresh" }
      ]
    }
  ],
  "item": { "id": "fuel_guide", "name": "Fuel Guide", "description": "How to price plasma cartridges.", "value": 50 }
}
```

Book fields: `id` (defaults to the file name), `title` (editor only), `background` (a vanilla sprite name such as `notebook_manual`, `guide_reworked`, `tutorial_sheet`, `business_card_template`, `exchange`, `test_strips`; a file name from your `Textures/Paper/`; or `"modId:name"`), `width`/`height` (displayed size; 0 keeps the vanilla size for a vanilla background), `designWidth`/`designHeight` (override the coordinate space; 0 means the background's pixels), `border` (`[left, bottom, right, top]` 9-slice for a stretched background), `posX`/`posY` (where the panel opens, offset from the screen center; the vanilla guides use -450, 0), `sounds`, `draggable`, `zoomable` (default true), `chrome` (elements drawn on every page), `templates`, `pages`, `item`.

Element fields: `type` (`text`, `image`, `button`, `flow`), `id`, `x`, `y`, `w`, `h`, `visible`, `locked` (editor only), `raycast` (texts and images let clicks through unless true). Text: `text` or `loc` (a key of your `Localization/*.csv`, wins over `text`), `style`, `fontSize` (0 keeps the style's), `align` (`left`, `center`, `right`), `valign` (`top`, `middle`, `bottom`), `color` (`#rrggbb`), `wrap`, `autoHeight` (grows with the text), `preview` (editor-only sample for texts you fill from code). Image: `sprite`, `fit` (`stretch`, `fit`, `native`). Button: `action` (the name you bind in code; `close`, `zoom`, `flip_left`, `flip_right` are handled by the book), `text` for a text button (blue plate), `sprite` and optional `hoverSprite` for an icon button. Flow: `spacing`, `align`; children set `flow` to the flow's id and are stacked vertically (texts take their height from their content). Template elements may carry a `slot` name; a page's `slots` map fills them (text for texts, sprite key for images).

Item fields: `id` (the item identifier, spawn it with `ModHelper.SpawnItem`), `name`/`nameLoc`, `description`/`descriptionLoc`, `sprite` (`atlas/sprite` from the vanilla item atlases, default `items_misc/manual1`, or a file name from `Textures/Items/`), `value`, `important` (cannot be stolen, default true). The item is a document: reading it opens the book.

Text styles: `header` (the "Station Trade Commission" stamp, Tektur), `title` (Noto Sans Medium), `section` and `body` (Noto Serif), `caption` and `label` (Noto Sans Bold), `serif_title` (Noto Serif Bold), `handwritten` and `page_number` (Caveat), `stamp` (the red LCD look), `button` (text button labels). Styles are font roles, so they switch fonts per language like the rest of the game.

### Binding code to a book

Layout in JSON, behavior in C#. The book is built when it is first opened and again after every reload, so bind in `OnPaperOpened`, not once at startup:

```csharp
public void OnEnable()
{
    ModHelper.OnPaperOpened("my_mod_id", "fuel_guide", ui =>
    {
        ui.OnAction("refresh", () => ui.SetText("price", $"{CurrentPrice()} Credits"));
        ui.OnPageShown((book, page) => { if (page == 1) book.SetText("price", $"{CurrentPrice()} Credits"); });
    });
}
```

- `ModHelper.OpenPaper(modId, bookId)` opens a book (or brings it to the front) and returns the `PaperUI`; `ClosePaper`, `IsPaperOpen`, `GetOpenPaper` do what they say. `ModHelper.SpawnPaperItem(modId, bookId)` spawns the declared item; `ModHelper.GetPaperBookIds(modId)` lists your books.
- On the `PaperUI`: `OnAction(name, callback)` binds a button, `Get(id)` returns the element handle with the usual setters (`SetText`, `SetSprite`, `SetVisible`, `OnClick`...), `SetText(id, text)` and `SetSprite(id, key)` are shortcuts, `FlipTo(page)`, `CurrentPage`, `PageCount`, `Hide()`, `Close()`, and the events `PageShown`, `Closed`, `ActionFired`.
- `ModHook.OnPaperOpened(string fullId, PaperUI ui)` is the global form of the same signal ("modId:bookId").
- Books register with the mod's assets, after `OnEnable`, so `OnPaperOpened` is safe to call from `OnEnable` before the file is loaded.

### Books in code

A book can also be built entirely in code with the same fields, for pages generated at runtime:

```csharp
PaperUI ui = ModHelper.CreatePaper("my_mod_id", "recipes", "notebook_manual")
    .AddPage("Recipes", template: "guide_page")
        .SetSlot("title", "House Recipes")
        .SetSlot("body", "Mix two parts water with one part regret.")
    .AddPage("Notes")
        .AddText(28, 49, 262, 21, "Notes", PaperTextStyle.TITLE, align: "center")
        .AddTextBelow("A paragraph under the title, growing with its text.")
        .AddImage(80, 200, 160, 62, "my_mod_id:still", fit: "fit")
        .AddButton(120, 340, 80, 18, "Brew", Brew)
    .Show();
```

`CreatePaper` gives the book the vanilla chrome; `SetChrome(close, zoom, flip, pageIndicator)` changes it, `SetSize` and `SetPosition` place it. `ModHelper.RegisterPaperBook(modId, data)` registers data you parsed or built yourself (`ModHelper.ParsePaperBook(json)`), so it gets an id, an item and `OnPaperOpened` like a file book. The **Copy C#** button of the editor writes the fluent form of the current book to the clipboard.

### Vanilla art and your own

The sprite picker and `background` / `sprite` keys accept every sprite the vanilla paper panels use, by sprite name: backgrounds (`notebook_manual`, `guide_reworked`, `guide`, `tutorial_sheet`, `business_card_template`, `exchange`, `test_strips`, `mentors_notes`...), the chrome buttons (`paper_buttons_close1`, `paper_buttons_screen_0`, `paper_buttons_l_1`, `paper_buttons1`, `blue_button_2x`), the guide header (`guide_logo`) and the illustrations of the vanilla guides. **F9 > Modding > Paper Sprite Picker** browses them and copies a key. Your own art goes in `Textures/Paper/` of your mod (PNG or JPG, loaded as smooth UI sprites) and is named by file name, or `"my_mod_id:name"` from another mod's book. Item sprites from `Textures/Items/` work too.

Console commands (F8): `paper-list`, `paper-open <id>`, `paper-close [id]`, `paper-reload`, `paper-edit [id]`, `paper-item <id>`. The F9 Modding column has **Reload Mod Books** for files added or edited while the game runs.

---

## Machine Windows

The window that opens on an item with a content window (machines, containers, the crafting table) is built from code with the game's Machinery widgets: a row of labelled panels, each holding an inventory or a stack of controls. Your own machines use the same builder, so they look like the vanilla ones.

```csharp
GameSlotInventory battery = new GameSlotInventory();
GameGridInventory modules = new GameGridInventory(MachineHelper.DEFAULT_MODULE_BAY_CONFIG, MachineHelper.DEFAULT_MODULE_BAY_WIDTH);
GameGridInventory input   = new GameGridInventory(6, 4);

MachineryProgressBar progress = new MachineryProgressBar(0f);
MachineryText status = MachineryText.Status("status", "idle");
MachineryButton start = new MachineryButton("Start", () => { /* run the machine */ });

PixelWindow window = MachineHelper.CreateMachineryWindow(canMove: true,
    MachineHelper.PowerPanel(battery),                              // battery icon label, node 0
    MachineHelper.Panel("Modules", modules, "module"),              // text label, node 1
    MachineHelper.Panel("Input", input, "input"),
    MachineHelper.Panel("Control", MachineryStack.Vertical(start, progress, status), "control"));

item.SetContentWindow(window);
MachineHelper.SetupBatterySlot(battery, item);
```

- `MachineHelper.Panel(label, content, role)` puts an inventory (or a `GridPixelElement` of slots) in a sunken intake under a label plate; any other element (a stack, a button, tabs) is placed as is. `PowerPanel` and `NotePanel` use the design's battery and note icons; `IconPanel(sprite, content, role)` takes your own sprite (`"modId:spriteName"` keys work through `CustomUIManager.Instance.GetSprite`).
- Widgets: `MachineryButton` (text, icon, or both; `SetDescription` for a tooltip; `Enable` / `Disable` / `Hide`), `MachineryRadioButton` (a toggle; `MachineryRadioGroup` keeps one on; `MachineryRadioList(captions, selected, onChanged)` is a captioned column), `MachineryProgressBar` (`SetValue(0..1)`, `SetColor`), `MachinerySlider` (`SetRange(min, max, step)` or `SetSteps(n)` plus `GetInt`; `onChanged`, `onReleased`), `MachineryTabs` (`AddTab(caption, page)`), `MachineryText` (one line, rich text allowed).
- Layout: `MachineryStack.Vertical(...)` / `Horizontal(...)` stacks elements with a gap; a vertical stack stretches buttons, sliders, progress bars and texts to the panel width. `window.AddHeaderButton(new MachineryButton(icon, callback))` adds a button left of the close cross.
- Reading a machine's inventories later: `MachineHelper.GetBodyStorage(item, i)` is the i-th inventory or grid of the body, left to right (`GetBatterySlot`, `GetModuleInv` and `GetSlot` use it), or `((MachineryPanelRow)window.childElement).GetPanel("role")`.
- The panel order is the save order of the inventories. Once your mod has shipped, add new panels at the end and never reorder the existing ones, or saved items land in the wrong inventory.
- The classic window look is still available with `new PixelWindow(canMove)`; the Machinery style is `new PixelWindow(canMove, style: WindowStyle.Machinery)` with any element attached (a bare inventory gets one plate and intake drawn by the window).

---

## Game Options

Your mod can put its own settings into the game's Options window (Escape menu > Options in the store, Options in the main menu), next to the built-in ones. You register entries; the game draws them with its own widgets, fills them from your getter when the window opens, and calls your setter when the player presses Apply.

```csharp
public void OnEnable()
{
    // A section of your own (or use ModHelper.OPTION_SECTION_GAMEPLAY / AUDIO / DISPLAY / DIALOGUE / KEYBIND to join a built-in one).
    ModHelper.AddGameOptionSection("my_mod_id", "settings", () => "My Mod");

    ModHelper.AddGameOptionToggle("my_mod_id", "settings", "fast_courier",
        () => ModHelper.GetLocalized("my_mod_id", "option_fast_courier"),
        () => fastCourier,
        v => { fastCourier = v; PlayerPrefs.SetInt("my_mod_id.fast_courier", v ? 1 : 0); },
        tooltip: () => "Couriers arrive twice as fast.");

    ModHelper.AddGameOptionSlider("my_mod_id", "settings", "spawn_rate",
        () => "Spawn rate", () => spawnRate, v => spawnRate = v, min: 0f, max: 2f);

    ModHelper.AddGameOptionDropdown("my_mod_id", "settings", "difficulty",
        () => "Difficulty", () => new[] { "Easy", "Normal", "Hard" }, () => difficulty, i => difficulty = i);

    // A key bind: a button showing the key; clicking it waits for the next key press (Escape cancels).
    // Put it in ModHelper.OPTION_SECTION_KEYBIND to sit with the game's own binds. Poll it with Input.GetKeyDown(hotkey).
    ModHelper.AddGameOptionKeyBind("my_mod_id", ModHelper.OPTION_SECTION_KEYBIND, "open_panel",
        () => "Open my panel", () => hotkey, k => { hotkey = k; PlayerPrefs.SetInt("my_mod_id.hotkey", (int)k); });
}

public void OnDisable()
{
    ModHelper.RemoveGameOptions("my_mod_id");
}
```

Rules:

- **You own the value.** The game only reads it through the getter and writes it through the setter, so store it where it belongs: `PlayerPrefs` or ES3 for a global preference, [mod data](#saving-mod-data) for something tied to the run. The getter runs every time the window opens; the setter runs on Apply only, never while the player is still dragging a slider.
- **Labels, tooltips and dropdown options are functions**, resolved every time the window opens, so `() => ModHelper.GetLocalized(...)` follows a language change. A tooltip adds the info icon next to the label.
- **Ids are namespaced.** `optionId` and your own section ids are prefixed with your mod id internally, so they cannot collide with another mod. Registering an id again replaces the earlier entry. `RemoveGameOption(modId, optionId)` and `RemoveGameOptions(modId)` take entries out again.
- **Order** is registration order inside a section; your sections appear after the built-in ones.
- **Key binds** refuse Escape, the digit keys and any key another bind row in the window already uses, and only keyboard keys can be captured. While the player is choosing a key, the game's own hotkeys stay quiet; yours should too: skip your poll while `KeyBindHelper.SuppressHotkeys` is true.
- Callable from `OnEnable`; the window is built fresh on every open.

Use this only for a setting that genuinely belongs among the game's own options. Settings about your mod itself go in your mod's configuration panel, below.

## Network Upgrades

Wild's Network is the upgrade shop the player buys perks from (new suppliers, services, permits). Your mod can add its own upgrades to it: you register a definition, and the window draws it in the right card and tab, handles the price, the favor and cash payment, prerequisites, cooldowns and the saved state. Nothing to lay out by hand.

```csharp
public void OnEnable()
{
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.COURIER",
        cost: 400,
        subtitle: "Supplier",                          // the card it sits in
        title: () => ModHelper.GetLocalized("my_mod_id", "network_courier_title"),
        description: () => ModHelper.GetLocalized("my_mod_id", "network_courier_desc"),
        onUnlock: () => courierUnlocked = true,
        iconKey: "my_mod_id:courier_icon",              // a sprite from your Textures/Items
        prerequisites: new[] { NetworkUpgrade.BUY_REFERAL });

    // A repeatable upgrade: usable again after the cooldown, like Evidence Removal.
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.BRIBE",
        cost: 250, subtitle: "Favor",
        title: () => "Bribe the inspector",
        description: () => "Skips the next inspection.",
        onUnlock: () => skipNextInspection = true,
        cooldownDays: 7,
        alreadyBought: () => "The inspector is already paid off.");

    // Upgrades on your own tab.
    ModHelper.SetNetworkTabLabel("my_mod", () => "My Mod");
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.DRONE", 800, "Logistics",
        () => "Delivery drone", () => "Deliveries arrive a day earlier.", () => droneUnlocked = true,
        tab: "my_mod");
}

public void OnDisable()
{
    ModHelper.RemoveNetworkUpgrades("my_mod_id");
}
```

How the window places things:

- **Tabs.** Leave `tab` empty for the first tab ("Basic", where every vanilla upgrade lives). Any other string makes a tab of that name, shared by every upgrade using the same string; `SetNetworkTabLabel` gives it a translated label, otherwise the raw string is shown.
- **Cards.** The `subtitle` names the card inside the tab. Reuse a vanilla subtitle (`Introduction`, `Favor`, `Informant`, `Referral`, `Service`, `Permit`, `Supplier`) to join that card, or use your own string for a new card; `subtitleLabel` translates a custom one. Cards are three slots wide and grow by rows when they fill up. `recommended: true` also shows a copy of the upgrade in the gold Recommended band at the top of its tab (the upgrade stays in its own card; both copies select and highlight together).
- **Chains.** A prerequisite on the same card is drawn as a connector between the two slots, left to right. Prerequisites on other cards work too, they are just listed in the description column instead.
- **Icons.** `iconKey` goes through the same lookup as `AddImage` (your `"modId:spriteName"` item sprites). Without one, the window looks for a vanilla icon named after the id, then falls back to the Referral icon. 72x72 pixels fills the slot.
- **Text providers** are resolved every time the window opens, so `() => ModHelper.GetLocalized(...)` follows the locale.

Rules:

- **Register in `Init` or `OnEnable`.** New games create the upgrade then, loaded saves receive it when they load. The upgrade's state (bought, cooldown, current cost) is saved with the run under its id, so keep ids stable and unique: prefix them with your mod id.
- **`onUnlock` runs once per purchase**, after the player paid (favor first, then cash). A repeatable upgrade (`cooldownDays` above zero) runs it on every use and re-arms after the cooldown. Hook `ModHook.OnNetworkUpgradeUnlocked(id)` to react to any upgrade, vanilla or mod, being bought.
- **Removing** (`RemoveNetworkUpgrades`) only takes the upgrades off the window; what the save remembers about them stays, so a mod re-enabled later finds its purchases intact.
- Read state with `ModHelper.IsNetworkUpgradeUnlocked(id)`, or `NetworkUpgrade.IsUnlocked(id)` for vanilla ids. `ModHelper.GetNetworkUpgrade(id)` returns the run's copy (state, current `cost`, cooldown); raise its `cost` from your `onUnlock` to make a repeatable upgrade dearer each time, as the vanilla favor upgrades do.
- A prerequisite id the run does not know (a typo, or an upgrade of a disabled mod) counts as not unlocked and is logged once; it never breaks the window.
- `ModHelper.OpenWildNetwork()` / `CloseWildNetwork()` open and close the window from your own code (store scene, run loaded), for example from a custom button or dialogue.

---

## Starting Scenarios

The "Specialization" step of a new game lists the starting scenarios (Apprentice, Fence, Gunsmith...) in an icon strip. Your mod can add its own: you register a definition, and the screen shows it after the vanilla ones with your icon, name, tag, description and "Start With" lines. When the player starts with it, your `onStart` runs in the store scene, at the moment the vanilla scenarios place their starting items.

```csharp
public void OnEnable()
{
    ModHelper.AddStartingScenario("my_mod_id", "my_mod_id.courier",
        title: () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_title"),
        description: () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_body"),
        startWith: new System.Func<string>[]
        {
            () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_gear1"),
            () => "Stock of Parcels",
        },
        onStart: () =>
        {
            ModHelper.MoveItemToInventory(ModHelper.SpawnItem("satchel"));
            ModHelper.MoveItemToInventory(ModHelper.SpawnItem("my_mod_id.parcel"));
            ModHelper.AddCredit(-100, false);
        },
        iconKey: "my_mod_id:courier_icon",          // a sprite from your Textures/Items
        tag: () => "Advanced start",                // optional short line next to the name
        tagTone: StartingScenario.TagTone.Warning); // Positive (green), Warning (orange), Danger (red)
}

public void OnDisable()
{
    ModHelper.RemoveStartingScenarios("my_mod_id");
}
```

Rules:

- **Register in `Init` or `OnEnable`**, before the player opens New Game. The run saves the scenario by its id (`StartType.MODDED` plus the id), so keep ids stable and unique: prefix them with your mod id. A save started with a scenario whose mod is gone still loads; the load list names it "Corrupted Save" until the mod is back.
- **`onStart` runs once**, when the new run begins in the store scene: the base store exists, the starting perks' items come right after. Spawn and place items there (`SpawnItem`, `MoveItemToInventory`, `AddCredit`...). An exception is caught and logged. It does not run when a save is loaded; use `ModHook.OnGameLoaded*` for that.
- **Icon.** `iconKey` goes through the same lookup as `AddImage` (`"modId:spriteName"`). The vanilla icons are 19x19 sprites that include their round frame, drawn at 2x; any sprite is scaled to 38x38 in the slot. Without one the Apprentice icon is shown.
- **`skipIntro`** makes the scenario always skip the introduction (as Fence, Gunsmith, Chemist and Rock Bottom do). **`comingSoon`** shows it with Continue disabled.
- The "Start With" lines are plain text (the vanilla colour accents are not reproduced). Every text provider is resolved each time the screen opens, so `() => ModHelper.GetLocalized(...)` follows the locale.
- `ModHelper.GetStartingScenarioId()` / `IsStartingScenario(id)` tell which scenario the current run began with. Vanilla ids: `apprentice`, `water_merchant`, `junker`, `fence`, `hydroponic_farmer`, `gunsmith`, `chemist`, `organ_trader`, `rock_bottom`, `street_food_vendor`, `rancher`, `moonshiner`, `pharmacist`. `ModHook.OnNewGameStarted(id)` fires for every new run, vanilla or mod, after the starting items were placed.
- `ModHelper.OpenNewGameSpecialization()` / `CloseNewGameSpecialization()` open and close the window from your own code (main menu scene).

---

## Starting Perks

The "Perks" step of a new game lists the starting perks (Saving, Bad Lease, Sentinel...) the player can pick. Your mod can add its own: register a definition, and the screen lists it with the vanilla ones, sorted by cost, with your icon, name and description in the hover tooltip. The player's picks are saved with the run; your mod reads its perk back and applies the effect itself.

```csharp
public void OnEnable()
{
    ModHelper.AddStartingPerk("my_mod_id", "my_mod_id.night_owl",
        cost: 1,                                        // positive perks cost points
        type: StartingPerk.StartingPerkType.POSITIVE,
        name: () => ModHelper.GetLocalized("my_mod_id", "perk_night_owl_name"),
        description: () => ModHelper.GetLocalized("my_mod_id", "perk_night_owl_desc"),
        iconKey: "my_mod_id:night_owl_icon");           // a white 32x32 sprite, tinted by type

    ModHelper.AddStartingPerk("my_mod_id", "my_mod_id.clumsy",
        cost: -1,                                       // negative perks grant points
        type: StartingPerk.StartingPerkType.NEGATIVE,
        name: () => "Clumsy",
        description: () => "You drop things. Fragile items break more often.",
        incompatiblePerks: new[] { "my_mod_id.night_owl", StartingPerkList.ALERT });

    ModHook.OnNewGameStarted += scenarioId =>
    {
        if (ModHelper.IsStartingPerkActive("my_mod_id.clumsy")) clumsy = true;
    };
    ModHook.OnGameLoadedNormal += () => clumsy = ModHelper.IsStartingPerkActive("my_mod_id.clumsy");
}

public void OnDisable()
{
    ModHelper.RemoveStartingPerks("my_mod_id");
}
```

Rules:

- **Register in `Init` or `OnEnable`**, before the player opens New Game. Keep ids stable and unique (prefix them with your mod id): the pick is saved in the run under the id, and a save made with a perk whose mod is gone keeps the id without effect.
- **Cost.** The player has 3 points and 4 slots. A positive perk costs points (`cost` above zero), a negative one grants them (`cost` below zero), a neutral one is free (`cost` 0, `StartingPerkType.NEUTRAL`). `extraPerkSlots` adds slots when picked, like Colorful Character. `incompatiblePerks` lists perk ids that cannot be picked together with yours (vanilla ids are the `StartingPerkList` constants).
- **The effect is yours.** The game only records the pick. Read it with `ModHelper.IsStartingPerkActive(id)` (or `GetStartingPerkIds()`) from `ModHook.OnNewGameStarted` and `ModHook.OnGameLoaded*`, and apply whatever the perk does.
- **Icon.** `iconKey` goes through the same lookup as `AddImage` (`"modId:spriteName"`). The vanilla icons are white 32x32 glyphs; the screen draws them at 2x and tints them green (positive), red (negative) or amber (neutral). Without one the generic perk icon is shown.
- `mindEditable: true` lets the Mind Reprogrammer add or remove the perk mid-run, like the vanilla perks of the mind.
- Text providers are resolved whenever the tooltip opens, so `() => ModHelper.GetLocalized(...)` follows the locale.
- `ModHelper.OpenNewGamePerks()` / `CloseNewGamePerks()` open and close the window from your own code (main menu scene, after a scenario was chosen).

---

## Difficulties

A difficulty is a set of rule values the game reads wherever the difficulty matters: rent increases, nightly service fees, Wild's favor, security pressure, the hand-holding switches. The vanilla ones are Price Gouge (`cozy`, order 100), Mark Up (`normal`, 200), Thin Margins (`hard`, 300) and Red Ink (`challenge`, 400). Your mod can add one or change an existing one; the selection screen lists them by order and describes each from the rules that differ from Normal.

```csharp
public void OnEnable()
{
    // A new difficulty between normal and hard, starting from Normal's values.
    ModHelper.AddDifficulty("my_mod_id", "my_mod_id.lean", order: 250,
        title: () => ModHelper.GetLocalized("my_mod_id", "difficulty_lean_title"),
        subtitle: () => "Lean Mode",
        configure: rules =>
        {
            rules.rentIncreaseMultiplier = 1.08f;
            rules.tradeFavorRate = 0.02f;
            rules.wildBailout = false;
        },
        notes: new System.Func<string>[] { () => "Suppliers restock a day later" }, // your own effect
        iconKey: "my_mod_id:lean_plate");                                           // the plate's 164x164 image (optional)

    // The effect behind the note, applied when a run starts or loads with that difficulty.
    ModHook.OnDifficultyApplied += id => slowRestock = id == "my_mod_id.lean";

    // Or tweak a vanilla difficulty.
    ModHelper.ModifyDifficulty(Difficulty.HARD, d => d.rules.vendorPermitFee = 1000);
}

public void OnDisable()
{
    ModHelper.RemoveDifficulties("my_mod_id");
}
```

Rules:

- **Register in `Init` or `OnEnable`.** Keep ids stable and unique (prefix them with your mod id): the run saves the id. A save started with a difficulty whose mod is gone plays as normal.
- **`configure` edits a copy** of the difficulty named by `basedOn` (`Difficulty.NORMAL` by default; `Difficulty.HARD` to start from hard). Every field of `DifficultyRules` is documented in `Difficulty.cs`: markup, rent increase, rent grace, service fee multipliers and first-night bumps, appraisal and permit prices, new customer discount, favor rates, security presence steps, the warning, the game over at full presence, the bailout, the reminders, the hints.
- **The plate.** The selection screen shows your `title` (28 px caps), the `subtitle` under it, the effect list and, with `iconKey`, a 164x164 image (a placeholder box without one).
- **The effect list is generated.** The screen lists one line per rule group that differs from Normal ("Higher nightly service fees", "No Wild's favor from trades"...). `notes` adds lines for effects the rules do not express; implement those yourself from `ModHook.OnDifficultyApplied(id)`, which fires when a run starts and when a save loads.
- `ModHelper.GetDifficultyId()`, `GetDifficultyRules()` and `IsDifficultyAtLeast(id)` (by order: `IsDifficultyAtLeast(Difficulty.HARD)` is true on hard and challenge) tell what the current run plays on. Skip intro and endless mode are separate toggles, not difficulties.
- `ModifyDifficulty` works on the shared definition, so two mods changing the same rule see each other's value; the last one to run wins.

---

## Afterhour Locations

After the shutter closes the player picks a destination on the transit screen (the dumping ground, the commissary, Dr. Jackson's). Your mod can add its own place: register a location, and the screen lists it after the vanilla ones with your title and picture once `isDiscovered` says so. Travelling there runs the shared outing (the store is left, the afterhour bag is shown with the chosen backpack), then your `onArrive`, then your panel; the Return button on that panel brings the player back through your `onLeave`.

```csharp
public void OnEnable()
{
    var mine = ModHelper.AddAfterhourLocation("my_mod_id", "my_mod_id.black_dock",
        title: () => ModHelper.GetLocalized("my_mod_id", "black_dock_title"),
        imageKey: "my_mod_id:black_dock_card",        // a sprite from your Textures, shown on the card (296x168)
        backgroundKey: "my_mod_id:black_dock_scene",  // the scene behind the panel (960x540 like the vanilla ones)
        ambienceId: "my_mod_id.dock",                 // registered below once your sounds are loaded
        isDiscovered: () => ModHelper.GetModDataBool("my_mod_id", "dock_found"),
        onArrive: () => ModLog.Log("welcome to the dock"),
        buildPanel: builder =>
        {
            builder.AddLabel("The dock is quiet tonight.");
            builder.AddButton("Search the crates", () =>
            {
                ModHelper.MoveItemToAfterhours(ModHelper.SpawnItem("scrap_metal"));
            });
        });

    mine.allowsHazardousWaste = true;                 // the bag accepts hazardous waste here
    mine.leaveWarning = () => "The dock workers keep what you leave behind.";

    ModHook.OnModAssetsLoaded += mod =>
    {
        if (mod.Manifest.ID != "my_mod_id") return;
        ModHelper.RegisterAfterhourAmbience("my_mod_id", "my_mod_id.dock", "dock_loop");  // Sounds/dock_loop.ogg
    };

    // A temporary event on your location (or a vanilla one). The card lists every running
    // event of a location: its title, its optional description and its effects as bullets;
    // an effect's modifier is read by the mechanics (the values of all running events add up).
    ModHelper.AddAfterhourEvent("my_mod_id", "my_mod_id.fresh_dump", AfterhourLocation.DUMPING_GROUND,
        title: () => "Fresh Dump", durationDays: 2,
        description: () => "A hauler just tipped a fresh load.",
        effects: new[]
        {
            ModHelper.AfterhourEffect(() => "Junk 50% less likely", "junk_chance", -50f, AfterhourEffectPolarity.Good),
            ModHelper.AfterhourEffect(() => "Injuries 25% more likely", "injury_chance", 25f, AfterhourEffectPolarity.Bad),
            ModHelper.AfterhourEffect(() => "Dock workers are watching"),   // text only, neutral
        },
        dailyChancePercent: 10f);
}

public void OnDisable()
{
    ModHelper.RemoveAfterhourLocations("my_mod_id");
    ModHelper.RemoveAfterhourEvents("my_mod_id");
}
```

Rules:

- **Register in `Init` or `OnEnable`.** Ids are saved (visits, counters, the running event live under them), so keep them stable and prefix them with your mod id. `AddAfterhourLocation` returns the `DelegateAfterhourLocation` it registered: every option a location has is a field on it (`backgroundSortingOrder`, `usesAfterhourBag`, `showsStoreCounters` with `frontCounterPosition` / `backCounterPosition`, `allowsHazardousWaste`, `countsDumpedWaste`, `onTick`, `panelTitle`, `leaveWarning`, `isAvailable`). You can also subclass `AfterhourLocation` yourself and pass it to `AddAfterhourLocation(location)`.
- **`onArrive` and `onLeave` run inside the black screen**, after the shared setup and before the shared return. Do not open or close the bag or the store windows yourself; spawn what the place offers with `SpawnItem` and `MoveItemToAfterhours`, open your own windows through `CustomUIManager` (they close on return with the rest). `onTick` runs every frame while the player is there.
- **The panel** is built from your `buildPanel(CustomUIBuilder)` (labels, buttons, toggles, sliders, images: see Custom UI) and gets the Return button after your controls. `ReturnFromAfterhour()` returns from your own control instead. A mod that builds its own panel GameObject sets `panelObject` and the game activates it instead of building one (then it needs its own Return control).
- **Pictures and the scene.** `imageKey` and `backgroundKey` go through the same lookup as `AddImage` (`"modId:spriteName"`). The card crops the picture to 296x168 keeping its aspect; the scene sprite is drawn at the origin with sorting order `backgroundSortingOrder` (20 by default; the vanilla art is 960x540). A mod that builds its own scene GameObject sets `stageObject` instead and the game activates it while the player is there. Without a picture the card shows a placeholder plate.
- **`isAvailable`** false shows the card greyed with "Unavailable" and refuses travel; `isDiscovered` false hides it. Both are asked every time the screen opens.
- **Where am I.** `ModHelper.IsOutsideStore()` and `GetCurrentAfterhourLocationId()`; the hooks `ModHook.OnAfterhourArriveEarly / Late` and `OnAfterhourLeaveEarly / Late` fire with the location id for every location, vanilla ones included (`AfterhourLocation.DUMPING_GROUND`, `COMMISSARY`, `DR_JACKSON`).
- **State.** `GetAfterhourVisits(id)`, `GetAfterhourCounter(id, key)` / `SetAfterhourCounter(id, key, value)` are saved with the run under the location id.
- **Events.** Several events can run on one location at once. `AddAfterhourEvent` with a `dailyChancePercent` starts on its own at day start while it is not already running (cap a location with `maxConcurrentEvents`), or with `weekdays` (`AfterhourWeekday.Wednesday`...) on those days of the station week (day 1 is Monday; a day a scheduled event starts on has no random events); `closesLocation: true` makes the location unavailable while the event runs (greyed card, no travel, the event still listed); `StartAfterhourEvent(eventId, days)` adds one from code (a running one is extended), `EndAfterhourEvent(eventId)` ends one, `EndAllAfterhourEvents(locationId)` all; `IsAfterhourEventActive(eventId)`, `GetActiveAfterhourEventIds(locationId)` and `GetAfterhourModifier(locationId, key)` (the sum over the running events) read them; your own mechanics read your own modifier names. The vanilla modifiers are relative percentages on a chance the game already has (write the effect line as "X% more/less likely"): the dumping ground reads `injury_chance` (scales both wound chances), `junk_chance` (scales the junk table's weight in the loot roll, negative for less junk) and `loot_double_chance` (percentage points added to the scanner's double-loot chance); two are not chances: `injury_immunity` (above 0: no wounds at all) and `scav_attempts` (flat extra attempts per night). Dr. Jackson's reads `inventor_sell_price` (relative change of his shop prices) and the commissary `commissary_restock_percent_of_max` (a share of each item's max stock added at day start). The vanilla events (`fresh_dump`, `georgio_assistance`, `special_stock`, `jackson_discount`, `commissary_burglary`, `fresh_restock`) use them. On the card the title is green when every effect is good, red when every one is bad and orange when mixed (pass `tone` to force one); the days left show after the description. `ModHook.OnAfterhourEventStarted / Ended` fire with the location id and the event id. The F9 console's `afterhour-events`, `afterhour-event-start` and `afterhour-event-end` test them.

---

## Mod Configuration

Your mod gets its own settings panel and a saved settings file without writing any UI or file code. Define entries once, read their values at runtime, and the game does the rest: it saves them, restores them on the next start, and draws a configuration panel for them behind the gear button of your mod in the Mods menu.

```csharp
public class MyMod : IMod
{
    ConfigEntry<float>  courierSpeed;
    ConfigEntry<bool>   fastDelivery;
    ConfigEntry<string> theme;
    ConfigEntry<Difficulty> difficulty;

    public void Init(ModManifest manifest)
    {
        ModConfig config = ModHelper.GetConfig(manifest.ID);

        courierSpeed = config.Define("courier_speed", 1f, "General", () => "Courier speed",
            min: 0.1f, max: 3f, tooltip: () => "Multiplier on courier travel time.");
        fastDelivery = config.Define("fast_delivery", false, "General", () => "Fast delivery");
        theme        = config.Define("theme", "Classic", "Look", () => "Theme",
            choices: new[] { "Classic", "Neon", "Paper" });
        difficulty   = config.DefineEnum("difficulty", Difficulty.Normal, "Gameplay", () => "Difficulty",
            requiresRestart: true);

        courierSpeed.OnChanged += v => RecalculateRoutes();
    }

    void SomewhereLater()
    {
        float speed = courierSpeed.Value;   // always the current, saved value
        if (fastDelivery.Value) { ... }
    }
}
```

What each entry becomes in the panel:

| Definition | Control |
|---|---|
| `bool` | toggle |
| `int` / `float` with `min` and `max` | slider (whole numbers for `int`) |
| `int` / `float` without a range | text field, parsed on Apply |
| `string` with `choices` | dropdown |
| `string` without choices | text field |
| `DefineEnum<T>` | dropdown of the enum names |

Rules:

- **Define in `Init`** (or `OnEnable`). The saved value is already applied when `Define` returns, so `Value` is right from the first read. Keys are per mod; use whatever names you like.
- **Values live in one file per mod**: `<persistentDataPath>/ModConfigs/<your mod id>.json`, a readable list of key and value pairs. It survives Workshop updates and is shared by all save slots (per-run data belongs in [mod data](#saving-mod-data)). Players can edit or delete it; a missing key takes the default, a number outside its range is clamped, an unreadable value falls back to the default with a warning, and keys your mod no longer defines are kept.
- **Changes arrive through `OnChanged`**, fired when the player presses Apply in the panel (once per entry that actually changed), when your code calls `entry.Set(value)`, or on `config.ResetToDefaults()`. Never on load. `ModHook.OnModConfigApplied(modId)` fires once per Apply for mods that prefer a single refresh.
- **`requiresRestart: true`** marks a value you only read at startup; the panel tells the player to restart after applying it.
- **Labels and tooltips are functions**, resolved when the panel is built, so `() => ModHelper.GetLocalized(...)` follows the language. A tooltip adds the info icon next to the label. The section string is shown as the header as given.
- The panel has **Reset to Defaults** (puts the defaults into the controls; nothing changes until Apply) and **Apply**. It is reachable from the Mods menu in the main menu; there is no in-game entry point yet.
- Only an **active** mod runs `Init`, so the gear button is disabled for inactive mods.

---

## Capabilities and the Scanner

A mod DLL runs with the same rights as the game, so the game cannot make a mod safe. What it does instead is make the player's **Activate** click an informed decision and remember exactly what was approved. When a player activates your mod, the game reads your DLLs (without loading them) and checks three things before it writes the approval:

1. the developers' remote block list (a mod found to be malicious is refused on every player's machine within hours, no game update needed);
2. that none of your DLLs carries the name of a game or framework assembly (`0Harmony`, `Assembly-CSharp`, `UnityEngine.*`, `Steamworks.NET`, `mscorlib`, ...);
3. that everything your code reaches is covered by the `<Capabilities>` element of your manifest.

The approval records the hashes of your manifest and listed DLLs. From then on the mod loads at every start as long as the files still match, or changed without gaining a capability.

### Declaring capabilities

`<Capabilities>` is required and, for most mods, empty: `<Capabilities />`. Items, machines, hooks, Harmony patches on game code, configuration, mod data, sprites, sounds, localization, loot files, books, custom UI: none of it needs a capability. Declare one only when your code uses what the table lists.

| Capability | What triggers it | Capability-free alternative |
|---|---|---|
| `files` | `System.IO.File`, `FileStream`, `Directory`, `FileInfo`, `DirectoryInfo`, `StreamReader` / `StreamWriter` opened on a path, ES3 overloads that take a path, `UnityEngine.Windows.File` | `ModHelper.GetConfig` for settings, `SetModData` for run data, `ReadModFile*` and `*ModDataFile*` for files (see below) |
| `network` | `System.Net.*` (`HttpClient`, `WebClient`, sockets), `UnityWebRequest`, `WWW`, Steam HTTP and networking APIs | none, declare it |
| `process` | `System.Diagnostics.Process`, `ProcessStartInfo`, `Application.OpenURL` (it runs ShellExecute, which can start a program) | none, declare it |
| `dynamic-code` | `Assembly.Load*`, `AppDomain.Load`, `Reflection.Emit`, `Activator.CreateInstanceFrom`, embedded resources that look encrypted | none, declare it |
| `native` | `DllImport`, `unsafe` code and pointers, `calli`, `Marshal`, `UnsafeUtility` | none, declare it |
| `reflection-external` | `Type.GetType`, `GetMethod` / `GetField` / `GetProperty` / `InvokeMember`, `Assembly.GetType`, `AccessTools` or `Traverse` with a **computed** name, or with a literal name under `System.`, `UnityEngine.`, `HarmonyLib.`, `Steamworks.`, `ES3` | reflect on game types with `typeof(GameItem)` or a literal game type name: that is free |

Only the game's own types (`Assembly-CSharp`) and your own are free for reflection. The scanner follows the IL back to the instruction that produced the type or the name; when it cannot tell (the value came through a variable, a branch, a method call), it counts as computed, so prefer `AccessTools.Method(typeof(PlayerStore), "ModCash")` over `AccessTools.Method("PlayerStore:ModCash")` built from strings, and `typeof(X)` over `someObject.GetType()`.

Declaring more than you use is allowed; the player simply sees the longer list. Using more than you declare refuses the activation, with the list of what was found.

### Hard refusals

Some patterns refuse the activation whatever the manifest says, because no legitimate mod needs them:

- an embedded resource that is an executable, or any resource that looks encrypted (high entropy and not a known image, sound, text or `.resources` format);
- string constants pointing at browser profiles, Steam login files, Discord data or crypto wallets;
- a string constant of a thousand or more base64 characters (a hidden payload);
- `Harmony.UnpatchAll()` without your Harmony id (it removes every mod's patches);
- Harmony patches or reflection aimed at the game's mod loader or trust code (`ModLoader`, `ModTrust`, `ModScanner`, `ModTrustList`);
- shipping your own `0Harmony`, MonoMod or Cecil, or any DLL named like a game assembly (including libraries the game already ships, such as `Newtonsoft.Json`). Reference the game's copies instead;
- a DLL in your folder that `<Assemblies>` does not list, or a listed DLL that references an assembly which is neither the game's nor listed. The runtime would load such a file from your folder without the scan, so the whole mod is refused until the manifest lists it.

Third-party libraries you bundle are scanned like your own code and must be listed. Many of them use reflection or `Reflection.Emit` internally, which then has to appear in your `<Capabilities>`; prefer libraries the game already ships. Embedded resources that are images, sounds, JSON, XML or `.resources` files are fine.

### Checking before you publish

Open the console (F8) and run `mod-scan <your_mod_id>` (any listed mod, active or not) or `mod-scan <path to a folder>`. It prints the listed assemblies, DLLs in the folder that are not listed, the capabilities your manifest declares, the capabilities the scanner detected, each finding as `capability: Type.Method -> what it referenced`, any hard flag, and the version hash. Fix the manifest until `declared` covers `detected` and there are no hard flags. If a finding surprises you, the method name tells you where to look; most `reflection-external` findings go away by switching to `typeof(...)`.

### What players see

- **Activating** a mod with an empty `<Capabilities>` just works. A mod with declared capabilities shows the player a confirmation listing them in plain words ("Access the internet", "Start other programs or open links", ...) and warning that such a mod can do anything they can. A refused mod shows why.
- The detail pane shows your capabilities and the approval state: approved on this date, updated without new capabilities, verified by the developers, or why it was not loaded.
- **Updating**: identical files load. Changed files that gain no capability load, and the pane notes the update. Changed files that gain a capability, or a new version that fails the scan, do not load; the row shows a warning and the pane offers **Review and enable**, which runs the activation checks again. Plan your capabilities before the first release: adding one later interrupts every player.
- **Deactivating** withdraws the approval; the next activation goes through the checks again.
- A mod on the remote **block list** cannot be activated and is turned off on the machines where it was running, with the reason shown. In an emergency the developers can pause all mod loading until a fix ships; the Mods menu says so.
- The first time the Mods menu opens, the game still tells the player that mods can contain code.

### Developer mode

While you work on a local mod (in `Mods/`), every rebuild changes the hashes. Once the mod has been activated once, the detail pane shows a **Developer mode** button for local mods: turn it on and every change of that folder is trusted at start, scan or no scan (the console still logs what the scan found). It is per mod, per computer, and off by default. Workshop copies never have it.

### Reading and writing files without the capability

`ModHelper` has helpers that stay inside two folders, so a mod using only them has nothing to declare:

```csharp
// Read-only: your mod folder (Mods/<folder> or the Workshop item). Relative paths only.
string notes = ModHelper.ReadModFileText("my_mod_id", "Data/notes.txt");      // null when missing
byte[] blob  = ModHelper.ReadModFileBytes("my_mod_id", "Data/table.bin");
bool has     = ModHelper.ModFileExists("my_mod_id", "Data/notes.txt");

// Read and write: a folder of your own in the save location (persistentDataPath/ModData/my_mod_id/).
ModHelper.WriteModDataFileText("my_mod_id", "cache/prices.json", json);
string cached = ModHelper.ReadModDataFileText("my_mod_id", "cache/prices.json");
ModHelper.DeleteModDataFile("my_mod_id", "cache/prices.json");
List<string> files = ModHelper.ListModDataFiles("my_mod_id");
string folder = ModHelper.GetModDataFolder("my_mod_id");                      // the folder itself, if you need to show it
```

A path that is absolute, empty or escapes the folder (`../`) throws `ArgumentException`. Do not write into your mod folder: Steam overwrites Workshop folders on every update. For values tied to a run, `SetModData` is still the right tool (see [Saving Mod Data](#saving-mod-data)); for settings, [Mod Configuration](#mod-configuration).

---

## Steam Workshop

Players can get mods from the game's Steam Workshop page as well as from the `Mods/` folder. A Workshop item is simply a mod folder, exactly as described in [Mod Assets](#mod-assets), with `manifest.xml` at its root; the game loads it from Steam's install location with the same loader as local mods. Nothing in your code changes.

What players see:

- Subscribed items appear in the Mods menu with a Steam icon and start **inactive**. The player activates them like any other mod, and the game must restart for that to take effect. An item subscribed while the game is running shows up after the next start.
- The Mods menu shows the item's Workshop preview image (the `previewfile` you upload, see below). A `preview.png` in the item's folder is only used when Steam has no preview or is offline. Mods without any image show no banner at all.
- **Unsubscribe Selected** in the Mods menu removes a Workshop mod: its row disappears and it is deactivated right away, and Steam deletes its files. If it was running, it keeps running until the game restarts. The Steam button next to Activate opens the item's Workshop page (in the Steam overlay, or in the browser when the overlay is turned off).
- Items that were subscribed but not yet downloaded when the game started download in the background; the Mods menu shows how many are still downloading, and they appear after the next restart.
- If a local folder in `Mods/` has the same `<ID>` as a subscribed item, the local copy is used and the Workshop copy is ignored. That is how you test a new version of your own mod without unsubscribing. The Mods menu notes it on the local mod, and that mod's Steam button and Unsubscribe act on the Workshop item (unsubscribing keeps the local copy).
- The first time the Mods menu opens, the game tells the player that mods can contain code. Keep that in mind: a mod that behaves badly hurts every modder's reputation.

Workshop is available on the main game only, not on the demo.

### Publishing with steamcmd

The game has no upload button. Items are published with Valve's `steamcmd` tool, using a Steam account that owns the game:

1. Install [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD) and make sure your mod folder has `manifest.xml` at its root and, ideally, a `preview.png` under 1 MB.
2. Write an item description file, for example `my_mod.vdf`:

```
"workshopitem"
{
    "appid"            "4348910"
    "publishedfileid"  "0"
    "contentfolder"    "C:\\Games\\ProbablyStolen\\Mods\\MyMod"
    "previewfile"      "C:\\Games\\ProbablyStolen\\Mods\\MyMod\\preview.png"
    "visibility"       "0"
    "title"            "My Mod"
    "description"      "What the mod does."
    "changenote"       "First release"
}
```

`publishedfileid` `0` creates a new item. `visibility` is `0` public, `1` friends only, `2` hidden (use hidden for a first test).

3. Run:

```
steamcmd +login <your_steam_account> +workshop_build_item "C:\path\to\my_mod.vdf" +quit
```

steamcmd prints the new item's id and writes it back into the `.vdf`. Keep that file: running the same command again with the id filled in **updates** the existing item, and subscribers receive the new version automatically. The first upload also requires accepting the Workshop legal agreement once, on the Steam website.

Tips: the manifest's `<GameVersions>` are what the Mods menu uses to colour compatibility, so keep them current when you update; list other mods your mod needs in `<Prerequisites>`, and mention them in the Workshop description too, since Steam does not subscribe to them automatically.

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
| Mod doesn't appear in the mod menu | No `manifest.xml` in the mod's root folder, or its `<ID>` is empty (look for a `[ModLoader]` warning), or the folder has no DLL with a class implementing `IMod` (look for `[Your Mod Name] Error: ...`). The loader skips the folder in every case. |
| Mod appears but nothing happens | The mod isn't enabled, or you didn't restart after enabling it. **Enabling, disabling, and reordering only take effect on the next launch.** |
| `[Your Mod Name] Error: ...` in the console, and a warning icon on your mod in the Mods menu | Your DLL failed to load (a library it references is missing, or it targets the wrong framework), or `Init`, `OnEnable`, or a Harmony patch threw. The line names the exception and the full stack trace follows it. When a mod from the `Mods/` folder fails, the console opens on its own at launch (Workshop mods only get the warning icon). The mod stays in the active list so you can deactivate it. |
| Code changes don't take effect | You copied an old DLL. Rebuild (`dotnet build -c Release`) and copy the fresh DLL from `bin/Release/netstandard2.1/` into the mod folder. |
| Item shows the "unknown" placeholder sprite | The `spriteKey` or mod ID passed to `SetSpriteAndShapeFromMod` doesn't match. The key is the **file name** (no extension, no folder); the ID is your manifest `<ID>`, **not** the folder name. Check the `item sprite(s) loaded` count in the console. |
| A sprite file is ignored entirely | It isn't *directly* inside `Textures/Items/` (subfolders aren't scanned), or it isn't a `.png`/`.jpg`. |
| `PlaySound` returns false / warning `Audio identifier ... was not found` | The mod ID or sound key doesn't match. The full identifier is `<manifest ID>:<file name without extension>`. Check the `sound(s) loaded` count in the console. Sounds also finish loading a few frames after startup ([wait for them](#knowing-when-your-assets-are-ready) if playing very early). |
| `GetLocalized` returns the key itself | No entry for that key in the current locale's CSV or in `en.csv`, or the file name doesn't match the game's locale code. Look for the one-time `[ModHelper]` warning and check the `localization entries loaded` count in the console. |
| `requires '<id>' which is not loaded/enabled` warning | Your manifest lists a `<Prerequisites>` mod that isn't enabled. Enable it, or drop the dependency. |
| Harmony patch never runs | The target type/method name is wrong, or the mod is disabled; patches are only applied to **enabled** mods, at launch. |
| My item never drops | Run `loot-list <tableId>` in the console. If the entry is missing, the table ID is wrong or the edit was rejected (look for a `[LootRegistry]` warning naming your mod). If it is there, check the percentage: weight `10` in a vanilla table is about 1%. |
| `[LootRegistry] ... which does not exist` warning | The table or group ID in your edit or JSON file does not match any table. `loot-list` prints every ID. When registering your own table, register it before patching or grouping it. |
