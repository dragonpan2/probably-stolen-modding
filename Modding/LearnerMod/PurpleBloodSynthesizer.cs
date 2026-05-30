using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LearnerMod
{
    public class PurpleBloodSynthesizer
    {
        public const string PURPLE_BLOOD_SYNTHESIZER_TAG = "PURPLE_BLOOD_SYNTHESIZER_TAG";
        public const int    BASE_POWER_USAGE       = 8;
        public const int    BASE_PROCESSING_SPEED  = 100;
        public const int    TARGET_PROGRESS        = 300; // 3 cycles (days) at base speed of 100

        public static GameItem CreatePurpleBloodSynthesizer()
        {
            (PixelWindow itemWindow, GameSlotInventory batterySlot, GameGridInventory moduleGrid, GameGridInventory inputGrid, GameGridInventory outputGrid, GameSlotInventory noteSlot) = CreateMachineInventoryWindow();

            inputGrid.mayInventoryAddItemFunc = (item, _) =>
            {
                if (GeneralHelper.IsItemOwned(item) == false) return false;
                return item.IsGameItemType(TypeHelper.CHEMICAL_SUPPLIES);
            };

            outputGrid.mayInventoryAddItemFunc = (item, _) => item.identifier.Equals("purple_blood");

            noteSlot.mayInventoryAddItemFunc = (item, _) => item.identifier.Equals("postit");
            noteSlot.SetBackgroundFadeSprite("Items/items_tool", "postit");

            GameItem machine = ItemDirectory.CreateEmptyItem()
                .SetContentWindow(itemWindow)
                .SetSpriteAndShape("Items/items_tool2", "printer_off");

            machine.name             = "Purple Blood Synthesizer";
            machine.shortDescription = "A machine that can synthesize Purple Blood bags from Chemical Supplies.";
            machine.flavorText       = "";

            machine.unitValue = 500;

            machine.SetGameItemType(TypeHelper.MACHINE);
            machine.EnableTag(ContainerHelper.CONTAINER_TAG);
            machine.EnableTag("manufacture");
            machine.EnableTag(MachineHelper.STANDARD_MACHINE_TAG);
            machine.EnableTag(PURPLE_BLOOD_SYNTHESIZER_TAG);

            MachineHelper.SetupBatterySlot(batterySlot, machine);

            MachineryHelper.InitMachinery(machine, BASE_POWER_USAGE);
            MachineProgressHelper.InitProgressTypeMachine(machine, BASE_PROCESSING_SPEED, useDefaultTooltip: false);

            // Production speed bonus from modules is applied at ratio 1 (full effect).
            machine.ModifyTag(MachineHelper.MACHINE_PERFORMANCE_RATIO_INT, state => state.Enable().SetInt(1));

            string[] possibleModule = { ModuleHelper.MODULE_TYPE_UNIVERSAL };
            ContainerHelper.AllowOnlyTaggedItemsOr(moduleGrid, possibleModule, true);

            moduleGrid.onSlotAddItemEndFunc = (addedItem, parentInventory, slot) =>
            {
                ModuleEffectHelper.OnAddedModuleToGrid(addedItem, machine, moduleGrid.childItems);
                if (addedItem.IsTag(ModuleHelper.MODULE_TAG))
                {
                    ModuleHelper.ComputeModuleEffect(moduleGrid, addedItem, machine);
                    ModuleHelper.ApplyBasicModuleEffect(moduleGrid, addedItem, machine);
                }
                MachineryHelper.UpdatePowerUsageProcessTypeMachine(machine);
            };
            moduleGrid.onSlotRemoveItemEndFunc = (removedItem, parentInventory, slot) =>
            {
                ModuleEffectHelper.OnRemovedModuleFromGrid(removedItem, machine, moduleGrid.childItems);
                if (removedItem.IsTag(ModuleHelper.MODULE_TAG))
                {
                    ModuleHelper.ComputeModuleEffect(moduleGrid, removedItem, machine);
                    ModuleHelper.ApplyBasicModuleEffect(moduleGrid, removedItem, machine);
                }
                MachineryHelper.UpdatePowerUsageProcessTypeMachine(machine);
            };

            machine.onCycleEndSlotItemFunc = (item, parentInventory, slot) =>
            {
                int energyUsage = MachineryHelper.GetMachinePowerUsage(item);
                if (MachineHelper.CanPower(item, batterySlot) == false) return;

                GameItem outputTester = DirectoryMaster.Item("purple_blood");
                bool outputHasRoom = GraphUtils.CanAccept(outputGrid, outputTester);
                outputTester.Destroy();
                if (outputHasRoom == false) return;

                GameItem chemSupply = GraphUtils.FindChildType<GameItem>(inputGrid, c => c.IsGameItemType(TypeHelper.CHEMICAL_SUPPLIES));

                string state = MachineProgressHelper.GetMachineState(item);

                if (state.Equals(MachineProgressHelper.STATE_READY))
                {
                    if (chemSupply == null) return;

                    PowerHelper.DrawPowerSource(batterySlot.childItem, energyUsage);

                    item.ModifyTag(MachineProgressHelper.MACHINE_STATE_TAG,           s => s.Enable().SetString(MachineProgressHelper.STATE_WORKING));
                    item.ModifyTag(MachineProgressHelper.MACHINE_PROGRESS_CURRENT_TAG, s => s.Enable().SetInt(0));
                    item.ModifyTag(MachineProgressHelper.MACHINE_PROGRESS_TARGET_TAG,  s => s.Enable().SetInt(TARGET_PROGRESS));

                    MachineProgressHelper.ContinueProgressTypeMachine(item);
                    MachineHelper.OnMachineActioned(machine, moduleGrid);

                    if (MachineProgressHelper.IsProgressTypeMachineFinished(item))
                    {
                        FinishSynthesis(item, chemSupply, outputGrid);
                    }
                }
                else if (state.Equals(MachineProgressHelper.STATE_WORKING))
                {
                    PowerHelper.DrawPowerSource(batterySlot.childItem, energyUsage);

                    MachineProgressHelper.ContinueProgressTypeMachine(item);
                    MachineHelper.OnMachineActioned(machine, moduleGrid);

                    if (MachineProgressHelper.IsProgressTypeMachineFinished(item))
                    {
                        if (chemSupply == null)
                        {
                            MachineProgressHelper.FinishProgressTypeMachine(item);
                            return;
                        }
                        FinishSynthesis(item, chemSupply, outputGrid);
                    }
                }
            };

            return machine;
        }

        public static void FinishSynthesis(GameItem machine, GameItem chemSupply, GameGridInventory outputGrid)
        {
            MachineProgressHelper.FinishProgressTypeMachine(machine);
            chemSupply.Destroy();
            GraphUtils.TryAcceptAll(outputGrid, DirectoryMaster.Item("purple_blood"));
        }

        public static (PixelWindow, GameSlotInventory, GameGridInventory, GameGridInventory, GameGridInventory, GameSlotInventory) CreateMachineInventoryWindow(bool isDraggable = true, bool isCentered = true, int minWidth = 5)
        {
            PixelWindow window = new PixelWindow(isDraggable);
            GridPixelElement mainGrid = new GridPixelElement(5, 2, isCentered);

            GameSlotInventory batterySlot = new GameSlotInventory();
            GameGridInventory moduleGrid  = new GameGridInventory(MachineHelper.DEFAULT_MODULE_BAY_CONFIG, MachineHelper.DEFAULT_MODULE_BAY_WIDTH);
            GameGridInventory inputGrid   = new GameGridInventory(6, 4);
            GameGridInventory outputGrid  = new GameGridInventory(6, 3);
            GameSlotInventory noteSlot    = new GameSlotInventory();

            TagElement batteryLabel = new TagElement().SetText("Battery");
            TagElement moduleLabel  = new TagElement().SetText("Modules");
            TagElement inputLabel   = new TagElement().SetText("Chemical Supplies");
            TagElement outputLabel  = new TagElement().SetText("Output");
            TagElement noteLabel    = new TagElement().SetText("Note");

            mainGrid.Attach(batteryLabel, 0, 0, minimumHeight: 20, minimumWidth: 20);
            mainGrid.Attach(moduleLabel,  1, 0, minimumHeight: 20, minimumWidth: 20);
            mainGrid.Attach(inputLabel,   2, 0, minimumHeight: 20, minimumWidth: minWidth);
            mainGrid.Attach(outputLabel,  3, 0, minimumHeight: 20, minimumWidth: 5);
            mainGrid.Attach(noteLabel,    4, 0, minimumHeight: 5,  minimumWidth: 5);

            mainGrid.Attach(batterySlot, 0, 1, minimumHeight: 50,  minimumWidth: 20);
            mainGrid.Attach(moduleGrid,  1, 1, minimumHeight: 50,  minimumWidth: 20);
            mainGrid.Attach(inputGrid,   2, 1, minimumHeight: 50,  minimumWidth: minWidth);
            mainGrid.Attach(outputGrid,  3, 1, minimumHeight: 100, minimumWidth: 5);
            mainGrid.Attach(noteSlot,    4, 1, minimumHeight: 5,   minimumWidth: 5);

            window.Attach(mainGrid);

            return (window, batterySlot, moduleGrid, inputGrid, outputGrid, noteSlot);
        }

        public static GameItem CreateNote()
        {
            GameItem item = DirectoryMaster.Item("postit", isOwned: true);

            item.name             = "Purple Blood Synthesizer - Instructions";
            item.shortDescription = "Place a battery in the power slot and load Chemical Supplies into the input row. Each synthesis cycle consumes 1 Chemical Supply and runs for 3 days, producing 1 Purple Blood bag in the output grid.\n\nUniversal modules can be installed in the module bay to improve power efficiency and production speed. This machine is not affected by quality bonuses.";

            item.SetGameItemType(TypeHelper.DOCUMENT);
            item.EnableTag(GeneralHelper.IMPORTANT_TAG);
            item.unitValue = 0;

            return item;
        }
    }
}