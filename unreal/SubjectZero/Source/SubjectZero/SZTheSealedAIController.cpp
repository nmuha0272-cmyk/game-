#include "SZTheSealedAIController.h"
#include "SZVoiceChatManager.h"
#include "Engine/World.h"
#include "TimerManager.h"

ASZTheSealedAIController::ASZTheSealedAIController()
{
	HearingRangeMultiplier = 2.0f; // DOUBLED hearing - key trait
	SightRange = 0.f; // BLIND
	SightAngle = 0.f;
	bIsBlind = true; // COMPLETELY BLIND
	bHearsWalkieTalkieFromFar = true;
	WalkieTalkieHearingMultiplier = 2.0f; // Also enhanced for walkie-talkie
	SearchDuration = 30.f; // Search longer since they can't see
	StunDuration = 1.f; // Harder to stun
}

void ASZTheSealedAIController::BeginPlay()
{
	Super::BeginPlay();
	
	// Override to ensure blind
	bIsBlind = true;
	HearingRangeMultiplier = BaseHearingMultiplier;
	
	UE_LOG(LogTemp, Log, TEXT("The Sealed spawned - BLIND, DOUBLED HEARING. Total silence required. Hearing multiplier: %f"), HearingRangeMultiplier);

	// Start door knocking behavior
	GetWorldTimerManager().SetTimer(KnockTimerHandle, this, &ASZTheSealedAIController::CheckDoorKnock, KnockCheckInterval, true);
}

void ASZTheSealedAIController::OnDoorKnocked_Implementation()
{
	// The Sealed knock on doors - could attract players or other Sealed
}

void ASZTheSealedAIController::OnPlayerMakesNoise_Implementation(float NoiseLevel)
{
	// Extra sensitive to player noise
	if (NoiseLevel > 0.1f)
	{
		// Immediate investigation
	}
}

void ASZTheSealedAIController::CheckDoorKnock()
{
	if (CurrentState == ESZMonsterState::Patrol && FMath::FRand() < KnockInvestigationChance)
	{
		OnDoorKnocked();
	}
}
