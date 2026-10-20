#include "SZInventorySystem.h"
#include "SZItemData.h"
#include "Engine/GameInstance.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/SaveGame.h"

void USZInventorySystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	InitializeDefaultRecipes();
	LoadProgress();
}

void USZInventorySystem::Deinitialize()
{
	SaveProgress();
	Super::Deinitialize();
}

void USZInventorySystem::InitializeDefaultRecipes()
{
	// Bandage + Antiseptic = Med Kit
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_MedKit");
		Recipe.DisplayName = FText::FromString(TEXT("Med Kit"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.Bandage")), FGameplayTag::RequestGameplayTag(FName("Item.Antiseptic")) };
		Recipe.RequiredQuantities = { 1, 1 };
		Recipe.ResultQuantity = 1;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("Revives a downed teammate faster, or heals fully"));
		CraftingRecipes.Add(Recipe);
	}

	// Gunpowder + Empty Shells = Ammo
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_Ammo");
		Recipe.DisplayName = FText::FromString(TEXT("Ammo"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.Gunpowder")), FGameplayTag::RequestGameplayTag(FName("Item.EmptyShells")) };
		Recipe.RequiredQuantities = { 1, 1 };
		Recipe.ResultQuantity = 6;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("A few rounds for the gun the player chose"));
		CraftingRecipes.Add(Recipe);
	}

	// Battery + Battery = Charged Battery
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_ChargedBattery");
		Recipe.DisplayName = FText::FromString(TEXT("Charged Battery"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.Battery")), FGameplayTag::RequestGameplayTag(FName("Item.Battery")) };
		Recipe.RequiredQuantities = { 2, 0 }; // Second entry ignored, using same tag twice
		Recipe.ResultQuantity = 1;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("Fully recharges a flashlight"));
		CraftingRecipes.Add(Recipe);
	}

	// Duct Tape + Pipe = Reinforced Pipe
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_ReinforcedPipe");
		Recipe.DisplayName = FText::FromString(TEXT("Reinforced Pipe"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.DuctTape")), FGameplayTag::RequestGameplayTag(FName("Item.Pipe")) };
		Recipe.RequiredQuantities = { 1, 1 };
		Recipe.ResultQuantity = 1;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("Melee weapon that lasts twice as long"));
		CraftingRecipes.Add(Recipe);
	}

	// Alarm Clock + Battery = Sound Lure
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_SoundLure");
		Recipe.DisplayName = FText::FromString(TEXT("Sound Lure"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.AlarmClock")), FGameplayTag::RequestGameplayTag(FName("Item.Battery")) };
		Recipe.RequiredQuantities = { 1, 1 };
		Recipe.ResultQuantity = 1;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("Throwable noise distraction"));
		CraftingRecipes.Add(Recipe);
	}

	// Cloth + Alcohol + Lighter = Fire Bottle
	{
		FSZCraftingRecipe Recipe;
		Recipe.RecipeID = FName("Recipe_FireBottle");
		Recipe.DisplayName = FText::FromString(TEXT("Fire Bottle"));
		Recipe.RequiredItemTags = { FGameplayTag::RequestGameplayTag(FName("Item.Cloth")), FGameplayTag::RequestGameplayTag(FName("Item.Alcohol")), FGameplayTag::RequestGameplayTag(FName("Item.Lighter")) };
		Recipe.RequiredQuantities = { 1, 1, 1 };
		Recipe.ResultQuantity = 1;
		Recipe.bConsumeIngredients = true;
		Recipe.Description = FText::FromString(TEXT("Creates a wall of fire monsters won't cross for 8 seconds"));
		CraftingRecipes.Add(Recipe);
	}

	UE_LOG(LogTemp, Log, TEXT("InventorySystem: Initialized %d crafting recipes"), CraftingRecipes.Num());
}

void USZInventorySystem::InitializePlayerInventory(int32 PlayerId)
{
	if (!PlayerInventories.Contains(PlayerId))
	{
		TArray<FSZInventorySlot> Slots;
		Slots.SetNum(4); // Start with 4 slots
		for (FSZInventorySlot& Slot : Slots)
		{
			Slot.bIsEmpty = true;
		}
		PlayerInventories.Add(PlayerId, Slots);
		PlayerInventoryCapacities.Add(PlayerId, 4);
	}
}

