#include "SZMonsterAIController.h"
#include "SZVoiceChatManager.h"
#include "NavigationSystem.h"
#include "GameFramework/Character.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"

ASZMonsterAIController::ASZMonsterAIController()
{
	PrimaryActorTick.bCanEverTick = true;
}

void ASZMonsterAIController::BeginPlay()
{
	Super::BeginPlay();

	if (UGameInstance* GameInstance = GetWorld()->GetGameInstance())
	{
		VoiceChatManager = GameInstance->GetSubsystem<USZVoiceChatManager>();
		if (VoiceChatManager)
		{
			VoiceChatManager->OnVoiceNoiseEvent.AddDynamic(this, &ASZMonsterAIController::OnVoiceNoiseEventReceived);
		}
	}

	if (PatrolPoints.Num() == 0 && GetPawn())
	{
		PatrolPoints.Add(GetPawn()->GetActorLocation());
	}

	SetMonsterState(ESZMonsterState::Patrol);
}

void ASZMonsterAIController::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	UpdateState(DeltaTime);
}

void ASZMonsterAIController::SetMonsterState(ESZMonsterState NewState)
{
	if (CurrentState == NewState)
	{
		return;
	}

	ESZMonsterState OldState = CurrentState;
	CurrentState = NewState;
	StateTimer = 0.f;

	OnStateChanged(OldState, NewState);

	UE_LOG(LogTemp, Log, TEXT("Monster %s state changed: %d -> %d"), *GetName(), (int32)OldState, (int32)NewState);
}

ESZMonsterState ASZMonsterAIController::GetMonsterState() const
{
	return CurrentState;
}

void ASZMonsterAIController::OnNoiseHeard(const FSZNoiseEvent& NoiseEvent)
{
	float Interest = CalculateNoiseInterest(NoiseEvent);
	if (Interest <= 0.f)
	{
		return;
	}

	switch (CurrentState)
	{
		case ESZMonsterState::Patrol:
			SetMonsterState(ESZMonsterState::Investigate);
			LastKnownPlayerLocation = nullptr;
			break;
		case ESZMonsterState::Investigate:
		case ESZMonsterState::Search:
			break;
		case ESZMonsterState::Chase:
			break;
		default:
			break;
	}

	OnNoiseEventReceived(NoiseEvent);
}

void ASZMonsterAIController::OnPlayerSeen(APawn* PlayerPawn)
{
	if (!PlayerPawn || bIsBlind)
	{
		return;
	}

	LastKnownPlayerLocation = PlayerPawn;
	SetMonsterState(ESZMonsterState::Chase);
	OnPlayerSpotted(PlayerPawn);
}

void ASZMonsterAIController::OnPlayerLost(APawn* PlayerPawn)
{
	if (LastKnownPlayerLocation == PlayerPawn)
	{
		SetMonsterState(ESZMonsterState::Search);
	}
}

void ASZMonsterAIController::OnStunned(float Duration)
{
	SetMonsterState(ESZMonsterState::Stunned);
	StateTimer = -Duration; // Negative timer for stun
}

void ASZMonsterAIController::OnDoorHeld(float HoldTime)
{
	// Monster is being held at a door - could trigger frustration behavior
}

void ASZMonsterAIController::OnStateChanged_Implementation(ESZMonsterState OldState, ESZMonsterState NewState)
{
	// Blueprint override point
}

void ASZMonsterAIController::OnNoiseEventReceived_Implementation(const FSZNoiseEvent& NoiseEvent)
{
	// Blueprint override point
}

void ASZMonsterAIController::OnPlayerSpotted_Implementation(APawn* PlayerPawn)
{
	// Blueprint override point
}

void ASZMonsterAIController::OnVoiceNoiseEventReceived(FVector Location, float Radius, int32 PlayerId)
{
	FSZNoiseEvent NoiseEvent;
	NoiseEvent.Location = Location;
	NoiseEvent.Radius = Radius * HearingRangeMultiplier;
	NoiseEvent.InstigatorPlayerId = PlayerId;
	NoiseEvent.TimeStamp = GetWorld()->GetTimeSeconds();
	NoiseEvent.NoiseType = FGameplayTag::RequestGameplayTag(FName("Noise.Voice"));

	OnNoiseHeard(NoiseEvent);
}

void ASZMonsterAIController::UpdateState(float DeltaTime)
{
	StateTimer += DeltaTime;

	switch (CurrentState)
	{
		case ESZMonsterState::Patrol:
			HandlePatrolState(DeltaTime);
			break;
		case ESZMonsterState::Investigate:
			HandleInvestigateState(DeltaTime);
			break;
		case ESZMonsterState::Chase:
			HandleChaseState(DeltaTime);
			break;
		case ESZMonsterState::Search:
			HandleSearchState(DeltaTime);
			break;
		case ESZMonsterState::Stunned:
			HandleStunnedState(DeltaTime);
			break;
		case ESZMonsterState::Dead:
			break;
	}
}

