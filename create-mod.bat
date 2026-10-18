@echo off
setlocal EnableDelayedExpansion
title Probably Stolen - new mod skeleton

:: ---------------------------------------------------------------------------
:: Creates the skeleton of a Probably Stolen mod: the C# project under
:: Modding\<Project>\ (csproj, manifest.xml, ModEntry.cs, asset folders) and a
:: post-build step that installs the build into Mods\<Project>\.
::
:: Put this file in the game folder (next to "Probably Stolen.exe") and
:: double-click it, or run it from anywhere and type the game folder when asked.
:: Needs the .NET SDK (dotnet) to build; see README.md, "Requirements".
:: ---------------------------------------------------------------------------

echo.
echo  Probably Stolen - new mod skeleton
echo  ==================================
echo.

:: ---------------------------------------------------------------- game folder
set "GAME=%~dp0"
if "!GAME:~-1!"=="\" set "GAME=!GAME:~0,-1!"
if exist "!GAME!\Probably Stolen.exe" goto gameok
:askgame
echo  This script is not inside the game folder.
set "GAME="
set /p "GAME= Game folder (the one containing Probably Stolen.exe): "
if "!GAME!"=="" goto askgame
set "GAME=!GAME:"=!"
if "!GAME:~-1!"=="\" set "GAME=!GAME:~0,-1!"
if not exist "!GAME!\Probably Stolen.exe" (
    echo  No "Probably Stolen.exe" in "!GAME!".
    goto askgame
)
:gameok
set "MANAGED=!GAME!\Probably Stolen_Data\Managed"
if not exist "!MANAGED!\Assembly-CSharp.dll" (
    echo  "!MANAGED!\Assembly-CSharp.dll" is missing. Is this a complete install?
    goto fail
)
echo  Game folder: !GAME!
echo.

