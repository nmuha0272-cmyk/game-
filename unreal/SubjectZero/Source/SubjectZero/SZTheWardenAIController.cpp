#include "SZTheWardenAIController.h"
#include "SZVoiceChatManager.h"
#include "Engine/World.h"
#include "TimerManager.h"

ASZTheWardenAIController::ASZTheWardenAIController()
{
	HearingRangeMultiplier = 1.5f; // Good hearing
	SightRange = 4000.f; // Excellent sight with tactical gear
	SightAngle = 100.f;
	bIsBlind = false;
	bHearsWalkieTalkieFromFar = true; // Headset picks up walkie-talkie
	WalkieTalkieHearingMultiplier = 2.5f; // Modern headset
	SearchDuration = 30.f; // Thorough search
	StunDuration = 1.f; // Very hard to stun (tactical training)
}

void ASZTheWardenAIController::BeginPlay()
{
	Super::BeginPlay();
	
	UE_LOG(LogTemp, Log, TEXT("The Warden spawned - Tactical AI active. Opens doors, uses flashlight, sets traps, remembers player locations."));
	
	CurrentTactic = ESZWardenTactic::Investigate;
	TacticTimer = 0.f;
}

void ASZTheWardenAIController::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	// Update memory timers
	for (auto It = LocationMemoryTimers.CreateIterator(); It; ++It)
	{
		It.Value() += DeltaTime;
		if (It.Value() > MemoryRetentionTime)
		{
			RememberedPlayerLocations.Remove(It.Key());
			It.RemoveCurrent();
		}
	}

	// Tactical decision making
	TacticTimer += DeltaTime;
	if (TacticTimer > TacticChangeInterval)
	{
		EvaluateTactics();
		TacticTimer = 0.f;
	}
}

void ASZTheWardenAIController::SetTactic(ESZWardenTactic NewTactic)
{
	if (CurrentTactic != NewTactic)
	{
		ESZWardenTactic OldTactic = CurrentTactic;
		CurrentTactic = NewTactic;
		OnTacticChanged(OldTactic, NewTactic);
	}
}

void ASZTheWardenAIController::RememberPlayerLocation(int32 PlayerId, FVector Location)
{
	RememberedPlayerLocations.Add(PlayerId, Location);
	LocationMemoryTimers.Add(PlayerId, 0.f);
}

void ASZTheWardenAIController::OnWalkieTalkieIntercepted(int32 SpeakerPlayerId, FVector SpeakerLocation)
{
	// Warden's headset picks up walkie-talkie - remembers location
	RememberPlayerLocation(SpeakerPlayerId, SpeakerLocation);
	
	// Immediately investigate walkie-talkie source
	SetTactic(ESZWardenTactic::Investigate);
	LastKnownPlayerLocation = nullptr; // Will use remembered location
}

void ASZTheWardenAIController::UseFlashlight(bool bEnable)
{
	bUsesFlashlight = bEnable;
	// Would toggle flashlight component on pawn
}

void ASZTheWardenAIController::SetTrap(FVector Location, FName TrapType)
{
	// Would spawn trap actor at location
	UE_LOG(LogTemp, Log, TEXT("Warden setting trap %s at %s"), *TrapType.ToString(), *Location.ToString());
}

void ASZTheWardenAIController::EvaluateTactics()
{
	// Simple tactical AI - could be expanded significantly
	if (LastKnownPlayerLocation.IsValid())
	{
		// Has recent contact - choose aggressive tactic
		float Rand = FMath::FRand();
		if (Rand < 0.4f)
			SetTactic(ESZWardenTactic::Flank);
		else if (Rand < 0.7f)
			SetTactic(ESZWardenTactic::Suppress);
		else
			SetTactic(ESZWardenTactic::Ambush);
	}
	else if (RememberedPlayerLocations.Num() > 0)
	{
		// Has memory of players - investigate
		SetTactic(ESZWardenTactic::Investigate);
	}
	else
	{
		// No info - patrol or call backup
		SetTactic(FMath::FRand() < 0.5f ? ESZWardenTactic::Investigate : ESZWardenTactic::CallBackup);
	}
}

void ASZTheWardenAIController::OnTacticChanged_Implementation(ESZWardenTactic OldTactic, ESZWardenTactic NewTactic)
{
	// Blueprint override - change behavior, animations, etc.
}

void ASZTheWardenAIController::OnTrapTriggered_Implementation(FName TrapType, int32 VictimPlayerId)
{
	// Blueprint override
}