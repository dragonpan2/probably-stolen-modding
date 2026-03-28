# probably-stolen-modding
This is a beginner friendly guide and examples about developing mods for Probably Stolen.

## Table of Contents
- [Requirements](#requirements)
- [Folder Setup](#folder-setup)
- [Creating your first Mod](#creating-your-first-mod-for-probably-stolen)
  - [Create the mod project](#create-the-mod-project)
  - [Edit TestMod.csproj](#edit-testmodcsproj)
  - [Create your manifest.xml](#create-your-manifestxml)
  - [Write your mod](#write-your-mod)
  - [Build the mod](#build-the-mod)
- [Install and Test the Mod](#install-and-test-the-mod)
  - [Create the mod folder](#create-the-mod-folder)
  - [Run the game and activate the mod](#run-the-game-and-activate-the-mod)
- [Save File Responsibility](#save-file-responsibility)

<a name="requirements"></a>
To start developing mods for Probably Stolen, you will need:
- A digital copy of Probably Stolen in order to access the .dll files
- Some knowledge of programming in C#
- [.NET SDK](https://dotnet.microsoft.com/download) (version 6.0 or later) installed on your machine

Probably Stolen uses Harmony to allow modders to patch in-game functions. Additionally, modders can append actions to the pre-defined hook points purposely exposed for modding. While Harmony patches are more powerful and flexible, using actions via hook points is more performant and should be preferred over Harmony patching when possible.

<a name="folder-setup"></a>

Recommended folder setup.

The Mods folder is used to let the game discover ready-to-install mods.
The Modding folder is used for mod developers.

```
Probably Stolen/
├── Probably Stolen.exe
├── Mods/
│   └── TestMod/
│       ├── manifest.xml
│       └── TestMod.dll
└── Modding/
    └── TestMod/
        ├── TestMod.cs
        └── TestMod.csproj
```

# Creating your first Mod for Probably Stolen

If not done already, create a Modding folder in your Probably Stolen root folder (same place where Probably Stolen.exe is).

### Create the mod project

Using the command line while in the Modding folder:
```bash
mkdir TestMod
cd TestMod
dotnet new classlib -n TestMod --framework netstandard2.1
cd TestMod
```
### Edit TestMod.csproj

Replace the contents with:

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.1</TargetFramework>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <Reference Include="Assembly-CSharp">
      <HintPath>..\..\Probably Stolen_Data\Managed\Assembly-CSharp.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="UnityEngine">
      <HintPath>..\..\Probably Stolen_Data\Managed\UnityEngine.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="UnityEngine.CoreModule">
      <HintPath>..\..\Probably Stolen_Data\Managed\UnityEngine.CoreModule.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="0Harmony">
      <HintPath>..\..\Probably Stolen_Data\Managed\0Harmony.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>

</Project>
```

### Create your manifest.xml

Every mod requires a `manifest.xml` file in the root of its mod folder. This file contains all the metadata about your mod and must be present for the game to recognize it.

Create a file named `manifest.xml` and fill in your mod's information:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Manifest>
  <ID>test_mod</ID>
  <Name>Test Mod</Name>
  <Author>YourName</Author>
  <ModVersion>1.0</ModVersion>
  <Description>A test mod for demonstration purposes.</Description>
  <GameVersions>
    <Version>045</Version>
  </GameVersions>
  <Prerequisites />
</Manifest>
```

Field descriptions:
- **ID** — A unique identifier for your mod. Use lowercase letters and underscores (e.g. `my_cool_mod`). This is required — the game will skip your mod folder if it is missing.
- **Name** — The display name shown in the mod menu.
- **Author** — Your name or username.
- **ModVersion** — The version of your mod.
- **Description** — A short description of what your mod does.
- **GameVersions** — The list of game versions your mod is compatible with. Add one `<Version>` entry per supported version.
- **Prerequisites** — The IDs of other mods that must be loaded before yours. Leave the tag empty (`<Prerequisites />`) if there are none. Add one `<Mod>` entry per dependency:

```xml
<Prerequisites>
  <Mod>some_other_mod_id</Mod>
</Prerequisites>
```

### Write your mod

Open `TestMod.cs` with a text editor or any IDE of your choice and replace the content with the following.

```csharp
using System;
using UnityEngine;
using HarmonyLib;

namespace TestMod
{
    public class Class1 : IMod
    {
        public void Init()
        {
            Debug.Log("[TestMod] Hello from Test Mod! The modding system works!");
        }

        public void OnDisable()
        {
            Debug.Log("[TestMod] Test Mod disabled. Goodbye!");
        }
    }
}
```

Note that your mod's name, ID, author, and other details are no longer defined in code — they come entirely from `manifest.xml`.

### Build the mod

Go into your mod's directory and open a command prompt there.

```bash
cd TestMod
dotnet build -c Release
```

The output DLL will be at: `TestMod/bin/Release/netstandard2.1/TestMod.dll`

## Install and Test the Mod

### Create the mod folder

```
Probably Stolen/
├── Probably Stolen.exe
└── Mods/
    └── TestMod/
        ├── manifest.xml      ← your manifest file
        └── TestMod.dll       ← copy from build output
```

Copy the `TestMod.dll` file and your `manifest.xml` into the mod folder. Both files are required.

### Run the game and activate the mod

Launch the game. If everything is set up correctly, your mod should be visible in the mod menu. Enable your mod and restart the game. After restarting, your mod will be active. Open the console via the F8 key — if your mod is working, it will display `[TestMod] Hello from Test Mod! The modding system works!`.

## Save File Responsibility

Player saves are permanent and belong to the player. As a mod author, you are responsible for how your mod interacts with them.

**Never:**
- Delete save files
- Corrupt saves silently (e.g. writing invalid data that breaks loading)

**If your mod affects saves:**
- Warn players clearly in your mod's description before they install it
- Provide a safe uninstall path — document what the player needs to do before disabling your mod to avoid losing progress

**Rule of thumb:** A player should be able to disable your mod without losing progress unless this is clearly stated upfront.
