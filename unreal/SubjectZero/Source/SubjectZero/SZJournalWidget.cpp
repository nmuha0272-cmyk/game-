#include "SZJournalWidget.h"
#include "SZLoreManager.h"
#include "SZChapterData.h"
#include "Components/Button.h"
#include "Components/TextBlock.h"
#include "Components/ListView.h"
#include "Components/Image.h"
#include "Components/WidgetSwitcher.h"

void USZJournalWidget::NativeConstruct()
{
	Super::NativeConstruct();
	SetupTabButtons();
}

void USZJournalWidget::InitializeJournal(USZLoreManager* InLoreManager)
{
	LoreManager = InLoreManager;
	RefreshJournal();
}

void USZJournalWidget::RefreshJournal()
{
	if (!LoreManager)
	{
		return;
	}

	UpdateProgressText();
	PopulateLoreList();
}

void USZJournalWidget::SetupTabButtons()
{
	if (TabFilesButton)
	{
		TabFilesButton->OnClicked.AddDynamic(this, &USZJournalWidget::OnTabFilesClicked);
	}
	if (TabTapesButton)
	{
		TabTapesButton->OnClicked.AddDynamic(this, &USZJournalWidget::OnTabTapesClicked);
	}
	if (TabPhotosButton)
	{
		TabPhotosButton->OnClicked.AddDynamic(this, &USZJournalWidget::OnTabPhotosClicked);
	}
	if (TabPersonalButton)
	{
		TabPersonalButton->OnClicked.AddDynamic(this, &USZJournalWidget::OnTabPersonalClicked);
	}
	if (LoreListView)
	{
		LoreListView->OnItemSelectionChanged().AddUObject(this, &USZJournalWidget::OnLoreEntrySelected);
	}
}

void USZJournalWidget::SelectTab(int32 TabIndex)
{
	CurrentTabIndex = FMath::Clamp(TabIndex, 0, 3);
	PopulateLoreList();
}

void USZJournalWidget::SelectLoreEntry(UObject* EntryObject)
{
	OnLoreEntrySelected(EntryObject);
}

void USZJournalWidget::OnTabFilesClicked() { SelectTab(0); }
void USZJournalWidget::OnTabTapesClicked() { SelectTab(1); }
void USZJournalWidget::OnTabPhotosClicked() { SelectTab(2); }
void USZJournalWidget::OnTabPersonalClicked() { SelectTab(3); }

void USZJournalWidget::PopulateLoreList()
{
	if (!LoreManager || !LoreListView)
	{
		return;
	}

	CurrentLoreEntries.Empty();
	TArray<FSZChapterLoreItem> AllLore = LoreManager->GetAllDiscoveredLore();

	for (const FSZChapterLoreItem& LoreItem : AllLore)
	{
		bool bShow = false;
		switch (CurrentTabIndex)
		{
			case 0: // Files
				bShow = true; // Show all for now, could filter by type
				break;
			case 1: // Tapes
				bShow = LoreItem.Title.ToString().Contains(TEXT("Tape")) || LoreItem.Title.ToString().Contains(TEXT("Recording"));
				break;
			case 2: // Photos
				bShow = LoreItem.Title.ToString().Contains(TEXT("Photo")) || LoreItem.Title.ToString().Contains(TEXT("Photograph"));
				break;
			case 3: // Personal
				bShow = LoreItem.OwnerCharacter != ESZCharacterID::None;
				break;
		}

		if (bShow)
		{
			// Create a wrapper object for the list view
			// In practice, you'd use a UObject wrapper or UDataTable row
			CurrentLoreEntries.Add(NewObject<UObject>(this)); // Placeholder
		}
	}

	LoreListView->SetListItems(CurrentLoreEntries);
}

void USZJournalWidget::OnLoreEntrySelected(UObject* EntryObject)
{
	if (!LoreManager)
	{
		return;
	}

	int32 Index = CurrentLoreEntries.IndexOfByKey(EntryObject);
	if (Index >= 0)
	{
		TArray<FSZChapterLoreItem> AllLore = LoreManager->GetAllDiscoveredLore();
		if (Index < AllLore.Num())
		{
			ShowLoreDetail(AllLore[Index]);
		}
	}
}

void USZJournalWidget::ShowLoreDetail(const FSZChapterLoreItem& LoreItem)
{
	if (DetailViewSwitcher)
	{
		DetailViewSwitcher->SetActiveWidgetIndex(0);
	}

	if (DetailTitleText)
	{
		DetailTitleText->SetText(LoreItem.Title);
	}

	if (DetailContentText)
	{
		DetailContentText->SetText(LoreItem.Content);
	}

	if (DetailOwnerText)
	{
		if (LoreItem.OwnerCharacter != ESZCharacterID::None)
		{
			FString OwnerName;
			switch (LoreItem.OwnerCharacter)
			{
				case ESZCharacterID::EliReyes: OwnerName = TEXT("The Son (Eli)"); break;
				case ESZCharacterID::NoraVance: OwnerName = TEXT("The Journalist (Nora)"); break;
				case ESZCharacterID::WalterKessler: OwnerName = TEXT("The Engineer (Walter)"); break;
				case ESZCharacterID::ColeBrennan: OwnerName = TEXT("The Guard (Cole)"); break;
				default: OwnerName = TEXT("Unknown"); break;
			}
			DetailOwnerText->SetText(FText::FromString(FString::Printf(TEXT("Personal Item: %s"), *OwnerName)));
			DetailOwnerText->SetVisibility(ESlateVisibility::Visible);
		}
		else
		{
			DetailOwnerText->SetVisibility(ESlateVisibility::Collapsed);
		}
	}
}

void USZJournalWidget::UpdateProgressText()
{
	if (!LoreManager || !ProgressText)
	{
		return;
	}

	int32 Discovered = LoreManager->GetDiscoveredLoreCount();
	int32 Total = LoreManager->GetTotalLoreCount();
	ProgressText->SetText(FText::FromString(FString::Printf(TEXT("Lore Discovered: %d / %d"), Discovered, Total)));
}