using System;
using UnityEngine;
using HarmonyLib;
using System.Collections.Generic;

namespace LearnerMod
{
    public class ModEntry : IMod
    {
        private ModLog log;

        public void Init(ModManifest manifest)
        {
            log = new ModLog(manifest);
            log.Log("Learner Mod initializing...");

            // Init Items into the modded item directory
            ModHook.OnModItemDirectoryInit += (ModItemDirectory modItemDirectory) =>
            {
                modItemDirectory.Add("purple_blood", Items.CreatePurpleBloodBag);
                modItemDirectory.Add("purple_blood_synthesizer", PurpleBloodSynthesizer.CreatePurpleBloodSynthesizer);
            };

            // Add what dr. jackson might have in stock
            ModHook.OnPlaceInventorInventoryItemLate += (List<GameItem> items) =>
            {
                // 50% chance dr. jackson will have the purple blood synthesizer in stock
                if (RNG.Roll(50)) PlayerStore.Instance.AddDirectSellingItemToTable(DirectoryMaster.Item("purple_blood_synthesizer"));
            };
        }
        public void OnEnable()
        {
            log.Log("Learner Mod enabled. Enjoy!");
        }
        public void OnDisable()
        {
            log.Log("Learner Mod disabled. Goodbye!");
        }
    }
}