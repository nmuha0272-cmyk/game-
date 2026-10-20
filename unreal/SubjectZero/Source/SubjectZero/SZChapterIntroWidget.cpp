#include "SZChapterIntroWidget.h"
#include "SZChapterData.h"
#include "Components/TextBlock.h"
#include "Components/Image.h"
#include "Components/ProgressBar.h"

void USZChapterIntroWidget::NativeConstruct()
{
	Super::NativeConstruct();
	SetLoadingProgress(0.f);
}

void USZChapterIntroWidget::SetChapterData(USZChapterData* ChapterData)
{
	CurrentChapterData = ChapterData;
	if (!ChapterData)
	{
		return;
	}

	if (ChapterTitleText)
	{
		ChapterTitleText->SetText(ChapterData->DisplayName);
	}

	if (ChapterDescriptionText)
	{
		ChapterDescriptionText->SetText(ChapterData->Description);
	}
}

void USZChapterIntroWidget::SetLoadingProgress(float Progress)
{
	if (LoadingProgressBar)
	{
		LoadingProgressBar->SetPercent(FMath::Clamp(Progress, 0.f, 1.f));
	}
}