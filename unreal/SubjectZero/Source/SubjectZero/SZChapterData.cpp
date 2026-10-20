#include "SZChapterData.h"

bool USZChapterData::IsUnlocked(const TMap<FName, ESZChapterState>& ChapterStates) const
{
	if (ChapterIndex == 0)
	{
		return true;
	}

	for (const FName& RequiredChapter : RequiredCompletedChapters)
	{
		const ESZChapterState* State = ChapterStates.Find(RequiredChapter);
		if (State == nullptr || *State != ESZChapterState::Completed)
		{
			return false;
		}
	}

	return true;
}

TArray<FSZChapterLoreItem> USZChapterData::GetLoreForCharacter(ESZCharacterID CharacterID) const
{
	TArray<FSZChapterLoreItem> Result;
	for (const FSZChapterLoreItem& LoreItem : LoreItems)
	{
		if (LoreItem.OwnerCharacter == ESZCharacterID::None || LoreItem.OwnerCharacter == CharacterID)
		{
			Result.Add(LoreItem);
		}
	}
	return Result;
}