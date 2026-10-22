#include "SZVoiceChatManager.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"

void USZVoiceChatManager::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	
	// Default settings
	VoiceSettings.ChatMode = ESZVoiceChatMode::OpenMic;
	VoiceSettings.MicrophoneSensitivity = 1.0f;
	VoiceSettings.VoiceDetectionThreshold = 0.1f;
	VoiceSettings.bEnableVoiceDetection = true;
	VoiceSettings.bEnableProximityChat = true;
	VoiceSettings.ProximityMaxDistance = 1000.f;
	VoiceSettings.WhisperRadius = 300.f;
	VoiceSettings.NormalTalkRadius = 1000.f;
	VoiceSettings.YellRadius = 2500.f;
	VoiceSettings.WallOcclusionFactor = 0.3f;
}

void USZVoiceChatManager::Deinitialize()
{
	WalkieTalkiePairs.Empty();
	ConnectedPlayerIds.Empty();
	Super::Deinitialize();
}

void USZVoiceChatManager::SetVoiceSettings(const FSZVoiceSettings& NewSettings)
{
	VoiceSettings = NewSettings;
}

FSZVoiceSettings USZVoiceChatManager::GetVoiceSettings() const
{
	return VoiceSettings;
}

void USZVoiceChatManager::SetPushToTalkPressed(bool bPressed)
{
	bPushToTalkPressed = bPressed;
}

void USZVoiceChatManager::OnMicrophoneDataReceived(const TArray<uint8>& AudioData, float VolumeLevel)
{
	if (!VoiceSettings.bEnableVoiceDetection)
	{
		return;
	}

	// Check push-to-talk
	if (VoiceSettings.ChatMode == ESZVoiceChatMode::PushToTalk && !bPushToTalkPressed)
	{
		return;
	}

	// Check volume threshold
	if (VolumeLevel < VoiceSettings.VoiceDetectionThreshold)
	{
		return;
	}

	// Get speaker location (would come from player character in practice)
	FVector SpeakerLocation = FVector::ZeroVector;
	if (APlayerController* PC = GetWorld()->GetFirstPlayerController())
	{
		if (APawn* Pawn = PC->GetPawn())
		{
			SpeakerLocation = Pawn->GetActorLocation();
		}
	}

	ProcessVoiceVolume(VolumeLevel, SpeakerLocation);
	
	// Broadcast to nearby players
	if (VoiceSettings.bEnableProximityChat)
	{
		BroadcastVoiceToNearbyPlayers(SpeakerLocation, AudioData, VolumeLevel);
	}
}

void USZVoiceChatManager::SendVoiceToPlayer(int32 TargetPlayerId, const TArray<uint8>& AudioData)
{
	OnVoiceReceived.Broadcast(TargetPlayerId, AudioData);
}

void USZVoiceChatManager::BroadcastVoiceToNearbyPlayers(FVector SpeakerLocation, const TArray<uint8>& AudioData, float VolumeLevel)
{
	// In a real implementation, this would:
	// 1. Find all players within ProximityMaxDistance
	// 2. Apply distance attenuation
	// 3. Apply wall occlusion
	// 4. Send audio to each player with appropriate volume
	
	// For now, broadcast to all connected players (placeholder)
	for (int32 PlayerId : ConnectedPlayerIds)
	{
		OnVoiceReceived.Broadcast(PlayerId, AudioData);
	}
}

void USZVoiceChatManager::RegisterWalkieTalkiePair(int32 PlayerA, int32 PlayerB)
{
	WalkieTalkiePairs.Add(PlayerA, PlayerB);
	WalkieTalkiePairs.Add(PlayerB, PlayerA);
}

void USZVoiceChatManager::UnregisterWalkieTalkiePair(int32 PlayerA, int32 PlayerB)
{
	WalkieTalkiePairs.Remove(PlayerA);
	WalkieTalkiePairs.Remove(PlayerB);
}

