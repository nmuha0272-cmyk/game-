#include "SZChapterManager.h"
#include "SZChapterData.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "GameFramework/SaveGame.h"
#include "HAL/PlatformFileManager.h"

#define SAVE_SLOT_NAME TEXT("SubjectZero_ChapterProgress")

void USZChapterManager::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	LoadProgress();
}

void USZChapterManager::Deinitialize()
{
	SaveProgress();
	Super::Deinitialize();
}

void USZChapterManager::RegisterChapterData(USZChapterData* ChapterData)
{
	if (ChapterData)
	{
		ChapterRegistry.Add(ChapterData->GetLevelName(), ChapterData);
		
		if (!ChapterStates.Contains(ChapterData->GetLevelName()))
		{
			const ESZChapterState InitialState = (ChapterData->GetChapterIndex() == 0) 
				? ESZChapterState::Available 
				: ESZChapterState::Locked;
			ChapterStates.Add(ChapterData->GetLevelName(), InitialState);
		}
	}
}

void USZChapterManager::UnregisterChapterData(USZChapterData* ChapterData)
{
	if (ChapterData)
	{
		ChapterRegistry.Remove(ChapterData->GetLevelName());
	}
}

USZChapterData* USZChapterManager::GetChapterData(FName ChapterName) const
{
	return ChapterRegistry.FindRef(ChapterName);
}

USZChapterData* USZChapterManager::GetChapterByIndex(int32 ChapterIndex) const
{
	for (const auto& Pair : ChapterRegistry)
	{
		if (Pair.Value && Pair.Value->GetChapterIndex() == ChapterIndex)
		{
			return Pair.Value;
		}
	}
	return nullptr;
}

TArray<USZChapterData*> USZChapterManager::GetAllChapters() const
{
	TArray<USZChapterData*> Result;
	for (const auto& Pair : ChapterRegistry)
	{
		Result.Add(Pair.Value);
	}
	Result.Sort([](const USZChapterData& A, const USZChapterData& B) {
		return A.GetChapterIndex() < B.GetChapterIndex();
	});
	return Result;
}

TArray<USZChapterData*> USZChapterManager::GetAvailableChapters() const
{
	TArray<USZChapterData*> Result;
	for (const auto& Pair : ChapterRegistry)
	{
		if (Pair.Value && GetChapterState(Pair.Key) == ESZChapterState::Available)
		{
			Result.Add(Pair.Value);
		}
	}
	Result.Sort([](const USZChapterData& A, const USZChapterData& B) {
		return A.GetChapterIndex() < B.GetChapterIndex();
	});
	return Result;
}

USZChapterData* USZChapterManager::GetCurrentChapter() const
{
	return CurrentChapter;
}

ESZChapterState USZChapterManager::GetChapterState(FName ChapterName) const
{
	return ChapterStates.FindRef(ChapterName);
}

bool USZChapterManager::StartChapter(FName ChapterName)
{
	USZChapterData* ChapterData = GetChapterData(ChapterName);
	if (!ChapterData)
	{
		UE_LOG(LogTemp, Warning, TEXT("ChapterManager: Chapter '%s' not found"), *ChapterName.ToString());
		return false;
	}

	const ESZChapterState State = GetChapterState(ChapterName);
	if (State == ESZChapterState::Locked)
	{
		UE_LOG(LogTemp, Warning, TEXT("ChapterManager: Chapter '%s' is locked"), *ChapterName.ToString());
		return false;
	}

	CurrentChapter = ChapterData;
	UpdateChapterState(ChapterName, ESZChapterState::Current);
	OnChapterStarted.Broadcast(ChapterData);

	LoadLevelByName(ChapterData->GetLevelName());
	return true;
}

bool USZChapterManager::StartChapterByIndex(int32 ChapterIndex)
{
	USZChapterData* ChapterData = GetChapterByIndex(ChapterIndex);
	if (ChapterData)
	{
		return StartChapter(ChapterData->GetLevelName());
	}
	return false;
}

