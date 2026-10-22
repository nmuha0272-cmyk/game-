#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "Brushes/SlateColorBrush.h"
#include "Input/Reply.h"
#include "SZPlayerController.generated.h"

class SEditableTextBox;
class SWidget;
template <typename ItemType> class SListView;
class USZChapterData;
class USZChapterManager;

USTRUCT()
struct FSZChapterMenuEntry
{
	GENERATED_BODY()

	UPROPERTY()
	TObjectPtr<USZChapterData> ChapterData;

	UPROPERTY()
	FText DisplayText;

	UPROPERTY()
	bool bIsAvailable = false;

	UPROPERTY()
	bool bIsCompleted = false;
};

/**
 * Your connection to the game. When the game first opens (not hosting or
 * joined yet) it shows the main menu: Host, Join (type an IP), Quit.
 * Host  = reopen the level as a "listen server" others can join (port 7777).
 * Join  = travel to the host's IP.
 * Esc   = leave and go back to the menu.
 */
UCLASS()
class SUBJECTZERO_API ASZPlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	ASZPlayerController();

	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void SetupInputComponent() override;

	UFUNCTION(BlueprintCallable, Category = "Chapter")
	void ShowChapterSelectMenu();

	UFUNCTION(BlueprintCallable, Category = "Chapter")
	void OnChapterSelected(USZChapterData* ChapterData);

protected:
	void ShowMenu();
	void HideMenu();
	void HideChapterSelectMenu();
	void BackToMenu();

	FReply OnHostClicked();
	FReply OnJoinClicked();
	FReply OnQuitClicked();
	FReply OnChapterSelectClicked();
	FReply OnChapterSelectBackClicked();

	void RefreshChapterList();

	TSharedPtr<SWidget> Menu;
	TSharedPtr<SWidget> ChapterSelectMenu;
	TSharedPtr<SEditableTextBox> AddressBox;
	TSharedPtr<SListView<TSharedPtr<FSZChapterMenuEntry>>> ChapterListView;
	TArray<TSharedPtr<FSZChapterMenuEntry>> ChapterEntries;

	FSlateColorBrush Background = FSlateColorBrush(FLinearColor(0.005f, 0.005f, 0.01f, 0.92f));

	UPROPERTY()
	TObjectPtr<USZChapterManager> ChapterManager;
};