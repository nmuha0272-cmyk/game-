#include "SZDoor.h"

#include "SZMaterials.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Net/UnrealNetwork.h"
#include "UObject/ConstructorHelpers.h"

ASZDoor::ASZDoor()
{
	PrimaryActorTick.bCanEverTick = true;

	USceneComponent* Root = CreateDefaultSubobject<USceneComponent>(TEXT("Root"));
	RootComponent = Root;
	Hinge = CreateDefaultSubobject<USceneComponent>(TEXT("Hinge"));
	Hinge->SetupAttachment(Root);

	// A 2 m wide, 3 m tall, 12 cm thick panel that starts at the hinge.
	Panel = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Panel"));
	Panel->SetupAttachment(Hinge);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Cube(TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (Cube.Succeeded())
	{
		Panel->SetStaticMesh(Cube.Object);
	}
	Panel->SetRelativeLocation(FVector(0.f, 100.f, 150.f));
	Panel->SetRelativeScale3D(FVector(0.12f, 2.f, 3.f));
	Panel->SetCollisionProfileName(UCollisionProfile::BlockAll_ProfileName);
}

void ASZDoor::BeginPlay()
{
	Super::BeginPlay();
	Panel->SetMaterial(0, SZMaterials::Get(TEXT("rusty_metal")));
	CurrentAngle = bOpen ? OpenAngle : 0.f;
}

FString ASZDoor::GetPrompt(const ASZCharacter* By) const
{
	return bOpen ? TEXT("[E] Close door") : TEXT("[E] Open door");
}

void ASZDoor::Interact(ASZCharacter* By)
{
	bOpen = !bOpen;
}

void ASZDoor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	CurrentAngle = FMath::FInterpTo(CurrentAngle, bOpen ? OpenAngle : 0.f, DeltaTime, 5.f);
	Hinge->SetRelativeRotation(FRotator(0.f, CurrentAngle, 0.f));
}

void ASZDoor::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME(ASZDoor, bOpen);
}
