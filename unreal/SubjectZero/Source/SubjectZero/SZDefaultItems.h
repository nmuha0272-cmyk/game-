#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "SZItemData.h"
#include "SZInventorySystem.h"
#include "SZDefaultItems.generated.h"

class USZItemData;

/**
 * Helper class to register default items for Deepwell.
 * Call USZDefaultItems::RegisterDefaultItems() during game initialization.
 */
UCLASS()
class SUBJECTZERO_API USZDefaultItems : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Item|Setup")
	static void RegisterDefaultItems(TArray<TObjectPtr<USZItemData>>& OutItemRegistry);
};