#include "SZLoreManager.h"
#include "SZChapterManager.h"
#include "SZChapterData.h"
#include "Engine/GameInstance.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/SaveGame.h"

void USZLoreManager::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	LoadProgress();
}

void USZLoreManager::Deinitialize()
{
	SaveProgress();
	Super::Deinitialize();
}

void USZLoreManager::DiscoverLoreItem(FName ChapterName, FName LoreID, ESZCharacterID DiscovererCharacterID)
{
	if (ChapterName.IsNone() || LoreID.IsNone())
	{
		return;
	}

	TSet<FName>& ChapterLore = DiscoveredLoreByChapter.FindOrAdd(ChapterName);
	if (ChapterLore.Add(LoreID))
	{
		// Get the lore item data to broadcast
		if (UGameInstance* GameInstance = GetGameInstance())
		{
			if (USZChapterManager* ChapterManager = GameInstance->GetSubsystem<USZChapterManager>())
			{
				if (USZChapterData* ChapterData = ChapterManager->GetChapterData(ChapterName))
				{
					for (const FSZChapterLoreItem& LoreItem : ChapterData->LoreItems)
					{
						if (LoreItem.LoreID == LoreID)
						{
							OnLoreDiscovered.Broadcast(LoreItem);
							
							// If this is a personal item and the discoverer is the owner, unlock it
							if (LoreItem.OwnerCharacter != ESZCharacterID::None && LoreItem.OwnerCharacter == DiscovererCharacterID)
							{
								UnlockPersonalItem(ChapterName, LoreID, DiscovererCharacterID);
							}
							break;
						}
					}
				}
			}
		}
		SaveProgress();
	}
}

void USZLoreManager::UnlockPersonalItem(FName ChapterName, FName LoreID, ESZCharacterID OwnerCharacterID)
{
	if (ChapterName.IsNone() || LoreID.IsNone() || OwnerCharacterID == ESZCharacterID::None)
	{
		return;
	}

	TSet<FName>& ChapterPersonalItems = UnlockedPersonalItemsByChapter.FindOrAdd(ChapterName);
	if (ChapterPersonalItems.Add(LoreID))
	{
		OnPersonalItemUnlocked.Broadcast(OwnerCharacterID);
		SaveProgress();
	}
}

bool USZLoreManager::IsLoreDiscovered(FName ChapterName, FName LoreID) const
{
	const TSet<FName>* ChapterLore = DiscoveredLoreByChapter.Find(ChapterName);
	if (ChapterLore)
	{
		return ChapterLore->Contains(LoreID);
	}
	return false;
}

bool USZLoreManager::IsPersonalItemUnlocked(FName ChapterName, FName LoreID) const
{
	const TSet<FName>* ChapterPersonalItems = UnlockedPersonalItemsByChapter.Find(ChapterName);
	if (ChapterPersonalItems)
	{
		return ChapterPersonalItems->Contains(LoreID);
	}
	return false;
}

TArray<FSZChapterLoreItem> USZLoreManager::GetDiscoveredLoreForChapter(FName ChapterName) const
{
	TArray<FSZChapterLoreItem> Result;
	
	if (UGameInstance* GameInstance = GetGameInstance())
	{
		if (USZChapterManager* ChapterManager = GameInstance->GetSubsystem<USZChapterManager>())
		{
			if (USZChapterData* ChapterData = ChapterManager->GetChapterData(ChapterName))
			{
				const TSet<FName>* DiscoveredIDs = DiscoveredLoreByChapter.Find(ChapterName);
				if (DiscoveredIDs)
				{
					for (const FSZChapterLoreItem& LoreItem : ChapterData->LoreItems)
					{
						if (DiscoveredIDs->Contains(LoreItem.LoreID))
						{
							Result.Add(LoreItem);
						}
					}
				}
			}
		}
	}
	
	return Result;
}