void ASZMonsterAIController::HandlePatrolState(float DeltaTime)
{
	APawn* Pawn = GetPawn();
	if (!Pawn || PatrolPoints.Num() == 0)
	{
		return;
	}

	if (UNavigationSystemV1* NavSys = FNavigationSystem::GetCurrent<UNavigationSystemV1>(GetWorld()))
	{
		if (!NavSys->IsNavigationBeingBuiltOrStreamed())
		{
			FVector TargetPoint = GetNextPatrolPoint();
			float Distance = FVector::Dist(Pawn->GetActorLocation(), TargetPoint);
			
			if (Distance < 100.f)
			{
				// Reached patrol point, wait
				if (StateTimer > FMath::FRandRange(PatrolWaitTimeMin, PatrolWaitTimeMax))
				{
					CurrentPatrolIndex = (CurrentPatrolIndex + 1) % PatrolPoints.Num();
					StateTimer = 0.f;
				}
			}
			else
			{
				MoveToLocation(TargetPoint);
				StateTimer = 0.f;
			}
		}
	}
}

void ASZMonsterAIController::HandleInvestigateState(float DeltaTime)
{
	APawn* Pawn = GetPawn();
	if (!Pawn || !LastKnownPlayerLocation.IsValid())
	{
		return;
	}

	if (UNavigationSystemV1* NavSys = FNavigationSystem::GetCurrent<UNavigationSystemV1>(GetWorld()))
	{
		MoveToActor(LastKnownPlayerLocation.Get());
		
		float Distance = FVector::Dist(Pawn->GetActorLocation(), LastKnownPlayerLocation->GetActorLocation());
		if (Distance < 200.f)
		{
			// Reached noise location, search
			SetMonsterState(ESZMonsterState::Search);
		}
	}
}

void ASZMonsterAIController::HandleChaseState(float DeltaTime)
{
	APawn* Pawn = GetPawn();
	if (!Pawn || !LastKnownPlayerLocation.IsValid())
	{
		SetMonsterState(ESZMonsterState::Search);
		return;
	}

	if (UNavigationSystemV1* NavSys = FNavigationSystem::GetCurrent<UNavigationSystemV1>(GetWorld()))
	{
		MoveToActor(LastKnownPlayerLocation.Get());
		
		// Check if we can still see the player
		if (!CanSeePlayer(LastKnownPlayerLocation.Get()))
		{
			OnPlayerLost(LastKnownPlayerLocation.Get());
		}
	}
}

void ASZMonsterAIController::HandleSearchState(float DeltaTime)
{
	if (StateTimer > SearchDuration)
	{
		SetMonsterState(ESZMonsterState::Patrol);
		LastKnownPlayerLocation = nullptr;
	}
}

void ASZMonsterAIController::HandleStunnedState(float DeltaTime)
{
	if (StateTimer > 0.f) // Stun timer was negative, now positive means stun ended
	{
		SetMonsterState(ESZMonsterState::Search);
	}
}

bool ASZMonsterAIController::CanSeePlayer(APawn* PlayerPawn) const
{
	if (!PlayerPawn || bIsBlind)
	{
		return false;
	}

	APawn* Pawn = GetPawn();
	if (!Pawn)
	{
		return false;
	}

	FVector ToPlayer = PlayerPawn->GetActorLocation() - Pawn->GetActorLocation();
	float Distance = ToPlayer.Size();
	
	if (Distance > SightRange)
	{
		return false;
	}

	FVector Forward = Pawn->GetActorForwardVector();
	ToPlayer.Normalize();
	
	float Dot = FVector::DotProduct(Forward, ToPlayer);
	float Angle = FMath::Acos(Dot) * 180.f / PI;
	
	return Angle <= SightAngle * 0.5f;
}

float ASZMonsterAIController::CalculateNoiseInterest(const FSZNoiseEvent& NoiseEvent) const
{
	if (NoiseEvent.Radius <= 0.f)
	{
		return 0.f;
	}

	APawn* Pawn = GetPawn();
	if (!Pawn)
	{
		return 0.f;
	}

	float Distance = FVector::Dist(Pawn->GetActorLocation(), NoiseEvent.Location);
	float EffectiveRadius = NoiseEvent.Radius * HearingRangeMultiplier;

	// Check for walkie-talkie noise bonus
	if (NoiseEvent.NoiseType.MatchesTag(FGameplayTag::RequestGameplayTag(FName("Noise.WalkieTalkie"))) && bHearsWalkieTalkieFromFar)
	{
		EffectiveRadius *= WalkieTalkieHearingMultiplier;
	}

	if (Distance > EffectiveRadius)
	{
		return 0.f;
	}

	// Interest decreases with distance
	return 1.f - (Distance / EffectiveRadius);
}

FVector ASZMonsterAIController::GetNextPatrolPoint()
{
	if (PatrolPoints.Num() == 0)
	{
		return GetPawn() ? GetPawn()->GetActorLocation() : FVector::ZeroVector;
	}
	return PatrolPoints[CurrentPatrolIndex];
}