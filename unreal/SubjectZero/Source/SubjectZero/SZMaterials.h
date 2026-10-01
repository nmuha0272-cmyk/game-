#pragma once

#include "CoreMinimal.h"

class UMaterialInterface;

/**
 * Turns a material name from the level file ("concrete_wall", "#3a4030") into
 * an Unreal material.
 *  - If you made a material at Content/Materials/M_<name> (for example
 *    M_concrete_wall), that one is used. This is how real textures get in.
 *  - Otherwise it's Unreal's basic shape material in a matching color.
 */
namespace SZMaterials
{
	UMaterialInterface* Get(const FString& Name);
}
