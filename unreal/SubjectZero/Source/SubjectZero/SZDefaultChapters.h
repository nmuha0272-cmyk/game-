#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "SZChapterData.h"
#include "SZDefaultChapters.generated.h"

class USZChapterManager;

/**
 * Helper class to register default chapter data for Deepwell.
 * Call USZDefaultChapters::RegisterDefaultChapters(ChapterManager) during game initialization.
 */
UCLASS()
class SUBJECTZERO_API USZDefaultChapters : public UObject
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Chapter|Setup")
	static void RegisterDefaultChapters(USZChapterManager* ChapterManager);
};