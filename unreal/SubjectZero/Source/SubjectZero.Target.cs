using UnrealBuildTool;

public class SubjectZeroTarget : TargetRules
{
	public SubjectZeroTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
		ExtraModuleNames.Add("SubjectZero");
	}
}
