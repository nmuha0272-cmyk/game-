#include "SZFlicker.h"

#include "Components/LightComponent.h"

USZFlicker::USZFlicker()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void USZFlicker::BeginPlay()
{
	Super::BeginPlay();
	if (Light)
	{
		BaseIntensity = Light->Intensity;
	}
}

void USZFlicker::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (!Light)
	{
		return;
	}
	Age += DeltaTime;
	if (bPulse)
	{
		Light->SetIntensity(BaseIntensity * (0.55f + 0.45f * FMath::Sin(Age * 3.0f)));
		return;
	}
	Timer -= DeltaTime;
	if (Timer <= 0.f)
	{
		if (bLit && FMath::FRand() < Brokenness)
		{
			// Cut out for a moment. Very broken lights stay dark longer.
			bLit = false;
			Timer = FMath::FRandRange(0.03f, 0.12f) + FMath::FRand() * Brokenness * 1.5f;
		}
		else
		{
			bLit = true;
			Timer = FMath::FRand() < 0.5f ? FMath::FRandRange(0.05f, 0.4f)
				: FMath::FRandRange(0.5f, 4.0f * (1.f - Brokenness) + 0.5f);
		}
		Light->SetIntensity(bLit ? BaseIntensity * FMath::FRandRange(0.85f, 1.f) : 0.f);
	}
}
