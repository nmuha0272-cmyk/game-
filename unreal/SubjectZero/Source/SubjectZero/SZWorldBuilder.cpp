#include "SZWorldBuilder.h"

#include "SubjectZero.h"
#include "SZDoor.h"
#include "SZFlicker.h"
#include "SZMaterials.h"

#include "Components/DirectionalLightComponent.h"
#include "Components/DynamicMeshComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Components/TextRenderComponent.h"
#include "Dom/JsonObject.h"
#include "DynamicMeshActor.h"
#include "Engine/DirectionalLight.h"
#include "Engine/ExponentialHeightFog.h"
#include "Engine/PointLight.h"
#include "Engine/PostProcessVolume.h"
#include "Engine/StaticMesh.h"
#include "Engine/TextRenderActor.h"
#include "Engine/World.h"
#include "GeometryScript/MeshBooleanFunctions.h"
#include "GeometryScript/MeshNormalsFunctions.h"
#include "GeometryScript/MeshPrimitiveFunctions.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "UDynamicMesh.h"

namespace
{
	FVector ReadVec(const TSharedPtr<FJsonObject>& Obj, const FString& Key)
	{
		const TArray<TSharedPtr<FJsonValue>>& A = Obj->GetArrayField(Key);
		return FVector(A[0]->AsNumber(), A[1]->AsNumber(), A[2]->AsNumber());
	}

	/** Position + rotation from a level-file entry (no scale). */
	FTransform ReadFrame(const TSharedPtr<FJsonObject>& Obj)
	{
		const FRotator Rotation = FRotationMatrix::MakeFromXZ(ReadVec(Obj, TEXT("x")), ReadVec(Obj, TEXT("z"))).Rotator();
		return FTransform(Rotation, ReadVec(Obj, TEXT("p")));
	}

	UStaticMesh* ShapeMesh(const FString& Kind)
	{
		// Unreal's built-in shapes are all 100 cm across, centered.
		const TCHAR* Path = TEXT("/Engine/BasicShapes/Cube.Cube");
		if (Kind == TEXT("cylinder")) Path = TEXT("/Engine/BasicShapes/Cylinder.Cylinder");
		else if (Kind == TEXT("sphere")) Path = TEXT("/Engine/BasicShapes/Sphere.Sphere");
		else if (Kind == TEXT("cone")) Path = TEXT("/Engine/BasicShapes/Cone.Cone");
		return LoadObject<UStaticMesh>(nullptr, Path);
	}

	/** One actor that holds many copies of the same shape (much faster than one actor each). */
	UInstancedStaticMeshComponent* MakeInstancer(AActor* Owner, UStaticMesh* Mesh, UMaterialInterface* Material, bool bCollide)
	{
		UInstancedStaticMeshComponent* Comp = NewObject<UInstancedStaticMeshComponent>(Owner);
		Comp->SetMobility(EComponentMobility::Movable);
		Comp->SetStaticMesh(Mesh);
		Comp->SetMaterial(0, Material);
		if (bCollide)
		{
			Comp->SetCollisionProfileName(UCollisionProfile::BlockAll_ProfileName);
		}
		else
		{
			Comp->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
		Comp->SetupAttachment(Owner->GetRootComponent());
		Comp->RegisterComponent();
		return Comp;
	}

	AActor* MakeHolder(UWorld& World, const TCHAR* Name)
	{
		FActorSpawnParameters Params;
		Params.Name = MakeUniqueObjectName(World.GetCurrentLevel(), AActor::StaticClass(), Name);
		AActor* Holder = World.SpawnActor<AActor>(AActor::StaticClass(), FTransform::Identity, Params);
		USceneComponent* Root = NewObject<USceneComponent>(Holder, TEXT("Root"));
		Root->SetMobility(EComponentMobility::Movable);
		Holder->SetRootComponent(Root);
		Root->RegisterComponent();
#if WITH_EDITOR
		Holder->SetActorLabel(Name);
#endif
		return Holder;
	}

	FLinearColor ReadColor(const TSharedPtr<FJsonObject>& Obj, const FString& Key)
	{
		return FLinearColor(FColor::FromHex(Obj->GetStringField(Key)));
	}
}

bool USZWorldBuilder::ShouldCreateSubsystem(UObject* Outer) const
{
	const UWorld* World = Cast<UWorld>(Outer);
	return World && (World->WorldType == EWorldType::Game || World->WorldType == EWorldType::PIE);
}

TSharedPtr<FJsonObject> USZWorldBuilder::LoadLevel()
{
	static TSharedPtr<FJsonObject> Cached;
	if (Cached.IsValid())
	{
		return Cached;
	}
	const FString Path = FPaths::ProjectContentDir() / TEXT("Data/chapter1.json");
	FString Text;
	if (!FFileHelper::LoadFileToString(Text, *Path))
	{
		UE_LOG(LogSubjectZero, Error, TEXT("Level file missing: %s"), *Path);
		return nullptr;
	}
	TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Text);
	if (!FJsonSerializer::Deserialize(Reader, Cached) || !Cached.IsValid())
	{
		UE_LOG(LogSubjectZero, Error, TEXT("Level file is broken: %s"), *Path);
		Cached.Reset();
	}
	return Cached;
}

