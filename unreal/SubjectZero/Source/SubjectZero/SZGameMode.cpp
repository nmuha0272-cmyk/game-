#include "SZGameMode.h"

#include "SZCharacter.h"
#include "SZHUD.h"
#include "SZPlayerController.h"
#include "SZWorldBuilder.h"

ASZGameMode::ASZGameMode()
{
	DefaultPawnClass = ASZCharacter::StaticClass();
	PlayerControllerClass = ASZPlayerController::StaticClass();
	HUDClass = ASZHUD::StaticClass();
}

void ASZGameMode::RestartPlayer(AController* NewPlayer)
{
	if (NewPlayer == nullptr || NewPlayer->IsPendingKillPending())
	{
		return;
	}
	// Start players on the road, at the spawn points from the level file.
	const TArray<FTransform> Spawns = USZWorldBuilder::GetSpawnTransforms();
	if (Spawns.Num() == 0)
	{
		Super::RestartPlayer(NewPlayer);
		return;
	}
	RestartPlayerAtTransform(NewPlayer, Spawns[NextSpawn++ % Spawns.Num()]);
}
