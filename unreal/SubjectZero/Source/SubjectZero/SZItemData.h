#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "GameplayTagContainer.h"
#include "SZInventorySystem.h"
#include "SZItemData.generated.h"

UCLASS(BlueprintType, Blueprintable)
class SUBJECTZERO_API USZItemData : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	FText DisplayName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	ESZItemCategory ItemCategory = ESZItemCategory::Consumable;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	ESZItemRarity Rarity = ESZItemRarity::Common;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	FGameplayTagContainer ItemTags;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	TSoftObjectPtr<class UStaticMesh> WorldMesh;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	TSoftObjectPtr<class UTexture2D> IconTexture;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	bool bIsStackable = true;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	int32 MaxStackSize = 10;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	bool bIsHeavy = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	float UseTime = 1.f; // Time to use/consume

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item")
	TSoftClassPtr<class AActor> PickupActorClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	float Damage = 0.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	float Durability = 100.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	float AttackSpeed = 1.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	float Range = 150.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	bool bIsRanged = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Weapon")
	TSubclassOf<class AActor> ProjectileClass;  // no projectile class yet

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Consumable")
	float HealthRestore = 0.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Consumable")
	float StaminaRestore = 0.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Item|Consumable")
	float BatteryRestore = 0.f;

	UFUNCTION(BlueprintPure, Category = "Item")
	FText GetDisplayName() const { return DisplayName; }

	UFUNCTION(BlueprintPure, Category = "Item")
	ESZItemCategory GetCategory() const { return ItemCategory; }

	UFUNCTION(BlueprintPure, Category = "Item")
	bool IsHeavy() const { return bIsHeavy || ItemCategory == ESZItemCategory::Heavy; }
};