TArray<FTransform> USZWorldBuilder::GetSpawnTransforms()
{
	TArray<FTransform> Result;
	if (TSharedPtr<FJsonObject> Level = LoadLevel())
	{
		for (const TSharedPtr<FJsonValue>& Value : Level->GetArrayField(TEXT("spawns")))
		{
			const TSharedPtr<FJsonObject> Spawn = Value->AsObject();
			// The marker is on the ground; the player's middle is 90 cm up.
			const FVector Pos = ReadVec(Spawn, TEXT("p")) + FVector(0, 0, 100);
			Result.Add(FTransform(FRotator(0, Spawn->GetNumberField(TEXT("yaw")), 0), Pos));
		}
	}
	return Result;
}

void USZWorldBuilder::OnWorldBeginPlay(UWorld& InWorld)
{
	Super::OnWorldBeginPlay(InWorld);
	const TSharedPtr<FJsonObject> Level = LoadLevel();
	if (!Level.IsValid())
	{
		return;
	}
	BuildRock(InWorld, Level->GetArrayField(TEXT("rock")));
	BuildShapes(InWorld, Level->GetArrayField(TEXT("shapes")));
	BuildTrees(InWorld, Level->GetArrayField(TEXT("trees")));
	BuildLights(InWorld, Level->GetArrayField(TEXT("lights")));
	BuildLabels(InWorld, Level->GetArrayField(TEXT("labels")));
	BuildAtmosphere(InWorld, Level->GetObjectField(TEXT("moon")));
	if (InWorld.GetNetMode() != NM_Client)
	{
		SpawnDoors(InWorld, Level->GetArrayField(TEXT("doors")));
	}
	UE_LOG(LogSubjectZero, Log, TEXT("Chapter 1 built."));
}

// The ground and everything underground: one huge block of rock with the
// tunnels, stairs and rooms cut out of it (like Godot's CSG).
void USZWorldBuilder::BuildRock(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Parts)
{
	ADynamicMeshActor* Rock = World.SpawnActor<ADynamicMeshActor>(ADynamicMeshActor::StaticClass(), FTransform::Identity);
	UDynamicMeshComponent* Comp = Rock->GetDynamicMeshComponent();
	UDynamicMesh* Mesh = Comp->GetDynamicMesh();
	Mesh->Reset();
	UDynamicMesh* Cutter = NewObject<UDynamicMesh>(Rock);
	FGeometryScriptPrimitiveOptions Options;

	bool bFirst = true;
	for (const TSharedPtr<FJsonValue>& Value : Parts)
	{
		const TSharedPtr<FJsonObject> Part = Value->AsObject();
		const FVector Size = ReadVec(Part, TEXT("s"));
		const FTransform Frame = ReadFrame(Part);
		if (bFirst)
		{
			UGeometryScriptLibrary_MeshPrimitiveFunctions::AppendBox(
				Mesh, Options, Frame, static_cast<float>(Size.X), static_cast<float>(Size.Y), static_cast<float>(Size.Z), 0, 0, 0, EGeometryScriptPrimitiveOriginMode::Center);
			bFirst = false;
			continue;
		}
		Cutter->Reset();
		UGeometryScriptLibrary_MeshPrimitiveFunctions::AppendBox(
			Cutter, Options, Frame, static_cast<float>(Size.X), static_cast<float>(Size.Y), static_cast<float>(Size.Z), 0, 0, 0, EGeometryScriptPrimitiveOriginMode::Center);
		const EGeometryScriptBooleanOperation Op = Part->GetStringField(TEXT("op")) == TEXT("subtract")
			? EGeometryScriptBooleanOperation::Subtract : EGeometryScriptBooleanOperation::Union;
		UGeometryScriptLibrary_MeshBooleanFunctions::ApplyMeshBoolean(
			Mesh, FTransform::Identity, Cutter, FTransform::Identity, Op, FGeometryScriptMeshBooleanOptions());
	}
	UGeometryScriptLibrary_MeshNormalsFunctions::SetPerFaceNormals(Mesh);
	Comp->SetMaterial(0, SZMaterials::Get(TEXT("terrain")));
	Comp->SetCollisionProfileName(UCollisionProfile::BlockAll_ProfileName);
	Comp->SetComplexAsSimpleCollisionEnabled(true, true);
}