bool USZInventorySystem::AddItemToPlayer(int32 PlayerId, const FSZItemInstance& Item)
{
	InitializePlayerInventory(PlayerId);
	
	TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
	
	// Try to stack with existing item
	for (FSZInventorySlot& Slot : Inventory)
	{
		if (!Slot.bIsEmpty && Slot.Item.ItemData == Item.ItemData && Slot.Item.InstanceID != Item.InstanceID)
		{
			// Check if stackable (consumables, components, ammo)
			if (Item.ItemData && (Item.ItemData->ItemCategory == ESZItemCategory::Consumable || 
				Item.ItemData->ItemCategory == ESZItemCategory::Component ||
				Item.ItemData->ItemCategory == ESZItemCategory::Ammo))
			{
				Slot.Item.Quantity += Item.Quantity;
				OnInventoryChanged.Broadcast(PlayerId, Slot);
				OnItemAdded.Broadcast(Slot.Item);
				return true;
			}
		}
	}

	// Find empty slot
	for (FSZInventorySlot& Slot : Inventory)
	{
		if (Slot.bIsEmpty)
		{
			Slot.Item = Item;
			Slot.bIsEmpty = false;
			OnInventoryChanged.Broadcast(PlayerId, Slot);
			OnItemAdded.Broadcast(Slot.Item);
			return true;
		}
	}

	// Inventory full
	return false;
}

bool USZInventorySystem::RemoveItemFromPlayer(int32 PlayerId, FGuid InstanceID, int32 Quantity)
{
	if (!PlayerInventories.Contains(PlayerId))
	{
		return false;
	}

	TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
	
	for (FSZInventorySlot& Slot : Inventory)
	{
		if (!Slot.bIsEmpty && Slot.Item.InstanceID == InstanceID)
		{
			if (Slot.Item.Quantity <= Quantity)
			{
				FSZItemInstance RemovedItem = Slot.Item;
				Slot.Item = FSZItemInstance();
				Slot.bIsEmpty = true;
				OnInventoryChanged.Broadcast(PlayerId, Slot);
				OnItemRemoved.Broadcast(RemovedItem);
				return true;
			}
			else
			{
				Slot.Item.Quantity -= Quantity;
				OnInventoryChanged.Broadcast(PlayerId, Slot);
				return true;
			}
		}
	}

	return false;
}

FSZItemInstance USZInventorySystem::GetPlayerItem(int32 PlayerId, FGuid InstanceID) const
{
	if (PlayerInventories.Contains(PlayerId))
	{
		const TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
		for (const FSZInventorySlot& Slot : Inventory)
		{
			if (!Slot.bIsEmpty && Slot.Item.InstanceID == InstanceID)
			{
				return Slot.Item;
			}
		}
	}
	return FSZItemInstance();
}

TArray<FSZInventorySlot> USZInventorySystem::GetPlayerInventory(int32 PlayerId) const
{
	if (PlayerInventories.Contains(PlayerId))
	{
		return PlayerInventories[PlayerId];
	}
	return TArray<FSZInventorySlot>();
}

int32 USZInventorySystem::GetPlayerInventoryCapacity(int32 PlayerId) const
{
	return PlayerInventoryCapacities.FindRef(PlayerId);
}

int32 USZInventorySystem::GetPlayerFreeSlots(int32 PlayerId) const
{
	if (PlayerInventories.Contains(PlayerId))
	{
		int32 Free = 0;
		for (const FSZInventorySlot& Slot : PlayerInventories[PlayerId])
		{
			if (Slot.bIsEmpty) Free++;
		}
		return Free;
	}
	return 0;
}

void USZInventorySystem::GrantPouchUpgrade(int32 PlayerId)
{
	InitializePlayerInventory(PlayerId);
	
	int32& Capacity = PlayerInventoryCapacities[PlayerId];
	TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
	
	Capacity++;
	Inventory.Add(FSZInventorySlot()); // Add empty slot
	
	UE_LOG(LogTemp, Log, TEXT("InventorySystem: Player %d granted pouch upgrade. New capacity: %d"), PlayerId, Capacity);
}

