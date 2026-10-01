#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "SZFlicker.generated.h"

class ULightComponent;

/** Makes a light flicker like a dying bulb, or pulse slowly (warning lights). */
UCLASS()
class SUBJECTZERO_API USZFlicker : public UActorComponent
{
	GENERATED_BODY()

public:
	USZFlicker();

	/** 0 = almost steady, 1 = barely works. */
	float Brokenness = 0.2f;
	/** Pulse smoothly instead of flickering. */
	bool bPulse = false;

	UPROPERTY()
	TObjectPtr<ULightComponent> Light;

	virtual void BeginPlay() override;
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
	float BaseIntensity = 0.f;
	float Timer = 0.f;
	float Age = 0.f;
	bool bLit = true;
};
