# Probably Stolen: Modding API Changes

What changed in the modding API, per game update, newest on top. Within each update, entries are ordered by importance: things you must act on first, new capabilities last. Full documentation lives in [ModdingGuide.md](ModdingGuide.md).

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

- **Decompilation: look, don't copy.** Decompiling the game to study it and find patch targets is officially tolerated; redistributing game code or assets is not. [Full policy](CodeOfConduit.md#decompilation-policy)
