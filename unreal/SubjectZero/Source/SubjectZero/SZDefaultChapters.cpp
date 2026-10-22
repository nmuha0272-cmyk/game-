#include "SZDefaultChapters.h"
#include "SZChapterManager.h"
#include "SZChapterData.h"
#include "SZCharacterData.h"
#include "SZDefaultCharacters.h"
#include "Engine/Engine.h"

void USZDefaultChapters::RegisterDefaultChapters(USZChapterManager* ChapterManager)
{
	if (!ChapterManager)
	{
		UE_LOG(LogTemp, Error, TEXT("DefaultChapters: ChapterManager is null"));
		return;
	}

	// Get character data for spotlight references
	TMap<ESZCharacterID, TObjectPtr<USZCharacterData>> CharacterRegistry;
	USZDefaultCharacters::RegisterDefaultCharacters(CharacterRegistry);

	// Helper lambda to create lore items
	auto MakeLoreItem = [](FName ID, FText Title, FText Content, ESZCharacterID Owner, bool bRequired, FName Room)
	{
		FSZChapterLoreItem Item;
		Item.LoreID = ID;
		Item.Title = Title;
		Item.Content = Content;
		Item.OwnerCharacter = Owner;
		Item.bIsRequired = bRequired;
		Item.RoomLocation = Room;
		return Item;
	};

	// Chapter 1: The Surface
	{
		USZChapterData* Chapter1 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter1_TheSurface"));
		Chapter1->DisplayName = FText::FromString(TEXT("Chapter 1: The Surface"));
		Chapter1->Description = FText::FromString(TEXT("Break into the abandoned Blackwater Weather Station. Find the hidden elevator and descend into Deepwell. The Goliath stalks the maintenance tunnels."));
		Chapter1->LevelName = FName("Chapter1_TheSurface");
		Chapter1->ChapterIndex = 1;
		Chapter1->EstimatedPlayTimeMinutes = 45.f;
		Chapter1->RequiredCompletedChapters = {};
		Chapter1->SpotlightCharacter = CharacterRegistry.FindRef(ESZCharacterID::NoraVance);
		Chapter1->MainMonster = ESZMonsterType::Goliath;
		Chapter1->MonsterDescription = FText::FromString(TEXT("Subject 7, a young soldier who volunteered for the G-7 serum. His bones never stopped growing. He was moved to the maintenance tunnels where he crawls on all fours. Sensitive to light (weak to Camera Flash)."));
		Chapter1->ChapterGoal = FText::FromString(TEXT("Break into the weather station, find the hidden elevator, learn the controls"));
		Chapter1->ChapterEnding = FText::FromString(TEXT("Elevator cable snaps, trapping the team below"));
		Chapter1->SpotlightCharacterArc = FText::FromString(TEXT("Nora discovers her informant was tracking G-7 and gets photographic proof of the experiments"));
		
		Chapter1->LoreItems = {
			MakeLoreItem(FName("Lore_WeatherStation_Sign"), FText::FromString(TEXT("No Trespassing Sign")), FText::FromString(TEXT("Rusted sign: \"Property of U.S. Government — No Trespassing\"")), ESZCharacterID::None, false, FName("WeatherStationExterior")),
			MakeLoreItem(FName("Lore_InformantsCar"), FText::FromString(TEXT("Informant's Notebook")), FText::FromString(TEXT("Her informant's abandoned car. Inside is his notebook with the words \"G-7\" and \"they're still down there\" circled")), ESZCharacterID::NoraVance, false, FName("WeatherStationExterior")),
			MakeLoreItem(FName("Lore_DragMarks"), FText::FromString(TEXT("Fresh Drag Marks")), FText::FromString(TEXT("Fresh drag marks leading to the station, proving something still moves around here")), ESZCharacterID::NoraVance, false, FName("WeatherStationExterior")),
			MakeLoreItem(FName("Lore_StaffDirectory"), FText::FromString(TEXT("Staff Directory")), FText::FromString(TEXT("Staff directory. One name is scratched out (the Engineer's)")), ESZCharacterID::None, false, FName("StationOffice")),
			MakeLoreItem(FName("Lore_EngineerDesk"), FText::FromString(TEXT("Engineer's Desk")), FText::FromString(TEXT("His old desk nameplate and coffee mug, still sitting where he left them")), ESZCharacterID::WalterKessler, false, FName("StationOffice")),
			MakeLoreItem(FName("Lore_ArticlesBoard"), FText::FromString(TEXT("Surveillance Board")), FText::FromString(TEXT("A corkboard with the Journalist's own newspaper articles pinned to it, some dated 2014. Someone has been here recently, and they've been watching her")), ESZCharacterID::NoraVance, false, FName("StationOffice")),
			MakeLoreItem(FName("Lore_Tape1_DirectorWelcome"), FText::FromString(TEXT("Director's Welcome Tape")), FText::FromString(TEXT("The facility director welcoming new \"volunteers\" and promising they'll serve their country. The keypad code for the Split Code puzzle is mentioned at the end")), ESZCharacterID::None, true, FName("StationOffice")),
			MakeLoreItem(FName("Lore_Poster_StrongerSoldiers"), FText::FromString(TEXT("Propaganda Poster")), FText::FromString(TEXT("\"STRONGER SOLDIERS. SAFER NATION.\" with a smiling soldier")), ESZCharacterID::None, false, FName("HiddenStairwell")),
			MakeLoreItem(FName("Lore_GuardRoster"), FText::FromString(TEXT("Guard Duty Roster")), FText::FromString(TEXT("A dusty clipboard with the guard duty roster for the night of the sealing. Cole's name is on it")), ESZCharacterID::ColeBrennan, false, FName("HiddenStairwell")),
			MakeLoreItem(FName("Lore_TallyMarks"), FText::FromString(TEXT("Tally Marks")), FText::FromString(TEXT("Hundreds of tally marks scratched into the wall")), ESZCharacterID::None, false, FName("HiddenStairwell")),
			MakeLoreItem(FName("Lore_Subject7MedicalLog"), FText::FromString(TEXT("Subject 7 Medical Log")), FText::FromString(TEXT("Subject 7 medical log, showing his height growing each week until staff note he \"no longer fits in his cell\"")), ESZCharacterID::None, false, FName("MaintenanceTunnels")),
			MakeLoreItem(FName("Lore_HeightChart"), FText::FromString(TEXT("Height Chart")), FText::FromString(TEXT("A height chart painted on the wall with marks climbing higher and higher until they go past the ceiling")), ESZCharacterID::None, false, FName("MaintenanceTunnels")),
			MakeLoreItem(FName("Lore_Volunteer14ID"), FText::FromString(TEXT("Volunteer 14 ID Card")), FText::FromString(TEXT("His parent's volunteer ID card: \"Volunteer 14,\" stamped TRANSFERRED — PROJECT ECHO")), ESZCharacterID::EliReyes, false, FName("MaintenanceTunnels")),
			MakeLoreItem(FName("Lore_CrayonDrawing"), FText::FromString(TEXT("Crayon Drawing")), FText::FromString(TEXT("A crayon drawing he made as a child and mailed to his parent, taped to the inside of a locker")), ESZCharacterID::EliReyes, false, FName("MaintenanceTunnels")),
			MakeLoreItem(FName("Lore_GoliathPhoto"), FText::FromString(TEXT("Goliath Photograph")), FText::FromString(TEXT("Journalist photographs Goliath. This photo is proof of the experiments and completes her Chapter 1 story")), ESZCharacterID::NoraVance, false, FName("MaintenanceTunnels")),
			MakeLoreItem(FName("Lore_GoliathChamberBlueprint"), FText::FromString(TEXT("Goliath Chamber Blueprint")), FText::FromString(TEXT("The Goliath Chamber blueprint with the Engineer's signature")), ESZCharacterID::WalterKessler, false, FName("ElevatorRoom")),
			MakeLoreItem(FName("Lore_ContainmentOrder"), FText::FromString(TEXT("Level B Containment Order")), FText::FromString(TEXT("Signed and stamped, with Cole listed as the guard responsible. A VIGIL symbol is scratched into the corner. Needed to learn the elevator override")), ESZCharacterID::ColeBrennan, true, FName("ElevatorRoom")),
			MakeLoreItem(FName("Lore_Tape2_Panic"), FText::FromString(TEXT("Scientist's Final Recording")), FText::FromString(TEXT("A panicked scientist's final recording as the alarms go off and the doors begin to seal")), ESZCharacterID::None, false, FName("ElevatorRoom")),
			MakeLoreItem(FName("Lore_ElevatorPanel"), FText::FromString(TEXT("Elevator Control Panel")), FText::FromString(TEXT("Shows \"LEVEL B — SEALED BY ORDER\" as the team rides down, right before the cable snaps")), ESZCharacterID::None, false, FName("ElevatorRoom")),
		};
		
		ChapterManager->RegisterChapterData(Chapter1);
	}

	// Chapter 2: Power Station
	{
		USZChapterData* Chapter2 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter2_PowerStation"));
		Chapter2->DisplayName = FText::FromString(TEXT("Chapter 2: Power Station"));
		Chapter2->Description = FText::FromString(TEXT("Restore three generators to power the facility. The Conduit, fused with the facility's wiring, hunts those who restore the current. Walter's past catches up to him."));
		Chapter2->LevelName = FName("Chapter2_PowerStation");
		Chapter2->ChapterIndex = 2;
		Chapter2->EstimatedPlayTimeMinutes = 60.f;
		Chapter2->RequiredCompletedChapters = { FName("Chapter1_TheSurface") };
		Chapter2->bGrantsPouchUpgrade = true;
		Chapter2->SpotlightCharacter = CharacterRegistry.FindRef(ESZCharacterID::WalterKessler);
		Chapter2->MainMonster = ESZMonsterType::Conduit;
		Chapter2->MonsterDescription = FText::FromString(TEXT("A test subject fused with the facility's machinery, attracted to electricity. Restoring power wakes it up. Hears walkie-talkie signals from much farther away."));
		Chapter2->ChapterGoal = FText::FromString(TEXT("Restore three generators to power the facility"));
		Chapter2->ChapterEnding = FText::FromString(TEXT("Clues reveal Walter built the Goliath Chamber"));
		Chapter2->SpotlightCharacterArc = FText::FromString(TEXT("Walter confronts his role in creating the Goliath Chamber and finds his old field manual with notes from Daniel Reyes"));
		Chapter2->UnlockedItems = { FName("PouchUpgrade_Chapter2"), FName("Revolver") }; // Revolver for Chapter 3
		
		Chapter2->LoreItems = {
			MakeLoreItem(FName("Lore_GeneratorLogs"), FText::FromString(TEXT("Generator Maintenance Logs")), FText::FromString(TEXT("Logs showing the three generators that need restoration")), ESZCharacterID::None, true, FName("PowerStationEntrance")),
			MakeLoreItem(FName("Lore_ConduitOrigin"), FText::FromString(TEXT("Conduit Origin File")), FText::FromString(TEXT("File describing the experiment that fused a subject with the facility's electrical systems")), ESZCharacterID::None, false, FName("GeneratorRoom1")),
			MakeLoreItem(FName("Lore_WalterFieldManual"), FText::FromString(TEXT("Daniel's Field Manual")), FText::FromString(TEXT("Daniel Reyes' Army field manual with handwritten notes in the margins, including a note written after he arrived at Deepwell")), ESZCharacterID::WalterKessler, false, FName("ControlRoom")),
			MakeLoreItem(FName("Lore_WalterBlueprint"), FText::FromString(TEXT("Goliath Chamber Schematics")), FText::FromString(TEXT("Original schematics with Walter's signature and annotations about the serum delivery system")), ESZCharacterID::WalterKessler, false, FName("EngineeringOffice")),
			MakeLoreItem(FName("Lore_AshbyMemo"), FText::FromString(TEXT("Dr. Ashby Memo")), FText::FromString(TEXT("Internal memo from Dr. Harold Ashby authorizing continued power to Level B despite the sealing order")), ESZCharacterID::None, false, FName("AdminOffice")),
		};
		
		ChapterManager->RegisterChapterData(Chapter2);
	}

	// Chapter 3: Level B
	{
		USZChapterData* Chapter3 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter3_LevelB"));
		Chapter3->DisplayName = FText::FromString(TEXT("Chapter 3: Level B"));
		Chapter3->Description = FText::FromString(TEXT("Navigate the sealed holding cells in total silence. The Sealed — blind, hearing-enhanced subjects — patrol the corridors. Cole must face what he did the night he sealed these doors."));
		Chapter3->LevelName = FName("Chapter3_LevelB");
		Chapter3->ChapterIndex = 3;
		Chapter3->EstimatedPlayTimeMinutes = 60.f;
		Chapter3->RequiredCompletedChapters = { FName("Chapter2_PowerStation") };
		Chapter3->bGrantsPouchUpgrade = true;
		Chapter3->SpotlightCharacter = CharacterRegistry.FindRef(ESZCharacterID::ColeBrennan);
		Chapter3->MainMonster = ESZMonsterType::TheSealed;
		Chapter3->MonsterDescription = FText::FromString(TEXT("The people Cole sealed in, now changed. Blind, so they hunt ONLY by sound. Their hearing range is doubled. Total silence is the only safe option. They still knock on doors."));
		Chapter3->ChapterGoal = FText::FromString(TEXT("Get through the sealed holding cells in total silence"));
		Chapter3->ChapterEnding = FText::FromString(TEXT("Cole is revealed as a VIGIL agent, and the team learns he sealed Eli's father inside"));
		Chapter3->SpotlightCharacterArc = FText::FromString(TEXT("Cole's secret is exposed: he's a VIGIL agent who sealed Daniel Reyes in Level B. The team must decide if they can trust him."));
		Chapter3->UnlockedItems = { FName("PouchUpgrade_Chapter3"), FName("GuardRevolver") };
		
		Chapter3->LoreItems = {
			MakeLoreItem(FName("Lore_SealedOrigin"), FText::FromString(TEXT("The Sealed Origin")), FText::FromString(TEXT("Files describing the volunteers who were locked in Level B when the facility was sealed")), ESZCharacterID::None, true, FName("LevelBEntrance")),
			MakeLoreItem(FName("Lore_SealingOrder"), FText::FromString(TEXT("Sealing Order - Full Version")), FText::FromString(TEXT("The complete order to seal Level B \"regardless of personnel inside\" with Cole's signature and VIGIL notation")), ESZCharacterID::ColeBrennan, true, FName("SecurityOffice")),
			MakeLoreItem(FName("Lore_VIGILFile_Cole"), FText::FromString(TEXT("VIGIL Personnel File: Cole Brennan")), FText::FromString(TEXT("VIGIL file showing Cole's recruitment, his assignment to watch Eli, and his orders to destroy Deepwell")), ESZCharacterID::ColeBrennan, true, FName("VIGILCache")),
			MakeLoreItem(FName("Lore_DanielCell"), FText::FromString(TEXT("Volunteer 14's Cell")), FText::FromString(TEXT("Daniel Reyes' cell in Level B, showing signs of struggle and a final message scratched into the wall")), ESZCharacterID::EliReyes, true, FName("HoldingCell14")),
			MakeLoreItem(FName("Lore_SealedBehavior"), FText::FromString(TEXT("Sealed Behavioral Notes")), FText::FromString(TEXT("Scientific observations of the Sealed's enhanced hearing and blindness adaptation")), ESZCharacterID::None, false, FName("ObservationRoom")),
			MakeLoreItem(FName("Lore_KnockingDoors"), FText::FromString(TEXT("Door Knocking Phenomenon")), FText::FromString(TEXT("Audio log describing how the Sealed still knock on doors, as if waiting for someone to answer")), ESZCharacterID::None, false, FName("CorridorB")),
		};
		
		ChapterManager->RegisterChapterData(Chapter3);
	}

	// Chapter 4: Project ECHO
	{
		USZChapterData* Chapter4 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter4_ProjectECHO"));
		Chapter4->DisplayName = FText::FromString(TEXT("Chapter 4: Project ECHO"));
		Chapter4->Description = FText::FromString(TEXT("Find Eli's father's cell and the ECHO laboratory. Echo — the result of Project ECHO, who absorbed the volunteers' voices and memories and speaks in Daniel's voice — stalks the team."));
		Chapter4->LevelName = FName("Chapter4_ProjectECHO");
		Chapter4->ChapterIndex = 4;
		Chapter4->EstimatedPlayTimeMinutes = 75.f;
		Chapter4->RequiredCompletedChapters = { FName("Chapter3_LevelB") };
		Chapter4->bGrantsPouchUpgrade = true;
		Chapter4->SpotlightCharacter = CharacterRegistry.FindRef(ESZCharacterID::EliReyes);
		Chapter4->MainMonster = ESZMonsterType::Echo;
		Chapter4->MonsterDescription = FText::FromString(TEXT("The final result of Project ECHO. Absorbed the voices and memories of the volunteers, and speaks most often in Daniel's voice. Hears everything and copies short phrases players have said to lure them away. Stalks rather than attacking right away."));
		Chapter4->ChapterGoal = FText::FromString(TEXT("Find Eli's father's cell and the ECHO lab"));
		Chapter4->ChapterEnding = FText::FromString(TEXT("Eli finds his father's remains. Echo speaks in Daniel's voice, then escapes deeper into Deepwell"));
		Chapter4->SpotlightCharacterArc = FText::FromString(TEXT("Eli finds his father's remains in the ECHO lab with the other half of the dog tags. Echo calls him by his childhood nickname and taps Morse code. Eli must accept his father is gone."));
		Chapter4->UnlockedItems = { FName("PouchUpgrade_Chapter4"), FName("Shotgun") };
		
		Chapter4->LoreItems = {
			MakeLoreItem(FName("Lore_ECHOProject"), FText::FromString(TEXT("Project ECHO Overview")), FText::FromString(TEXT("Files detailing Project ECHO — the secret branch that continued after BASTION officially ended")), ESZCharacterID::None, true, FName("ECHOLobby")),
			MakeLoreItem(FName("Lore_VoiceAbsorption"), FText::FromString(TEXT("Voice Absorption Research")), FText::FromString(TEXT("Research notes on how Echo absorbs and replicates voices and memories of test subjects")), ESZCharacterID::None, false, FName("ResearchLab")),
			MakeLoreItem(FName("Lore_DanielRemains"), FText::FromString(TEXT("Daniel Reyes' Remains")), FText::FromString(TEXT("Eli finds his father's remains in the ECHO lab, with the other half of the dog tags")), ESZCharacterID::EliReyes, true, FName("ECHOLab")),
			MakeLoreItem(FName("Lore_MorseCodeWall"), FText::FromString(TEXT("Morse Code on Wall")), FText::FromString(TEXT("Echo taps Morse code on a wall the way Daniel did at the kitchen table — a message only Eli would recognize")), ESZCharacterID::EliReyes, true, FName("ECHOCorridor")),
			MakeLoreItem(FName("Lore_EchoEscape"), FText::FromString(TEXT("Echo's Escape")), FText::FromString(TEXT("Echo speaks in Daniel's voice one last time, then escapes deeper into Deepwell")), ESZCharacterID::None, false, FName("ECHOExit")),
		};
		
		ChapterManager->RegisterChapterData(Chapter4);
	}

	// Chapter 5: Still Running
	{
		USZChapterData* Chapter5 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter5_StillRunning"));
		Chapter5->DisplayName = FText::FromString(TEXT("Chapter 5: Still Running"));
		Chapter5->Description = FText::FromString(TEXT("Discover a hidden modern lab beneath the old facility. The experiments never stopped. Dr. Lillian Ashby has restarted them, and she's been watching. The Warden — a modern super-soldier — hunts the team."));
		Chapter5->LevelName = FName("Chapter5_StillRunning");
		Chapter5->ChapterIndex = 5;
		Chapter5->EstimatedPlayTimeMinutes = 75.f;
		Chapter5->RequiredCompletedChapters = { FName("Chapter4_ProjectECHO") };
		Chapter5->bGrantsPouchUpgrade = true;
		Chapter5->SpotlightCharacter = CharacterRegistry.FindRef(ESZCharacterID::NoraVance); // Whole team, but Nora's investigation pays off
		Chapter5->MainMonster = ESZMonsterType::TheWarden;
		Chapter5->MonsterDescription = FText::FromString(TEXT("Ashby's newest, successful modern super-soldier in tactical gear. Faster and smarter than the old experiments: opens doors, uses flashlights, sets traps. Wears a modern headset that picks up walkie-talkie chatter and remembers where he last heard players."));
		Chapter5->ChapterGoal = FText::FromString(TEXT("Discover a hidden modern lab under the old one"));
		Chapter5->ChapterEnding = FText::FromString(TEXT("The experiments never stopped. Dr. Lillian Ashby has restarted them, and she's been watching Nora"));
		Chapter5->SpotlightCharacterArc = FText::FromString(TEXT("Nora discovers Dr. Lillian Ashby has been monitoring her investigation for years. The modern lab reveals the program evolved with modern technology."));
		Chapter5->UnlockedItems = { FName("PouchUpgrade_Chapter5"), FName("ModernAssaultRifle"), FName("TacticalGear") };
		
		Chapter5->LoreItems = {
			MakeLoreItem(FName("Lore_ModernLab"), FText::FromString(TEXT("Modern Laboratory Discovery")), FText::FromString(TEXT("A hidden modern lab beneath the 1960s facility with advanced equipment")), ESZCharacterID::None, true, FName("ModernLabEntrance")),
			MakeLoreItem(FName("Lore_LillianAshby"), FText::FromString(TEXT("Dr. Lillian Ashby Profile")), FText::FromString(TEXT("Harold Ashby's daughter, secretly restarted the program in 2009. Main villain of Chapters 5-6.")), ESZCharacterID::None, true, FName("DirectorOffice")),
			MakeLoreItem(FName("Lore_WardenProject"), FText::FromString(TEXT("The Warden Project")), FText::FromString(TEXT("Files on the successful modern super-soldier program using refined G-7 derivatives")), ESZCharacterID::None, false, FName("WardenChamber")),
			MakeLoreItem(FName("Lore_SurveillanceNora"), FText::FromString(TEXT("Surveillance on Nora")), FText::FromString(TEXT("Evidence that Lillian Ashby has been watching Nora Vance's investigation for years")), ESZCharacterID::NoraVance, true, FName("SurveillanceRoom")),
			MakeLoreItem(FName("Lore_ModernTech"), FText::FromString(TEXT("Modern Equipment Logs")), FText::FromString(TEXT("Logs showing modern weapons, comms, and monitoring equipment being supplied to Deepwell")), ESZCharacterID::None, false, FName("Armory")),
		};
		
		ChapterManager->RegisterChapterData(Chapter5);
	}

	// Chapter 6: The Way Out
	{
		USZChapterData* Chapter6 = NewObject<USZChapterData>(ChapterManager, TEXT("Chapter6_TheWayOut"));
		Chapter6->DisplayName = FText::FromString(TEXT("Chapter 6: The Way Out"));
		Chapter6->Description = FText::FromString(TEXT("Escape as Ashby floods Deepwell to erase the evidence, while VIGIL orders Cole to let it all sink. The Warden and Echo both hunt the team. Eli must choose: destroy Echo and let his father's voice finally rest, or let VIGIL take it, keeping the last piece of him alive."));
		Chapter6->LevelName = FName("Chapter6_TheWayOut");
		Chapter6->ChapterIndex = 6;
		Chapter6->EstimatedPlayTimeMinutes = 90.f;
		Chapter6->RequiredCompletedChapters = { FName("Chapter5_StillRunning") };
		Chapter6->SpotlightCharacter = nullptr; // Whole team
		Chapter6->MainMonster = ESZMonsterType::TheWarden; // Both Warden and Echo
		Chapter6->MonsterDescription = FText::FromString(TEXT("The Warden hunts the team during the escape while Echo appears at key moments, using Daniel's voice to try to separate Eli from the team. Ashby floods the facility. VIGIL orders Cole to let it sink."));
		Chapter6->ChapterGoal = FText::FromString(TEXT("Escape as Ashby floods Deepwell to erase the evidence"));
		Chapter6->ChapterEnding = FText::FromString(TEXT("Eli must choose: destroy Echo and let his father's voice finally rest, or let VIGIL take it. Cole chooses between VIGIL and his promise. The team only escapes if everyone works together."));
		Chapter6->SpotlightCharacterArc = FText::FromString(TEXT("Final confrontation: Eli's choice about Echo, Cole's choice between VIGIL and his promise to Daniel, and the team's escape from the flooding facility."));
		
		Chapter6->LoreItems = {
			MakeLoreItem(FName("Lore_FloodProtocol"), FText::FromString(TEXT("Flood Protocol")), FText::FromString(TEXT("Ashby's order to flood Deepwell to erase all evidence of the restarted program")), ESZCharacterID::None, true, FName("ControlCenter")),
			MakeLoreItem(FName("Lore_VIGILFinalOrders"), FText::FromString(TEXT("VIGIL Final Orders")), FText::FromString(TEXT("VIGIL command ordering Cole to ensure Deepwell is destroyed with all evidence")), ESZCharacterID::ColeBrennan, true, FName("VIGILComms")),
			MakeLoreItem(FName("Lore_EchoFinalChoice"), FText::FromString(TEXT("Echo's Final Plea")), FText::FromString(TEXT("Echo, in Daniel's voice, asks Eli to let VIGIL take him — preserving the last piece of his father")), ESZCharacterID::EliReyes, true, FName("ECHOCore")),
			MakeLoreItem(FName("Lore_EscapeRoute"), FText::FromString(TEXT("Emergency Escape Route")), FText::FromString(TEXT("The only way out as the facility floods — requires all four characters' abilities")), ESZCharacterID::None, true, FName("EscapeRoute")),
			MakeLoreItem(FName("Lore_Aftermath"), FText::FromString(TEXT("Post-Game Report")), FText::FromString(TEXT("The aftermath varies based on Eli and Cole's choices")), ESZCharacterID::None, false, FName("SurfaceExit")),
		};
		
		ChapterManager->RegisterChapterData(Chapter6);
	}

	UE_LOG(LogTemp, Log, TEXT("DefaultChapters: Registered 6 chapters for Deepwell with full lore data"));
}