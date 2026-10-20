#include "SZGameMode.h"

#include "SZCharacter.h"
#include "SZHUD.h"
#include "SZPlayerController.h"
#include "SZWorldBuilder.h"
#include "SZChapterManager.h"
#include "SZDefaultChapters.h"
#include "Engine/GameInstance.h"

ASZGameMode::ASZGameMode()
{
	DefaultPawnClass = ASZCharacter::StaticClass();
	PlayerControllerClass = ASZPlayerController::StaticClass();
	HUDClass = ASZHUD::StaticClass();
}

void ASZGameMode::BeginPlay()
{
	Super::BeginPlay();

	if (UGameInstance* GameInstance = GetGameInstance())
	{
		ChapterManager = GameInstance->GetSubsystem<USZChapterManager>();
		if (ChapterManager)
		{
			USZDefaultChapters::RegisterDefaultChapters(ChapterManager);
		}
	}
}

void ASZGameMode::RestartPlayer(AController* NewPlayer)
{
	if (NewPlayer == nullptr || NewPlayer->IsPendingKillPending())
	{
		return;
	}
	const TArray<FTransform> Spawns = USZWorldBuilder::GetSpawnTransforms();
	if (Spawns.Num() == 0)
	{
		Super::RestartPlayer(NewPlayer);
		return;
	}
	RestartPlayerAtTransform(NewPlayer, Spawns[NextSpawn++ % Spawns.Num()]);
}