void USZChapterManager::CompleteCurrentChapter()
{
	if (!CurrentChapter)
	{
		return;
	}

	const FName ChapterName = CurrentChapter->GetLevelName();
	UpdateChapterState(ChapterName, ESZChapterState::Completed);

	FSZChapterSaveData& SaveData = ChapterSaveData.FindOrAdd(ChapterName);
	SaveData.State = ESZChapterState::Completed;
	
	OnChapterCompleted.Broadcast(CurrentChapter);

	USZChapterData* NextChapter = GetChapterByIndex(CurrentChapter->GetChapterIndex() + 1);
	if (NextChapter && NextChapter->IsUnlocked(ChapterStates))
	{
		UpdateChapterState(NextChapter->GetLevelName(), ESZChapterState::Available);
	}

	CurrentChapter = nullptr;
	SaveProgress();
}

bool USZChapterManager::LoadNextChapter()
{
	if (!CurrentChapter)
	{
		return false;
	}

	const int32 NextIndex = CurrentChapter->GetChapterIndex() + 1;
	USZChapterData* NextChapter = GetChapterByIndex(NextIndex);
	
	if (NextChapter && GetChapterState(NextChapter->GetLevelName()) != ESZChapterState::Locked)
	{
		return StartChapter(NextChapter->GetLevelName());
	}
	
	return false;
}

void USZChapterManager::RestartCurrentChapter()
{
	if (CurrentChapter)
	{
		LoadLevelByName(CurrentChapter->GetLevelName(), true);
	}
}

void USZChapterManager::UpdateChapterState(FName ChapterName, ESZChapterState NewState)
{
	ChapterStates.Add(ChapterName, NewState);
	
	FSZChapterSaveData& SaveData = ChapterSaveData.FindOrAdd(ChapterName);
	SaveData.State = NewState;
	
	OnChapterStateChanged.Broadcast(ChapterName);
}

void USZChapterManager::LoadLevelByName(FName LevelName, bool bAbsolute)
{
	UWorld* World = GetWorld();
	if (World)
	{
		UGameplayStatics::OpenLevel(World, LevelName, bAbsolute);
	}
}

void USZChapterManager::OnLevelLoaded()
{
}

void USZChapterManager::SaveProgress()
{
	USaveGame* SaveGame = CreateSaveGameObject();
	if (SaveGame)
	{
		UGameplayStatics::SaveGameToSlot(SaveGame, SaveSlotName, SaveUserIndex);
	}
}

void USZChapterManager::LoadProgress()
{
	if (UGameplayStatics::DoesSaveGameExist(SaveSlotName, SaveUserIndex))
	{
		USaveGame* SaveGame = UGameplayStatics::LoadGameFromSlot(SaveSlotName, SaveUserIndex);
		if (SaveGame)
		{
		}
	}
	else
	{
		for (const auto& Pair : ChapterRegistry)
		{
			if (Pair.Value && Pair.Value->GetChapterIndex() == 0)
			{
				UpdateChapterState(Pair.Key, ESZChapterState::Available);
			}
		}
	}
}

void USZChapterManager::ResetAllProgress()
{
	ChapterStates.Empty();
	ChapterSaveData.Empty();
	CurrentChapter = nullptr;
	
	for (const auto& Pair : ChapterRegistry)
	{
		if (Pair.Value)
		{
			const ESZChapterState InitialState = (Pair.Value->GetChapterIndex() == 0) 
				? ESZChapterState::Available 
				: ESZChapterState::Locked;
			ChapterStates.Add(Pair.Key, InitialState);
		}
	}
	SaveProgress();
}

USaveGame* USZChapterManager::CreateSaveGameObject()
{
	USaveGame* SaveGame = UGameplayStatics::CreateSaveGameObject(USaveGame::StaticClass());
	if (SaveGame)
	{
	}
	return SaveGame;
}