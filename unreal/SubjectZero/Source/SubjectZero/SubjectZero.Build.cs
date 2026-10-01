using UnrealBuildTool;

public class SubjectZero : ModuleRules
{
	public SubjectZero(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core", "CoreUObject", "Engine", "InputCore",
			"Slate", "SlateCore",
			"Json", "JsonUtilities",
			"GeometryCore", "GeometryFramework", "GeometryScriptingCore",
		});
	}
}
