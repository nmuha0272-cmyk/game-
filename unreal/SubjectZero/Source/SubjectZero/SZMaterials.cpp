#include "SZMaterials.h"

#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "UObject/Package.h"

namespace
{
	TMap<FString, UMaterialInterface*> GCache;

	// Placeholder colors until real materials exist (same look as the Godot gray-box).
	FLinearColor ColorFor(const FString& Name)
	{
		if (Name.StartsWith(TEXT("#")) || Name.StartsWith(TEXT("!")))
		{
			return FLinearColor(FColor::FromHex(Name.RightChop(1)));
		}
		static const TMap<FString, FLinearColor> Table = {
			{TEXT("terrain"), FLinearColor(0.30f, 0.30f, 0.28f)},
			{TEXT("ground"), FLinearColor(0.20f, 0.17f, 0.13f)},
			{TEXT("concrete_wall"), FLinearColor(0.45f, 0.44f, 0.41f)},
			{TEXT("concrete_floor"), FLinearColor(0.30f, 0.30f, 0.28f)},
			{TEXT("cinder_block"), FLinearColor(0.38f, 0.39f, 0.36f)},
			{TEXT("rock"), FLinearColor(0.25f, 0.24f, 0.21f)},
			{TEXT("painted_wall"), FLinearColor(0.32f, 0.38f, 0.32f)},
			{TEXT("wood"), FLinearColor(0.30f, 0.20f, 0.12f)},
			{TEXT("dark_wood"), FLinearColor(0.18f, 0.12f, 0.08f)},
			{TEXT("rusty_metal"), FLinearColor(0.22f, 0.24f, 0.21f)},
			{TEXT("asphalt"), FLinearColor(0.08f, 0.08f, 0.09f)},
			{TEXT("lino_floor"), FLinearColor(0.30f, 0.30f, 0.25f)},
			{TEXT("chainlink"), FLinearColor(0.12f, 0.12f, 0.12f)},
		};
		if (const FLinearColor* Found = Table.Find(Name))
		{
			return *Found;
		}
		return FLinearColor(0.5f, 0.5f, 0.5f);
	}
}

UMaterialInterface* SZMaterials::Get(const FString& Name)
{
	if (UMaterialInterface** Found = GCache.Find(Name))
	{
		if (IsValid(*Found))
		{
			return *Found;
		}
	}

	UMaterialInterface* Result = nullptr;
	if (!Name.StartsWith(TEXT("#")) && !Name.StartsWith(TEXT("!")))
	{
		const FString Path = FString::Printf(TEXT("/Game/Materials/M_%s.M_%s"), *Name, *Name);
		Result = LoadObject<UMaterialInterface>(nullptr, *Path, nullptr, LOAD_NoWarn | LOAD_Quiet);
	}
	if (Result == nullptr)
	{
		UMaterialInterface* Base = LoadObject<UMaterialInterface>(
			nullptr, TEXT("/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial"));
		UMaterialInstanceDynamic* Instance = UMaterialInstanceDynamic::Create(Base, GetTransientPackage());
		Instance->SetVectorParameterValue(TEXT("Color"), ColorFor(Name));
		Result = Instance;
	}
	Result->AddToRoot();  // keep it alive between levels
	GCache.Add(Name, Result);
	return Result;
}
