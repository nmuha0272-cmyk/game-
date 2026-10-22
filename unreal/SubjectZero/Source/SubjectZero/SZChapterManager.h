#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstanceSubsystem.h"
#include "SZChapterData.h"
#include "SZChapterManager.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnChapterStateChanged, FName, ChapterName);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnChapterStarted, USZChapterData*, ChapterData);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnChapterCompleted, USZChapterData*, ChapterData);

class UWorld;
class USaveGame;

/**
 * Manages chapter progression, saving/loading, and level transitions.
 * Access via GetGameInstance()->GetSubsystem<USZChapterManager>()
 */
UCLASS(BlueprintType, Blueprintable)
class SUBJECTZERO_API USZChapterManager : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void Deinitialize() override;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Management")
	void RegisterChapterData(USZChapterData* ChapterData);

	UFUNCTION(BlueprintCallable, Category = "Chapter|Management")
	void UnregisterChapterData(USZChapterData* ChapterData);

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	USZChapterData* GetChapterData(FName ChapterName) const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	USZChapterData* GetChapterByIndex(int32 ChapterIndex) const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	TArray<USZChapterData*> GetAllChapters() const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	TArray<USZChapterData*> GetAvailableChapters() const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	USZChapterData* GetCurrentChapter() const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Query")
	ESZChapterState GetChapterState(FName ChapterName) const;

	UFUNCTION(BlueprintCallable, Category = "Chapter|Progression")
	bool StartChapter(FName ChapterName);

	UFUNCTION(BlueprintCallable, Category = "Chapter|Progression")
	bool StartChapterByIndex(int32 ChapterIndex);

	UFUNCTION(BlueprintCallable, Category = "Chapter|Progression")
	void CompleteCurrentChapter();

	UFUNCTION(BlueprintCallable, Category = "Chapter|Progression")
	bool LoadNextChapter();

	UFUNCTION(BlueprintCallable, Category = "Chapter|Progression")
	void RestartCurrentChapter();

	UFUNCTION(BlueprintCallable, Category = "Chapter|SaveLoad")
	void SaveProgress();

	UFUNCTION(BlueprintCallable, Category = "Chapter|SaveLoad")
	void LoadProgress();

	UFUNCTION(BlueprintCallable, Category = "Chapter|SaveLoad")
	void ResetAllProgress();

	UPROPERTY(BlueprintAssignable, Category = "Chapter|Events")
	FOnChapterStateChanged OnChapterStateChanged;

	UPROPERTY(BlueprintAssignable, Category = "Chapter|Events")
	FOnChapterStarted OnChapterStarted;

	UPROPERTY(BlueprintAssignable, Category = "Chapter|Events")
	FOnChapterCompleted OnChapterCompleted;

protected:
	UPROPERTY()
	TMap<FName, TObjectPtr<USZChapterData>> ChapterRegistry;

	UPROPERTY()
	TMap<FName, ESZChapterState> ChapterStates;

	UPROPERTY()
	TMap<FName, FSZChapterSaveData> ChapterSaveData;

	UPROPERTY()
	TObjectPtr<USZChapterData> CurrentChapter = nullptr;

	UPROPERTY()
	FString SaveSlotName = TEXT("SubjectZero_Save");

	UPROPERTY()
	int32 SaveUserIndex = 0;

	void UpdateChapterState(FName ChapterName, ESZChapterState NewState);
	void LoadLevelByName(FName LevelName, bool bAbsolute = false);
	void OnLevelLoaded();
	USaveGame* CreateSaveGameObject();
};