#include "SZPlayerController.h"

#include "Engine/Engine.h"
#include "Engine/GameViewportClient.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Styling/CoreStyle.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Input/SEditableTextBox.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/Text/STextBlock.h"

ASZPlayerController::ASZPlayerController()
{
}

void ASZPlayerController::BeginPlay()
{
	Super::BeginPlay();
	if (!IsLocalController())
	{
		return;
	}
	if (GetNetMode() == NM_Standalone)
	{
		ShowMenu();
	}
	else
	{
		SetInputMode(FInputModeGameOnly());
		bShowMouseCursor = false;
	}
}

void ASZPlayerController::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	HideMenu();
	Super::EndPlay(EndPlayReason);
}

void ASZPlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();
	InputComponent->BindAction(TEXT("BackToMenu"), IE_Pressed, this, &ASZPlayerController::BackToMenu);
}

namespace
{
	TSharedRef<SWidget> MenuButton(const FString& Label, FOnClicked OnClicked)
	{
		return SNew(SButton)
			.HAlign(HAlign_Center)
			.ContentPadding(FMargin(10.f, 8.f))
			.OnClicked(OnClicked)
			[
				SNew(STextBlock)
				.Text(FText::FromString(Label))
				.Font(FCoreStyle::GetDefaultFontStyle("Regular", 18))
			];
	}
}

void ASZPlayerController::ShowMenu()
{
	if (Menu.IsValid() || GEngine == nullptr || GEngine->GameViewport == nullptr)
	{
		return;
	}
	Menu = SNew(SBorder)
		.BorderImage(&Background)
		.HAlign(HAlign_Center)
		.VAlign(VAlign_Center)
		[
			SNew(SBox)
			.WidthOverride(440.f)
			[
				SNew(SVerticalBox)
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					SNew(STextBlock)
					.Text(FText::FromString(TEXT("SUBJECT ZERO")))
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 40))
					.ColorAndOpacity(FLinearColor(0.8f, 0.08f, 0.06f))
					.Justification(ETextJustify::Center)
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f, 0.f, 8.f, 24.f)
				[
					SNew(STextBlock)
					.Text(FText::FromString(TEXT("Chapter 1: The Surface  (Unreal test build)")))
					.Font(FCoreStyle::GetDefaultFontStyle("Regular", 14))
					.Justification(ETextJustify::Center)
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					MenuButton(TEXT("Host"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnHostClicked))
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f, 16.f, 8.f, 4.f)
				[
					SAssignNew(AddressBox, SEditableTextBox)
					.Text(FText::FromString(TEXT("127.0.0.1")))
					.Font(FCoreStyle::GetDefaultFontStyle("Regular", 16))
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					MenuButton(TEXT("Join"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnJoinClicked))
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f, 24.f, 8.f, 8.f)
				[
					MenuButton(TEXT("Quit"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnQuitClicked))
				]
			]
		];
	GEngine->GameViewport->AddViewportWidgetContent(Menu.ToSharedRef(), 10);
	bShowMouseCursor = true;
	SetInputMode(FInputModeUIOnly());
}

void ASZPlayerController::HideMenu()
{
	if (Menu.IsValid() && GEngine && GEngine->GameViewport)
	{
		GEngine->GameViewport->RemoveViewportWidgetContent(Menu.ToSharedRef());
	}
	Menu.Reset();
	AddressBox.Reset();
}

FReply ASZPlayerController::OnHostClicked()
{
	HideMenu();
	UGameplayStatics::OpenLevel(this, FName(*UGameplayStatics::GetCurrentLevelName(this, true)), true, TEXT("listen"));
	return FReply::Handled();
}

FReply ASZPlayerController::OnJoinClicked()
{
	const FString Address = AddressBox.IsValid() ? AddressBox->GetText().ToString().TrimStartAndEnd() : FString();
	if (!Address.IsEmpty())
	{
		HideMenu();
		ClientTravel(Address, TRAVEL_Absolute);
	}
	return FReply::Handled();
}

FReply ASZPlayerController::OnQuitClicked()
{
	UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, false);
	return FReply::Handled();
}

void ASZPlayerController::BackToMenu()
{
	if (GetNetMode() != NM_Standalone)
	{
		// Leave the game: reopen the level on our own, which shows the menu.
		UGameplayStatics::OpenLevel(this, FName(*UGameplayStatics::GetCurrentLevelName(this, true)), true);
	}
}