:: ---------------------------------------------------------------- mod id
echo  The mod ID is the permanent, unique key of your mod (players' approvals,
echo  save data and the Workshop all use it). Lower case letters, digits, "_",
echo  "-" and "." only, for example: my_cool_mod
:askid
set "MODID="
set /p "MODID= Mod ID: "
if "!MODID!"=="" goto askid
echo(!MODID!| findstr /r /c:"^[a-zA-Z0-9][a-zA-Z0-9_.-]*$" >nul || (
    echo  Only letters, digits, "_", "-" and ".", and it cannot start with ".".
    goto askid
)
if not "!MODID:~64!"=="" (
    echo  At most 64 characters.
    goto askid
)

:: ---------------------------------------------------------------- project name
set "PROJ=!MODID:-=_!"
set "PROJ=!PROJ:.=_!"
echo(!PROJ!| findstr /r /c:"^[0-9]" >nul && set "PROJ=Mod!PROJ!"
echo.
echo  The project name is the C# namespace and the DLL name (letters, digits, "_").
:askproj
set "IN="
set /p "IN= Project name [!PROJ!]: "
if not "!IN!"=="" (
    echo(!IN!| findstr /r /c:"^[a-zA-Z_][a-zA-Z0-9_]*$" >nul || (
        echo  Letters, digits and "_" only, not starting with a digit.
        goto askproj
    )
    set "PROJ=!IN!"
)
set "PROJDIR=!GAME!\Modding\!PROJ!"
if exist "!PROJDIR!" (
    echo  "!PROJDIR!" already exists. Pick another project name or move that folder away.
    goto askproj
)

:: ---------------------------------------------------------------- the rest
echo.
set "NAME="
set /p "NAME= Display name [!MODID!]: "
if "!NAME!"=="" set "NAME=!MODID!"
set "AUTHOR="
set /p "AUTHOR= Author: "
if "!AUTHOR!"=="" set "AUTHOR=Unknown"
set "VERSION="
set /p "VERSION= Mod version [1.0]: "
if "!VERSION!"=="" set "VERSION=1.0"
set "DESC="
set /p "DESC= One-line description: "
if "!DESC!"=="" set "DESC=A mod for Probably Stolen."
echo.
echo  The game version your mod targets is shown in the Mods menu (compatibility
echo  colour). You can read it in the game's main menu. Leave empty to skip.
set "GAMEVER="
set /p "GAMEVER= Game version (for example 0.46): "

:: XML-escape the free text (& < > are what matters in element text; quotes are fine there).
for %%V in (NAME AUTHOR VERSION DESC GAMEVER) do (
    set "X=!%%V!"
    set "X=!X:&=&amp;!"
    set "X=!X:<=&lt;!"
    set "X=!X:>=&gt;!"
    set "%%V_XML=!X!"
)

:: ---------------------------------------------------------------- summary
echo.
echo  About to create:
echo    !PROJDIR!\!PROJ!.csproj      project, builds into Mods\!PROJ!\
echo    !PROJDIR!\manifest.xml       ID !MODID!, name "!NAME!", version !VERSION!
echo    !PROJDIR!\ModEntry.cs        the IMod class
echo    !PROJDIR!\Textures\Items\    plus Sounds\, Localization\, LootTables\, Books\
echo.
set "OK="
set /p "OK= Continue? [Y/n]: "
if /i "!OK!"=="n" goto cancelled

:: ---------------------------------------------------------------- folders
mkdir "!PROJDIR!" || goto fail
mkdir "!PROJDIR!\Textures\Items"
mkdir "!PROJDIR!\Sounds"
mkdir "!PROJDIR!\Localization"
mkdir "!PROJDIR!\LootTables"
mkdir "!PROJDIR!\Books"

:: ---------------------------------------------------------------- csproj
set "F=!PROJDIR!\!PROJ!.csproj"
>"!F!" echo ^<Project Sdk="Microsoft.NET.Sdk"^>
>>"!F!" echo.
>>"!F!" echo   ^<PropertyGroup^>
>>"!F!" echo     ^<TargetFramework^>netstandard2.1^</TargetFramework^>
>>"!F!" echo     ^<LangVersion^>latest^</LangVersion^>
>>"!F!" echo     ^<AssemblyName^>!PROJ!^</AssemblyName^>
>>"!F!" echo     ^<RootNamespace^>!PROJ!^</RootNamespace^>
>>"!F!" echo     ^<Nullable^>disable^</Nullable^>
>>"!F!" echo     ^<^^!-- Where the game is. The default assumes this project sits in ^<game^>\Modding\!PROJ!\ --^>
>>"!F!" echo     ^<GameDir^>$(MSBuildProjectDirectory)\..\..^</GameDir^>
>>"!F!" echo     ^<ManagedDir^>$(GameDir)\Probably Stolen_Data\Managed^</ManagedDir^>
>>"!F!" echo     ^<ModInstallDir^>$(GameDir)\Mods\!PROJ!^</ModInstallDir^>
>>"!F!" echo   ^</PropertyGroup^>
>>"!F!" echo.
>>"!F!" echo   ^<ItemGroup^>
>>"!F!" echo     ^<Reference Include="Assembly-CSharp"^>
>>"!F!" echo       ^<HintPath^>$(ManagedDir)\Assembly-CSharp.dll^</HintPath^>
>>"!F!" echo       ^<Private^>false^</Private^>
>>"!F!" echo     ^</Reference^>
>>"!F!" echo     ^<Reference Include="UnityEngine"^>
>>"!F!" echo       ^<HintPath^>$(ManagedDir)\UnityEngine.dll^</HintPath^>
>>"!F!" echo       ^<Private^>false^</Private^>
>>"!F!" echo     ^</Reference^>
>>"!F!" echo     ^<Reference Include="UnityEngine.CoreModule"^>
>>"!F!" echo       ^<HintPath^>$(ManagedDir)\UnityEngine.CoreModule.dll^</HintPath^>
>>"!F!" echo       ^<Private^>false^</Private^>
>>"!F!" echo     ^</Reference^>
>>"!F!" echo     ^<Reference Include="0Harmony"^>
>>"!F!" echo       ^<HintPath^>$(ManagedDir)\0Harmony.dll^</HintPath^>
>>"!F!" echo       ^<Private^>false^</Private^>
>>"!F!" echo     ^</Reference^>
>>"!F!" echo   ^</ItemGroup^>
>>"!F!" echo.
>>"!F!" echo   ^<^^!-- Files that ship with the mod besides the DLL: the manifest and the asset folders. --^>
>>"!F!" echo   ^<ItemGroup^>
>>"!F!" echo     ^<ModFile Include="manifest.xml;preview.png;Textures\**;Sounds\**;Localization\**;LootTables\**;Books\**" /^>
>>"!F!" echo     ^<None Remove="Textures\**;Sounds\**;Localization\**;LootTables\**;Books\**" /^>
>>"!F!" echo   ^</ItemGroup^>
>>"!F!" echo.
>>"!F!" echo   ^<^^!-- After every build, install the mod into ^<game^>\Mods\!PROJ!\ so the game picks it up. --^>
>>"!F!" echo   ^<Target Name="InstallMod" AfterTargets="Build"^>
>>"!F!" echo     ^<MakeDir Directories="$(ModInstallDir)" /^>
>>"!F!" echo     ^<Copy SourceFiles="$(TargetPath)" DestinationFolder="$(ModInstallDir)" /^>
>>"!F!" echo     ^<Copy SourceFiles="@(ModFile)" DestinationFiles="@(ModFile->'$(ModInstallDir)\%%(RecursiveDir)%%(Filename)%%(Extension)')" Condition="Exists('%%(ModFile.FullPath)')" /^>
>>"!F!" echo     ^<Message Importance="high" Text="Installed into $(ModInstallDir)" /^>
>>"!F!" echo   ^</Target^>
>>"!F!" echo.
>>"!F!" echo ^</Project^>

:: ---------------------------------------------------------------- manifest
set "F=!PROJDIR!\manifest.xml"
>"!F!" echo ^<?xml version="1.0" encoding="utf-8"?^>
>>"!F!" echo ^<Manifest^>
>>"!F!" echo   ^<ID^>!MODID!^</ID^>
>>"!F!" echo   ^<Name^>!NAME_XML!^</Name^>
>>"!F!" echo   ^<Author^>!AUTHOR_XML!^</Author^>
>>"!F!" echo   ^<ModVersion^>!VERSION_XML!^</ModVersion^>
>>"!F!" echo   ^<Description^>!DESC_XML!^</Description^>
if "!GAMEVER!"=="" (
    >>"!F!" echo   ^<GameVersions /^>
) else (
    >>"!F!" echo   ^<GameVersions^>
    >>"!F!" echo     ^<Version^>!GAMEVER_XML!^</Version^>
    >>"!F!" echo   ^</GameVersions^>
)
>>"!F!" echo   ^<Prerequisites /^>
>>"!F!" echo   ^<^^!-- Every DLL the game must load, relative to this folder. Nothing else in the folder is loaded. --^>
>>"!F!" echo   ^<Assemblies^>
>>"!F!" echo     ^<Assembly^>!PROJ!.dll^</Assembly^>
>>"!F!" echo   ^</Assemblies^>
>>"!F!" echo   ^<^^!-- What your code does beyond the game's API: files, network, process, dynamic-code, native, reflection-external.
>>"!F!" echo        Most mods need none. The game scans your DLL when a player activates the mod; an undeclared capability
>>"!F!" echo        refuses the activation. Check with the console command: mod-scan !MODID!   (see ModdingGuide.md) --^>
>>"!F!" echo   ^<Capabilities /^>
>>"!F!" echo ^</Manifest^>

:: ---------------------------------------------------------------- ModEntry.cs
set "F=!PROJDIR!\ModEntry.cs"
>"!F!" echo using System;
>>"!F!" echo using UnityEngine;
>>"!F!" echo using HarmonyLib;
>>"!F!" echo.
>>"!F!" echo namespace !PROJ!
>>"!F!" echo {
>>"!F!" echo     /// ^<summary^>
>>"!F!" echo     /// Entry point of the mod. The loader finds the one class implementing IMod, creates it,
>>"!F!" echo     /// applies the [HarmonyPatch] classes of this assembly, then calls Init and OnEnable.
>>"!F!" echo     /// All of that happens in the main menu: no save is loaded yet, so do not touch game
>>"!F!" echo     /// state here. Subscribe to ModHook events instead (see ModdingGuide.md, "Hook Points").
>>"!F!" echo     /// ^</summary^>
>>"!F!" echo     public class ModEntry : IMod
>>"!F!" echo     {
>>"!F!" echo         public static ModEntry Instance { get; private set; }
>>"!F!" echo         public ModManifest Manifest { get; private set; }
>>"!F!" echo         public ModLog Log { get; private set; }
>>"!F!" echo.
>>"!F!" echo         public void Init(ModManifest manifest)
>>"!F!" echo         {
>>"!F!" echo             Instance = this;
>>"!F!" echo             Manifest = manifest;
>>"!F!" echo             Log = new ModLog(manifest);
>>"!F!" echo             Log.Log($"{manifest.Name} v{manifest.ModVersion} loaded.");
>>"!F!" echo         }
>>"!F!" echo.
>>"!F!" echo         public void OnEnable()
>>"!F!" echo         {
>>"!F!" echo             // Runs right after Init, still in the main menu. Register hooks, items, loot edits,
>>"!F!" echo             // options and configuration here. Examples:
>>"!F!" echo             //   ModHook.OnGameLoadedInit += OnGameLoaded;
>>"!F!" echo             //   ModHelper.AddLootEntry(Manifest.ID, "junkTable", "my_item", 10);
>>"!F!" echo             Log.Log("Enabled.");
>>"!F!" echo         }
>>"!F!" echo.
>>"!F!" echo         public void OnDisable()
>>"!F!" echo         {
>>"!F!" echo             // Runs when the game shuts down. Unsubscribe what you subscribed in OnEnable.
>>"!F!" echo             //   ModHook.OnGameLoadedInit -= OnGameLoaded;
>>"!F!" echo             Log.Log("Disabled.");
>>"!F!" echo         }
>>"!F!" echo.
>>"!F!" echo         // private void OnGameLoaded()
>>"!F!" echo         // {
>>"!F!" echo         //     // A save is loaded: game systems exist from here on.
>>"!F!" echo         // }
>>"!F!" echo     }
>>"!F!" echo }

:: ---------------------------------------------------------------- .gitignore
set "F=!PROJDIR!\.gitignore"
>"!F!" echo bin/
>>"!F!" echo obj/

:: ---------------------------------------------------------------- done
echo.
echo  Created !PROJDIR!
echo.
echo  Next steps:
echo    1. Write your code in ModEntry.cs (and more files next to it).
echo    2. Build:   cd "!PROJDIR!"   then   dotnet build -c Release
echo       The build installs the mod into Mods\!PROJ!\ by itself.
echo    3. Start the game, open the Mods menu, select "!NAME!" and activate it, then restart.
echo       Press F8 in the game for the console; your log lines start with [!NAME!].
echo    4. Keep manifest.xml here in the project; the build copies it. Put item sprites in
echo       Textures\Items\, sounds in Sounds\, strings in Localization\ (see ModdingGuide.md).
echo.

where dotnet >nul 2>nul
if errorlevel 1 (
    echo  dotnet was not found on this machine. Install the .NET SDK to build: https://dotnet.microsoft.com/download
    goto end
)
set "BUILD="
set /p "BUILD= Build it now? [Y/n]: "
if /i "!BUILD!"=="n" goto end
echo.
pushd "!PROJDIR!"
dotnet build -c Release
set "RESULT=!errorlevel!"
popd
echo.
if "!RESULT!"=="0" (
    echo  Built and installed. Start the game and activate "!NAME!" in the Mods menu.
) else (
    echo  The build failed; read the errors above. The project is in !PROJDIR!
)
goto end

:cancelled
echo  Nothing created.
goto end

:fail
echo.
echo  Could not create the mod. See the message above.

:end
echo.
pause
endlocal
