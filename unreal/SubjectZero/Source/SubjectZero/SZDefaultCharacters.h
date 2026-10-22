#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "SZCharacterData.h"
#include "SZDefaultCharacters.generated.h"

class USZCharacterData;

/**
 * Helper class to register default character data for Deepwell.
 * Call USZDefaultCharacters::RegisterDefaultCharacters() during game initialization.
 */
UCLASS()
class SUBJECTZERO_API USZDefaultCharacters : public UObject
{
	GENERATED_BODY()

public:
	// Not a UFUNCTION: Blueprints can't take a TMap of TObjectPtr by reference.
	static void RegisterDefaultCharacters(TMap<ESZCharacterID, TObjectPtr<USZCharacterData>>& OutCharacterRegistry);
};