// Walls, floors, furniture, pipes... grouped by shape + material.
void USZWorldBuilder::BuildShapes(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Shapes)
{
	AActor* Holder = MakeHolder(World, TEXT("LevelShapes"));
	TMap<FString, UInstancedStaticMeshComponent*> Groups;
	for (const TSharedPtr<FJsonValue>& Value : Shapes)
	{
		const TSharedPtr<FJsonObject> Shape = Value->AsObject();
		const FString Kind = Shape->GetStringField(TEXT("t"));
		const FString MaterialName = Shape->GetStringField(TEXT("m"));
		const bool bCollide = Shape->GetBoolField(TEXT("c"));
		const FString Key = FString::Printf(TEXT("%s|%s|%d"), *Kind, *MaterialName, bCollide ? 1 : 0);
		UInstancedStaticMeshComponent** Group = Groups.Find(Key);
		if (Group == nullptr)
		{
			Group = &Groups.Add(Key, MakeInstancer(Holder, ShapeMesh(Kind), SZMaterials::Get(MaterialName), bCollide));
		}
		FTransform T = ReadFrame(Shape);
		T.SetScale3D(ReadVec(Shape, TEXT("s")) / 100.0);
		(*Group)->AddInstance(T, true);
	}
}

void USZWorldBuilder::BuildTrees(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Parts)
{
	AActor* Forest = MakeHolder(World, TEXT("Forest"));
	for (const TSharedPtr<FJsonValue>& Value : Parts)
	{
		const TSharedPtr<FJsonObject> Part = Value->AsObject();
		UInstancedStaticMeshComponent* Comp = MakeInstancer(
			Forest, ShapeMesh(Part->GetStringField(TEXT("t"))), SZMaterials::Get(Part->GetStringField(TEXT("m"))), false);
		for (const TSharedPtr<FJsonValue>& ItemValue : Part->GetArrayField(TEXT("items")))
		{
			const TSharedPtr<FJsonObject> Item = ItemValue->AsObject();
			FTransform T = ReadFrame(Item);
			T.SetScale3D(ReadVec(Item, TEXT("s")) / 100.0);
			Comp->AddInstance(T, true);
		}
	}
}

void USZWorldBuilder::BuildLights(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Lights)
{
	// Godot "energy 1" is about 12 candela here. Change this if rooms are too dark/bright.
	constexpr float EnergyToCandela = 12.f;
	for (const TSharedPtr<FJsonValue>& Value : Lights)
	{
		const TSharedPtr<FJsonObject> L = Value->AsObject();
		APointLight* Actor = World.SpawnActor<APointLight>(APointLight::StaticClass(), FTransform(ReadVec(L, TEXT("p"))));
		UPointLightComponent* Light = Cast<UPointLightComponent>(Actor->GetLightComponent());
		Light->SetMobility(EComponentMobility::Movable);
		Light->SetIntensityUnits(ELightUnits::Candelas);
		Light->SetIntensity(static_cast<float>(L->GetNumberField(TEXT("energy"))) * EnergyToCandela);
		Light->SetAttenuationRadius(static_cast<float>(L->GetNumberField(TEXT("range"))));
		Light->SetLightColor(ReadColor(L, TEXT("color")));
		Light->SetCastShadows(L->GetBoolField(TEXT("shadow")));

		const double Brokenness = L->GetNumberField(TEXT("flicker"));
		const bool bPulse = L->GetBoolField(TEXT("pulse"));
		if (Brokenness >= 0.0 || bPulse)
		{
			USZFlicker* Flicker = NewObject<USZFlicker>(Actor);
			Flicker->Light = Light;
			Flicker->Brokenness = static_cast<float>(FMath::Max(0.0, Brokenness));
			Flicker->bPulse = bPulse;
			Flicker->RegisterComponent();
		}
	}
}

