#pragma once

#include "CoreMinimal.h"
#include "SZMonsterAIController.h"
#include "SZTheWardenAIController.generated.h"

UENUM(BlueprintType)
enum class ESZWardenTactic : uint8
{
	Flank,
	Ambush,
	Suppress,
	Investigate,
	CallBackup
};

/**
 * The Warden (Chapter 5-6) - Modern super-soldier in tactical gear.
 * Faster and smarter than old experiments: opens doors, uses flashlights, sets traps.
 * Wears modern headset that picks up walkie-talkie chatter and remembers where he last heard players.
 */
UCLASS()
class SUBJECTZERO_API ASZTheWardenAIController : public ASZMonsterAIController
{
	GENERATED_BODY()

public:
	ASZTheWardenAIController();

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	UFUNCTION(BlueprintCallable, Category = "Monster|Warden")
	void SetTactic(ESZWardenTactic NewTactic);

	UFUNCTION(BlueprintCallable, Category = "Monster|Warden")
	void RememberPlayerLocation(int32 PlayerId, FVector Location);

	UFUNCTION(BlueprintCallable, Category = "Monster|Warden")
	void OnWalkieTalkieIntercepted(int32 SpeakerPlayerId, FVector SpeakerLocation);

	UFUNCTION(BlueprintCallable, Category = "Monster|Warden")
	void UseFlashlight(bool bEnable);

	UFUNCTION(BlueprintCallable, Category = "Monster|Warden")
	void SetTrap(FVector Location, FName TrapType);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Warden")
	void OnTacticChanged(ESZWardenTactic OldTactic, ESZWardenTactic NewTactic);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Warden")
	void OnTrapTriggered(FName TrapType, int32 VictimPlayerId);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	ESZWardenTactic CurrentTactic = ESZWardenTactic::Investigate;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	float TacticChangeInterval = 15.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	float MemoryRetentionTime = 60.f; // Remembers player locations for 60 seconds

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	bool bCanOpenDoors = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	bool bUsesFlashlight = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Warden")
	float FlashlightRange = 3000.f;

	UPROPERTY()
	TMap<int32, FVector> RememberedPlayerLocations;

	UPROPERTY()
	TMap<int32, float> LocationMemoryTimers;

	UPROPERTY()
	float TacticTimer = 0.f;
};