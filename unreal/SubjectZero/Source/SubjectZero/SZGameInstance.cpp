#include "SZGameInstance.h"
#include "SZChapterManager.h"

void USZGameInstance::Init()
{
	Super::Init();
	
	ChapterManager = GetSubsystem<USZChapterManager>();
}

USZChapterManager* USZGameInstance::GetChapterManager() const
{
	return ChapterManager;
}