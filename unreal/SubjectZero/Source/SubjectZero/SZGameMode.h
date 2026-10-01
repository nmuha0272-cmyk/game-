#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "SZGameMode.generated.h"

/** The game's rules (host only): which classes to use and where players start. */
UCLASS()
class SUBJECTZERO_API ASZGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	ASZGameMode();

	virtual void RestartPlayer(AController* NewPlayer) override;

private:
	int32 NextSpawn = 0;
};
