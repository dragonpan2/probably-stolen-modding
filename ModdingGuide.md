# Probably Stolen — Modding Guide

This guide covers advanced topics for mod development and assumes you have already read the [README.md](README.md) quick start. For modding community rules, see [CodeOfConduit.md](CodeOfConduit.md).

## Table of Contents
- [Probably Stolen — Modding Guide](#probably-stolen--modding-guide)
  - [Table of Contents](#table-of-contents)
  - [Example Projects](#example-projects)
  - [Logging with ModLog](#logging-with-modlog)
  - [Dev Tools](#dev-tools)
  - [Save File Responsibility](#save-file-responsibility)
  - [Supported \& Unsupported Modding Features](#supported--unsupported-modding-features)
    - [✅ Natively supported](#-natively-supported)
    - [❌ Not supported at the moment](#-not-supported-at-the-moment)
  - [Harmony Patches](#harmony-patches)
    - [Patches are applied automatically](#patches-are-applied-automatically)
    - [Postfix — run code after the original](#postfix--run-code-after-the-original)
    - [Prefix — run code before the original](#prefix--run-code-before-the-original)
    - [Finalizer — run code even when the original throws](#finalizer--run-code-even-when-the-original-throws)
    - [Transpiler — rewrite the original method's IL (advanced)](#transpiler--rewrite-the-original-methods-il-advanced)

---

## Example Projects

📁 Full example mod projects are included in this repository alongside the guide. They are complete, buildable mods you can open, study, and adapt — use them as a reference whenever a snippet here doesn't give you enough context to see how the pieces fit together as a whole project.

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

- 🐛 **Debug Console — `F8`** — opens a console that displays all log output, including messages from `ModLog`, `Debug.Log`, warnings, and errors. Use this to verify your mod loaded, watch hook points fire, and read stack traces when something goes wrong.
- 🛠️ **Dev Menu — `F9`** — opens a menu containing many functions useful for mod development and testing, such as spawning items, triggering events, and inspecting game state. Handy for reproducing edge cases without having to play through to them.

---

## Save File Responsibility

Player saves are permanent and belong to the player. As a mod author, you are responsible for how your mod interacts with them.

**Never:**
- Delete save files
- Corrupt saves silently (e.g. writing invalid data that breaks loading)

**If your mod affects saves:**
- Warn players clearly in your mod's description before they install it
- Provide a safe uninstall path — document what the player needs to do before disabling your mod to avoid losing progress

**Rule of thumb:** A player should be able to disable your mod without losing progress unless this is clearly stated upfront.

---

## Supported & Unsupported Modding Features

Not every kind of mod is feasible right now. Before you start a project, check that what you have in mind is on the supported list — otherwise you may hit walls the modding API doesn't currently let you work around.

### ✅ Natively supported

- **Modded items with custom sprites** — add new items to the game, including their artwork
- **Modded customers with custom sprites** — add new customers with their own appearance
- **Modded events** — add new in-game events

### ❌ Not supported at the moment

- **Custom UI** — adding entirely new UI panels or screens
- **Major changes to existing UI** — restructuring or replacing built-in UI
- **Changes to the store** — modifying the store's behavior or contents
- **Overhaul-style mods** — sweeping reworks that touch many systems at once
- **Modded deals for the Underground Exchange** — adding new deals to the Underground Exchange
- **Special Item** - Inspectable Items and Appraisal Items

Not supported features may be supported in the future.

---

## Harmony Patches

> ⚠️ **Prefer native hooks when they exist.** Harmony has measurable runtime overhead and is more sensitive to game updates than the native modding API. If the feature you need is on the [natively supported](#-natively-supported) list, use that. Reach for Harmony when there is no native hook for what you want to do — that's exactly what it's for.

Harmony is a runtime patching library that lets you inject code before, after, or in place of any method in the game. The `0Harmony.dll` reference is already included in the `.csproj` from the [README.md](README.md) quick start.

### Patches are applied automatically

You do not need to call `Harmony.PatchAll()` yourself. The game scans each loaded mod assembly and applies every `[HarmonyPatch]` class it finds. Just declare your patch classes (see below) and they will be active as soon as the mod is enabled.

### Postfix — run code after the original

A **Postfix** runs after the original method completes. Use it to observe results, or to modify the return value via the `__result` parameter.

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class PrintLog
{
    // Postfix runs AFTER the original method.
    // __result is a ref to the return value — we can change it.
    static void Postfix()
    {
        Debug.Log("[TestMod] StoreClientManager.GenerateClient called.");
    }
}
```

### Prefix — run code before the original

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

### Finalizer — run code even when the original throws

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

### Transpiler — rewrite the original method's IL (advanced)

A **Transpiler** rewrites the original method's IL instructions before they run. This is the most powerful patch type, but also the most fragile — small game updates can break a transpiler that matches specific opcode patterns. Only use one when Prefix / Postfix / Finalizer can't express what you need.

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
