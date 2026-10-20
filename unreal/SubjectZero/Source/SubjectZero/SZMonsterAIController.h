#pragma once

#include "CoreMinimal.h"
#include "AIController.h"
#include "GameplayTagContainer.h"
#include "SZMonsterAIController.generated.h"

class USZVoiceChatManager;
class APawn;

UENUM(BlueprintType)
enum class ESZMonsterState : uint8
{
	Patrol,
	Investigate,
	Chase,
	Search,
	Stunned,
	Dead
};

USTRUCT(BlueprintType)
struct FSZNoiseEvent
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadWrite)
	FVector Location;

	UPROPERTY(BlueprintReadWrite)
	float Radius;

	UPROPERTY(BlueprintReadWrite)
	int32 InstigatorPlayerId;

	UPROPERTY(BlueprintReadWrite)
	float TimeStamp;

	UPROPERTY(BlueprintReadWrite)
	FGameplayTag NoiseType; // Footstep, Voice, Gunshot, ItemDrop, etc.
};

UCLASS(Blueprintable, BlueprintType)
class SUBJECTZERO_API ASZMonsterAIController : public AAIController
{
	GENERATED_BODY()

public:
	ASZMonsterAIController();

	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	UFUNCTION(BlueprintCallable, Category = "Monster|State")
	void SetMonsterState(ESZMonsterState NewState);

	UFUNCTION(BlueprintCallable, Category = "Monster|State")
	ESZMonsterState GetMonsterState() const;

	UFUNCTION(BlueprintCallable, Category = "Monster|Perception")
	void OnNoiseHeard(const FSZNoiseEvent& NoiseEvent);

	UFUNCTION(BlueprintCallable, Category = "Monster|Perception")
	void OnPlayerSeen(APawn* PlayerPawn);

	UFUNCTION(BlueprintCallable, Category = "Monster|Perception")
	void OnPlayerLost(APawn* PlayerPawn);

	UFUNCTION(BlueprintCallable, Category = "Monster|Combat")
	void OnStunned(float Duration);

	UFUNCTION(BlueprintCallable, Category = "Monster|Combat")
	void OnDoorHeld(float HoldTime);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Behavior")
	void OnStateChanged(ESZMonsterState OldState, ESZMonsterState NewState);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Behavior")
	void OnNoiseEventReceived(const FSZNoiseEvent& NoiseEvent);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Behavior")
	void OnPlayerSpotted(APawn* PlayerPawn);

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Monster|State")
	ESZMonsterState CurrentState = ESZMonsterState::Patrol;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	float HearingRangeMultiplier = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	float SightRange = 2000.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	float SightAngle = 90.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	bool bIsBlind = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	bool bHearsWalkieTalkieFromFar = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Perception")
	float WalkieTalkieHearingMultiplier = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Behavior")
	float PatrolWaitTimeMin = 3.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Behavior")
	float PatrolWaitTimeMax = 8.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Behavior")
	float SearchDuration = 15.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Behavior")
	float StunDuration = 2.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Behavior")
	TArray<FVector> PatrolPoints;

	UPROPERTY()
	int32 CurrentPatrolIndex = 0;

	UPROPERTY()
	float StateTimer = 0.f;

	UPROPERTY()
	TObjectPtr<APawn> LastKnownPlayerLocation;

	UPROPERTY()
	TObjectPtr<USZVoiceChatManager> VoiceChatManager;

	void UpdateState(float DeltaTime);
	void HandlePatrolState(float DeltaTime);
	void HandleInvestigateState(float DeltaTime);
	void HandleChaseState(float DeltaTime);
	void HandleSearchState(float DeltaTime);
	void HandleStunnedState(float DeltaTime);

	bool CanSeePlayer(APawn* PlayerPawn) const;
	float CalculateNoiseInterest(const FSZNoiseEvent& NoiseEvent) const;
	FVector GetNextPatrolPoint();
};