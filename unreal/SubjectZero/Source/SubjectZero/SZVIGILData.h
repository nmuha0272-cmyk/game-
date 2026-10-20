#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "SZVIGILData.generated.h"

UCLASS(BlueprintType, Const)
class SUBJECTZERO_API USZVIGILData : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	FText OrganizationName;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	FText Description;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	FText Motto;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	FText FoundingDate;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	TArray<FText> KnownAgents;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	TArray<FText> Objectives;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "VIGIL")
	TArray<FText> Methods;

	UFUNCTION(BlueprintPure, Category = "VIGIL")
	FText GetOrganizationName() const { return OrganizationName; }
};