#pragma once

#include "CoreMinimal.h"
#include "SZMonsterAIController.h"
#include "SZTheSealedAIController.generated.h"

/**
 * The Sealed (Chapter 3) - Blind subjects Cole locked in Level B.
 * Hunt ONLY by sound. Hearing range is doubled. Total silence is the only safe option.
 * They still knock on doors.
 */
UCLASS()
class SUBJECTZERO_API ASZTheSealedAIController : public ASZMonsterAIController
{
	GENERATED_BODY()

public:
	ASZTheSealedAIController();

protected:
	virtual void BeginPlay() override;

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|TheSealed")
	void OnDoorKnocked();

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|TheSealed")
	void OnPlayerMakesNoise(float NoiseLevel);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|TheSealed")
	float BaseHearingMultiplier = 2.0f; // Doubled hearing

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|TheSealed")
	float KnockCheckInterval = 10.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|TheSealed")
	float KnockInvestigationChance = 0.3f;
};