#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "SZWorldBuilder.generated.h"

class FJsonObject;
class FJsonValue;

/**
 * Builds Chapter 1 when the level starts, from Content/Data/chapter1.json
 * (exported from the Godot version by tools/export_for_unreal.gd).
 *
 * Every computer builds the walls, lights and trees itself (they never
 * change, so there's nothing to send over the network). Only the host spawns
 * things that change, like doors; Unreal then copies them to everyone.
 */
UCLASS()
class SUBJECTZERO_API USZWorldBuilder : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	virtual bool ShouldCreateSubsystem(UObject* Outer) const override;
	virtual void OnWorldBeginPlay(UWorld& InWorld) override;

	/** The level file, loaded once. Null if it's missing. */
	static TSharedPtr<FJsonObject> LoadLevel();

	/** Where players start (the host's GameMode asks for these). */
	static TArray<FTransform> GetSpawnTransforms();

private:
	void BuildRock(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Parts);
	void BuildShapes(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Shapes);
	void BuildTrees(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Parts);
	void BuildLights(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Lights);
	void BuildLabels(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Labels);
	void BuildAtmosphere(UWorld& World, const TSharedPtr<FJsonObject>& Moon);
	void SpawnDoors(UWorld& World, const TArray<TSharedPtr<FJsonValue>>& Doors);
};
