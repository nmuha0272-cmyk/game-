class_name UnrealExport
extends Node
## Exports Godot items/crafting data to JSON for Unreal Engine integration.

import json

func export_items() -> String:
	var items_data := []
	for id in Items.INFO:
		var info := Items.INFO[id]
		var entry := {
			"id": id,
			"name": info.has("name") ? info.name : id,
			"description": info.has("description") ? info.description : "",
			"max_stack": info.has("max_stack") ? info.max_stack : 1,
			"category": info.has("category") ? info.category : "Misc"
		}
		items_data.append(entry)
	return to_json(items_data)

func export_recipes() -> String:
	var recipes_data := []
	var Crafting = load("res://scripts/items/crafting.gd")
	
	for recipe_id, recipe in Crafting.RECIPES:
		var ingredients := []
		for mat_id, count in recipe.ingredients:
			ingredients.append({"item_id": mat_id, "count": count})
		
		var entry := {
			"id": recipe_id,
			"name": recipe.has("name") ? recipe.name : recipe_id,
			"category": recipe.has("category") ? recipe.category : "Other",
			"craft_time": recipe.has("craft_time") ? recipe.craft_time : 0.0,
			"is_melee": recipe.has("is_melee") ? recipe.is_melee : false,
			"ingredients": ingredients,
			"output": recipe.output
		}
		recipes_data.append(entry)
	
	return to_json(recipes_data)

func export_inventory(inv) -> String:
	var quick := []
	var storage := []
	
	for i in Inventory.QUICK_SLOTS:
		var item := inv.get_quick(i)
		if not item.is_empty():
			quick.append({
				"id": item.has("id") ? item.id : "",
				"stack": item.has("stack") ? item.stack : 1
			})
	
	for i in inv.storage_count():
		var item := inv.get_storage(i)
		if not item.is_empty():
			storage.append({
				"id": item.has("id") ? item.id : "",
				"stack": item.has("stack") ? item.stack : 1
			})
	
	var state := {"quick_slots": quick, "storage_slots": storage}
	return to_json(state)

func export_game_state() -> String:
	var gs = load("res://scripts/autoload/game_state.gd")
	var unlocks := 0
	if gs.has("crafting_unlocks"):
		unlocks = gs.get("crafting_unlocks")
	else:
		unlocks = gs._team_unlocks
	
	var state := {"team_unlocks": unlocks}
	return to_json(state)

func to_json(data) -> String:
	var json := JSON.new()
	var ok := json.print(data)
	if ok:
		return json.print(data)
	return '{}'