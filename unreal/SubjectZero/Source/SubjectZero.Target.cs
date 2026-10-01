using UnrealBuildTool;

public class SubjectZeroTarget : TargetRules
{
	public SubjectZeroTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("SubjectZero");
	}
}
