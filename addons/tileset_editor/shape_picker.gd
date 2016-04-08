tool

extends WindowDialog

export(NodePath) var name_path
export(NodePath) var scene_tree_path
export(NodePath) var collision_path
export(NodePath) var collision_poly_path
export(NodePath) var occluder_path
export(NodePath) var navpoly_path
export(NodePath) var viewport_path
export(NodePath) var light_anim_path
export(NodePath) var modulate_canvas_path
export(NodePath) var light_path

# region variables

var shape_name = "" setget set_shape_name,get_shape_name

onready var name_edit = get_node(name_path)
onready var scene_tree = get_node(scene_tree_path)
onready var collision_node = get_node(collision_path)
onready var collision_poly_node = get_node(collision_poly_path)
onready var occluder_node = get_node(occluder_path)
onready var navpoly_node = get_node(navpoly_path)
var file_dialog # Used to get a PackedScene

var scene_root

var shape #stores a reference to the selected shape, if any

var shape_icons = [
load("res://addons/tileset_editor/icons/icon_collision_shape_2d.png"),
load("res://addons/tileset_editor/icons/icon_collision_polygon_2d.png"),
load("res://addons/tileset_editor/icons/icon_light_occluder_2d.png"),
load("res://addons/tileset_editor/icons/icon_navigation_polygon_instance.png")
]

var switch_icons = [
load("res://addons/tileset_editor/icons/toggle_off.png"),
load("res://addons/tileset_editor/icons/toggle_on.png")
]

# region signals

signal packed_scene_selected

# region getters and setters

func set_shape_name(val):
	name_edit.set_text(val)

func get_shape_name():
	return name_edit.get_text()

# region constructors

func _init():
	file_dialog = EditorFileDialog.new()
	file_dialog.set_size(Vector2(700,500))

func _ready():
	call_deferred("add_child", file_dialog)
	file_dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
	file_dialog.set_mode(file_dialog.MODE_OPEN_FILE)
	for ext in ResourceSaver.get_recognized_extensions(PackedScene.new()):
		file_dialog.add_filter("*."+ext)
	file_dialog.connect("file_selected",self,"_on_file_selected")
	scene_tree.set_columns(2)
	scene_tree.set_column_min_width( 0, 340)
	scene_tree.set_column_min_width( 1, 70)
	scene_tree.connect("cell_selected",self,"_on_item_selected")
	scene_tree.connect("button_pressed",self,"_on_button_pressed")

func import():
	self.shape_name = ""
	file_dialog.set_title("Load Shape from...")
	file_dialog.popup_centered()
	yield(self,"packed_scene_selected")
	scene_tree.clear()
	if scene_root != null:
		var root = scene_tree.create_item()
		root.set_text(0, scene_root.get_name())
		var is_shape = false
		if scene_root extends CollisionShape2D:
			is_shape=true
			root.set_icon(0, shape_icons[0])
		elif scene_root extends CollisionPolygon2D:
			is_shape=true
			root.set_icon(0, shape_icons[1])
		elif scene_root extends LightOccluder2D:
			is_shape=true
			root.set_icon(0, shape_icons[2])
		elif scene_root extends NavigationPolygonInstance:
			is_shape=true
			root.set_icon(0, shape_icons[3])
		root.set_selectable(0,is_shape)
		root.set_metadata( 0, scene_root)
		if is_shape:
			root.add_button(1,switch_icons[1])
			root.set_metadata( 1, true)
		else:
			root.set_cell_mode( 1, root.CELL_MODE_CUSTOM )
			root.set_custom_color( 0, Color(0.976563,0.312805,0.312805) )
		add_childs_recursively(scene_root,root)
	get_tree().set_debug_collisions_hint(true)
	get_tree().set_debug_navigation_hint(true)
	popup_centered()

func add_childs_recursively(parent_node, parent_item):
	for child in parent_node.get_children():
		var item = scene_tree.create_item(parent_item)
		item.set_text(0, child.get_name())
		var is_shape = false
		if child extends CollisionShape2D:
			is_shape=true
			item.set_icon(0, shape_icons[0])
		elif child extends CollisionPolygon2D:
			is_shape=true
			item.set_icon(0, shape_icons[1])
		elif child extends LightOccluder2D:
			is_shape=true
			item.set_icon(0, shape_icons[2])
		elif child extends NavigationPolygonInstance:
			is_shape=true
			item.set_icon(0, shape_icons[3])
		item.set_selectable(0,is_shape)
		item.set_selectable(1,false)
		item.set_metadata( 0, child)
		if is_shape:
			item.add_button(1,switch_icons[1])
			item.set_metadata( 1, true)
		else:
			item.set_custom_color( 0, Color(0.976563,0.312805,0.312805) )
		add_childs_recursively(child,item)

func _on_file_selected(file_path):
	var scn = load(file_path)
	if scn extends PackedScene:
		scene_root = scn.instance()
	else:
		scene_root = null
	emit_signal("packed_scene_selected")

func _on_button_pressed( item, column, id ):
	var import = !item.get_metadata(column)
	item.set_metadata(column,import)
	item.erase_button(column,id)
	if import:
		item.add_button(column,switch_icons[1])
	else:
		item.add_button(column,switch_icons[0])

func _on_item_selected():
	get_node(light_anim_path).stop()
	get_node(light_path).hide()
	get_node(modulate_canvas_path).hide()
	var item = scene_tree.get_selected()
	var shape_node = item.get_metadata(0)
	if shape_node extends CollisionShape2D:
		shape = shape_node.get_shape()
		collision_node.set_shape(shape)
		print(shape.get_path())
		collision_node.set_pos(shape_node.get_pos())
		collision_node.show()
		collision_poly_node.hide()
		occluder_node.hide()
		navpoly_node.hide()
	elif shape_node extends CollisionPolygon2D:
		shape = shape_node
		collision_poly_node.set_polygon(shape_node.get_polygon())
		collision_poly_node.set_pos(shape_node.get_pos())
		collision_poly_node.show()
		collision_node.hide()
		occluder_node.hide()
		navpoly_node.hide()
	elif shape_node extends LightOccluder2D:
		shape = shape_node.get_occluder_polygon()
		occluder_node.set_occluder_polygon(shape)
		occluder_node.show()
		collision_node.hide()
		collision_poly_node.hide()
		navpoly_node.hide()
		get_node(light_anim_path).play("light")
		get_node(light_path).show()
		get_node(modulate_canvas_path).show()
	elif shape_node extends NavigationPolygonInstance:
		shape = shape_node.get_navigation_polygon()
		navpoly_node.set_navigation_polygon(shape)
		navpoly_node.show()
		collision_node.hide()
		collision_poly_node.hide()
		occluder_node.hide()
	else:
		shape = null