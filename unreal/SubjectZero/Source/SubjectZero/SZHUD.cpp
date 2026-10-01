#include "SZHUD.h"

#include "SZCharacter.h"
#include "SZInteractable.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "Engine/Font.h"

void ASZHUD::DrawHUD()
{
	Super::DrawHUD();
	if (Canvas == nullptr || GetNetMode() == NM_Standalone)
	{
		return;  // the menu is showing
	}
	const float CX = Canvas->ClipX * 0.5f;
	const float CY = Canvas->ClipY * 0.5f;
	DrawRect(FLinearColor(1.f, 1.f, 1.f, 0.6f), CX - 2.f, CY - 2.f, 4.f, 4.f);

	UFont* Font = GEngine->GetMediumFont();
	const ASZCharacter* Me = Cast<ASZCharacter>(GetOwningPawn());
	if (Me == nullptr)
	{
		return;
	}
	if (Me->FocusedThing)
	{
		const FString Prompt = Me->FocusedThing->GetPrompt(Me);
		float W = 0.f, H = 0.f;
		GetTextSize(Prompt, W, H, Font, 1.2f);
		DrawText(Prompt, FLinearColor::White, CX - W * 0.5f, CY + 40.f, Font, 1.2f);
	}
	const FString Hint = FString::Printf(TEXT("[F] Flashlight %s    [Shift] Sprint    [Ctrl] Crouch    [Esc] Leave"),
		Me->IsFlashlightOn() ? TEXT("ON") : TEXT("off"));
	DrawText(Hint, FLinearColor(0.8f, 0.8f, 0.8f, 0.8f), 24.f, Canvas->ClipY - 40.f, Font, 1.f);
}
