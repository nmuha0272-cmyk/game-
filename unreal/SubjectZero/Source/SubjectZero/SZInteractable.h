#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "SZInteractable.generated.h"

class ASZCharacter;

/**
 * Anything you can look at and press E on (doors now; buttons, levers,
 * items and notes in later phases). The press always runs on the host.
 */
UCLASS(Abstract)
class SUBJECTZERO_API ASZInteractable : public AActor
{
	GENERATED_BODY()

public:
	ASZInteractable();

	/** The text shown in the middle of the screen while looking at it. */
	virtual FString GetPrompt(const ASZCharacter* By) const { return TEXT("[E] Use"); }

	/** Host only: someone pressed E on this. */
	virtual void Interact(ASZCharacter* By) {}
};
