#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstanceSubsystem.h"
#include "GameplayTagContainer.h"
#include "SZInventorySystem.generated.h"

class USZItemData;
class AActor;

UENUM(BlueprintType)
enum class ESZItemCategory : uint8
{
	Consumable,
	KeyItem,
	Tool,
	Weapon,
	Ammo,
	Component,
	Heavy,
	PouchUpgrade
};

UENUM(BlueprintType)
enum class ESZItemRarity : uint8
{
	Common,
	Uncommon,
	Rare,
	Unique
};

USTRUCT(BlueprintType)
struct FSZItemInstance
{
	GENERATED_BODY()

	UPROPERTY()
	TObjectPtr<USZItemData> ItemData;

	UPROPERTY()
	int32 Quantity = 1;

	UPROPERTY()
	float Durability = 1.0f; // For weapons/tools

	UPROPERTY()
	TMap<FName, float> CustomStats; // For randomized stats

	UPROPERTY()
	FGuid InstanceID;

	FSZItemInstance()
	{
		InstanceID = FGuid::NewGuid();
	}

	FSZItemInstance(USZItemData* InItemData, int32 InQuantity = 1)
	{
		ItemData = InItemData;
		Quantity = InQuantity;
		Durability = 1.0f;
		InstanceID = FGuid::NewGuid();
	}
};

USTRUCT(BlueprintType)
struct FSZCraftingRecipe
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	FName RecipeID;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	FText DisplayName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	TArray<FGameplayTag> RequiredItemTags; // e.g., "Item.Bandage", "Item.Antiseptic"

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	TArray<int32> RequiredQuantities;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	TObjectPtr<USZItemData> ResultItem;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	int32 ResultQuantity = 1;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	bool bConsumeIngredients = true;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Crafting")
	FText Description;
};

USTRUCT(BlueprintType)
struct FSZInventorySlot
{
	GENERATED_BODY()

	UPROPERTY()
	FSZItemInstance Item;

	UPROPERTY()
	bool bIsEmpty = true;

	FSZInventorySlot() : bIsEmpty(true) {}
	FSZInventorySlot(const FSZItemInstance& InItem) : Item(InItem), bIsEmpty(false) {}
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnInventoryChanged, int32, PlayerId, const FSZInventorySlot&, Slot);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnItemAdded, const FSZItemInstance&, Item);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnItemRemoved, const FSZItemInstance&, Item);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnCraftingResult, bool, bSuccess, const FSZItemInstance&, ResultItem);

/**
 * Manages inventory, storage boxes, crafting, and item sharing for all players.
 * Each player has their own inventory; storage boxes are shared across the team.
 */
UCLASS(BlueprintType, Blueprintable)
class SUBJECTZERO_API USZInventorySystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void Deinitialize() override;

	// Player Inventory (per player)
	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	bool AddItemToPlayer(int32 PlayerId, const FSZItemInstance& Item);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	bool RemoveItemFromPlayer(int32 PlayerId, FGuid InstanceID, int32 Quantity = 1);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	FSZItemInstance GetPlayerItem(int32 PlayerId, FGuid InstanceID) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	TArray<FSZInventorySlot> GetPlayerInventory(int32 PlayerId) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	int32 GetPlayerInventoryCapacity(int32 PlayerId) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	int32 GetPlayerFreeSlots(int32 PlayerId) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Player")
	void GrantPouchUpgrade(int32 PlayerId);

	// Shared Storage Box (accessible from any safe room)
	UFUNCTION(BlueprintCallable, Category = "Inventory|Storage")
	bool AddItemToStorage(const FSZItemInstance& Item);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Storage")
	bool RemoveItemFromStorage(FGuid InstanceID, int32 Quantity = 1);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Storage")
	TArray<FSZInventorySlot> GetStorageContents() const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Storage")
	int32 GetStorageCapacity() const;

	// Item Sharing (drop/give to nearby teammate)
	UFUNCTION(BlueprintCallable, Category = "Inventory|Sharing")
	bool DropItem(int32 PlayerId, FGuid InstanceID, FVector Location, FRotator Rotation);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Sharing")
	bool GiveItemToPlayer(int32 FromPlayerId, int32 ToPlayerId, FGuid InstanceID, int32 Quantity = 1);

	// Crafting
	UFUNCTION(BlueprintCallable, Category = "Inventory|Crafting")
	bool CraftItem(int32 PlayerId, FName RecipeID);

	UFUNCTION(BlueprintCallable, Category = "Inventory|Crafting")
	TArray<FSZCraftingRecipe> GetAvailableRecipes(int32 PlayerId) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Crafting")
	bool CanCraftRecipe(int32 PlayerId, FName RecipeID) const;

	// Heavy Items
	UFUNCTION(BlueprintCallable, Category = "Inventory|Heavy")
	bool IsHeavyItem(const FSZItemInstance& Item) const;

	UFUNCTION(BlueprintCallable, Category = "Inventory|Heavy")
	float GetItemWeight(const FSZItemInstance& Item) const;

	// Save/Load
	UFUNCTION(BlueprintCallable, Category = "Inventory|SaveLoad")
	void SaveProgress();

	UFUNCTION(BlueprintCallable, Category = "Inventory|SaveLoad")
	void LoadProgress();

	UFUNCTION(BlueprintCallable, Category = "Inventory|SaveLoad")
	void ResetAllProgress();

	UPROPERTY(BlueprintAssignable, Category = "Inventory|Events")
	FOnInventoryChanged OnInventoryChanged;

	UPROPERTY(BlueprintAssignable, Category = "Inventory|Events")
	FOnItemAdded OnItemAdded;

	UPROPERTY(BlueprintAssignable, Category = "Inventory|Events")
	FOnItemRemoved OnItemRemoved;

	UPROPERTY(BlueprintAssignable, Category = "Inventory|Events")
	FOnCraftingResult OnCraftingResult;

protected:
	// Not a UPROPERTY: Unreal doesn't allow a TArray inside a TMap there.
	TMap<int32, TArray<FSZInventorySlot>> PlayerInventories; // PlayerId -> Slots

	UPROPERTY()
	TMap<int32, int32> PlayerInventoryCapacities; // PlayerId -> Capacity (starts at 4)

	UPROPERTY()
	TArray<FSZInventorySlot> SharedStorage;

	UPROPERTY()
	int32 StorageCapacity = 50;

	UPROPERTY()
	TArray<FSZCraftingRecipe> CraftingRecipes;

	UPROPERTY()
	FString SaveSlotName = TEXT("SubjectZero_InventorySave");

	UPROPERTY()
	int32 SaveUserIndex = 0;

	void InitializeDefaultRecipes();
	void InitializePlayerInventory(int32 PlayerId);
};