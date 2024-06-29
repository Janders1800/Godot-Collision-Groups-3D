@tool
extends EditorPlugin


const SAVE_FILE : String = "res://collision_groups.data"
const DROPDOWN_OFFSET : int = 5


var undo_redo := get_undo_redo()

var dropdown := MenuButton.new()
var rename_popup := Popup.new()
var vBoxContainer := VBoxContainer.new()
var rename_select := MenuButton.new()
var line_edit := LineEdit.new()
var hBoxContainer := HBoxContainer.new()
var ok_button := Button.new()
var cancel_button := Button.new()

var nodes : Array[CollisionObject3D]
var collisions : Array
var group_names : Array

var new_name : String = ""
var rename_index : int = 0


func _enter_tree() -> void:
	get_editor_interface().get_selection().connect("selection_changed", selection_changed)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dropdown)
	dropdown.text = "Collision Group"
	dropdown.hide()
	dropdown.get_popup().connect("index_pressed", index_pressed)
	fill_dropdown()


func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dropdown)
	rename_popup.get_parent().remove_child(rename_popup)


func _ready() -> void:
	# Sets the rename popup
	get_editor_interface().get_base_control().add_child(rename_popup)
	rename_popup.connect("popup_hide", rename_popup_hide)
	rename_popup.title = "Rename collision group"
	rename_popup.size.x = 205
	rename_popup.add_child(vBoxContainer)
	vBoxContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
	vBoxContainer.add_child(rename_select)
	rename_select.get_popup().connect("index_pressed", rename_index_change)
	vBoxContainer.add_child(line_edit)
	line_edit.connect("text_submitted", line_edit_submitted)
	vBoxContainer.add_child(hBoxContainer)
	hBoxContainer.size_flags_horizontal = Control.SIZE_FILL
	hBoxContainer.size_flags_vertical = Control.SIZE_FILL
	hBoxContainer.add_child(ok_button)
	ok_button.custom_minimum_size = Vector2i(100, 30)
	ok_button.text = "OK"
	ok_button.connect("pressed", ok_button_pressed)
	hBoxContainer.add_child(cancel_button)
	cancel_button.custom_minimum_size = Vector2i(100, 30)
	cancel_button.text = "Cancel"
	cancel_button.connect("pressed", cancel_button_pressed)


func rename_popup_hide() -> void:
	line_edit.clear()
	rename_select.get_popup().clear(true)
	new_name = ""
	rename_index = 0


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
	match index:
		0:
			# Add a new entry per collision setup
			add_group()
			return
		1:
			# Remove entry per selection collision coincidence
			remove_group()
			return
		3:
			# Rename popup
			if not group_names.is_empty():
				rename_select.text = group_names[0]
				for name in group_names:
					rename_select.get_popup().add_item(name)
				rename_popup.popup_centered()
			else:
				print("No collision groups found")
			return
		_:
			# Assign masks to nodes
			undo_redo.create_action("Set collision group")
			for node in nodes:
				undo_redo.add_undo_property(node, "collision_layer", node.collision_layer)
				undo_redo.add_undo_property(node, "collision_mask", node.collision_mask)
				undo_redo.add_do_property(node, "collision_layer", collisions[index - DROPDOWN_OFFSET].layer)
				undo_redo.add_do_property(node, "collision_mask", collisions[index - DROPDOWN_OFFSET].mask)
			undo_redo.commit_action()


func fill_dropdown() -> void:
	dropdown.get_popup().add_item("Add from selected")
	dropdown.get_popup().add_item("Remove from selected")
	dropdown.get_popup().add_separator()
	dropdown.get_popup().add_item("Rename group...")
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


func rename_index_change(index : int) -> void:
	rename_select.text = group_names[index]
	rename_index = index


func line_edit_submitted(text : String) -> void:
	ok_button_pressed()


func ok_button_pressed() -> void:
	if line_edit.text.is_empty():
		print("The name field is empty!")
		return
	dropdown.get_popup().set_item_text(rename_index + DROPDOWN_OFFSET, line_edit.text)
	group_names[rename_index] = line_edit.text
	save_data()
	rename_popup.hide()


func cancel_button_pressed() -> void:
	rename_popup.hide()


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
