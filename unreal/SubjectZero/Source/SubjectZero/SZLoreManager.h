#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstanceSubsystem.h"
#include "SZChapterData.h"
#include "SZCharacterData.h"
#include "SZLoreManager.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnLoreDiscovered, const FSZChapterLoreItem&, LoreItem);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPersonalItemUnlocked, ESZCharacterID, CharacterID);

/**
 * Manages lore discovery, journal entries, and personal item system.
 * Access via GetGameInstance()->GetSubsystem<USZLoreManager>()
 */
UCLASS(BlueprintType, Blueprintable)
class SUBJECTZERO_API USZLoreManager : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void Deinitialize() override;

	UFUNCTION(BlueprintCallable, Category = "Lore|Discovery")
	void DiscoverLoreItem(FName ChapterName, FName LoreID, ESZCharacterID DiscovererCharacterID);

	UFUNCTION(BlueprintCallable, Category = "Lore|Discovery")
	void UnlockPersonalItem(FName ChapterName, FName LoreID, ESZCharacterID OwnerCharacterID);

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	bool IsLoreDiscovered(FName ChapterName, FName LoreID) const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	bool IsPersonalItemUnlocked(FName ChapterName, FName LoreID) const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	TArray<FSZChapterLoreItem> GetDiscoveredLoreForChapter(FName ChapterName) const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	TArray<FSZChapterLoreItem> GetDiscoveredLoreForCharacter(ESZCharacterID CharacterID) const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	TArray<FSZChapterLoreItem> GetAllDiscoveredLore() const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	int32 GetTotalLoreCount() const;

	UFUNCTION(BlueprintCallable, Category = "Lore|Query")
	int32 GetDiscoveredLoreCount() const;

	UFUNCTION(BlueprintCallable, Category = "Lore|SaveLoad")
	void SaveProgress();

	UFUNCTION(BlueprintCallable, Category = "Lore|SaveLoad")
	void LoadProgress();

	UFUNCTION(BlueprintCallable, Category = "Lore|SaveLoad")
	void ResetAllProgress();

	UPROPERTY(BlueprintAssignable, Category = "Lore|Events")
	FOnLoreDiscovered OnLoreDiscovered;

	UPROPERTY(BlueprintAssignable, Category = "Lore|Events")
	FOnPersonalItemUnlocked OnPersonalItemUnlocked;

protected:
	UPROPERTY()
	TMap<FName, TSet<FName>> DiscoveredLoreByChapter; // ChapterName -> LoreIDs

	UPROPERTY()
	TMap<FName, TSet<FName>> UnlockedPersonalItemsByChapter; // ChapterName -> LoreIDs

	UPROPERTY()
	FName SaveSlotName = TEXT("SubjectZero_LoreSave");

	UPROPERTY()
	int32 SaveUserIndex = 0;

	void SaveLoreData();
	void LoadLoreData();
};