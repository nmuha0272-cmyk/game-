#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "SZCharacter.generated.h"

class UCameraComponent;
class USpotLightComponent;
class ASZInteractable;

/**
 * The player: first-person walking, sprinting, crouching, a flashlight, and
 * pressing E on things. Each player controls their own character; Unreal
 * sends their movement to everyone else.
 */
UCLASS()
class SUBJECTZERO_API ASZCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	ASZCharacter();

	UPROPERTY(EditAnywhere, Category = "Movement")
	float WalkSpeed = 350.f;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float SprintSpeed = 600.f;

	/** What we're looking at right now (only on our own computer). */
	UPROPERTY(Transient)
	TObjectPtr<ASZInteractable> FocusedThing;

	virtual void Tick(float DeltaTime) override;
	virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	bool IsFlashlightOn() const { return bFlashlightOn; }

protected:
	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UCameraComponent> Camera;

	UPROPERTY(VisibleAnywhere)
	TObjectPtr<USpotLightComponent> Flashlight;

	/** What other players see (you don't see your own). */
	UPROPERTY(VisibleAnywhere)
	TObjectPtr<UStaticMeshComponent> BodyMesh;

	UPROPERTY(ReplicatedUsing = OnRep_Flashlight)
	bool bFlashlightOn = false;

	UPROPERTY(ReplicatedUsing = OnRep_Sprinting)
	bool bSprinting = false;

	void MoveForward(float Value);
	void MoveRight(float Value);
	void Turn(float Value);
	void LookUp(float Value);
	void StartSprint();
	void StopSprint();
	void StartCrouch();
	void StopCrouch();
	void ToggleFlashlight();
	void PressInteract();

	UFUNCTION(Server, Reliable)
	void ServerSetSprinting(bool bNewSprinting);

	UFUNCTION(Server, Reliable)
	void ServerSetFlashlight(bool bOn);

	UFUNCTION(Server, Reliable)
	void ServerInteract(ASZInteractable* Thing);

	UFUNCTION()
	void OnRep_Flashlight();

	UFUNCTION()
	void OnRep_Sprinting();

private:
	void UpdateFocus();
};
