using UnrealBuildTool;

public class SubjectZeroEditorTarget : TargetRules
{
	public SubjectZeroEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.Latest;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("SubjectZero");
	}
}
