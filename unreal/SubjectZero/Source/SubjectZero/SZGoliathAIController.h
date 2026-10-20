#pragma once

#include "CoreMinimal.h"
#include "SZMonsterAIController.h"
#include "SZGoliathAIController.generated.h"

class ASZMonsterCharacter;

/**
 * Goliath (Chapter 1) - Hears voices normally. Teaches players the rule.
 * A failed test subject stretched too tall for the tunnels, crawls on all fours in tight spaces.
 * Sensitive to light (weak to Journalist's Camera Flash).
 */
UCLASS()
class SUBJECTZERO_API ASZGoliathAIController : public ASZMonsterAIController
{
	GENERATED_BODY()

public:
	ASZGoliathAIController();

protected:
	virtual void BeginPlay() override;

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Goliath")
	void OnLightStunned(float Duration);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Goliath")
	void OnEnterTightSpace();

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Goliath")
	void OnExitTightSpace();
};