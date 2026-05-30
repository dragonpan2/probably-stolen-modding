using System;
using UnityEngine;
using HarmonyLib;

namespace LearnerMod
{
    public class Items
    {
        // Consumable Item Example
        public static GameItem CreatePurpleBloodBag()
        {
            GameItem item = ItemDirectory.CreateEmptyItem()
                .SetName("Bag of Purple Blood")
                .SetSpriteAndShapeFromMod("learner_mod", "health_pack"); //use SetSpriteAndShapeFromMod for sprite from mod. The first parameter is the mod's unique ID, and the second is the name of the sprite in the mod's assets folder (without file extension)
            item.unitValue = 100; //Use unitValue for base price
            item.shortDescription = "A bag of advanced serum that can be used to heal wounds immediately.";
            item.flavorText = "This serum is known for its rapid healing properties, often used in emergency situations. Not actually blood";

            item.SetGameItemType(TypeHelper.MEDICAL); // set the item's GameItem Type which is used for buyer/seller and storage

            item.mayActivateSlotItemFunc = (item, _, _) =>
            {
                if (GeneralHelper.IsItemOwned(item))
                {
                    return true;
                }
                if (PlayerStore.Instance.healthData.woundState > 0 || PlayerStore.Instance.healthData.isWoundStable == false || PlayerStore.Instance.healthData.isWoundedFresh == true)
                {
                    return true;
                }
                return false;
            };

            item.onActivateSlotItemFunc = (item, _, _) =>
            {
                PlayerStore.Instance.healthData.woundState = 0;
                PlayerStore.Instance.healthData.isWoundStable = true;
                PlayerStore.Instance.healthData.isWoundedFresh = false;

                item.Destroy();
            };


            return item;
        }
        
    }
}