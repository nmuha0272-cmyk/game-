#include "SZCharacter.h"

#include "SZInteractable.h"
#include "SZMaterials.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/SpotLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Net/UnrealNetwork.h"
#include "UObject/ConstructorHelpers.h"

/** How far away you can press E on something (cm). */
static constexpr float InteractReach = 250.f;

ASZCharacter::ASZCharacter()
{
	PrimaryActorTick.bCanEverTick = true;
	GetCapsuleComponent()->InitCapsuleSize(35.f, 90.f);  // 1.8 m tall
	bUseControllerRotationYaw = true;

	Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	Camera->SetupAttachment(GetCapsuleComponent());
	Camera->SetRelativeLocation(FVector(0.f, 0.f, 70.f));  // eyes at 1.6 m
	Camera->bUsePawnControlRotation = true;
	Camera->SetFieldOfView(80.f);

	Flashlight = CreateDefaultSubobject<USpotLightComponent>(TEXT("Flashlight"));
	Flashlight->SetupAttachment(Camera);
	Flashlight->SetRelativeLocation(FVector(10.f, 15.f, -12.f));
	Flashlight->IntensityUnits = ELightUnits::Candelas;
	Flashlight->Intensity = 350.f;
	Flashlight->InnerConeAngle = 10.f;
	Flashlight->OuterConeAngle = 24.f;
	Flashlight->AttenuationRadius = 2500.f;
	Flashlight->SetVisibility(false);

	BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
	BodyMesh->SetupAttachment(GetCapsuleComponent());
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Cylinder(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (Cylinder.Succeeded())
	{
		BodyMesh->SetStaticMesh(Cylinder.Object);
	}
	BodyMesh->SetRelativeScale3D(FVector(0.6f, 0.6f, 1.8f));
	BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BodyMesh->SetOwnerNoSee(true);

	UCharacterMovementComponent* Move = GetCharacterMovement();
	Move->MaxWalkSpeed = WalkSpeed;
	Move->MaxWalkSpeedCrouched = 180.f;
	Move->NavAgentProps.bCanCrouch = true;
	Move->SetCrouchedHalfHeight(50.f);  // 1 m tall: fits through the vent crawl
	Move->JumpZVelocity = 380.f;
}

void ASZCharacter::SetupPlayerInputComponent(UInputComponent* Input)
{
	Super::SetupPlayerInputComponent(Input);
	Input->BindAxis(TEXT("MoveForward"), this, &ASZCharacter::MoveForward);
	Input->BindAxis(TEXT("MoveRight"), this, &ASZCharacter::MoveRight);
	Input->BindAxis(TEXT("Turn"), this, &ASZCharacter::Turn);
	Input->BindAxis(TEXT("LookUp"), this, &ASZCharacter::LookUp);
	Input->BindAction(TEXT("Sprint"), IE_Pressed, this, &ASZCharacter::StartSprint);
	Input->BindAction(TEXT("Sprint"), IE_Released, this, &ASZCharacter::StopSprint);
	Input->BindAction(TEXT("Crouch"), IE_Pressed, this, &ASZCharacter::StartCrouch);
	Input->BindAction(TEXT("Crouch"), IE_Released, this, &ASZCharacter::StopCrouch);
	Input->BindAction(TEXT("Jump"), IE_Pressed, this, &ACharacter::Jump);
	Input->BindAction(TEXT("Flashlight"), IE_Pressed, this, &ASZCharacter::ToggleFlashlight);
	Input->BindAction(TEXT("Interact"), IE_Pressed, this, &ASZCharacter::PressInteract);
}

void ASZCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	if (IsLocallyControlled())
	{
		UpdateFocus();
	}
}

void ASZCharacter::MoveForward(float Value)
{
	if (Value != 0.f)
	{
		AddMovementInput(FRotationMatrix(FRotator(0.f, GetControlRotation().Yaw, 0.f)).GetUnitAxis(EAxis::X), Value);
	}
}

void ASZCharacter::MoveRight(float Value)
{
	if (Value != 0.f)
	{
		AddMovementInput(FRotationMatrix(FRotator(0.f, GetControlRotation().Yaw, 0.f)).GetUnitAxis(EAxis::Y), Value);
	}
}

void ASZCharacter::Turn(float Value)
{
	AddControllerYawInput(Value);
}

void ASZCharacter::LookUp(float Value)
{
	AddControllerPitchInput(Value);
}

void ASZCharacter::StartSprint()
{
	bSprinting = true;
	OnRep_Sprinting();
	ServerSetSprinting(true);
}

void ASZCharacter::StopSprint()
{
	bSprinting = false;
	OnRep_Sprinting();
	ServerSetSprinting(false);
}

void ASZCharacter::ServerSetSprinting_Implementation(bool bNewSprinting)
{
	bSprinting = bNewSprinting;
	OnRep_Sprinting();
}

void ASZCharacter::OnRep_Sprinting()
{
	GetCharacterMovement()->MaxWalkSpeed = bSprinting ? SprintSpeed : WalkSpeed;
}

void ASZCharacter::StartCrouch()
{
	Crouch();
}

void ASZCharacter::StopCrouch()
{
	UnCrouch();
}

void ASZCharacter::ToggleFlashlight()
{
	bFlashlightOn = !bFlashlightOn;
	OnRep_Flashlight();
	ServerSetFlashlight(bFlashlightOn);
}

void ASZCharacter::ServerSetFlashlight_Implementation(bool bOn)
{
	bFlashlightOn = bOn;
	OnRep_Flashlight();
}

void ASZCharacter::OnRep_Flashlight()
{
	Flashlight->SetVisibility(bFlashlightOn);
}

void ASZCharacter::UpdateFocus()
{
	FocusedThing = nullptr;
	const FVector Start = Camera->GetComponentLocation();
	const FVector End = Start + Camera->GetForwardVector() * InteractReach;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(SZInteract), false, this);
	if (GetWorld()->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
	{
		FocusedThing = Cast<ASZInteractable>(Hit.GetActor());
	}
}

void ASZCharacter::PressInteract()
{
	if (FocusedThing)
	{
		ServerInteract(FocusedThing);
	}
}

void ASZCharacter::ServerInteract_Implementation(ASZInteractable* Thing)
{
	// The host checks they're really close enough (no opening doors across the map).
	if (Thing && FVector::Dist(Thing->GetActorLocation(), GetActorLocation()) < InteractReach + 250.f)
	{
		Thing->Interact(this);
	}
}

void ASZCharacter::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME(ASZCharacter, bFlashlightOn);
	DOREPLIFETIME(ASZCharacter, bSprinting);
}