TArray<FSZChapterLoreItem> USZLoreManager::GetDiscoveredLoreForCharacter(ESZCharacterID CharacterID) const
{
	TArray<FSZChapterLoreItem> Result;
	
	if (UGameInstance* GameInstance = GetGameInstance())
	{
		if (USZChapterManager* ChapterManager = GameInstance->GetSubsystem<USZChapterManager>())
		{
			TArray<USZChapterData*> AllChapters = ChapterManager->GetAllChapters();
			for (USZChapterData* ChapterData : AllChapters)
			{
				if (!ChapterData) continue;
				
				const TSet<FName>* DiscoveredIDs = DiscoveredLoreByChapter.Find(ChapterData->GetLevelName());
				if (DiscoveredIDs)
				{
					for (const FSZChapterLoreItem& LoreItem : ChapterData->LoreItems)
					{
						if (DiscoveredIDs->Contains(LoreItem.LoreID) && 
							(LoreItem.OwnerCharacter == ESZCharacterID::None || LoreItem.OwnerCharacter == CharacterID))
						{
							Result.Add(LoreItem);
						}
					}
				}
			}
		}
	}
	
	return Result;
}

TArray<FSZChapterLoreItem> USZLoreManager::GetAllDiscoveredLore() const
{
	TArray<FSZChapterLoreItem> Result;
	
	if (UGameInstance* GameInstance = GetGameInstance())
	{
		if (USZChapterManager* ChapterManager = GameInstance->GetSubsystem<USZChapterManager>())
		{
			TArray<USZChapterData*> AllChapters = ChapterManager->GetAllChapters();
			for (USZChapterData* ChapterData : AllChapters)
			{
				if (!ChapterData) continue;
				
				const TSet<FName>* DiscoveredIDs = DiscoveredLoreByChapter.Find(ChapterData->GetLevelName());
				if (DiscoveredIDs)
				{
					for (const FSZChapterLoreItem& LoreItem : ChapterData->LoreItems)
					{
						if (DiscoveredIDs->Contains(LoreItem.LoreID))
						{
							Result.Add(LoreItem);
						}
					}
				}
			}
		}
	}
	
	return Result;
}

int32 USZLoreManager::GetTotalLoreCount() const
{
	int32 Count = 0;
	
	if (UGameInstance* GameInstance = GetGameInstance())
	{
		if (USZChapterManager* ChapterManager = GameInstance->GetSubsystem<USZChapterManager>())
		{
			TArray<USZChapterData*> AllChapters = ChapterManager->GetAllChapters();
			for (USZChapterData* ChapterData : AllChapters)
			{
				if (ChapterData)
				{
					Count += ChapterData->LoreItems.Num();
				}
			}
		}
	}
	
	return Count;
}

int32 USZLoreManager::GetDiscoveredLoreCount() const
{
	int32 Count = 0;
	for (const auto& Pair : DiscoveredLoreByChapter)
	{
		Count += Pair.Value.Num();
	}
	return Count;
}

void USZLoreManager::SaveProgress()
{
	SaveLoreData();
}

void USZLoreManager::LoadProgress()
{
	LoadLoreData();
}

void USZLoreManager::ResetAllProgress()
{
	DiscoveredLoreByChapter.Empty();
	UnlockedPersonalItemsByChapter.Empty();
	SaveProgress();
}

void USZLoreManager::SaveLoreData()
{
	USaveGame* SaveGame = UGameplayStatics::CreateSaveGameObject(USaveGame::StaticClass());
	if (SaveGame)
	{
		UGameplayStatics::SaveGameToSlot(SaveGame, SaveSlotName, SaveUserIndex);
	}
}

void USZLoreManager::LoadLoreData()
{
	if (UGameplayStatics::DoesSaveGameExist(SaveSlotName, SaveUserIndex))
	{
		USaveGame* SaveGame = UGameplayStatics::LoadGameFromSlot(SaveSlotName, SaveUserIndex);
		if (SaveGame)
		{
			// TODO: Implement actual save/load serialization
		}
	}
}