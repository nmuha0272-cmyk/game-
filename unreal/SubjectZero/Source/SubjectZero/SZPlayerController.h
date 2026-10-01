#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "Brushes/SlateColorBrush.h"
#include "SZPlayerController.generated.h"

class SEditableTextBox;
class SWidget;

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

private:
	void ShowMenu();
	void HideMenu();
	void BackToMenu();

	FReply OnHostClicked();
	FReply OnJoinClicked();
	FReply OnQuitClicked();

	TSharedPtr<SWidget> Menu;
	TSharedPtr<SEditableTextBox> AddressBox;
	FSlateColorBrush Background = FSlateColorBrush(FLinearColor(0.005f, 0.005f, 0.01f, 0.92f));
};
