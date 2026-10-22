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
	// Not a UFUNCTION: Blueprints can't take a TArray of TObjectPtr by reference.
	static void RegisterDefaultItems(TArray<TObjectPtr<USZItemData>>& OutItemRegistry);
};