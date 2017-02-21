tool

extends WindowDialog

export(NodePath) var scene_tree_path
export(NodePath) var icon_path
export(NodePath) var collision_path
export(NodePath) var collision_poly_path
export(NodePath) var occluder_path
export(NodePath) var navpoly_path
export(NodePath) var viewport_path
export(NodePath) var light_anim_path
export(NodePath) var modulate_canvas_path
export(NodePath) var light_path

# region variables

onready var scene_tree = get_node(scene_tree_path)
onready var icon_node = get_node(icon_path)
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
signal import_success
signal import_cancel

# region getters and setters


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
			root.set_metadata( 1, false)
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
			item.set_metadata( 1, false)
		add_childs_recursively(child,item)

func _on_file_selected(file_path):
	var scn = load(file_path)
	if scn extends PackedScene:
		scene_root = scn.instance()
		emit_signal("packed_scene_selected")
	else:
		scene_root = null

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
	var icon = shape_node.get_parent()
	if icon extends Sprite:
		icon_node.set_texture(icon.get_texture())
		icon_node.set_region(icon.is_region())
		icon_node.set_region_rect(icon.get_region_rect())
		icon_node.set_vframes(icon.get_vframes())
		icon_node.set_hframes(icon.get_hframes())
		icon_node.set_flip_h(icon.is_flipped_h())
		icon_node.set_flip_v(icon.is_flipped_v())
		icon_node.set_frame(icon.get_frame())
		
	else:
		icon_node.set_texture(null)
	if shape_node extends CollisionShape2D:
		shape = shape_node.get_shape()
		collision_node.set_shape(shape)
		#print(shape.get_path())
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

func get_import_data():
	var data = []
	var tree_item = scene_tree.get_root()
	add_import_data_recursively(tree_item,data)
	return data

func add_import_data_recursively(tree_item,list):
	if is_import(tree_item):
		var d = {"type":"undefined","icon":null,"icon_region":Rect2(Vector2(),Vector2()),"shape":null} # default values
		var node = tree_item.get_metadata(0)
		d["name"] = tree_item.get_metadata(0).get_parent().get_name()
		var icon = tree_item.get_metadata(0).get_parent()
		if icon != null:
			d["icon"] = icon.get_texture()
			d["icon_region"] = icon.get_region_rect()
		if is_collider(node):
			d["type"] = "collision"
			if node extends CollisionShape2D:
				d["shape"] = node.get_shape()
			elif node extends CollisionPolygon2D:
				var s = ConvexPolygonShape2D.new()
				s.set_points(node.get_polygon())
				d["shape"] = s
		elif is_navpoly(node):
			d["type"] = "navpoly"
		elif is_occluder(node):
			d["type"] = "occluder"
		d["offset"] = node.get_pos()
		list.push_back(d)
	
	var child = tree_item.get_children()
	if child != null:
		add_import_data_recursively(child,list)
	var next = tree_item.get_next()
	if next != null:
		add_import_data_recursively(next,list)

func is_import(tree_item):
	return tree_item.get_metadata(1)

func _on_ok_pressed():
	var data = get_import_data()
	if data.size() == 0:
		return
	hide()
	emit_signal("import_success",data)


func _on_cancel_pressed():
	hide()
	emit_signal("import_cancel")

func import_colliders_recursively(who):
	if (is_collider(who.get_metadata(0)) && !who.get_metadata(1)):
		who.set_metadata(1,true)
		who.erase_button(1,0)
		who.add_button(1,switch_icons[1])
	if who.get_children() != null:
		import_colliders_recursively(who.get_children())
	if who.get_next() != null:
		import_colliders_recursively(who.get_next())

func import_occluders_recursively(who):
	if (is_occluder(who.get_metadata(0)) && !who.get_metadata(1)):
		who.set_metadata(1,true)
		who.erase_button(1,0)
		who.add_button(1,switch_icons[1])
	if who.get_children() != null:
		import_occluders_recursively(who.get_children())
	if who.get_next() != null:
		import_occluders_recursively(who.get_next())

func import_navpolys_recursively(who):
	if (is_navpoly(who.get_metadata(0)) && !who.get_metadata(1)):
		who.set_metadata(1,true)
		who.erase_button(1,0)
		who.add_button(1,switch_icons[1])
	if who.get_children() != null:
		import_navpolys_recursively(who.get_children())
	if who.get_next() != null:
		import_navpolys_recursively(who.get_next())

func dont_import_recursively(who):
	var node = who.get_metadata(0)
	print(node.get_name())
	var is_shape = is_collider(node) || is_occluder(node) || is_navpoly(node)
	if (is_shape && who.get_metadata(1)):
		who.set_metadata(1,false)
		who.erase_button(1,0)
		who.add_button(1,switch_icons[0])
	if who.get_children() != null:
		dont_import_recursively(who.get_children())
	if who.get_next() != null:
		dont_import_recursively(who.get_next())

func is_collider(node):
	return (node != null && (node extends CollisionShape2D || node extends CollisionPolygon2D))
func is_occluder(node):
	return node != null && node extends LightOccluder2D
func is_navpoly(node):
	return node != null && node extends NavigationPolygonInstance


func _on_all_colliders_pressed():
	import_colliders_recursively(scene_tree.get_root())


func _on_all_occluders_pressed():
	import_occluders_recursively(scene_tree.get_root())


func _on_all_navpolys_pressed():
	import_navpolys_recursively(scene_tree.get_root())


func _on_clear_selection_pressed():
	dont_import_recursively(scene_tree.get_root())
