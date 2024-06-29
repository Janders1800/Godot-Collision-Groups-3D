@tool
extends EditorPlugin


const SAVE_FILE : String = "res://collision_groups.data"
const DROPDOWN_OFFSET : int = 3


var dropdown := MenuButton.new()
var nodes : Array[CollisionObject3D]

var collisions : Array
var group_names : Array


func _enter_tree() -> void:
	get_editor_interface().get_selection().connect("selection_changed", selection_changed)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dropdown)
	dropdown.text = "Collision Group"
	dropdown.hide()
	dropdown.get_popup().connect("index_pressed", index_pressed)
	fill_dropdown()


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dropdown)


func selection_changed() -> void:
	nodes.clear()
	
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	for selection in selected:
		if selection is CollisionObject3D:
			nodes.append(selection)
			dropdown.show()
	
	if nodes.is_empty():
		dropdown.hide()


func index_pressed(index : int) -> void:
	# Add a new entry per collision setup
	if index == 0:
		add_group()
		return
	# Remove entry per selection collision coincidence
	if index == 1:
		remove_group()
		return
	
	# Assign masks to nodes
	for node in nodes:
		node.collision_layer = collisions[index - DROPDOWN_OFFSET].layer
		node.collision_mask = collisions[index - DROPDOWN_OFFSET].mask


func fill_dropdown() -> void:
	dropdown.get_popup().add_item("Add from selected")
	dropdown.get_popup().add_item("Remove from selected")
	dropdown.get_popup().add_separator()
	# Add saved groups to the menu
	load_data()


func add_group() -> void:
	for node in nodes:
		var layer := node.collision_layer
		var mask := node.collision_mask
		
		var c := {"layer": layer, "mask": mask}
		
		if not collisions.has(c):
			var layers_set := int_to_mask(c.layer)
			var masks_set := int_to_mask(c.mask)
			var name := "Layer: " + layers_set + "    Mask: " + masks_set
			
			collisions.append(c)
			group_names.append(name)
			dropdown.get_popup().add_item(name)
			save_data()


func remove_group() -> void:
	for node in nodes:
		var layer := node.collision_layer
		var mask := node.collision_mask
		
		var c := {"layer": layer, "mask": mask}
		
		if collisions.has(c):
			var i := collisions.find(c)
			collisions.remove_at(i)
			group_names.remove_at(i)
			dropdown.get_popup().remove_item(i + DROPDOWN_OFFSET)
			save_data()


func int_to_mask(number : int) -> String:
	var positions : Array
	var pos : int = 1
	while number > 0:
		if number & 1 == 1:
			positions.append(pos)
		number >>= 1
		pos += 1
	return str(positions)


func save_data() -> void:
	var file := FileAccess.open(SAVE_FILE,FileAccess.WRITE)
	if file:
		file.store_var(collisions)
		file.store_var(group_names)
		file.close()


func load_data() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		collisions = file.get_var()
		group_names = file.get_var()
		file.close()
		
		for name in group_names:
			dropdown.get_popup().add_item(name)
