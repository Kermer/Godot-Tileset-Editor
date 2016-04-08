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

var mode = 1

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
	scene_tree.connect("cell_selected",self,"_on_item_selected")
	var anim = get_node(light_anim_path)
	anim.play("light")

func import(what):
	mode = what
	self.shape_name = ""
	file_dialog.set_title("Load Shape from...")
	file_dialog.popup_centered()
	yield(self,"packed_scene_selected")
	scene_tree.clear()
	if scene_root != null:
		var root = scene_tree.create_item()
		root.set_text(0, scene_root.get_name())
		var is_shape = false
		if mode == 1:
			is_shape = scene_root extends CollisionShape2D || scene_root extends CollisionPolygon2D
		elif mode == 2:
			is_shape = scene_root extends LightOccluder2D
		elif mode == 3:
			is_shape = scene_root extends NavigationPolygon
		root.set_selectable(0,is_shape)
		if !is_shape:
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
		if mode == 1:
			is_shape = child extends CollisionShape2D || child extends CollisionPolygon2D
		elif mode == 2:
			is_shape = child extends LightOccluder2D
		elif mode == 3:
			is_shape = child extends NavigationPolygonInstance
		item.set_selectable(0,is_shape)
		if !is_shape:
			item.set_custom_color( 0, Color(0.976563,0.312805,0.312805) )
		add_childs_recursively(child,item)

func _on_file_selected(file_path):
	var scn = load(file_path)
	if scn extends PackedScene:
		scene_root = scn.instance()
	else:
		scene_root = null
	
	emit_signal("packed_scene_selected")

func _on_item_selected():
	print("signal emmited")
	var item = scene_tree.get_selected()
	var nodepath = item.get_text(0)
	while (item.get_parent() != scene_tree.get_root()):
		item = item.get_parent()
		nodepath = item.get_text(0)+"/"+nodepath
	var shape_node = scene_root.get_node(nodepath)
	if mode == 1: # Collision
		if shape_node extends CollisionShape2D:
			shape = shape_node.get_shape()
			collision_node.set_shape(shape)
			print(shape.get_path())
			collision_node.set_pos(shape_node.get_pos())
			collision_node.show()
			collision_poly_node.hide()
		elif shape_node extends CollisionPolygon2D:
			shape = shape_node
			collision_poly_node.set_polygon(shape_node.get_polygon())
			collision_poly_node.set_pos(shape_node.get_pos())
			collision_poly_node.show()
			collision_node.hide()
		else:
			shape = null
		occluder_node.hide()
		navpoly_node.hide()
	elif mode == 2: # Occlusion
		if shape_node extends LightOccluder2D:
			shape = shape_node.get_occluder_polygon()
			occluder_node.set_occluder_polygon(shape)
			occluder_path.show()
			collision_node.hide()
			collision_poly_node.hide()
			navpoly_node.hide()
		else:
			shape = null
	elif mode == 3:
		if shape_node extends NavigationPolygonInstance:
			shape = shape_node.get_navigation_polygon()
			navpoly_node.set_navigation_polygon(shape)
			navpoly_node.show()
			collision_node.hide()
			collision_poly_node.hide()
			occluder_node.hide()
			print(str(shape))