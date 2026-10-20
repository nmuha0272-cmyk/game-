#pragma once

#include "CoreMinimal.h"
#include "SZMonsterAIController.h"
#include "SZConduitAIController.generated.h"

/**
 * Conduit (Chapter 2) - Fused with facility's wiring, attracted to electricity.
 * Restoring power wakes it up. Hears walkie-talkie signals from much farther away.
 */
UCLASS()
class SUBJECTZERO_API ASZConduitAIController : public ASZMonsterAIController
{
	GENERATED_BODY()

public:
	ASZConduitAIController();

protected:
	virtual void BeginPlay() override;

	UFUNCTION(BlueprintCallable, Category = "Monster|Conduit")
	void OnPowerRestored();

	UFUNCTION(BlueprintCallable, Category = "Monster|Conduit")
	void OnPowerLost();

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Conduit")
	void OnElectricalStunned(float Duration);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Conduit")
	bool bIsAwakened = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Conduit")
	float ElectricityAttractionRange = 5000.f;
};