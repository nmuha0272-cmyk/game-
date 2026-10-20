#include "SZEchoAIController.h"
#include "SZVoiceChatManager.h"
#include "Engine/World.h"
#include "TimerManager.h"

ASZEchoAIController::ASZEchoAIController()
{
	HearingRangeMultiplier = 2.0f; // Hears everything
	SightRange = 2500.f;
	SightAngle = 120.f;
	bIsBlind = false;
	bHearsWalkieTalkieFromFar = true;
	WalkieTalkieHearingMultiplier = 2.0f;
	SearchDuration = 20.f;
	StunDuration = 1.5f; // Harder to stun
}

void ASZEchoAIController::BeginPlay()
{
	Super::BeginPlay();
	
	UE_LOG(LogTemp, Log, TEXT("Echo spawned - Hears everything, can mimic voices (if enabled), stalks team. Daniel voice lines: %d"), DanielVoiceLines.Num());
	
	bIsStalking = true;
	MimicTimer = 0.f;
}

void ASZEchoAIController::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (bCanMimic)
	{
		MimicTimer += DeltaTime;
	}

	// Stalking behavior - maintain distance, don't attack immediately
	if (bIsStalking && GetPawn())
	{
		// Logic to follow team at StalkDistance would go here
	}
}

void ASZEchoAIController::RecordPlayerPhrase(int32 PlayerId, const FString& Phrase)
{
	if (!bCanMimic || Phrase.IsEmpty())
	{
		return;
	}

	FSZMimickedPhrase NewPhrase;
	NewPhrase.Text = Phrase;
	NewPhrase.OriginalPlayerId = PlayerId;
	NewPhrase.TimeRecorded = GetWorld()->GetTimeSeconds();

	MimickedPhrases.Add(NewPhrase);

	// Limit stored phrases
	if (MimickedPhrases.Num() > 20)
	{
		MimickedPhrases.RemoveAt(0);
	}

	UE_LOG(LogTemp, Log, TEXT("Echo recorded phrase from player %d: %s"), PlayerId, *Phrase);
}

void ASZEchoAIController::MimicPhraseAtLocation(FVector Location, int32 TargetPlayerId)
{
	if (!bCanMimic || MimickedPhrases.Num() == 0 || MimicTimer < MimicCooldown)
	{
		return;
	}

	// Pick a random recorded phrase
	const FSZMimickedPhrase& Phrase = MimickedPhrases[FMath::RandRange(0, MimickedPhrases.Num() - 1)];
	
	// Play the phrase at the location (would use audio system)
	OnMimicryUsed(Phrase.Text, Location);
	
	// This creates a noise event at the mimic location
	FSZNoiseEvent NoiseEvent;
	NoiseEvent.Location = Location;
	NoiseEvent.Radius = 1500.f; // Mimicry is loud
	NoiseEvent.InstigatorPlayerId = -1; // Echo's ID
	NoiseEvent.TimeStamp = GetWorld()->GetTimeSeconds();
	NoiseEvent.NoiseType = FGameplayTag::RequestGameplayTag(FName("Noise.EchoMimicry"));

	OnNoiseHeard(NoiseEvent);

	MimicTimer = 0.f;
}

void ASZEchoAIController::SpeakAsDaniel(FVector Location, FName DialogueID)
{
	if (DanielVoiceLines.Contains(DialogueID))
	{
		OnDanielVoiceLinePlayed(DialogueID);
		
		// Daniel's voice also creates noise
		FSZNoiseEvent NoiseEvent;
		NoiseEvent.Location = Location;
		NoiseEvent.Radius = 2000.f;
		NoiseEvent.InstigatorPlayerId = -1;
		NoiseEvent.TimeStamp = GetWorld()->GetTimeSeconds();
		NoiseEvent.NoiseType = FGameplayTag::RequestGameplayTag(FName("Noise.EchoDanielVoice"));

		OnNoiseHeard(NoiseEvent);
	}
}

void ASZEchoAIController::OnMimicryUsed_Implementation(const FString& Phrase, FVector Location)
{
	// Blueprint override - play audio, trigger events
}

void ASZEchoAIController::OnDanielVoiceLinePlayed_Implementation(FName DialogueID)
{
	// Blueprint override - play Daniel voice line
}