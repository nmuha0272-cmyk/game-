#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "GameplayTagContainer.h"
#include "SZCharacterData.h"
#include "SZChapterData.generated.h"

class UWorld;
class USZCharacterData;

UENUM(BlueprintType)
enum class ESZChapterState : uint8
{
	Locked,
	Available,
	Completed,
	Current
};

UENUM(BlueprintType)
enum class ESZMonsterType : uint8
{
	None,
	Goliath,
	Conduit,
	TheSealed,
	Echo,
	TheWarden
};

USTRUCT(BlueprintType)
struct FSZChapterSaveData
{
	GENERATED_BODY()

	UPROPERTY()
	ESZChapterState State = ESZChapterState::Locked;

	UPROPERTY()
	float PlayTime = 0.f;

	UPROPERTY()
	int32 DeathCount = 0;

	UPROPERTY()
	TArray<FName> CompletedObjectives;

	UPROPERTY()
	TArray<FName> CollectedLoreItems;

	UPROPERTY()
	TArray<FName> FoundPersonalItems;
};

USTRUCT(BlueprintType)
struct FSZChapterLoreItem
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	FName LoreID;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	FText Title;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	FText Content;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	ESZCharacterID OwnerCharacter = ESZCharacterID::None; // None = accessible to all

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	bool bIsRequired = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lore")
	FName RoomLocation;
};

UCLASS(BlueprintType, Const)
class SUBJECTZERO_API USZChapterData : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	FText DisplayName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	FName LevelName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	int32 ChapterIndex = 0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	TArray<FName> RequiredCompletedChapters;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	FGameplayTagContainer UnlockTags;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	TSoftObjectPtr<UWorld> LevelAsset;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	TSoftClassPtr<UUserWidget> ChapterIntroWidget;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter")
	float EstimatedPlayTimeMinutes = 30.f;

	// Enhanced chapter info from GAME_PLAN
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	TObjectPtr<USZCharacterData> SpotlightCharacter;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	ESZMonsterType MainMonster = ESZMonsterType::None;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	FText MonsterDescription;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	FText ChapterGoal;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	FText ChapterEnding;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Story")
	FText SpotlightCharacterArc;

	// Lore items for this chapter
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Lore")
	TArray<FSZChapterLoreItem> LoreItems;

	// Pouch upgrade (Chapters 2-5)
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Rewards")
	bool bGrantsPouchUpgrade = false;

	// New weapons/tools unlocked
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Chapter|Rewards")
	TArray<FName> UnlockedItems;

	UFUNCTION(BlueprintPure, Category = "Chapter")
	FName GetLevelName() const { return LevelName; }

	UFUNCTION(BlueprintPure, Category = "Chapter")
	int32 GetChapterIndex() const { return ChapterIndex; }

	UFUNCTION(BlueprintPure, Category = "Chapter")
	bool IsUnlocked(const TMap<FName, ESZChapterState>& ChapterStates) const;

	UFUNCTION(BlueprintPure, Category = "Chapter")
	TArray<FSZChapterLoreItem> GetLoreForCharacter(ESZCharacterID CharacterID) const;
};