#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "GameplayTagContainer.h"
#include "SZCharacterData.generated.h"

UENUM(BlueprintType)
enum class ESZCharacterRole : uint8
{
	Tracker,
	Stunner,
	Fixer,
	Protector
};

UENUM(BlueprintType)
enum class ESZCharacterID : uint8
{
	None,
	EliReyes,
	NoraVance,
	WalterKessler,
	ColeBrennan
};

USTRUCT(BlueprintType)
struct FSZCharacterAbility
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	FGameplayTag AbilityTag;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	FText DisplayName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	float CooldownSeconds = 0.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	float DurationSeconds = 0.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Ability")
	TSoftObjectPtr<class UTexture2D> Icon;
};

USTRUCT(BlueprintType)
struct FSZPassiveAbility
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Passive")
	FGameplayTag PassiveTag;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Passive")
	FText DisplayName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Passive")
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Passive")
	TSoftObjectPtr<class UTexture2D> Icon;
};

UCLASS(BlueprintType, Const)
class SUBJECTZERO_API USZCharacterData : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	ESZCharacterID CharacterID = ESZCharacterID::None;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	FText CharacterName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	FText Title;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	int32 Age = 0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	FText Backstory;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Identity")
	FText Motivation;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Role")
	ESZCharacterRole Role = ESZCharacterRole::Tracker;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Role")
	FSZCharacterAbility ActiveAbility;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Role")
	TArray<FSZPassiveAbility> PassiveAbilities;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Visuals")
	FText HeldItemName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Visuals")
	TSoftObjectPtr<class UStaticMesh> HeldItemMesh;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Visuals")
	TSoftObjectPtr<class UTexture2D> PortraitTexture;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gameplay")
	int32 StartingInventorySlots = 4;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gameplay")
	float BaseWalkSpeed = 350.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gameplay")
	float BaseSprintSpeed = 600.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gameplay")
	float SprintStaminaDrainRate = 20.f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gameplay")
	float SprintStaminaRegenRate = 15.f;

	UFUNCTION(BlueprintPure, Category = "Character")
	ESZCharacterID GetCharacterID() const { return CharacterID; }

	UFUNCTION(BlueprintPure, Category = "Character")
	FText GetCharacterName() const { return CharacterName; }

	UFUNCTION(BlueprintPure, Category = "Character")
	ESZCharacterRole GetRole() const { return Role; }
};