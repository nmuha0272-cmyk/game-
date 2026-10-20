#include "SZGoliathAIController.h"
#include "SZVoiceChatManager.h"
#include "Engine/World.h"

ASZGoliathAIController::ASZGoliathAIController()
{
	// Goliath settings
	HearingRangeMultiplier = 1.0f; // Normal hearing
	SightRange = 2000.f;
	SightAngle = 90.f;
	bIsBlind = false;
	bHearsWalkieTalkieFromFar = false;
	WalkieTalkieHearingMultiplier = 1.0f;
	SearchDuration = 15.f;
	StunDuration = 2.f; // Camera flash stuns for 2 seconds
}

void ASZGoliathAIController::BeginPlay()
{
	Super::BeginPlay();
	
	// Goliath has normal voice hearing - this teaches players the voice detection rule
	UE_LOG(LogTemp, Log, TEXT("Goliath spawned - Normal voice hearing active. Players learn: monsters hear voices."));
}

void ASZGoliathAIController::OnLightStunned_Implementation(float Duration)
{
	OnStunned(Duration);
}

void ASZGoliathAIController::OnEnterTightSpace_Implementation()
{
	// Goliath crawls on all fours in tight spaces - could change movement mode
}

void ASZGoliathAIController::OnExitTightSpace_Implementation()
{
	// Return to normal movement
}