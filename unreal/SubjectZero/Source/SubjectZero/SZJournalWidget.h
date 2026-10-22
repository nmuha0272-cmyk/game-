#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "SZChapterData.h"
#include "SZCharacterData.h"
#include "SZJournalWidget.generated.h"

class UButton;
class UTextBlock;
class UListView;
class UImage;
class UWidgetSwitcher;
class USZLoreManager;

UCLASS(Blueprintable, BlueprintType)
class SUBJECTZERO_API USZJournalWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Journal")
	void InitializeJournal(USZLoreManager* InLoreManager);

	UFUNCTION(BlueprintCallable, Category = "Journal")
	void RefreshJournal();

	UFUNCTION(BlueprintCallable, Category = "Journal")
	void SelectTab(int32 TabIndex);

	UFUNCTION(BlueprintCallable, Category = "Journal")
	void SelectLoreEntry(class UObject* EntryObject);

protected:
	virtual void NativeConstruct() override;

private:
	UPROPERTY()
	TObjectPtr<USZLoreManager> LoreManager;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UButton> TabFilesButton;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UButton> TabTapesButton;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UButton> TabPhotosButton;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UButton> TabPersonalButton;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UListView> LoreListView;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UWidgetSwitcher> DetailViewSwitcher;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UTextBlock> DetailTitleText;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UTextBlock> DetailContentText;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UImage> DetailImage;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UTextBlock> DetailOwnerText;

	UPROPERTY(meta = (BindWidget))
	TObjectPtr<UTextBlock> ProgressText;

	UPROPERTY()
	int32 CurrentTabIndex = 0;

	UPROPERTY()
	TArray<TObjectPtr<UObject>> CurrentLoreEntries;

	void SetupTabButtons();
	void PopulateLoreList();
	void ShowLoreDetail(const FSZChapterLoreItem& LoreItem);
	void UpdateProgressText();

	UFUNCTION()
	void OnTabFilesClicked();

	UFUNCTION()
	void OnTabTapesClicked();

	UFUNCTION()
	void OnTabPhotosClicked();

	UFUNCTION()
	void OnTabPersonalClicked();

	UFUNCTION()
	void OnLoreEntrySelected(UObject* EntryObject);
};