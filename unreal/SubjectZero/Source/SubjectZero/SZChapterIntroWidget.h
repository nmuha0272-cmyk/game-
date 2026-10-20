#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SZChapterIntroWidget.generated.h"

class UTextBlock;
class UImage;
class UProgressBar;

UCLASS(Blueprintable, BlueprintType)
class SUBJECTZERO_API USZChapterIntroWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, meta = (BindWidget))
	TObjectPtr<UTextBlock> ChapterTitleText;

	UPROPERTY(BlueprintReadOnly, meta = (BindWidget))
	TObjectPtr<UTextBlock> ChapterDescriptionText;

	UPROPERTY(BlueprintReadOnly, meta = (BindWidget))
	TObjectPtr<UImage> BackgroundImage;

	UPROPERTY(BlueprintReadOnly, meta = (BindWidget))
	TObjectPtr<UProgressBar> LoadingProgressBar;

	UFUNCTION(BlueprintCallable, Category = "Chapter")
	void SetChapterData(class USZChapterData* ChapterData);

	UFUNCTION(BlueprintCallable, Category = "Chapter")
	void SetLoadingProgress(float Progress);

protected:
	virtual void NativeConstruct() override;

private:
	UPROPERTY()
	TObjectPtr<class USZChapterData> CurrentChapterData;
};