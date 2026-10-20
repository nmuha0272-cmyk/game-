#pragma once

#include "CoreMinimal.h"
#include "SZMonsterAIController.h"
#include "SZEchoAIController.generated.h"

USTRUCT(BlueprintType)
struct FSZMimickedPhrase
{
	GENERATED_BODY()

	UPROPERTY()
	FString Text;

	UPROPERTY()
	int32 OriginalPlayerId;

	UPROPERTY()
	float TimeRecorded;
};

/**
 * Echo (Chapter 4 and 6) - Absorbed voices and memories of volunteers.
 * Speaks most often in Daniel Reyes' voice. Hears everything.
 * Stretch goal: copies short phrases players have said to lure them away.
 * Stalks the team rather than attacking right away.
 */
UCLASS()
class SUBJECTZERO_API ASZEchoAIController : public ASZMonsterAIController
{
	GENERATED_BODY()

public:
	ASZEchoAIController();

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaTime) override;

	UFUNCTION(BlueprintCallable, Category = "Monster|Echo")
	void RecordPlayerPhrase(int32 PlayerId, const FString& Phrase);

	UFUNCTION(BlueprintCallable, Category = "Monster|Echo")
	void MimicPhraseAtLocation(FVector Location, int32 TargetPlayerId);

	UFUNCTION(BlueprintCallable, Category = "Monster|Echo")
	void SpeakAsDaniel(FVector Location, FName DialogueID);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Echo")
	void OnMimicryUsed(const FString& Phrase, FVector Location);

	UFUNCTION(BlueprintNativeEvent, Category = "Monster|Echo")
	void OnDanielVoiceLinePlayed(FName DialogueID);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Echo")
	bool bCanMimic = true; // Stretch goal - can be disabled in settings

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Echo")
	float MimicCooldown = 30.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Echo")
	float StalkDistance = 3000.f; // Stalks from distance

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Echo")
	float AttackTriggerDistance = 500.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Monster|Echo")
	TArray<FName> DanielVoiceLines;

	UPROPERTY()
	TArray<FSZMimickedPhrase> MimickedPhrases;

	UPROPERTY()
	float MimicTimer = 0.f;

	UPROPERTY()
	bool bIsStalking = true;
};