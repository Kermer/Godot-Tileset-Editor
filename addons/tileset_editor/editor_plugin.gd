
tool

extends EditorPlugin

const editor_script = preload("res://addons/tileset_editor/editor.tscn")

var editor
onready var info_dialog = AcceptDialog.new()


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
	info_dialog.set_size(Vector2(500,300))
	add_child(info_dialog)

func _enter_tree():
	add_custom_type("TilesetInfo","Resource",load("res://addons/tileset_editor/tileset.gd"),load("res://addons/tileset_editor/icons/icon_tile_map.png"))

func _exit_tree():
	remove_custom_type("TilesetInfo")

# region functions

func _on_export_requested( path ):
	if editor.tileset.get("texture_count") == 0: # No textures
		alert("Add some textures first!")
		return
	var tileset = editor.tileset.generate_tileset()
	if tileset.get_last_unused_tile_id() == 0: # No tiles in tileset
		alert("You must select tiles which are going to be exported!")
		return
	# Finally export the tileset...
	var err = ResourceSaver.save(path,tileset)
	if err == OK: alert("Export succesful!")
	else: alert("Failed to export into selected file!\n\nError: "+str(err))

func alert(text,title="Alert!"):
	info_dialog.set_title(str(title))
	info_dialog.set_text(str(text))
	info_dialog.popup_centered()
