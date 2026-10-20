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
#include "Widgets/Views/SListView.h"
#include "SZChapterManager.h"
#include "SZChapterData.h"
#include "Engine/GameInstance.h"

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

	if (UGameInstance* GameInstance = GetGameInstance())
	{
		ChapterManager = GameInstance->GetSubsystem<USZChapterManager>();
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
	HideChapterSelectMenu();
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

	TSharedRef<STableRow<TSharedPtr<FSZChapterMenuEntry>>> MakeChapterListEntry(TSharedPtr<FSZChapterMenuEntry> Entry, const TSharedRef<STableViewBase>& OwnerTable)
	{
		return SNew(STableRow<TSharedPtr<FSZChapterMenuEntry>>, OwnerTable)
			.Padding(FMargin(8.f, 4.f))
			[
				SNew(SHorizontalBox)
				+ SHorizontalBox::Slot().FillWidth(1.f)
				[
					SNew(STextBlock)
					.Text(Entry->DisplayText)
					.Font(FCoreStyle::GetDefaultFontStyle(Entry->bIsCompleted ? "Bold" : "Regular", 16))
					.ColorAndOpacity(Entry->bIsAvailable ? FLinearColor::White : FLinearColor(0.5f, 0.5f, 0.5f))
				]
				+ SHorizontalBox::Slot().AutoWidth()
				[
					SNew(STextBlock)
					.Text(Entry->bIsCompleted ? FText::FromString(TEXT("[COMPLETED]")) : (Entry->bIsAvailable ? FText::FromString(TEXT("[AVAILABLE]")) : FText::FromString(TEXT("[LOCKED]"))))
					.Font(FCoreStyle::GetDefaultFontStyle("Regular", 12))
					.ColorAndOpacity(Entry->bIsCompleted ? FLinearColor::Green : (Entry->bIsAvailable ? FLinearColor::Yellow : FLinearColor::Red))
				]
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
					.Text(FText::FromString(TEXT("DEEPWELL")))
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 40))
					.ColorAndOpacity(FLinearColor(0.8f, 0.08f, 0.06f))
					.Justification(ETextJustify::Center)
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f, 0.f, 8.f, 24.f)
				[
					SNew(STextBlock)
					.Text(FText::FromString(TEXT("A Co-op Horror Game")))
					.Font(FCoreStyle::GetDefaultFontStyle("Regular", 14))
					.Justification(ETextJustify::Center)
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					MenuButton(TEXT("Select Chapter"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnChapterSelectClicked))
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					MenuButton(TEXT("Host Chapter 1"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnHostClicked))
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

void ASZPlayerController::ShowChapterSelectMenu()
{
	if (ChapterSelectMenu.IsValid() || GEngine == nullptr || GEngine->GameViewport == nullptr)
	{
		return;
	}

	RefreshChapterList();

	ChapterSelectMenu = SNew(SBorder)
		.BorderImage(&Background)
		.HAlign(HAlign_Center)
		.VAlign(VAlign_Center)
		[
			SNew(SBox)
			.WidthOverride(500.f)
			.HeightOverride(500.f)
			[
				SNew(SVerticalBox)
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					SNew(STextBlock)
					.Text(FText::FromString(TEXT("SELECT CHAPTER")))
					.Font(FCoreStyle::GetDefaultFontStyle("Bold", 32))
					.ColorAndOpacity(FLinearColor(0.8f, 0.08f, 0.06f))
					.Justification(ETextJustify::Center)
				]
				+ SVerticalBox::Slot().FillHeight(1.f).Padding(8.f)
				[
					SAssignNew(ChapterListView, SListView<TSharedPtr<FSZChapterMenuEntry>>)
					.ListItemsSource(&ChapterEntries)
					.OnGenerateRow_Lambda([](TSharedPtr<FSZChapterMenuEntry> Entry, const TSharedRef<STableViewBase>& OwnerTable)
					{
						return MakeChapterListEntry(Entry, OwnerTable);
					})
					.OnSelectionChanged_Lambda([this](TSharedPtr<FSZChapterMenuEntry> Entry, ESelectInfo::Type)
					{
						if (Entry.IsValid() && Entry->ChapterData.IsValid() && Entry->bIsAvailable)
						{
							OnChapterSelected(Entry->ChapterData.Get());
						}
					})
					.SelectionMode(ESelectionMode::Single)
				]
				+ SVerticalBox::Slot().AutoHeight().Padding(8.f)
				[
					MenuButton(TEXT("Back"), FOnClicked::CreateUObject(this, &ASZPlayerController::OnChapterSelectBackClicked))
				]
			]
		];
	GEngine->GameViewport->AddViewportWidgetContent(ChapterSelectMenu.ToSharedRef(), 11);
	bShowMouseCursor = true;
	SetInputMode(FInputModeUIOnly());
}

void ASZPlayerController::HideChapterSelectMenu()
{
	if (ChapterSelectMenu.IsValid() && GEngine && GEngine->GameViewport)
	{
		GEngine->GameViewport->RemoveViewportWidgetContent(ChapterSelectMenu.ToSharedRef());
	}
	ChapterSelectMenu.Reset();
	ChapterListView.Reset();
	ChapterEntries.Empty();
}

void ASZPlayerController::RefreshChapterList()
{
	ChapterEntries.Empty();

	if (!ChapterManager)
	{
		return;
	}

	TArray<USZChapterData*> AllChapters = ChapterManager->GetAllChapters();
	for (USZChapterData* ChapterData : AllChapters)
	{
		if (!ChapterData)
		{
			continue;
		}

		TSharedPtr<FSZChapterMenuEntry> Entry = MakeShared<FSZChapterMenuEntry>();
		Entry->ChapterData = ChapterData;
		Entry->DisplayText = FText::Format(FText::FromString(TEXT("Chapter {0}: {1}")), FText::AsNumber(ChapterData->GetChapterIndex()), ChapterData->DisplayName);
		Entry->bIsAvailable = (ChapterManager->GetChapterState(ChapterData->GetLevelName()) != ESZChapterState::Locked);
		Entry->bIsCompleted = (ChapterManager->GetChapterState(ChapterData->GetLevelName()) == ESZChapterState::Completed);
		ChapterEntries.Add(Entry);
	}

	if (ChapterListView.IsValid())
	{
		ChapterListView->RequestListRefresh();
	}
}

void ASZPlayerController::OnChapterSelected(USZChapterData* ChapterData)
{
	if (!ChapterData || !ChapterManager)
	{
		return;
	}

	HideChapterSelectMenu();
	HideMenu();

	if (ChapterManager->StartChapter(ChapterData->GetLevelName()))
	{
	}
}

FReply ASZPlayerController::OnChapterSelectClicked()
{
	HideMenu();
	ShowChapterSelectMenu();
	return FReply::Handled();
}

FReply ASZPlayerController::OnChapterSelectBackClicked()
{
	HideChapterSelectMenu();
	ShowMenu();
	return FReply::Handled();
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
		UGameplayStatics::OpenLevel(this, FName(*UGameplayStatics::GetCurrentLevelName(this, true)), true);
	}
}