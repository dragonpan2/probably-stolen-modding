# Probably Stolen：模组制作指南

English version: [ModdingGuide.md](ModdingGuide.md)

本指南涵盖模组开发的进阶主题，并假定你已经读过 [README.zh-CN.md](README.zh-CN.md) 快速入门。模组社区规则见 [CodeOfConduct.zh-CN.md](CodeOfConduct.zh-CN.md)。游戏更新后要升级模组？请查看 [APIChanges.zh-CN.md](APIChanges.zh-CN.md) 了解模组 API 的变化。

> **免责声明。** 本指南在 AI 辅助下撰写，并经开发者审阅。代码片段和 API 名称都对照过游戏源码，但仍可能有疏漏。如果这里的内容与游戏的实际行为不符，请以游戏为准，并通过社区渠道反馈，以便我们修正指南。

## 目录
- [Probably Stolen：模组制作指南](#probably-stolen模组制作指南)
  - [目录](#目录)
  - [示例项目](#示例项目)
  - [用 ModLog 记录日志](#用-modlog-记录日志)
  - [开发工具](#开发工具)
  - [对存档负责](#对存档负责)
  - [已支持与暂不支持的模组功能](#已支持与暂不支持的模组功能)
    - [✅ 原生支持](#-原生支持)
    - [❌ 暂不支持](#-暂不支持)
  - [模组资源](#模组资源)
    - [物品精灵图](#物品精灵图)
    - [声音](#声音)
    - [其他贴图](#其他贴图)
    - [本地化](#本地化)
    - [如何知道资源已就绪](#如何知道资源已就绪)
  - [钩子点](#钩子点)
    - [订阅钩子](#订阅钩子)
    - [通过物品目录钩子添加物品](#通过物品目录钩子添加物品)
    - [可用钩子](#可用钩子)
  - [掉落表](#掉落表)
    - [权重](#权重)
    - [从代码编辑掉落表](#从代码编辑掉落表)
    - [用 JSON 文件编辑掉落表](#用-json-文件编辑掉落表)
    - [响应掷取](#响应掷取)
    - [在控制台中查看掉落表](#在控制台中查看掉落表)
  - [保存模组数据](#保存模组数据)
  - [自定义 UI](#自定义-ui)
  - [Harmony 补丁](#harmony-补丁)
    - [补丁会自动应用](#补丁会自动应用)
    - [Postfix：在原方法之后运行](#postfix在原方法之后运行)
    - [Prefix：在原方法之前运行](#prefix在原方法之前运行)
    - [Finalizer：即使原方法抛出异常也会运行](#finalizer即使原方法抛出异常也会运行)
    - [Transpiler：改写原方法的 IL（进阶）](#transpiler改写原方法的-il进阶)
  - [故障排查](#故障排查)

---

## 示例项目

📁 完整的示例模组项目与本指南一起收录在本仓库中。它们是完整、可构建的模组，你可以打开、研究并改造。当这里的代码片段不足以让你看清各部分如何组合成一个完整项目时，就去参考它们。

---

## 用 ModLog 记录日志

请使用 `ModLog` 而不是 `Debug.Log`，这样你的消息会自动带上模组名前缀。玩家和其他模组作者在阅读控制台时就能轻松分辨某一行日志来自哪个模组。

用 `Init` 中收到的 `ModManifest` 构造一个 `ModLog` 并复用它：

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

控制台输出中方括号里的前缀来自清单文件的 `<Name>`。如果你在代码的其他地方需要模组的 ID、版本或其他元数据，请保存 `Init` 传入的 `manifest` 引用并从中读取。

---

## 开发工具

Probably Stolen 内置了两个在开发和测试模组时必不可少的工具。

- 🐛 **调试控制台（`F8`）**：打开一个显示全部日志输出的控制台，包括 `ModLog`、`Debug.Log`、警告和错误。用它确认模组已加载、观察钩子点触发，以及在出错时阅读堆栈跟踪。
- 🛠️ **开发菜单（`F9`）**：打开一个包含许多对模组开发和测试有用的功能的菜单，例如生成物品、触发事件、查看游戏状态。用于复现边缘情况，而不必一路玩到那里。

---

## 对存档负责

玩家的存档是永久的，属于玩家。作为模组作者，你要对模组与存档的交互方式负责。

**绝对不要：**
- 删除存档文件
- 悄悄损坏存档（例如写入会导致载入失败的无效数据）

**如果你的模组会影响存档：**
- 在玩家安装之前，在模组描述中清楚地警告
- 提供安全的卸载路径：说明玩家在禁用你的模组之前需要做什么才能不丢失进度

**经验法则：** 除非事先明确说明，玩家应该能够在不丢失进度的情况下禁用你的模组。

---

## 已支持与暂不支持的模组功能

目前并非所有类型的模组都可行。开始一个项目之前，请确认你的想法在已支持列表中；否则你可能会撞上当前模组 API 无法绕过的墙。

### ✅ 原生支持

- **带自定义精灵图的模组物品**：向游戏添加新物品，包括它们的美术资源
- **带自定义精灵图的模组顾客**：添加拥有自己外观的新顾客
- **模组事件**：添加新的游戏内事件
- **掉落表编辑**：把你的物品放进游戏的掉落表、修改或移除已有掉落，或者添加全新的表，可通过代码或 JSON 文件完成（[掉落表](#掉落表)）
- **自定义 UI**：用游戏的控件从代码构建你自己的窗口和面板（设置、查看器、计数器）（[自定义 UI](#自定义-ui)）

### ❌ 暂不支持

- **对现有 UI 的大改**：重构或替换内置 UI
- **修改商店**：修改商店的行为或内容
- **大修型模组**：一次触及许多系统的大规模重做
- **地下交易所的模组交易**：向地下交易所添加新的交易
- **特殊物品**：可检视物品和鉴定物品

暂不支持的功能将来可能会得到支持。

---

## 模组资源

把图片和音频文件放进模组文件夹中指定名称的子文件夹，加载器会在启动时自动读取；你不需要写任何加载代码。每个资源以**不含扩展名的文件名**作为键（例如 `health_pack.png` → 键 `health_pack`）。

```
Mods/
└── MyMod/
    ├── manifest.xml
    ├── MyMod.dll
    ├── Textures/
    │   ├── banner.png          → 通用贴图，键 "banner"
    │   └── Items/
    │       └── health_pack.png → 物品精灵图，键 "health_pack"
    ├── Sounds/
    │   └── ding.wav            → 声音，键 "ding"
    ├── Localization/
    │   ├── en.csv              → "en" 语言的文本
    │   └── fr.csv              → "fr" 语言的文本
    └── LootTables/
        └── drops.json          → 掉落表编辑，见"掉落表"
```

> ⚠️ **文件夹名必须完全一致，且扫描不递归。** 物品精灵图必须*直接*放在 `Textures/Items/` 下；声音*直接*放在 `Sounds/` 下；本地化文件*直接*放在 `Localization/` 下；掉落文件*直接*放在 `LootTables/` 下。放在 `Textures/Sprites/` 或任何嵌套子文件夹中的 PNG 会被静默忽略。支持的图片格式：`.png`、`.jpg`。支持的音频：`.wav`、`.ogg`、`.mp3`。本地化：`.csv`。掉落表：`.json`。

每个模组都会记录它加载了什么，你可以在 F8 控制台中确认：

```
[ModLoader] My Mod: 1 texture(s), 1 item sprite(s) loaded
[ModLoader] My Mod: 2 locale(s), 34 localization entries loaded
[ModLoader] My Mod: 1 sound(s) loaded
```

### 物品精灵图

物品美术放在 `Textures/Items/` 下，会按像素画导入（点采样过滤、无 mipmap）。用 `SetSpriteAndShapeFromMod` 把它绑定到物品上，传入你的**模组 `<ID>`** 和**文件名键**：

```csharp
GameItem item = ItemDirectory.CreateEmptyItem("health_pack");
item.name = "Health Pack";
item.shortDescription = "Restores a bit of health.";
item.SetSpriteAndShapeFromMod("my_mod_id", "health_pack");  // (modId, spriteKey)
```

`SetSpriteAndShapeFromMod` 做两件事：设置物品的精灵图，并根据图片中不透明的像素推导物品的**网格形状**（它在背包中占据的格子）。透明区域变成空格子，所以 L 形的画会得到 L 形的物品。每个背包格子是 `gridSize` 像素见方，请按网格来定尺寸（例如 64 像素网格下的 2×1 物品就是一张 128×64 的图）。

> 模组 ID 是 `manifest.xml` 中的 `<ID>`，**不是**模组文件夹名。找不到精灵图时会在控制台给出警告，物品会回退到"未知"占位图。

### 声音

`Sounds/` 中的每个文件都会以 **`<modId>:<key>`** 为标识自动注册到游戏的音频系统，例如模组 `my_mod_id` 中的 `ding.wav` 变成 `my_mod_id:ding`。因为你的声音走的是游戏自己的音频通道，它们会遵循玩家的音量设置和暂停状态。绝对不要用你自己的 `AudioSource` 播放。

可以在任何时刻播放声音（钩子处理函数、Harmony 补丁、你的物品逻辑）：

```csharp
ModHelper.PlaySound("my_mod_id", "ding");   // 通用音效通道
ModHelper.PlaySound2("my_mod_id", "ding");  // 第二通道（倒水之类的动作使用）
ModHelper.PlaySound3("my_mod_id", "ding");  // 第三通道（枪声使用；可通过 AudioManager.Instance.StopPlay3() 停止）
```

找不到声音时，三个方法都返回 `false` 并在控制台记录警告。每个通道同一时间只播放一个声音：在某个通道上开始新声音会切断该通道正在播放的内容，所以可能重叠的声音请使用不同通道。

你还可以给物品配上自己的声音。物品以标识字段的形式携带声音（`soundDragStart`、`soundDragEnd`、`soundSelect`、`soundUse`、`soundActivate`、`soundContainerOpen`、`soundContainerClose`、`soundToggle`），这些字段和内置标识一样接受模组标识：

```csharp
item.soundDragStart = ModHelper.GetSoundIdentifier("my_mod_id", "leather_drag");
item.soundUse       = ModHelper.GetSoundIdentifier("my_mod_id", "potion_gulp");
```

（要复用游戏内置的声音，改为赋值 `AudioHelper` 中的常量，例如 `item.soundUse = AudioHelper.EAT`。）

### 其他贴图

通用贴图（`Textures/` 下、`Items/` 之外）会被载入内存，但游戏**没有内置 API 为你显示它们**；它们供你自己的代码使用。通过 `ModLoader.Mods` 访问：

```csharp
var mod = ModLoader.Mods.Find(m => m.Manifest.ID == "my_mod_id");
Texture2D tex = mod.Textures["banner"];
// 自行绘制 `tex`
```

（原始的 `AudioClip` 也可以通过 `mod.Sounds` 在那里拿到，但请优先使用 `ModHelper.PlaySound`，这样玩家的音频设置才会生效。）

要在特定的游戏时刻触发它，请结合[钩子点](#钩子点)或 [Harmony 补丁](#harmony-补丁)。

### 本地化

本地化是**可选的**。如果你的模组只有英文，可以完全跳过本节，直接赋纯字符串（`item.name = "Health Pack";`）。一个不错的折中：只提供一个 `en.csv` 并照样使用 `ModHelper.GetLocalized`；模组行为完全相同，但改文案不需要重新构建，而且之后任何人都可以通过添加一个 CSV 文件贡献翻译，无需改代码。

翻译以每种语言一个 CSV 文件的形式放在 `Localization/` 下，以**语言代码**命名（`en.csv`、`fr.csv` 等）。游戏目前支持下列语言，文件名必须使用这些精确的代码：

| 语言 | 代码 |
|---|---|
| 英语 | `en` |
| 法语 | `fr` |
| 德语 | `de` |
| 俄语 | `ru` |
| 中文 | `zh` |
| 日语 | `ja` |
| 西班牙语 | `es` |
| 葡萄牙语（巴西） | `ptBR` |
| 韩语 | `ko` |
| 意大利语 | `it` |

（其他名字的文件会被加载但永远不会被解析到。不确定时，用 `ModHelper.GetCurrentLocale().Identifier.Code` 打印当前语言代码。）

每行一条：键、一个逗号、然后是文本。UTF-8，无表头行。空行和以 `#` 开头的行会被忽略。

```csv
# en.csv
health_pack_name,Health Pack
health_pack_desc,"Restores health, cures bleeding, and smells faintly of mint."
merchant_line,"She said ""no refunds"" and meant it."
days_left,Expires in {0} day(s)
trade_offer,"{0} offers {1} credits for it."
multi_line,First line\nSecond line
```

格式规则：

- **第一个逗号**之后的一切都属于文本，所以文本中不加引号的逗号也没问题。因此键不能包含逗号；请只用字母、数字和下划线。
- 文本可以选择用双引号包起来（电子表格导出会自动这么做）。引号内用 `""` 表示一个字面的 `"`。
- 用 `\n` 表示换行。每行一条；值内部的真实换行不受支持。

用 `ModHelper.GetLocalized` 读取条目。它先解析当前语言，再回退到 `en`，最后返回键本身（并给出一次性的控制台警告），所以缺少翻译永远不会崩溃或显示空白：

```csharp
item.name = ModHelper.GetLocalized("my_mod_id", "health_pack_name");
item.shortDescription = ModHelper.GetLocalized("my_mod_id", "health_pack_desc");

// 额外参数用 string.Format 插入：{0} 是第一个参数，{1} 是第二个，依此类推
string label = ModHelper.GetLocalized("my_mod_id", "days_left", 3);
// -> "Expires in 3 day(s)"

string offer = ModHelper.GetLocalized("my_mod_id", "trade_offer", clientName, price);
// -> "Vera offers 250 credits for it."
```

> 只支持带编号的 `string.Format` 占位符（`{0}`、`{1}` 等）。Unity 的 **Smart Strings**（命名占位符、复数规则、`choose()`）是游戏内置字符串表的功能，模组条目**不能**使用。需要复数形式时，请使用不同的键（例如 `days_left_one` / `days_left_many`）并在代码中选择。

本地化文件与其他资源一起加载，在 `Init`/`OnEnable` 之后。任何[钩子](#钩子点)触发时它们都已就绪，所以在物品工厂或钩子处理函数中解析字符串总是安全的；在 `Init`/`OnEnable` 中调用 `GetLocalized` 则不安全。

### 如何知道资源已就绪

资源在 `Init`/`OnEnable` 运行**之后**才加载完成：贴图和本地化在所有模组初始化后立即加载，声音则在之后的几帧里异步加载。所以 `OnEnable` 里的 `mod.Sounds["ding"]` 会是空的。如果你在启动时（而不是游戏过程中按需）就需要资源，请订阅 `ModHook.OnModAssetsLoaded`。它在每个已启用模组的*全部*贴图、物品精灵图、声音和本地化条目都进入内存后触发一次：

```csharp
public void OnEnable()  => ModHook.OnModAssetsLoaded += OnAssetsLoaded;
public void OnDisable() => ModHook.OnModAssetsLoaded -= OnAssetsLoaded;

void OnAssetsLoaded(LoadedMod mod)
{
    if (mod.Manifest.ID != "my_mod_id") return; // 它会为每个模组触发，检查是不是你的
    log.Log($"All assets ready: {mod.Sounds.Count} sound(s), {mod.Sprites.Count} sprite(s)");
}
```

在 `OnModItemDirectoryInit` 中用 `SetSpriteAndShapeFromMod` 绑定的物品精灵图不需要这个；那里的精灵图查找发生在游戏过程中，远在加载完成之后。

---

## 钩子点

钩子点是游戏在固定时刻触发的事件：存档载入、顾客生成、卷帘门打开、提示框构建等等。订阅一个钩子就能让你的代码在那个时刻运行，**无需修补任何东西**。这是扩展游戏的首选方式：它比 Harmony 快，而且在游戏更新时远不容易失效。只有在没有钩子覆盖你的需求时才去用 [Harmony](#harmony-补丁)。

所有钩子都是静态类 `ModHook` 上的 C# 事件。

### 订阅钩子

在 `OnEnable` 中订阅，在 `OnDisable` 中取消订阅。每个处理函数的签名与钩子匹配；有的带参数，有的没有：

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

> 与在主菜单运行的 `Init`/`OnEnable` 不同，钩子在**游戏过程中**触发：钩子运行时游戏系统已经存在，所以可以安全地生成物品、读取存档状态、访问管理器。

**异常是隔离的。** 每个订阅者都在自己的 try/catch 中运行：如果你的处理函数抛出异常，错误会带着你的模组名记录到控制台，其他模组的处理函数（以及游戏本身）不受影响地继续。这是一张安全网，不是许可证；记录下来的异常仍然意味着你的模组有问题，所以开发时请留意 F8 控制台中的 `[ModHook]` 错误。

**顺序层级。** 许多钩子分为多个层级，让多个模组可以相对彼此定位。选择与你需要的先后顺序匹配的层级：

- 顾客生成：`VeryEarly → Early → Normal → Late → VeryLate`
- 游戏载入：`Init → Early → Normal → Late`
- 其他大多数：`Early → Late`

如果与其他模组的相对顺序对你无所谓，用 `Normal`（或 `Early`）层级。

### 通过物品目录钩子添加物品

`OnModItemDirectoryInit` 是注册新物品、使其可按 ID 生成的方式。它把模组物品目录交给你；调用 `Add(id, factory)` 并传入构建物品的函数：

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

注册后，可以在任何地方用 `ModHelper.SpawnItem("health_pack")` 生成它。

### 可用钩子

把 `*` 替换为层级名，例如 `ModHook.OnGenerateCustomerVeryEarly`、`ModHook.OnShutterClosedLate`。

| 钩子 | 层级 | 触发时机 | 处理函数接收 |
|---|---|---|---|
| `OnModItemDirectoryInit` | 无 | 物品目录初始化（在此注册物品） | `ModItemDirectory` |
| `OnGenerateCustomer*` | VeryEarly … VeryLate | 正在生成一名商店顾客 | `StoreClientManager` |
| `OnGameLoaded*` | Init … Late | 存档载入完成 | 无 |
| `OnShutterOpened*` / `OnShutterClosed*` | Early, Late | 商店卷帘门打开 / 关闭 | 无 |
| `OnGoingSleep*` / `OnWakingUp*` | Early, Late | 玩家入睡 / 醒来 | 无 |
| `OnLeavingStore*` / `OnReturningStore*` | Early, Late | 玩家离开 / 返回店面 | 无 |
| `OnHandlingNightlyServices*` | Early, Late | 处理夜间维护 | 无 |
| `OnPlaceInventorInventoryItem*` | Early, Late | 物品被放入背包 | `List<GameItem>` |
| `OnCreateTooltip*` / `OnCreateDevTooltip*` | Early, Late | 正在构建物品提示框（追加你自己的行） | `RichTextBuilder`, `GameItem` |
| `OnModAssetsLoaded` | 无 | 某个模组的资源（贴图、物品精灵图、声音、本地化）全部加载完成（每个已启用模组触发一次；检查是不是你的模组） | `LoadedMod` |
| `OnLootTablesLoaded` | 无 | 掉落表已加载且所有模组编辑已应用（每次场景加载一次） | 无 |
| `OnLootRolled` | 无 | 某张掉落表被掷取；设置 `context.itemId` 可覆盖结果（[详情](#响应掷取)） | `LootRollContext` |

---

## 掉落表

随机掉落（拾荒所得、供应商货物、部分顾客带来的东西）都从具名的**掉落表**中掷取：带权重的物品 ID 列表。**表组**是带权重的掉落表列表；掷取表组时先选一张表，再掷取那张表。模组可以向已有表添加物品、修改或移除条目、注册新的表和表组，可以从代码完成，也可以完全不写代码、用一个 JSON 文件完成。

编辑与游戏数据分开存储，并在每次表加载时重新应用，所以它们能在场景切换后保留、永不修改游戏文件，而且可以在任何时候进行，包括在任何表存在之前的 `OnEnable` 中。

原版 ID（实时列表，包括其他模组的添加，在[控制台](#在控制台中查看掉落表)里一条 `loot-list` 就能看到）：

| 掉落表 | 用途 |
|---|---|
| `junkTable` | 废料和垃圾 |
| `materialTable` | 制作材料 |
| `packedFoodTable` | 廉价包装食品（供应商货物、食品顾客、补货的冰箱） |
| `householdTable` | 家居用品 |
| `medicalTable`、`dumpingGroundMedical` | 医疗用品 |
| `toolTable` | 工具 |
| `makeshiftWeaponTable` | 简易武器 |
| `t1moduleTable`、`t2moduleTable`、`allModuleTable` | 按等级划分的模块 |
| `accessCardTable` | 门禁卡 |
| `POI_dumpingGround` | 远征兴趣点（ID 是 POI，不是物品） |

| 表组 | 用途 |
|---|---|
| `dumpingGroundTG` | 垃圾场拾荒 |
| `dumpingGroundFreshTG` | 垃圾场新鲜拾荒 |

### 权重

每个条目都有一个权重，条目的概率等于它的权重除以所在表的总权重。原版表经过缩放，使条目**总和为 1000**，这让权重很容易读：

| 权重 | 在未改动的原版表中的概率 |
|---|---|
| `100` | 约 10% |
| `10` | 约 1% |
| `1` | 约 0.1% |
| `0.5` | 约 0.05% |

权重是相对的，所以添加条目会稀释其他条目：向原版表添加权重 `10` 会让你的物品得到 10 / 1010，即 0.99%，并让其他所有条目同样缩小 1%。小数也可以。权重 `0` 会让条目留在表中但永远不会被掷出；添加权重为 0 或更小的条目会被拒绝。

### 从代码编辑掉落表

在 `OnEnable` 中调用；不需要等待任何东西。把你的清单 `<ID>` 作为第一个参数传入，这样控制台就能显示每处编辑来自哪个模组。

```csharp
public void OnEnable()
{
    // 把你的物品放进垃圾堆，约占 1% 的掷取
    ModHelper.AddLootEntry("my_mod_id", "junkTable", "my_item", 10);

    // 让某个已有掉落更稀有，或者完全移除
    ModHelper.SetLootWeight("my_mod_id", "packedFoodTable", "cup_noodle", 20);
    ModHelper.RemoveLootEntry("my_mod_id", "packedFoodTable", "zerochew");

    // 一张新表，然后让它在垃圾场拾荒中占一份
    ModHelper.RegisterLootTable("my_mod_id", "my_table", ("my_item", 700), ("my_rare_item", 300));
    ModHelper.AddLootGroupEntry("my_mod_id", "dumpingGroundTG", "my_table", 50);
}
```

规则：

- 对已在表中的物品调用 `AddLootEntry` 会**替换它的权重**，而不是添加重复项。
- 如果 ID 已存在，`RegisterLootTable` 会失败（并给出控制台警告）。要从零重建一张原版表，先调用 `ClearLootTable`，再添加条目。
- 表组有一套名字里带 `Group` 的相同调用：`RegisterLootGroup`、`AddLootGroupEntry`、`RemoveLootGroupEntry`、`SetLootGroupWeight`、`ClearLootGroup`。它们的条目是掉落表 ID。
- 添加物品 ID 时不做检查。请通过 [`OnModItemDirectoryInit`](#通过物品目录钩子添加物品) 注册你的物品；未知 ID 会掷出"未知"占位物品。
- 关于错误编辑的每条警告都以 `[LootRegistry]` 开头并标明你的模组。

要自己掷取或查看一张表：`ModHelper.RollLootTable(id)` 返回一个物品 ID，`ModHelper.SpawnFromLootTable(id)` 生成它，`ModHelper.GetLootEntries(id)` 返回条目的快照，包括权重和添加每条的模组（原版条目的 `sourceModId` 为 `null`）。表组版本：`RollLootGroup`、`SpawnFromLootGroup`、`GetLootGroupEntries`。

### 用 JSON 文件编辑掉落表

同样的编辑可以以数据的形式提供。把一个或多个 `.json` 文件直接放进模组文件夹中的 `LootTables/` 文件夹；它们与其他资源一起加载，每处编辑都归属于你的模组。三个顶层列表中的任何一个都可以省略。

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

- `tables` 和 `groups` 创建新列表；`patches` 编辑已有列表（原版的或任何模组的，包括你自己 `tables` 里的）。
- 一个 patch 只能指定 `table` 或 `group` 之一。patch 内部先执行 `clear`，然后是 `add`、`remove`、`setWeight`。
- 文件内的顺序是先 tables，再 groups，然后 patches；多个文件按字母顺序应用。请先注册一张表，再对它打补丁或加入表组。
- 加载器会记录 `[ModLoader] My Mod: 1 loot file(s): 1 table(s), 1 group(s), 3 patch(es) loaded`；无法读取的文件会被跳过，并给出指明文件名的错误。

### 响应掷取

`ModHook.OnLootTablesLoaded` 在表已存在且所有模组编辑都已应用后触发，所以这是用 `GetLootEntries` 读取一张表最终状态的时机。

`ModHook.OnLootRolled` 在任何表的每次掷取之后触发，带一个 `LootRollContext`：`tableId`、`groupId`（选中该表的表组，直接掷取时为 `null`）和 `itemId`。给 `itemId` 赋值即可替换结果：

```csharp
public void OnEnable()  => ModHook.OnLootRolled += OnLootRolled;
public void OnDisable() => ModHook.OnLootRolled -= OnLootRolled;

void OnLootRolled(LootRollContext context)
{
    // 每二十次拾荒所得中有一次变成你的物品，无论来自哪张表
    if (context.groupId == "dumpingGroundTG" && UnityEngine.Random.value < 0.05f)
        context.itemId = "my_item";
}
```

普通的掉落改动请优先用权重而不是这个钩子；它在每次掷取时运行，而且后面的模组会看到你设置的值。

### 在控制台中查看掉落表

F8 控制台有两个命令。`loot-list` 打印所有表和表组；`loot-list <id>` 打印某一张，包括实际百分比以及每个条目由哪个模组添加或修改；`loot-roll <id> [count]` 掷取它并统计结果。

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

如果你的物品没有出现在 `loot-list` 中，说明表 ID 写错了或编辑被拒绝了；请在控制台中查找 `[LootRegistry]` 警告。

---

## 保存模组数据

模组经常需要记住一些不属于某个物品的东西：任务进度、计数器、标志、一小块设置数据。`ModHelper` 为每个模组提供一个随玩家本局游戏一起保存的键值存储。

```csharp
// 写入。键按你的模组 ID 隔离命名空间，所以名字随意。
ModHelper.SetModDataInt("my_mod_id", "deliveries", 3);
ModHelper.SetModDataBool("my_mod_id", "met_courier", true);
ModHelper.SetModData("my_mod_id", "route", JsonUtility.ToJson(routeState));

// 读取，并为从未写入过的键提供回退值。
int deliveries = ModHelper.GetModDataInt("my_mod_id", "deliveries", 0);
bool met = ModHelper.GetModDataBool("my_mod_id", "met_courier");
RouteState route = JsonUtility.FromJson<RouteState>(ModHelper.GetModData("my_mod_id", "route", "{}"));

// 整理
ModHelper.HasModData("my_mod_id", "route");
ModHelper.RemoveModData("my_mod_id", "route");
ModHelper.GetModDataKeys("my_mod_id");   // 你存过的每个键，不含前缀
ModHelper.ClearModData("my_mod_id");     // 清除你的模组在本局中存的一切
```

规则：

- **按局保存。** 数据是存档槽的一部分：每次游戏保存（每晚）时写入，载入时恢复，新游戏时为空。玩家入睡之前写的任何东西都会进当晚的存档。保存之后的写入保留在内存中，进入下一次存档。
- **在一局游戏载入期间可用。** 从 `ModHook.OnGameLoadedInit` 开始可以读取。在主菜单中或一局游戏载入之前的调用不做任何事并返回回退值，写入时会给出警告。
- **值是字符串。** 游戏永远不需要知道你的类型，所以即使你的模组更新或被移除，存档依然能载入。结构化数据请自行序列化为 JSON；`JsonUtility` 最简单。`Int`、`Float` 和 `Bool` 辅助方法会为你做格式化和解析，与文化设置无关。
- **禁用的模组保留其数据。** 模组被关闭时不会清理任何东西，所以重新启用会恢复其状态。如果你的模组想要一个干净的开始，请自己调用 `ClearModData`。
- **保持小巧。** 这个存储在每次保存时都会写入。几 KB 没问题；不要往里塞大块数据或每帧的数据。
- **它不是用来存物品数据的。** 属于某个特定物品的东西应放在该物品的标签上（`item.ModifyTag` / `GetTagReadonly`），它们随物品保存并跟随物品移动。

---

## 自定义 UI

模组可以通过 `CustomUIManager` 在运行时构建自己的窗口（设置面板、查看器、计数器等），它是建立在游戏 UI 预制件之上的 C# 链式构建器。模组一侧不需要 Unity 项目、预制件或任何编辑器工作；游戏提供控件，你用代码把它们组合起来。

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
    .AddImage("my_mod_id:health_pack")   // 来自 Textures/Items 的物品精灵图
    .BeginRow()
        .AddFlexibleSpace()
        .AddButton("Apply", Apply).WithTooltip("Saves the settings")
        .AddButton("Close", () => CustomUIManager.Instance.CloseWindow("my_mod_id.settings"))
    .End()
    .Show();
```

- `CustomUIManager.Window(id, title, layer)` 开始一个窗口，并替换任何同 ID 的已有窗口。请给 ID 加上你的模组 ID 前缀，以避免与其他模组冲突。`Show()` 结束链式调用并返回一个 `CustomUIWindow`；`GetWindow()` 则以隐藏状态返回它。
- 控件：`AddLabel`、`AddButton`、`AddImage`、`AddToggle`、`AddSlider`、`AddInput`、`AddDropdown`、`AddProgressBar`、`AddSpace`、`AddFlexibleSpace`。给任何之后想更新的控件传一个 `id`。
- 布局：`BeginRow` / `BeginColumn` / `BeginGrid(columns, cellWidth, cellHeight)` / `BeginScroll(height)`，每个都用 `End()` 结束。标签页：`BeginTabs()`，然后每个标签页一组 `BeginTab("Name") ... End()`，最后 `EndTabs()`。
- 窗口选项：`SetSize`、`SetPosition`、`Center`、`SetDraggable`、`SetCloseOnEscape`、`OnClose(callback)`。`WithTooltip(text)` 给最后添加的元素附加一个悬停提示。
- 层（layer）决定由哪个画布承载窗口：游戏场景中的 `LAYER_PAPER`（书籍和文档，大多数普通 UI）、`LAYER_FRONT`、`LAYER_REAR`、`LAYER_META`（选项和退出菜单），主菜单中的 `LAYER_MENU`，以及 `LAYER_OVERLAY`，即管理器自己的、跨场景保留的画布。场景层上的窗口会随场景销毁，所以需要时请重建它们，例如在 `ModHook.OnGameLoadedNormal` 中。指向当前场景中不存在的层时会回退到覆盖层并给出警告。

之后通过句柄更新窗口：

```csharp
CustomUIWindow window = CustomUIManager.Instance.GetWindow("my_mod_id.settings");
window.Get("progress").SetProgress(0.7f, "70%");
window.Get("feature").SetBool(false);      // 静默；传 notify: true 才会触发回调
bool on = window.Get("feature").GetBool();
window.Hide(); window.Show(); window.Close(); // Close 会销毁并注销窗口
```

元素的 setter 是空安全的：对一个标签调用滑块方法只会记录警告并且什么都不做，所以写错的 ID 永远不会把异常抛进游戏的 UI 循环。`AddImage("key")` 和 `SetSprite("key")` 既接受游戏自己的精灵图键，也接受 `"modId:spriteName"` 形式的模组物品精灵图（精灵图键是 `Textures/Items/` 中的文件名，见[物品精灵图](#物品精灵图)）。

经验法则：

- 构建之前先用 `CustomUIManager.Instance != null` 做保护。
- 使用模组精灵图的 UI 不要早于 [`ModHook.OnModAssetsLoaded`](#如何知道资源已就绪) 构建。
- `SetCloseOnEscape` 是可选开启的，因为游戏在商店场景中也会全局处理 Escape；请在窗口打开的状态下测试是否冲突。

---

## Harmony 补丁

> ⚠️ **有原生钩子时优先用钩子。** Harmony 有可测量的运行时开销，而且比原生模组 API 对游戏更新更敏感。如果某个[钩子点](#钩子点)覆盖了你的需求，就用它。只有当没有钩子暴露你想介入的时刻时才用 Harmony；这正是它的用途。

Harmony 是一个运行时修补库，让你能在游戏中任意方法之前、之后注入代码，或者替换它。[README.zh-CN.md](README.zh-CN.md) 快速入门中的 `.csproj` 已经包含了 `0Harmony.dll` 引用。

### 补丁会自动应用

你不需要自己调用 `Harmony.PatchAll()`。游戏会扫描每个已加载的模组程序集，并应用它找到的每个 `[HarmonyPatch]` 类。只要声明补丁类（见下文），模组一启用它们就会生效。

### Postfix：在原方法之后运行

**Postfix** 在原方法完成后运行。用它观察结果；当方法有返回值时，可以添加一个名为 `__result` 的 `ref` 参数来读取或修改返回值。（`GenerateClient` 返回 `void`，所以下面的例子只做观察。）

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class PrintLog
{
    // Postfix 在原方法之后运行。
    static void Postfix()
    {
        Debug.Log("[TestMod] StoreClientManager.GenerateClient called.");
    }
}
```

### Prefix：在原方法之前运行

**Prefix** 在原方法之前运行。返回 `false` 会完全跳过原方法；返回 `true`（或 `void`）则让它正常运行。

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class SkipClient
{
    static bool Prefix()
    {
        Debug.Log("[TestMod] Skipping client generation.");
        return false; // 原方法不会运行
    }
}
```

### Finalizer：即使原方法抛出异常也会运行

**Finalizer** 在原方法之后运行，即使它抛出了异常。用它做清理，或者吞掉、替换异常。返回 `null` 吞掉异常；返回一个 `Exception` 实例则替换它。

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

        return null; // 吞掉异常，让游戏继续运行
    }
}
```

### Transpiler：改写原方法的 IL（进阶）

**Transpiler** 在原方法运行之前改写它的 IL 指令。这是最强大的补丁类型，也是最脆弱的；游戏的小更新就可能让匹配特定操作码模式的 transpiler 失效。只有当 Prefix / Postfix / Finalizer 无法表达你的需求时才用它。

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
            // 在这里检查、替换或插入 IL。
            // 这个直通实现原样返回原始 IL。
            yield return instr;
        }
    }
}
```

完整参考请见 [Harmony 文档](https://harmony.pardeike.net/)，包括注入参数名（`__instance`、`__state`、`___privateField` 等）。

---

## 故障排查

先打开 **F8 控制台**：每个模组都会记录它的加载结果、资源数量以及修补了多少个 Harmony 方法，全部带有 `[ModLoader]` 或你的模组名前缀。

| 症状 | 可能原因 |
|---|---|
| 模组没有出现在模组菜单中 | 模组根文件夹中没有 `manifest.xml`，或者它的 `<ID>` 为空；加载器跳过了该文件夹。查找 `[ModLoader]` 警告。 |
| 模组出现了但什么都没发生 | 模组没有启用，或者启用后没有重启。**启用、禁用和重新排序都要到下次启动才生效。** |
| 代码改动没有生效 | 你复制的是旧 DLL。重新构建（`dotnet build -c Release`）并把 `bin/Release/netstandard2.1/` 中新鲜的 DLL 复制到模组文件夹。 |
| 物品显示"未知"占位精灵图 | 传给 `SetSpriteAndShapeFromMod` 的 `spriteKey` 或模组 ID 不匹配。键是**文件名**（不含扩展名和文件夹）；ID 是你清单中的 `<ID>`，**不是**文件夹名。检查控制台中的 `item sprite(s) loaded` 数量。 |
| 某个精灵图文件被完全忽略 | 它没有*直接*放在 `Textures/Items/` 下（子文件夹不会被扫描），或者它不是 `.png`/`.jpg`。 |
| `PlaySound` 返回 false / 警告 `Audio identifier ... was not found` | 模组 ID 或声音键不匹配。完整标识是 `<清单 ID>:<不含扩展名的文件名>`。检查控制台中的 `sound(s) loaded` 数量。声音也会在启动后几帧才加载完成（如果播放得很早，请[等待它们](#如何知道资源已就绪)）。 |
| `GetLocalized` 返回键本身 | 当前语言的 CSV 或 `en.csv` 中没有该键的条目，或者文件名与游戏的语言代码不匹配。查找一次性的 `[ModHelper]` 警告，并检查控制台中的 `localization entries loaded` 数量。 |
| 警告 `requires '<id>' which is not loaded/enabled` | 你的清单在 `<Prerequisites>` 中列出的模组没有启用。启用它，或者去掉这个依赖。 |
| Harmony 补丁从不运行 | 目标类型/方法名写错了，或者模组被禁用了；补丁只在启动时应用于**已启用**的模组。 |
| 我的物品从不掉落 | 在控制台运行 `loot-list <tableId>`。如果条目不在，说明表 ID 写错了或编辑被拒绝了（查找指明你的模组的 `[LootRegistry]` 警告）。如果在，检查百分比：原版表中权重 `10` 约为 1%。 |
| 警告 `[LootRegistry] ... which does not exist` | 你的编辑或 JSON 文件中的表或表组 ID 与任何表都不匹配。`loot-list` 会打印所有 ID。注册自己的表时，先注册，再对它打补丁或加入表组。 |
