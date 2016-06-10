
tool

extends EditorPlugin

const editor_script = preload("res://addons/tileset_editor/editor.tscn")

var editor


#region virtual overrides

func clear(): editor._on_resource_btn(2) # New resource

func handles(object):
	return object extends preload("res://addons/tileset_editor/tileset.gd")

func edit(object):
	if object extends preload("res://addons/tileset_editor/tileset.gd"):
		editor.show()
		editor.reload(object)

# region constructors

func _init():
	editor = editor_script.instance()

func _ready():
	call_deferred("add_child", editor)
	editor.connect("export_requested", self, "_on_export_requested")
	

func _enter_tree():
	add_custom_type("TilesetInfo","Resource",load("res://addons/tileset_editor/tileset.gd"),load("res://addons/tileset_editor/icons/icon_tile_map.png"))

func _exit_tree():
	remove_custom_type("TilesetInfo")

# region functions

	
func _on_export_requested():
	print("TODO: export the tileset")
