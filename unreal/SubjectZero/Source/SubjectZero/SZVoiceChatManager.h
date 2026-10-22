#pragma once

#include "CoreMinimal.h"
#include "Engine/GameInstanceSubsystem.h"
#include "SZVoiceChatManager.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnVoiceNoiseEvent, FVector, NoiseLocation, float, NoiseRadius, int32, InstigatorPlayerId);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnVoiceTransmission, int32, SpeakerPlayerId, const TArray<uint8>&, AudioData);

UENUM(BlueprintType)
enum class ESZVoiceChatMode : uint8
{
	OpenMic,
	PushToTalk
};

UENUM(BlueprintType)
enum class ESZVoiceVolumeLevel : uint8
{
	Silent,
	Whisper,
	Normal,
	Yell
};

USTRUCT(BlueprintType)
struct FSZVoiceSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	ESZVoiceChatMode ChatMode = ESZVoiceChatMode::OpenMic;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float MicrophoneSensitivity = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float VoiceDetectionThreshold = 0.1f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	bool bEnableVoiceDetection = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	bool bEnableProximityChat = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float ProximityMaxDistance = 1000.f; // 10 meters in cm

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float WhisperRadius = 300.f; // 3 meters

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float NormalTalkRadius = 1000.f; // 10 meters

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float YellRadius = 2500.f; // 25 meters

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Voice")
	float WallOcclusionFactor = 0.3f;
};

/**
 * Manages proximity voice chat and voice detection for monster AI.
 * This is a signature feature: monsters can hear player voices.
 */
UCLASS(BlueprintType, Blueprintable)
class SUBJECTZERO_API USZVoiceChatManager : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void Deinitialize() override;

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	void SetVoiceSettings(const FSZVoiceSettings& NewSettings);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	FSZVoiceSettings GetVoiceSettings() const;

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	void SetPushToTalkPressed(bool bPressed);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	void OnMicrophoneDataReceived(const TArray<uint8>& AudioData, float VolumeLevel);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	void SendVoiceToPlayer(int32 TargetPlayerId, const TArray<uint8>& AudioData);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat")
	void BroadcastVoiceToNearbyPlayers(FVector SpeakerLocation, const TArray<uint8>& AudioData, float VolumeLevel);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|WalkieTalkie")
	void RegisterWalkieTalkiePair(int32 PlayerA, int32 PlayerB);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|WalkieTalkie")
	void UnregisterWalkieTalkiePair(int32 PlayerA, int32 PlayerB);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|WalkieTalkie")
	bool ArePlayersOnWalkieTalkie(int32 PlayerA, int32 PlayerB) const;

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|WalkieTalkie")
	void SendWalkieTalkieVoice(int32 SpeakerPlayerId, const TArray<uint8>& AudioData, float VolumeLevel);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|QuickChat")
	void SendQuickChatMessage(int32 PlayerId, FName MessageID);

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|Noise")
	ESZVoiceVolumeLevel GetCurrentVolumeLevel(float MicVolume) const;

	UFUNCTION(BlueprintCallable, Category = "VoiceChat|Noise")
	float CalculateNoiseRadius(ESZVoiceVolumeLevel VolumeLevel) const;

	UPROPERTY(BlueprintAssignable, Category = "VoiceChat|Events")
	FOnVoiceNoiseEvent OnVoiceNoiseEvent;

	UPROPERTY(BlueprintAssignable, Category = "VoiceChat|Events")
	FOnVoiceTransmission OnVoiceReceived;

	UPROPERTY(BlueprintAssignable, Category = "VoiceChat|Events")
	FOnVoiceTransmission OnWalkieTalkieVoiceReceived;

protected:
	UPROPERTY()
	FSZVoiceSettings VoiceSettings;

	UPROPERTY()
	bool bPushToTalkPressed = false;

	UPROPERTY()
	TMap<int32, int32> WalkieTalkiePairs; // PlayerA -> PlayerB

	UPROPERTY()
	TArray<int32> ConnectedPlayerIds;

	void ProcessVoiceVolume(float VolumeLevel, FVector SpeakerLocation);
	void NotifyMonstersOfNoise(FVector Location, float Radius, int32 PlayerId);
};