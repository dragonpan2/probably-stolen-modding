# Probably Stolen: Modding API Changes

中文版本：[APIChanges.zh-CN.md](APIChanges.zh-CN.md)

What changed in the modding API, per game update, newest on top. Within each update, entries are ordered by importance: things you must act on first, new capabilities last. Full documentation lives in [ModdingGuide.md](ModdingGuide.md).

## Next update (in development)

**Action recommended**

- **Stop patching `TableMaster` / `TableGroupMaster` for loot changes.** Their static dictionaries are gone; rolls now go through `LootRegistry`, which has a supported API for exactly that. [Details](ModdingGuide.md#loot-tables)

**New**

- **Loot table editing.** Add your items to the game's drop tables, change or remove existing drops, and register new tables and groups: `ModHelper.AddLootEntry / SetLootWeight / RemoveLootEntry / RegisterLootTable` and the `Group` equivalents, callable from `OnEnable`. Weights are relative and vanilla tables sum to 1000, so weight `10` is about 1%. [Details](ModdingGuide.md#loot-tables)
- **JSON loot files.** The same edits as data: `LootTables/*.json` in your mod folder, no C# needed. [Details](ModdingGuide.md#editing-tables-with-json-files)
- **`ModHook.OnLootTablesLoaded`** (tables are ready, all edits applied) and **`ModHook.OnLootRolled(LootRollContext)`** (override the result of any roll). [Details](ModdingGuide.md#reacting-to-rolls)
- **Console commands** `loot-list [id]` and `loot-roll <id> [count]` to see effective odds, which mod touched what, and to test-roll a table. [Details](ModdingGuide.md#inspecting-tables-in-the-console)
- **Mod data store.** Save anything not tied to an item with `ModHelper.SetModData / GetModData` (plus `Int`, `Float`, `Bool` variants, `HasModData`, `RemoveModData`, `GetModDataKeys`, `ClearModData`). Namespaced by mod id, saved with the run, restored on load. [Details](ModdingGuide.md#saving-mod-data)
- **Custom UI.** Build your own windows from code with the `CustomUIManager` fluent builder (labels, buttons, toggles, sliders, inputs, dropdowns, progress bars, images, tabs, scroll lists), on any game canvas or a persistent overlay. Mod sprites work through the `"modId:spriteName"` key. Custom UI moves from the "not supported" list to supported. [Details](ModdingGuide.md#custom-ui)

## July 2026

**Action recommended**

- **Stop playing sounds through your own `AudioSource`.** Mod sounds are now registered with the game's audio system under `<modId>:<key>`. Use `ModHelper.PlaySound / PlaySound2 / PlaySound3(modId, key)` instead, so the player's volume and pause settings apply. Reading `mod.Sounds` directly still works but bypasses volume settings. [Details](ModdingGuide.md#sounds)

**Behavior change**

- **Hook handler exceptions no longer break the game or other mods.** Each subscriber runs in its own try/catch; errors are logged to the F8 console as `[ModHook] ... from '<your mod>' threw: ...` and everything else continues. Throwing from a handler to abort game code no longer works (it was never supported; use a Harmony prefix returning `false`). A logged exception still means your mod is broken.

**New**

- **CSV-based localization.** Ship translations as `Localization/<localeCode>.csv` files in your mod folder and read them with `ModHelper.GetLocalized(modId, key, args...)`. Resolves the current locale, falls back to English, then to the key itself. [Details](ModdingGuide.md#localization)
- **Custom item sounds.** Item sound fields (`soundUse`, `soundDragStart`, `soundContainerOpen`, ...) now accept mod sound identifiers: `item.soundUse = ModHelper.GetSoundIdentifier("my_mod_id", "gulp");`
- **`ModHook.OnModAssetsLoaded(LoadedMod)`**: fires once per enabled mod when all of its textures, item sprites, and sounds are in memory. Check `mod.Manifest.ID` is yours; it fires for every mod. [Details](ModdingGuide.md#knowing-when-your-assets-are-ready)

**Policy**

- **Decompilation: look, don't copy.** Decompiling the game to study it and find patch targets is officially tolerated; redistributing game code or assets is not. [Full policy](CodeOfConduct.md#respect-other-creators)
