#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "SZHUD.generated.h"

/** The on-screen bits: a dot in the middle, what E will do, flashlight hint. */
UCLASS()
class SUBJECTZERO_API ASZHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;
};
