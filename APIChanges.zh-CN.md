# Probably Stolen：模组 API 变更

English version: [APIChanges.md](APIChanges.md)

按游戏更新记录模组 API 的变化，最新的在最上面。每次更新内部按重要性排序：需要你立即处理的在前，新增能力在后。完整文档见 [ModdingGuide.zh-CN.md](ModdingGuide.zh-CN.md)。

## 下一次更新（开发中）

**建议处理**

- **不要再为修改掉落而修补 `TableMaster` / `TableGroupMaster`。** 它们的静态字典已被移除；掷取（roll）现在都经过 `LootRegistry`，它为此提供了受支持的 API。[详情](ModdingGuide.zh-CN.md#掉落表)

**新增**

- **掉落表编辑。** 把你的物品加进游戏的掉落表、修改或移除已有掉落、注册新的表和表组：`ModHelper.AddLootEntry / SetLootWeight / RemoveLootEntry / RegisterLootTable` 以及对应的 `Group` 版本，可在 `OnEnable` 中调用。权重是相对值，原版表的总和为 1000，因此权重 `10` 约为 1%。[详情](ModdingGuide.zh-CN.md#掉落表)
- **JSON 掉落文件。** 同样的编辑可以以数据形式提供：模组文件夹中的 `LootTables/*.json`，无需 C#。[详情](ModdingGuide.zh-CN.md#用-json-文件编辑掉落表)
- **`ModHook.OnLootTablesLoaded`**（掉落表就绪，所有编辑已应用）和 **`ModHook.OnLootRolled(LootRollContext)`**（覆盖任意一次掷取的结果）。[详情](ModdingGuide.zh-CN.md#响应掷取)
- **控制台命令** `loot-list [id]` 和 `loot-roll <id> [count]`，用于查看实际概率、哪个模组改了什么，以及试掷一张表。[详情](ModdingGuide.zh-CN.md#在控制台中查看掉落表)
- **模组数据存储。** 用 `ModHelper.SetModData / GetModData`（以及 `Int`、`Float`、`Bool` 变体、`HasModData`、`RemoveModData`、`GetModDataKeys`、`ClearModData`）保存任何不属于某个物品的数据。按模组 ID 隔离命名空间，随本局游戏一起保存，载入时恢复。[详情](ModdingGuide.zh-CN.md#保存模组数据)
- **自定义 UI。** 用 `CustomUIManager` 的链式构建器从代码创建你自己的窗口（标签、按钮、开关、滑块、输入框、下拉框、进度条、图片、标签页、滚动列表），可放在任意游戏画布上或一个跨场景持久的覆盖层上。模组精灵图通过 `"modId:spriteName"` 键使用。自定义 UI 从"暂不支持"列表移入已支持列表。[详情](ModdingGuide.zh-CN.md#自定义-ui)

## 2026 年 7 月

**建议处理**

- **不要再用自己的 `AudioSource` 播放声音。** 模组声音现在会以 `<modId>:<key>` 为标识注册到游戏的音频系统。请改用 `ModHelper.PlaySound / PlaySound2 / PlaySound3(modId, key)`，这样玩家的音量和暂停设置才会生效。直接读取 `mod.Sounds` 仍然可行，但会绕过音量设置。[详情](ModdingGuide.zh-CN.md#声音)

**行为变化**

- **钩子处理函数抛出的异常不再影响游戏或其他模组。** 每个订阅者都在自己的 try/catch 中运行；错误会以 `[ModHook] ... from '<your mod>' threw: ...` 的形式记录到 F8 控制台，其余一切照常继续。通过在处理函数中抛出异常来中止游戏代码的做法不再有效（这从来就不受支持；请使用返回 `false` 的 Harmony Prefix）。记录下来的异常仍然意味着你的模组有问题。

**新增**

- **基于 CSV 的本地化。** 在模组文件夹中以 `Localization/<localeCode>.csv` 文件提供翻译，并用 `ModHelper.GetLocalized(modId, key, args...)` 读取。先解析当前语言，再回退到英语，最后回退到键本身。[详情](ModdingGuide.zh-CN.md#本地化)
- **自定义物品音效。** 物品的声音字段（`soundUse`、`soundDragStart`、`soundContainerOpen` 等）现在接受模组声音标识：`item.soundUse = ModHelper.GetSoundIdentifier("my_mod_id", "gulp");`
- **`ModHook.OnModAssetsLoaded(LoadedMod)`**：每个已启用的模组在其全部贴图、物品精灵图和声音载入内存后触发一次。它会为每个模组触发，请检查 `mod.Manifest.ID` 是不是你的。[详情](ModdingGuide.zh-CN.md#如何知道资源已就绪)

**政策**

- **反编译：可以看，不可以复制。** 为了研究游戏、寻找补丁目标而反编译游戏是官方默许的；再分发游戏代码或资源则不行。[完整政策](CodeOfConduct.zh-CN.md#尊重其他创作者)
