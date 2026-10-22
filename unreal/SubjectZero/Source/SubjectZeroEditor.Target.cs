using UnrealBuildTool;

public class SubjectZeroEditorTarget : TargetRules
{
	public SubjectZeroEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
		ExtraModuleNames.Add("SubjectZero");
	}
}
