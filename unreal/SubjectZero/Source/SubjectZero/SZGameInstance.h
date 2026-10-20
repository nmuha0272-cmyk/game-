#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstance.h"
#include "SZGameInstance.generated.h"

class USZChapterManager;

/**
 * Main game instance that provides access to global subsystems.
 */
UCLASS()
class SUBJECTZERO_API USZGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	virtual void Init() override;

	UFUNCTION(BlueprintCallable, Category = "Game")
	USZChapterManager* GetChapterManager() const;

private:
	UPROPERTY()
	TObjectPtr<USZChapterManager> ChapterManager;
};