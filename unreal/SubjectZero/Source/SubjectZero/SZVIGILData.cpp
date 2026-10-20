#include "SZVIGILData.h"

USZVIGILData::USZVIGILData()
{
	OrganizationName = FText::FromString(TEXT("VIGIL"));
	Description = FText::FromString(TEXT("A secret organization formed by people who survived programs like BASTION. It takes in former guards, scientists, test-subject survivors, and family members — anyone with a connection to these experiments. VIGIL hunts down escaped creatures, contains or destroys them, and keeps watch over the families the government lied to."));
	Motto = FText::FromString(TEXT("We watch. We contain. We remember."));
	FoundingDate = FText::FromString(TEXT("1999 (after Deepwell sealing)"));
	
	KnownAgents = {
		FText::FromString(TEXT("Cole Brennan - Field Agent, Eli Reyes surveillance detail")),
		FText::FromString(TEXT("Unknown - Regional Director")),
		FText::FromString(TEXT("Unknown - Research Division"))
	};
	
	Objectives = {
		FText::FromString(TEXT("Hunt and contain escaped BASTION/ECHO subjects")),
		FText::FromString(TEXT("Monitor and protect families of test subjects")),
		FText::FromString(TEXT("Destroy all evidence of illegal government programs")),
		FText::FromString(TEXT("Prevent restart of super-soldier programs"))
	};
	
	Methods = {
		FText::FromString(TEXT("Covert surveillance and infiltration")),
		FText::FromString(TEXT("Creature tracking and neutralization")),
		FText::FromString(TEXT("Evidence seizure and destruction")),
		FText::FromString(TEXT("Disinformation and cover-up operations"))
	};
}