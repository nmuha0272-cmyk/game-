#include "SZDefaultCharacters.h"
#include "SZCharacterData.h"
#include "Engine/Engine.h"

void USZDefaultCharacters::RegisterDefaultCharacters(TMap<ESZCharacterID, TObjectPtr<USZCharacterData>>& OutCharacterRegistry)
{
	// Eli Reyes (The Son) - Tracker
	{
		USZCharacterData* Eli = NewObject<USZCharacterData>(GetTransientPackage(), TEXT("Character_EliReyes"));
		Eli->CharacterID = ESZCharacterID::EliReyes;
		Eli->CharacterName = FText::FromString(TEXT("Eli Reyes"));
		Eli->Title = FText::FromString(TEXT("The Son"));
		Eli->Age = 21;
		Eli->Role = ESZCharacterRole::Tracker;
		Eli->HeldItemName = FText::FromString(TEXT("Parent's Dog Tags"));
		Eli->StartingInventorySlots = 4;
		Eli->BaseWalkSpeed = 350.f;
		Eli->BaseSprintSpeed = 600.f;
		Eli->SprintStaminaDrainRate = 20.f;
		Eli->SprintStaminaRegenRate = 15.f;

		Eli->Backstory = FText::FromString(TEXT(
			"When Eli was little, his father, Sgt. Daniel Reyes, turned everything into "
			"\"soldier training\": morning push-ups, running drills, standing at attention, "
			"tapping out Morse code on the kitchen table, and reading maps. To 5-year-old "
			"Eli it was a game. Then, in 1999, his father left for \"a special assignment\" "
			"and never came home. The Army told the family he died in a training accident. "
			"There was a closed casket, a folded flag, and one of his dog tags, which Eli "
			"has carried ever since. Eli never believed the story. Nobody would tell him "
			"where the accident happened.\n\n"
			"His father is dead when the game starts, and Eli knows it. He isn't going to "
			"Deepwell to save him. He's going to find out the truth and bring his father home. "
			"Eli held on to the only thing his father left him: the training. He kept practicing "
			"with his dad's old Army field manual, full of handwritten notes in the margins. "
			"At 18 he joined the Army Reserve, hoping that being a soldier would help him find "
			"out what happened. At 21, he finds a lead in his father's old letters that points "
			"to the Blackwater Weather Station, and he skips the semester to follow it.\n\n"
			"Unbeknownst to Eli, he has been watched his entire life. VIGIL — a secret "
			"organization formed by survivors of programs like BASTION — assigned Cole Brennan "
			"to monitor Eli from a distance. Cole was at the back of Daniel's funeral. He was "
			"there when Eli joined the Army Reserve. Every major moment of Eli's life had a "
			"silent guardian. But VIGIL's interest wasn't purely protective — they were also "
			"monitoring Eli as the son of Volunteer 14, watching for any signs of genetic "
			"anomalies from the G-7 serum his father was injected with.\n\n"
			"In Chapter 3, Eli suffers a catastrophic injury — his leg is severed by a trap "
			"in Level B. As the team races to save him, the truth crashes down: Cole reveals "
			"he's VIGIL, that he sealed Eli's father in Level B, and that VIGIL has been "
			"tracking Eli his whole life not just to protect him, but because Eli himself may "
			"carry the dormant G-7 genetic markers. His father wasn't just a volunteer — he was "
			"one of the successful ones, and Eli is the proof that the experiment continues "
			"through bloodline."
		));

		Eli->Motivation = FText::FromString(TEXT("Find the truth about his father's fate, survive the revelation that he's been monitored his whole life, and decide what he is — a son, a soldier, or an experiment."));

		// Active Ability: Sense
		Eli->ActiveAbility.AbilityTag = FGameplayTag::RequestGameplayTag(FName("Ability.Sense"));
		Eli->ActiveAbility.DisplayName = FText::FromString(TEXT("Sense"));
		Eli->ActiveAbility.Description = FText::FromString(TEXT("Hold to see nearby monsters glow through walls for 3 seconds. 20 second cooldown."));
		Eli->ActiveAbility.CooldownSeconds = 20.f;
		Eli->ActiveAbility.DurationSeconds = 3.f;

		// Passive: Military Training
		FSZPassiveAbility MilitaryTraining;
		MilitaryTraining.PassiveTag = FGameplayTag::RequestGameplayTag(FName("Passive.MilitaryTraining"));
		MilitaryTraining.DisplayName = FText::FromString(TEXT("Military Training"));
		MilitaryTraining.Description = FText::FromString(TEXT("Steadier aim and faster reloads than everyone except Cole. Can read Morse code and military maps without a translation sheet."));
		Eli->PassiveAbilities.Add(MilitaryTraining);

		// Passive: G-7 Bloodline (hidden, revealed in Chapter 3)
		FSZPassiveAbility G7Bloodline;
		G7Bloodline.PassiveTag = FGameplayTag::RequestGameplayTag(FName("Passive.G7Bloodline"));
		G7Bloodline.DisplayName = FText::FromString(TEXT("G-7 Bloodline (Dormant)"));
		G7Bloodline.Description = FText::FromString(TEXT("Carries dormant G-7 genetic markers from his father. May manifest unexpected resilience or mutations under extreme stress. [HIDDEN - Revealed Chapter 3]"));
		Eli->PassiveAbilities.Add(G7Bloodline);

		OutCharacterRegistry.Add(ESZCharacterID::EliReyes, Eli);
	}

	// Nora Vance (The Journalist) - Stunner/Lore
	{
		USZCharacterData* Nora = NewObject<USZCharacterData>(GetTransientPackage(), TEXT("Character_NoraVance"));
		Nora->CharacterID = ESZCharacterID::NoraVance;
		Nora->CharacterName = FText::FromString(TEXT("Nora Vance"));
		Nora->Title = FText::FromString(TEXT("The Journalist"));
		Nora->Age = 35;
		Nora->Role = ESZCharacterRole::Stunner;
		Nora->HeldItemName = FText::FromString(TEXT("Digital Camera with External Flash"));
		Nora->StartingInventorySlots = 4;
		Nora->BaseWalkSpeed = 350.f;
		Nora->BaseSprintSpeed = 600.f;
		Nora->SprintStaminaDrainRate = 20.f;
		Nora->SprintStaminaRegenRate = 15.f;

		Nora->Backstory = FText::FromString(TEXT(
			"Nora Vance is an investigative journalist who has been chasing the story of "
			"Project BASTION for years. Her informant inside the program vanished under "
			"mysterious circumstances, leaving behind only fragmented notes about something "
			"called \"G-7.\" She's determined to expose the truth about what happened at "
			"Deepwell, both for her missing source and for the public's right to know. "
			"She sees this as the story that will define her career.\n\n"
			"In Chapter 5, Nora discovers she hasn't just been investigating the story — "
			"she's been the story. Dr. Lillian Ashby has been watching Nora for years, "
			"using her investigation to locate Deepwell. Nora's missing informant didn't "
			"vanish — he was taken by Ashby's people. Nora's pursuit of the truth has been "
			"manipulated from the start."
		));

		Nora->Motivation = FText::FromString(TEXT("Expose Project BASTION, find her informant, and discover she's been a pawn in a larger game."));

		// Active Ability: Camera Flash
		Nora->ActiveAbility.AbilityTag = FGameplayTag::RequestGameplayTag(FName("Ability.CameraFlash"));
		Nora->ActiveAbility.DisplayName = FText::FromString(TEXT("Camera Flash"));
		Nora->ActiveAbility.Description = FText::FromString(TEXT("Stuns a monster in front of her for 2 seconds. 15 second cooldown. Photographing evidence unlocks lore entries."));
		Nora->ActiveAbility.CooldownSeconds = 15.f;
		Nora->ActiveAbility.DurationSeconds = 2.f;

		OutCharacterRegistry.Add(ESZCharacterID::NoraVance, Nora);
	}

	// Walter Kessler (The Engineer) - Fixer
	{
		USZCharacterData* Walter = NewObject<USZCharacterData>(GetTransientPackage(), TEXT("Character_WalterKessler"));
		Walter->CharacterID = ESZCharacterID::WalterKessler;
		Walter->CharacterName = FText::FromString(TEXT("Walter Kessler"));
		Walter->Title = FText::FromString(TEXT("The Engineer"));
		Walter->Age = 60;
		Walter->Role = ESZCharacterRole::Fixer;
		Walter->HeldItemName = FText::FromString(TEXT("Wrench"));
		Walter->StartingInventorySlots = 4;
		Walter->BaseWalkSpeed = 300.f; // Slower due to age
		Walter->BaseSprintSpeed = 500.f;
		Walter->SprintStaminaDrainRate = 25.f;
		Walter->SprintStaminaRegenRate = 10.f;

		Walter->Backstory = FText::FromString(TEXT(
			"Walter Kessler designed the Goliath Chamber — the machine that delivered the "
			"G-7 serum to test subjects. He believed he was serving his country, creating "
			"stronger soldiers to keep the peace. He didn't know the full extent of what the "
			"program would become, or that his work would be used to create monsters. Now, "
			"decades later, he's returned to undo what he built — and to hide the fact that "
			"he built it at all. His signature is on the blueprints, and the weight of that "
			"responsibility drives him forward.\n\n"
			"In Chapter 2, Walter confronts his legacy when the team finds his original "
			"schematics and discovers he knew more about the serum's effects than he admitted. "
			"He also finds Daniel Reyes' field manual with a note written after Daniel arrived "
			"at Deepwell — proving Daniel survived the initial experiments and was moved to "
			"Project ECHO."
		));

		Walter->Motivation = FText::FromString(TEXT("Undo what he built, atone for his role, and learn if his work created the monster that killed Daniel Reyes."));

		// Active Ability: Repair
		Walter->ActiveAbility.AbilityTag = FGameplayTag::RequestGameplayTag(FName("Ability.Repair"));
		Walter->ActiveAbility.DisplayName = FText::FromString(TEXT("Repair"));
		Walter->ActiveAbility.Description = FText::FromString(TEXT("Hold to fix generators, elevators, broken panels, and hack locked security doors. Only he can do this."));
		Walter->ActiveAbility.CooldownSeconds = 0.f; // No cooldown, but takes time
		Walter->ActiveAbility.DurationSeconds = 0.f; // Variable duration

		OutCharacterRegistry.Add(ESZCharacterID::WalterKessler, Walter);
	}

	// Cole Brennan (The Guard) - Protector
	{
		USZCharacterData* Cole = NewObject<USZCharacterData>(GetTransientPackage(), TEXT("Character_ColeBrennan"));
		Cole->CharacterID = ESZCharacterID::ColeBrennan;
		Cole->CharacterName = FText::FromString(TEXT("Cole Brennan"));
		Cole->Title = FText::FromString(TEXT("The Guard"));
		Cole->Age = 35;
		Cole->Role = ESZCharacterRole::Protector;
		Cole->HeldItemName = FText::FromString(TEXT("Heavy Flashlight"));
		Cole->StartingInventorySlots = 4;
		Cole->BaseWalkSpeed = 320.f; // Heavier gear
		Cole->BaseSprintSpeed = 550.f;
		Cole->SprintStaminaDrainRate = 15.f; // Better stamina management
		Cole->SprintStaminaRegenRate = 20.f;

		Cole->Backstory = FText::FromString(TEXT(
			"In 1999, Cole was a 20-year-old guard at Deepwell. He got to know Volunteer 14, "
			"Daniel Reyes, who showed him photos of his little boy and made Cole promise "
			"something: \"If anything happens to me, look out for Eli.\" Weeks later, the "
			"experiments went wrong and Cole received the order to seal Level B \"regardless "
			"of personnel inside.\" Daniel was on the other side. Cole followed the order.\n\n"
			"The government buried the facility and the truth. Cole was quietly discharged "
			"and fell apart, until VIGIL found him. VIGIL is a secret organization formed by "
			"people who survived programs like BASTION. It takes in former guards, scientists, "
			"test-subject survivors, and family members — anyone with a connection to these "
			"experiments. VIGIL hunts down escaped creatures, contains or destroys them, and "
			"keeps watch over the families the government lied to.\n\n"
			"Cole asked VIGIL for one assignment: Eli. For 16 years he's watched from a "
			"distance — a silent mentor, a ghost in the periphery. He was at the back of "
			"Daniel's funeral. He was there when Eli joined the Army Reserve. When VIGIL "
			"picked up signs that someone had reactivated Deepwell, Cole saw that Eli had "
			"found the same lead, and he showed up to \"help\" before Eli could go in alone. "
			"At first he tells the team he's a former soldier who knows the facility. He hides "
			"two things: that he's a VIGIL agent, and that he sealed Daniel inside.\n\n"
			"The mentor relationship is real — Cole genuinely cares for Eli, taught him "
			"survival skills through letters sent anonymously, intervened when Eli got in "
			"trouble. But it's built on a foundation of lies. In Chapter 3, when Eli loses "
			"his leg in a containment trap, Cole has to carry him to safety while confessing "
			"everything: the sealing, the VIGIL surveillance, the fact that VIGIL sees Eli "
			"as a potential carrier of the G-7 gene. The betrayal and the genuine care "
			"coexist — the central tragedy of their relationship."
		));

		Cole->Motivation = FText::FromString(TEXT("Keep his promise to Daniel to protect Eli, confess the truth when Eli is injured, and choose between VIGIL's orders and his promise to a dead man."));

		// Active Ability: Strength
		Cole->ActiveAbility.AbilityTag = FGameplayTag::RequestGameplayTag(FName("Ability.Strength"));
		Cole->ActiveAbility.DisplayName = FText::FromString(TEXT("Strength"));
		Cole->ActiveAbility.Description = FText::FromString(TEXT("Hold doors shut against monsters, move heavy objects, build barricades, carry a downed teammate. Moves slower and makes more noise."));
		Cole->ActiveAbility.CooldownSeconds = 0.f;
		Cole->ActiveAbility.DurationSeconds = 0.f;

		// Passive: VIGIL Training
		FSZPassiveAbility VIGILTraining;
		VIGILTraining.PassiveTag = FGameplayTag::RequestGameplayTag(FName("Passive.VIGILTraining"));
		VIGILTraining.DisplayName = FText::FromString(TEXT("VIGIL Training"));
		VIGILTraining.Description = FText::FromString(TEXT("Longer stuns on monsters. Can inspect a monster for a few seconds to reveal its weak point to the whole team."));
		Cole->PassiveAbilities.Add(VIGILTraining);

		// Passive: Silent Guardian (mentor relationship with Eli)
		FSZPassiveAbility SilentGuardian;
		SilentGuardian.PassiveTag = FGameplayTag::RequestGameplayTag(FName("Passive.SilentGuardian"));
		SilentGuardian.DisplayName = FText::FromString(TEXT("Silent Guardian"));
		SilentGuardian.Description = FText::FromString(TEXT("Has watched over Eli for 16 years. Gains bonus to reviving Eli and carrying Eli. If Eli is downed, Cole's speed while carrying him is increased. [Revealed Chapter 3]"));
		Cole->PassiveAbilities.Add(SilentGuardian);

		OutCharacterRegistry.Add(ESZCharacterID::ColeBrennan, Cole);
	}

	UE_LOG(LogTemp, Log, TEXT("DefaultCharacters: Registered 4 characters for Deepwell with expanded story"));
}