bool USZInventorySystem::AddItemToStorage(const FSZItemInstance& Item)
{
	// Try to stack
	for (FSZInventorySlot& Slot : SharedStorage)
	{
		if (!Slot.bIsEmpty && Slot.Item.ItemData == Item.ItemData && Slot.Item.InstanceID != Item.InstanceID)
		{
			if (Item.ItemData && (Item.ItemData->ItemCategory == ESZItemCategory::Consumable || 
				Item.ItemData->ItemCategory == ESZItemCategory::Component ||
				Item.ItemData->ItemCategory == ESZItemCategory::Ammo))
			{
				Slot.Item.Quantity += Item.Quantity;
				return true;
			}
		}
	}

	// Find empty slot
	if (SharedStorage.Num() < StorageCapacity)
	{
		SharedStorage.Add(FSZInventorySlot(Item));
		return true;
	}

	return false;
}

bool USZInventorySystem::RemoveItemFromStorage(FGuid InstanceID, int32 Quantity)
{
	for (FSZInventorySlot& Slot : SharedStorage)
	{
		if (!Slot.bIsEmpty && Slot.Item.InstanceID == InstanceID)
		{
			if (Slot.Item.Quantity <= Quantity)
			{
				Slot.Item = FSZItemInstance();
				Slot.bIsEmpty = true;
				return true;
			}
			else
			{
				Slot.Item.Quantity -= Quantity;
				return true;
			}
		}
	}
	return false;
}

TArray<FSZInventorySlot> USZInventorySystem::GetStorageContents() const
{
	return SharedStorage;
}

int32 USZInventorySystem::GetStorageCapacity() const
{
	return StorageCapacity;
}

bool USZInventorySystem::DropItem(int32 PlayerId, FGuid InstanceID, FVector Location, FRotator Rotation)
{
	FSZItemInstance Item = GetPlayerItem(PlayerId, InstanceID);
	if (Item.ItemData)
	{
		if (RemoveItemFromPlayer(PlayerId, InstanceID, 1))
		{
			// Spawn pickup actor at location (would be implemented in gameplay code)
			UE_LOG(LogTemp, Log, TEXT("InventorySystem: Player %d dropped item at %s"), PlayerId, *Location.ToString());
			return true;
		}
	}
	return false;
}

bool USZInventorySystem::GiveItemToPlayer(int32 FromPlayerId, int32 ToPlayerId, FGuid InstanceID, int32 Quantity)
{
	FSZItemInstance Item = GetPlayerItem(FromPlayerId, InstanceID);
	if (Item.ItemData)
	{
		FSZItemInstance GiveItem = Item;
		GiveItem.Quantity = Quantity;
		
		if (AddItemToPlayer(ToPlayerId, GiveItem))
		{
			RemoveItemFromPlayer(FromPlayerId, InstanceID, Quantity);
			return true;
		}
	}
	return false;
}