bool USZVoiceChatManager::ArePlayersOnWalkieTalkie(int32 PlayerA, int32 PlayerB) const
{
	const int32* PairedPlayer = WalkieTalkiePairs.Find(PlayerA);
	return PairedPlayer && *PairedPlayer == PlayerB;
}

void USZVoiceChatManager::SendWalkieTalkieVoice(int32 SpeakerPlayerId, const TArray<uint8>& AudioData, float VolumeLevel)
{
	const int32* ListenerId = WalkieTalkiePairs.Find(SpeakerPlayerId);
	if (ListenerId)
	{
		// Voice plays from listener's walkie-talkie speaker (creates noise at listener's location)
		FVector ListenerLocation = FVector::ZeroVector;
		if (APlayerController* PC = GetWorld()->GetFirstPlayerController())
		{
			if (APawn* Pawn = PC->GetPawn())
			{
				ListenerLocation = Pawn->GetActorLocation();
			}
		}

		// Notify monsters of noise at listener's location (walkie-talkie danger!)
		NotifyMonstersOfNoise(ListenerLocation, CalculateNoiseRadius(GetCurrentVolumeLevel(VolumeLevel)), SpeakerPlayerId);

		// Send audio to listener
		OnWalkieTalkieVoiceReceived.Broadcast(*ListenerId, AudioData);
	}
}

void USZVoiceChatManager::SendQuickChatMessage(int32 PlayerId, FName MessageID)
{
	// Quick chat messages also create noise
	FVector PlayerLocation = FVector::ZeroVector;
	if (APlayerController* PC = GetWorld()->GetFirstPlayerController())
	{
		if (APawn* Pawn = PC->GetPawn())
		{
			PlayerLocation = Pawn->GetActorLocation();
		}
	}

	// Quick chat creates "normal talk" level noise
	NotifyMonstersOfNoise(PlayerLocation, VoiceSettings.NormalTalkRadius, PlayerId);

	// TODO: Send quick chat message to nearby players
}

ESZVoiceVolumeLevel USZVoiceChatManager::GetCurrentVolumeLevel(float MicVolume) const
{
	float NormalizedVolume = MicVolume * VoiceSettings.MicrophoneSensitivity;
	
	if (NormalizedVolume < VoiceSettings.VoiceDetectionThreshold)
	{
		return ESZVoiceVolumeLevel::Silent;
	}
	else if (NormalizedVolume < 0.3f)
	{
		return ESZVoiceVolumeLevel::Whisper;
	}
	else if (NormalizedVolume < 0.7f)
	{
		return ESZVoiceVolumeLevel::Normal;
	}
	else
	{
		return ESZVoiceVolumeLevel::Yell;
	}
}

float USZVoiceChatManager::CalculateNoiseRadius(ESZVoiceVolumeLevel VolumeLevel) const
{
	switch (VolumeLevel)
	{
		case ESZVoiceVolumeLevel::Whisper:
			return VoiceSettings.WhisperRadius;
		case ESZVoiceVolumeLevel::Normal:
			return VoiceSettings.NormalTalkRadius;
		case ESZVoiceVolumeLevel::Yell:
			return VoiceSettings.YellRadius;
		default:
			return 0.f;
	}
}

void USZVoiceChatManager::ProcessVoiceVolume(float VolumeLevel, FVector SpeakerLocation)
{
	ESZVoiceVolumeLevel VolumeEnum = GetCurrentVolumeLevel(VolumeLevel);
	float NoiseRadius = CalculateNoiseRadius(VolumeEnum);
	
	if (NoiseRadius > 0.f)
	{
		NotifyMonstersOfNoise(SpeakerLocation, NoiseRadius, 0); // PlayerId would be passed in real impl
	}
}

void USZVoiceChatManager::NotifyMonstersOfNoise(FVector Location, float Radius, int32 PlayerId)
{
	// Broadcast noise event for monster AI to hear
	OnVoiceNoiseEvent.Broadcast(Location, Radius, PlayerId);
}