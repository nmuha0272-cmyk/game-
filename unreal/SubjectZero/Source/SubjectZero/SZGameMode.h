#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "SZGameMode.generated.h"

class USZChapterManager;

/**
 * The game's rules (host only): which classes to use and where players start.
 * Initializes the chapter system on the server.
 */
UCLASS()
class SUBJECTZERO_API ASZGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ASZGameMode();

	virtual void BeginPlay() override;
	virtual void RestartPlayer(AController* NewPlayer) override;

protected:
	UPROPERTY()
	TObjectPtr<USZChapterManager> ChapterManager;

	/** Which spawn point the next player gets. */
	int32 NextSpawn = 0;
};