bool USZInventorySystem::CraftItem(int32 PlayerId, FName RecipeID)
{
	const FSZCraftingRecipe* Recipe = CraftingRecipes.FindByPredicate([RecipeID](const FSZCraftingRecipe& R) { return R.RecipeID == RecipeID; });
	if (!Recipe)
	{
		OnCraftingResult.Broadcast(false, FSZItemInstance());
		return false;
	}

	if (!CanCraftRecipe(PlayerId, RecipeID))
	{
		OnCraftingResult.Broadcast(false, FSZItemInstance());
		return false;
	}

	// Consume ingredients
	if (Recipe->bConsumeIngredients)
	{
		for (int32 i = 0; i < Recipe->RequiredItemTags.Num(); i++)
		{
			FGameplayTag RequiredTag = Recipe->RequiredItemTags[i];
			int32 RequiredQty = Recipe->RequiredQuantities[i];
			
			// Find and remove items with this tag from player inventory
			TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
			int32 RemainingToRemove = RequiredQty;
			
			for (FSZInventorySlot& Slot : Inventory)
			{
				if (!Slot.bIsEmpty && Slot.Item.ItemData && Slot.Item.ItemData->ItemTags.HasTag(RequiredTag))
				{
					int32 RemoveQty = FMath::Min(Slot.Item.Quantity, RemainingToRemove);
					Slot.Item.Quantity -= RemoveQty;
					RemainingToRemove -= RemoveQty;
					OnInventoryChanged.Broadcast(PlayerId, Slot);
					
					if (Slot.Item.Quantity <= 0)
					{
						Slot.Item = FSZItemInstance();
						Slot.bIsEmpty = true;
					}
					
					if (RemainingToRemove <= 0) break;
				}
			}
		}
	}

	// Create result item
	FSZItemInstance ResultItem(Recipe->ResultItem, Recipe->ResultQuantity);
	bool bSuccess = AddItemToPlayer(PlayerId, ResultItem);
	
	OnCraftingResult.Broadcast(bSuccess, ResultItem);
	return bSuccess;
}

TArray<FSZCraftingRecipe> USZInventorySystem::GetAvailableRecipes(int32 PlayerId) const
{
	return CraftingRecipes;
}

bool USZInventorySystem::CanCraftRecipe(int32 PlayerId, FName RecipeID) const
{
	const FSZCraftingRecipe* Recipe = CraftingRecipes.FindByPredicate([RecipeID](const FSZCraftingRecipe& R) { return R.RecipeID == RecipeID; });
	if (!Recipe) return false;

	if (!PlayerInventories.Contains(PlayerId)) return false;

	const TArray<FSZInventorySlot>& Inventory = PlayerInventories[PlayerId];
	
	for (int32 i = 0; i < Recipe->RequiredItemTags.Num(); i++)
	{
		FGameplayTag RequiredTag = Recipe->RequiredItemTags[i];
		int32 RequiredQty = Recipe->RequiredQuantities[i];
		int32 FoundQty = 0;
		
		for (const FSZInventorySlot& Slot : Inventory)
		{
			if (!Slot.bIsEmpty && Slot.Item.ItemData && Slot.Item.ItemData->ItemTags.HasTag(RequiredTag))
			{
				FoundQty += Slot.Item.Quantity;
			}
		}
		
		if (FoundQty < RequiredQty)
		{
			return false;
		}
	}

	return true;
}

bool USZInventorySystem::IsHeavyItem(const FSZItemInstance& Item) const
{
	return Item.ItemData && Item.ItemData->ItemCategory == ESZItemCategory::Heavy;
}

float USZInventorySystem::GetItemWeight(const FSZItemInstance& Item) const
{
	if (!Item.ItemData) return 0.f;
	
	switch (Item.ItemData->ItemCategory)
	{
		case ESZItemCategory::Heavy: return 50.f; // Car battery, gas canister
		case ESZItemCategory::Weapon: return 10.f;
		case ESZItemCategory::Tool: return 5.f;
		case ESZItemCategory::Consumable: return 1.f;
		case ESZItemCategory::Ammo: return 0.5f;
		case ESZItemCategory::Component: return 2.f;
		default: return 1.f;
	}
}

void USZInventorySystem::SaveProgress()
{
	USaveGame* SaveGame = UGameplayStatics::CreateSaveGameObject(USaveGame::StaticClass());
	if (SaveGame)
	{
		UGameplayStatics::SaveGameToSlot(SaveGame, SaveSlotName, SaveUserIndex);
	}
}

void USZInventorySystem::LoadProgress()
{
	if (UGameplayStatics::DoesSaveGameExist(SaveSlotName, SaveUserIndex))
	{
		USaveGame* SaveGame = UGameplayStatics::LoadGameFromSlot(SaveSlotName, SaveUserIndex);
		if (SaveGame)
		{
			// TODO: Implement actual save/load
		}
	}
}

void USZInventorySystem::ResetAllProgress()
{
	PlayerInventories.Empty();
	PlayerInventoryCapacities.Empty();
	SharedStorage.Empty();
	SaveProgress();
}