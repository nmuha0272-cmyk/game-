#include "SZConduitAIController.h"
#include "SZVoiceChatManager.h"
#include "Engine/World.h"

ASZConduitAIController::ASZConduitAIController()
{
	HearingRangeMultiplier = 1.0f;
	SightRange = 1500.f; // Relies more on hearing
	SightAngle = 60.f;
	bIsBlind = false;
	bHearsWalkieTalkieFromFar = true; // Key trait: hears walkie-talkie from far
	WalkieTalkieHearingMultiplier = 3.0f; // 3x range for walkie-talkie
	SearchDuration = 20.f;
	StunDuration = 2.f;
}

void ASZConduitAIController::BeginPlay()
{
	Super::BeginPlay();
	UE_LOG(LogTemp, Log, TEXT("Conduit spawned - Enhanced walkie-talkie hearing active. Range multiplier: %f"), WalkieTalkieHearingMultiplier);
}

void ASZConduitAIController::OnPowerRestored()
{
	bIsAwakened = true;
	HearingRangeMultiplier = 1.5f; // More alert when powered
	SetMonsterState(ESZMonsterState::Investigate);
}

void ASZConduitAIController::OnPowerLost()
{
	bIsAwakened = false;
	HearingRangeMultiplier = 0.5f; // Less active without power
}

void ASZConduitAIController::OnElectricalStunned_Implementation(float Duration)
{
	OnStunned(Duration);
}