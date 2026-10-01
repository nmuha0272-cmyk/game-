#pragma once

#include "CoreMinimal.h"
#include "SZInteractable.h"
#include "SZDoor.generated.h"

/** A door anyone can open or close with E. It swings on its hinge. */
UCLASS()
class SUBJECTZERO_API ASZDoor : public ASZInteractable
{
	GENERATED_BODY()

public:
	ASZDoor();

	/** Open or shut. The host changes it; Unreal copies it to everyone. */
	UPROPERTY(Replicated)
	bool bOpen = false;

	/** How far it swings open, in degrees. */
	UPROPERTY(EditAnywhere)
	float OpenAngle = 100.f;

	virtual FString GetPrompt(const ASZCharacter* By) const override;
	virtual void Interact(ASZCharacter* By) override;
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

private:
	UPROPERTY(VisibleAnywhere)
	TObjectPtr<USceneComponent> Hinge;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UStaticMeshComponent> Panel;

	float CurrentAngle = 0.f;
};
