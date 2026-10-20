#include "SZDefaultItems.h"
#include "SZItemData.h"
#include "Engine/Engine.h"

void USZDefaultItems::RegisterDefaultItems(TArray<TObjectPtr<USZItemData>>& OutItemRegistry)
{
	auto CreateItem = [&](FName Name, FText DisplayName, FText Description, ESZItemCategory Category, 
		ESZItemRarity Rarity, FGameplayTagContainer Tags, bool bStackable, int32 MaxStack, bool bHeavy,
		float UseTime = 1.f, float HealthRestore = 0.f, float StaminaRestore = 0.f, float BatteryRestore = 0.f)
	{
		USZItemData* Item = NewObject<USZItemData>(GetTransientPackage(), Name);
		Item->DisplayName = DisplayName;
		Item->Description = Description;
		Item->ItemCategory = Category;
		Item->Rarity = Rarity;
		Item->ItemTags = Tags;
		Item->bIsStackable = bStackable;
		Item->MaxStackSize = MaxStack;
		Item->bIsHeavy = bHeavy;
		Item->UseTime = UseTime;
		Item->HealthRestore = HealthRestore;
		Item->StaminaRestore = StaminaRestore;
		Item->BatteryRestore = BatteryRestore;
		OutItemRegistry.Add(Item);
		return Item;
	};

	// Battery
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Battery")));
		CreateItem(FName("Item_Battery"), FText::FromString(TEXT("Battery")), 
			FText::FromString(TEXT("Recharges a flashlight. Flashlights slowly drain, so batteries are precious.")),
			ESZItemCategory::Consumable, ESZItemRarity::Common, Tags, true, 5, false, 2.f, 0.f, 0.f, 50.f);
	}

	// Fuse
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Fuse")));
		CreateItem(FName("Item_Fuse"), FText::FromString(TEXT("Fuse")), 
			FText::FromString(TEXT("Fits into fuse boxes to power doors and machines. Engineer installs faster.")),
			ESZItemCategory::Component, ESZItemRarity::Common, Tags, true, 10, false);
	}

	// Green Keycard
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Keycard.Green")));
		CreateItem(FName("Item_GreenKeycard"), FText::FromString(TEXT("Green Keycard")), 
			FText::FromString(TEXT("Opens doors of Green security level.")),
			ESZItemCategory::KeyItem, ESZItemRarity::Common, Tags, false, 1, false);
	}

	// Yellow Keycard
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Keycard.Yellow")));
		CreateItem(FName("Item_YellowKeycard"), FText::FromString(TEXT("Yellow Keycard")), 
			FText::FromString(TEXT("Opens doors of Yellow security level.")),
			ESZItemCategory::KeyItem, ESZItemRarity::Uncommon, Tags, false, 1, false);
	}

	// Red Keycard
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Keycard.Red")));
		CreateItem(FName("Item_RedKeycard"), FText::FromString(TEXT("Red Keycard")), 
			FText::FromString(TEXT("Opens doors of Red security level. Deepest levels need this.")),
			ESZItemCategory::KeyItem, ESZItemRarity::Rare, Tags, false, 1, false);
	}

	// Crowbar
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Crowbar")));
		USZItemData* Crowbar = CreateItem(FName("Item_Crowbar"), FText::FromString(TEXT("Crowbar")), 
			FText::FromString(TEXT("Pries open vents, crates, and jammed doors. Single-use pry takes 3 seconds and makes noise.")),
			ESZItemCategory::Tool, ESZItemRarity::Common, Tags, false, 1, false, 3.f);
		Crowbar->Damage = 15.f;
		Crowbar->Durability = 3.f; // 3 uses
		Crowbar->AttackSpeed = 0.5f;
		Crowbar->Range = 200.f;
	}

	// Flare
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Flare")));
		CreateItem(FName("Item_Flare"), FText::FromString(TEXT("Flare")), 
			FText::FromString(TEXT("Throw to light an area and distract monsters for 10 seconds. Great for covering teammates.")),
			ESZItemCategory::Consumable, ESZItemRarity::Uncommon, Tags, true, 3, false, 1.f);
	}

	// Med Kit
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.MedKit")));
		CreateItem(FName("Item_MedKit"), FText::FromString(TEXT("Med Kit")), 
			FText::FromString(TEXT("Instantly revives a downed teammate from a distance of 1 meter. Rare.")),
			ESZItemCategory::Consumable, ESZItemRarity::Rare, Tags, true, 3, false, 2.f, 100.f, 50.f, 0.f);
	}

	// Gas Mask
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.GasMask")));
		CreateItem(FName("Item_GasMask"), FText::FromString(TEXT("Gas Mask")), 
			FText::FromString(TEXT("Lets the wearer walk through toxic gas rooms. Filter lasts 45 seconds.")),
			ESZItemCategory::Tool, ESZItemRarity::Uncommon, Tags, false, 1, false, 0.f);
	}

	// Walkie-Talkie
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.WalkieTalkie")));
		CreateItem(FName("Item_WalkieTalkie"), FText::FromString(TEXT("Walkie-Talkie")), 
			FText::FromString(TEXT("Lets two players hear each other from anywhere. Only 2 per chapter; very useful when split up.")),
			ESZItemCategory::Tool, ESZItemRarity::Rare, Tags, false, 2, false);
	}

	// Reel Tape
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.ReelTape")));
		CreateItem(FName("Item_ReelTape"), FText::FromString(TEXT("Reel Tape")), 
			FText::FromString(TEXT("Plays a lore recording on tape machines. Collectible story item.")),
			ESZItemCategory::KeyItem, ESZItemRarity::Common, Tags, true, 10, false);
	}

	// Car Battery (Heavy)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.CarBattery")));
		USZItemData* CarBattery = CreateItem(FName("Item_CarBattery"), FText::FromString(TEXT("Car Battery")), 
			FText::FromString(TEXT("Powers a single heavy machine. Heavy item - only the Guard carries at normal speed.")),
			ESZItemCategory::Heavy, ESZItemRarity::Uncommon, Tags, false, 1, true, 5.f);
	}

	// Bandage (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Bandage")));
		CreateItem(FName("Item_Bandage"), FText::FromString(TEXT("Bandage")), 
			FText::FromString(TEXT("Basic healing item. Combine with Antiseptic to make a Med Kit.")),
			ESZItemCategory::Consumable, ESZItemRarity::Common, Tags, true, 10, false, 1.f, 25.f, 0.f, 0.f);
	}

	// Antiseptic (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Antiseptic")));
		CreateItem(FName("Item_Antiseptic"), FText::FromString(TEXT("Antiseptic")), 
			FText::FromString(TEXT("Medical supply. Combine with Bandage to make a Med Kit.")),
			ESZItemCategory::Component, ESZItemRarity::Common, Tags, true, 10, false);
	}

	// Gunpowder (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Gunpowder")));
		CreateItem(FName("Item_Gunpowder"), FText::FromString(TEXT("Gunpowder")), 
			FText::FromString(TEXT("Explosive powder. Combine with Empty Shells to make Ammo.")),
			ESZItemCategory::Component, ESZItemRarity::Uncommon, Tags, true, 10, false);
	}

	// Empty Shells (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.EmptyShells")));
		CreateItem(FName("Item_EmptyShells"), FText::FromString(TEXT("Empty Shells")), 
			FText::FromString(TEXT("Spent casings. Combine with Gunpowder to make Ammo.")),
			ESZItemCategory::Component, ESZItemRarity::Common, Tags, true, 20, false);
	}

	// Duct Tape (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.DuctTape")));
		CreateItem(FName("Item_DuctTape"), FText::FromString(TEXT("Duct Tape")), 
			FText::FromString(TEXT("Strong adhesive tape. Combine with Pipe to make Reinforced Pipe.")),
			ESZItemCategory::Component, ESZItemRarity::Common, Tags, true, 5, false);
	}

	// Pipe (for crafting/melee)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Pipe")));
		USZItemData* Pipe = CreateItem(FName("Item_Pipe"), FText::FromString(TEXT("Pipe")), 
			FText::FromString(TEXT("Metal pipe. Use as melee weapon or combine with Duct Tape.")),
			ESZItemCategory::Weapon, ESZItemRarity::Common, Tags, false, 1, false, 1.f);
		Pipe->Damage = 20.f;
		Pipe->Durability = 50.f;
		Pipe->AttackSpeed = 0.8f;
		Pipe->Range = 250.f;
	}

	// Alarm Clock (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.AlarmClock")));
		CreateItem(FName("Item_AlarmClock"), FText::FromString(TEXT("Alarm Clock")), 
			FText::FromString(TEXT("Old mechanical alarm clock. Combine with Battery to make Sound Lure.")),
			ESZItemCategory::Component, ESZItemRarity::Uncommon, Tags, false, 1, false);
	}

	// Cloth (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Cloth")));
		CreateItem(FName("Item_Cloth"), FText::FromString(TEXT("Cloth")), 
			FText::FromString(TEXT("Rag or fabric scrap. Combine with Alcohol and Lighter to make Fire Bottle.")),
			ESZItemCategory::Component, ESZItemRarity::Common, Tags, true, 10, false);
	}

	// Alcohol (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Alcohol")));
		CreateItem(FName("Item_Alcohol"), FText::FromString(TEXT("Alcohol")), 
			FText::FromString(TEXT("Flammable liquid. Combine with Cloth and Lighter to make Fire Bottle.")),
			ESZItemCategory::Component, ESZItemRarity::Uncommon, Tags, true, 5, false);
	}

	// Lighter (for crafting)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Lighter")));
		CreateItem(FName("Item_Lighter"), FText::FromString(TEXT("Lighter")), 
			FText::FromString(TEXT("Disposable lighter. Combine with Cloth and Alcohol to make Fire Bottle.")),
			ESZItemCategory::Tool, ESZItemRarity::Common, Tags, true, 3, false);
	}

	// Reinforced Pipe (crafted weapon)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.ReinforcedPipe")));
		USZItemData* ReinforcedPipe = CreateItem(FName("Item_ReinforcedPipe"), FText::FromString(TEXT("Reinforced Pipe")), 
			FText::FromString(TEXT("Pipe reinforced with duct tape. Melee weapon that lasts twice as long.")),
			ESZItemCategory::Weapon, ESZItemRarity::Uncommon, Tags, false, 1, false);
		ReinforcedPipe->Damage = 30.f;
		ReinforcedPipe->Durability = 100.f;
		ReinforcedPipe->AttackSpeed = 0.8f;
		ReinforcedPipe->Range = 250.f;
	}

	// Sound Lure (crafted)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.SoundLure")));
		CreateItem(FName("Item_SoundLure"), FText::FromString(TEXT("Sound Lure")), 
			FText::FromString(TEXT("Throwable noise distraction. Combine Alarm Clock + Battery.")),
			ESZItemCategory::Consumable, ESZItemRarity::Uncommon, Tags, true, 3, false, 1.f);
	}

	// Fire Bottle (crafted)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.FireBottle")));
		CreateItem(FName("Item_FireBottle"), FText::FromString(TEXT("Fire Bottle")), 
			FText::FromString(TEXT("Creates a wall of fire monsters won't cross for 8 seconds. Combine Cloth + Alcohol + Lighter.")),
			ESZItemCategory::Consumable, ESZItemRarity::Rare, Tags, true, 2, false, 2.f);
	}

	// Charged Battery (crafted)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.ChargedBattery")));
		CreateItem(FName("Item_ChargedBattery"), FText::FromString(TEXT("Charged Battery")), 
			FText::FromString(TEXT("Fully recharges a flashlight. Combine Battery + Battery.")),
			ESZItemCategory::Consumable, ESZItemRarity::Uncommon, Tags, true, 3, false, 1.f, 0.f, 0.f, 100.f);
	}

	// Pouch Upgrade (Chapter 2-5 rewards)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.PouchUpgrade")));
		CreateItem(FName("Item_PouchUpgrade"), FText::FromString(TEXT("Pouch Upgrade")), 
			FText::FromString(TEXT("Adds one inventory slot. Found once per chapter in Chapters 2-5.")),
			ESZItemCategory::PouchUpgrade, ESZItemRarity::Unique, Tags, false, 1, false);
	}

	// Revolver (Chapter 3 unlock)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Revolver")));
		USZItemData* Revolver = CreateItem(FName("Item_Revolver"), FText::FromString(TEXT("Guard Revolver")), 
			FText::FromString(TEXT("Old service revolver. Chapter 3 unlock. Limited ammo.")),
			ESZItemCategory::Weapon, ESZItemRarity::Rare, Tags, false, 1, false);
		Revolver->Damage = 40.f;
		Revolver->Durability = 100.f;
		Revolver->AttackSpeed = 0.5f;
		Revolver->Range = 2000.f;
		Revolver->bIsRanged = true;
	}

	// Shotgun (Chapter 4 unlock)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.Shotgun")));
		USZItemData* Shotgun = CreateItem(FName("Item_Shotgun"), FText::FromString(TEXT("Shotgun")), 
			FText::FromString(TEXT("Pump-action shotgun. Chapter 4 unlock. Devastating at close range.")),
			ESZItemCategory::Weapon, ESZItemRarity::Rare, Tags, false, 1, false);
		Shotgun->Damage = 60.f;
		Shotgun->Durability = 80.f;
		Shotgun->AttackSpeed = 0.7f;
		Shotgun->Range = 800.f;
		Shotgun->bIsRanged = true;
	}

	// Modern Assault Rifle (Chapter 5 unlock)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.AssaultRifle")));
		USZItemData* AssaultRifle = CreateItem(FName("Item_AssaultRifle"), FText::FromString(TEXT("Modern Assault Rifle")), 
			FText::FromString(TEXT("Modern tactical rifle from Ashby's security. Chapter 5 unlock.")),
			ESZItemCategory::Weapon, ESZItemRarity::Rare, Tags, false, 1, false);
		AssaultRifle->Damage = 35.f;
		AssaultRifle->Durability = 150.f;
		AssaultRifle->AttackSpeed = 0.1f; // Full auto
		AssaultRifle->Range = 3000.f;
		AssaultRifle->bIsRanged = true;
	}

	// Tactical Gear (Chapter 5 unlock - armor)
	{
		FGameplayTagContainer Tags;
		Tags.AddTag(FGameplayTag::RequestGameplayTag(FName("Item.TacticalGear")));
		CreateItem(FName("Item_TacticalGear"), FText::FromString(TEXT("Tactical Gear")), 
			FText::FromString(TEXT("Modern body armor. Reduces damage taken. Chapter 5 unlock.")),
			ESZItemCategory::Tool, ESZItemRarity::Unique, Tags, false, 1, false);
	}

	UE_LOG(LogTemp, Log, TEXT("DefaultItems: Registered %d items for Deepwell"), OutItemRegistry.Num());
}