void USZWorldBuilder::BuildLabels(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Labels)
{
	for (const TSharedPtr<FJsonValue>& Value : Labels)
	{
		const TSharedPtr<FJsonObject> L = Value->AsObject();
		FTransform T = ReadFrame(L);
		// Godot labels face their +Z; Unreal text faces its +X. Turn it around.
		T.SetRotation(T.GetRotation() * FQuat(FVector::UpVector, PI));
		ATextRenderActor* Actor = World.SpawnActor<ATextRenderActor>(ATextRenderActor::StaticClass(), T);
		UTextRenderComponent* Text = Actor->GetTextRender();
		Text->SetMobility(EComponentMobility::Movable);
		Text->SetText(FText::FromString(L->GetStringField(TEXT("text"))));
		Text->SetTextRenderColor(FColor::FromHex(L->GetStringField(TEXT("color"))));
		Text->SetWorldSize(static_cast<float>(L->GetNumberField(TEXT("size"))));
		Text->SetHorizontalAlignment(EHTA_Center);
		Text->SetVerticalAlignment(EVRTA_TextCenter);
	}
}

// Moonlight, fog, and the camera "look" (dark corners, film grain).
void USZWorldBuilder::BuildAtmosphere(UWorld& World, const TSharedPtr<FJsonObject>& Moon)
{
	if (Moon.IsValid() && Moon->HasField(TEXT("dir")))
	{
		ADirectionalLight* Sun = World.SpawnActor<ADirectionalLight>(
			ADirectionalLight::StaticClass(), FTransform(ReadVec(Moon, TEXT("dir")).Rotation()));
		ULightComponent* Light = Sun->GetLightComponent();
		Light->SetMobility(EComponentMobility::Movable);
		Light->SetIntensity(static_cast<float>(Moon->GetNumberField(TEXT("energy"))) * 1.5f);  // lux
		Light->SetLightColor(ReadColor(Moon, TEXT("color")));
	}

	AExponentialHeightFog* FogActor = World.SpawnActor<AExponentialHeightFog>(
		AExponentialHeightFog::StaticClass(), FTransform(FVector(0, 0, -1000)));
	UExponentialHeightFogComponent* Fog = FogActor->GetComponent();
	Fog->SetFogDensity(0.03f);
	Fog->SetFogHeightFalloff(0.002f);
	Fog->SetFogInscatteringColor(FLinearColor(0.01f, 0.012f, 0.02f));
	Fog->SetVolumetricFog(true);

	APostProcessVolume* Post = World.SpawnActor<APostProcessVolume>(APostProcessVolume::StaticClass(), FTransform::Identity);
	Post->bUnbound = true;
	FPostProcessSettings& S = Post->Settings;
	S.bOverride_VignetteIntensity = true;
	S.VignetteIntensity = 0.7f;
	S.bOverride_FilmGrainIntensity = true;
	S.FilmGrainIntensity = 0.25f;
	S.bOverride_SceneFringeIntensity = true;
	S.SceneFringeIntensity = 0.6f;
	// Don't let the camera brighten the darkness too much: it's a horror game.
	S.bOverride_AutoExposureMinBrightness = true;
	S.AutoExposureMinBrightness = -1.0f;
	S.bOverride_AutoExposureMaxBrightness = true;
	S.AutoExposureMaxBrightness = 1.0f;
}

void USZWorldBuilder::SpawnDoors(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Doors)
{
	for (const TSharedPtr<FJsonValue>& Value : Doors)
	{
		const TSharedPtr<FJsonObject> D = Value->AsObject();
		const FTransform T(FRotator(0, D->GetNumberField(TEXT("yaw")), 0), ReadVec(D, TEXT("p")));
		ASZDoor* Door = World.SpawnActor<ASZDoor>(ASZDoor::StaticClass(), T);
		// Puzzles aren't in the Unreal version yet, so puzzle doors start open
		// (otherwise you couldn't get through the chapter).
		Door->bOpen = D->GetBoolField(TEXT("puzzle"));
	}
}
