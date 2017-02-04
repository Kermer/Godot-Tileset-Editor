
tool

extends WindowDialog

var tileset_script = load("res://addons/tileset_editor/tileset.gd")
var icon_collider = load("res://addons/tileset_editor/icons/icon_collision_shape_2d.png")
var icon_occlusion = load("res://addons/tileset_editor/icons/icon_light_occluder_2d.png")
var icon_navpoly = load("res://addons/tileset_editor/icons/icon_navigation_polygon_instance.png")

# region export variables

export(NodePath) var texture_list_path
export(NodePath) var texture_view_path
export(NodePath) var overlay_path

export(NodePath) var tool_layout_path
export(NodePath) var tool_collision_path
export(NodePath) var tool_occluder_path
export(NodePath) var tool_navpoly_path

export(NodePath) var layout_toolbox_path
export(NodePath) var shape_toolbox_path
export(NodePath) var shape_list_path

export(NodePath) var layout_x_off_path
export(NodePath) var layout_y_off_path
export(NodePath) var layout_w_path
export(NodePath) var layout_h_path
export(NodePath) var layout_x_sep_path
export(NodePath) var layout_y_Sep_path

export(NodePath) var export_path

export(NodePath) var add_texture_path
export(NodePath) var del_texture_path

export(NodePath) var add_shape_path
export(NodePath) var del_shape_path

# region control variables

onready var mode_buttons = [
get_node(tool_layout_path),
get_node(tool_collision_path),
get_node(tool_occluder_path),
get_node(tool_navpoly_path)
]

onready var export_button = get_node(export_path)

onready var texture_buttons = [
get_node(add_texture_path),
get_node(del_texture_path)
]

onready var shape_buttons = [
get_node(add_shape_path),
get_node(del_shape_path)
]

onready var layout_spinboxes = [
get_node(layout_x_off_path),
get_node(layout_y_off_path),
get_node(layout_w_path),
get_node(layout_h_path),
get_node(layout_x_sep_path),
get_node(layout_y_Sep_path)
]

onready var texture_list = get_node(texture_list_path)
onready var texture_view = get_node(texture_view_path)
onready var overlay = get_node(overlay_path)

onready var layout_toolbox = get_node(layout_toolbox_path)
onready var shape_toolbox = get_node(shape_toolbox_path)

onready var shape_list = get_node(shape_list_path)

# region signals

signal export_requested

#region variables

var current_mode = -1
var current_tex_id = -1
var changing_texture = false
onready var tileset = tileset_script.new()
onready var texture_dialog = FileDialog.new()
onready var export_dialog = FileDialog.new()
onready var shape_picker = load("res://addons/tileset_editor/shape_picker.tscn").instance()

#region constructors

func _ready():
	for i in range(mode_buttons.size()):
		mode_buttons[i].connect("pressed", self, "_on_change_mode", [i])
	for i in range(texture_buttons.size()):
		texture_buttons[i].connect("pressed", self, "_on_texture_btn", [i])
	for i in range(shape_buttons.size()):
		shape_buttons[i].connect("pressed", self, "_on_shape_btn", [i])
	for i in layout_spinboxes:
		i.connect("value_changed", self, "_layout_changed")
	
	export_button.connect("pressed", self, "_on_export_btn")
	
	texture_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	texture_dialog.add_filter("*.atex")
	texture_dialog.add_filter("*.cube")
	texture_dialog.add_filter("*.dds")
	texture_dialog.add_filter("*.jpeg")
	texture_dialog.add_filter("*.jpg")
	texture_dialog.add_filter("*.ltex")
	texture_dialog.add_filter("*.png")
	texture_dialog.add_filter("*.pvr")
	texture_dialog.add_filter("*.res")
	texture_dialog.add_filter("*.tex")
	texture_dialog.add_filter("*.tres")
	texture_dialog.add_filter("*.webp")
	texture_dialog.add_filter("*.watex")
	texture_dialog.add_filter("*.xltex")
	texture_dialog.add_filter("*.xml")
	texture_dialog.add_filter("*.xtex")
	texture_dialog.connect("file_selected",self,"_on_texture_added")
	texture_dialog.set_size(Vector2(700,500))
	get_parent().add_child(texture_dialog)
	
	export_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	for ext in ["tres","res","xml"]:
		export_dialog.add_filter("*."+ext)
	export_dialog.set_title("Export TileSet")
	export_dialog.set_mode(FileDialog.MODE_SAVE_FILE)
	export_dialog.set_size(Vector2(700,500))
	export_dialog.connect("file_selected",self,"_on_export")
	get_parent().add_child(export_dialog)
	
	shape_picker.connect("import_success",self,"_on_shape_import_success")
	shape_picker.connect("import_cancel",self,"_on_shape_import_cancel")
	get_parent().add_child(shape_picker)
	
	texture_list.connect("item_selected",self,"_on_texture_selected")
	
	overlay.connect("draw", self, "_draw_overlay")
	overlay.connect("input_event", self, "_input_overlay")
	
	shape_list.set_select_mode(ItemList.SELECT_MULTI)
	shape_list.set_fixed_icon_size(Vector2(20,20))
	
	_on_change_mode(0)

# region functions

func update_editor():
	texture_list.clear()
	var idx = 0
	for tex in tileset.tileset_data:
		texture_list.add_item(tex.texture.get_name(),tex.texture)
		var w = min(64, tex.texture.get_width())
		var h = min(64, tex.texture.get_height())
		texture_list.set_item_icon_region(idx,Rect2(0,0,w,h))
		idx += 1
	pass

func _on_change_mode(mode):
	for i in range(mode_buttons.size()):
		mode_buttons[i].set_pressed(mode==i)
	if mode == current_mode && !changing_texture:
		return
	current_mode = mode
	refresh_toolbox()

func refresh_toolbox():
	var mode = current_mode
	if (mode==0):
		layout_toolbox.show()
		shape_toolbox.hide()
	else:
		layout_toolbox.hide()
		shape_toolbox.show()
		shape_toolbox.get_node("title/label").set_text(mode_buttons[mode].get_text())
		shape_toolbox.get_node("title/icon").set_texture(mode_buttons[mode].get_button_icon())
		shape_list.clear()
		if current_tex_id < 0 || current_tex_id >= tileset.tileset_data.size():
			return
		var items = []
		if mode == 1: items = tileset.collisions # Collision shape
		elif mode == 2: items = tileset.occluders # Occluder shape
		elif mode == 3: items = tileset.navpolys # Navpoly shape
		
		var item_id = 0
		for item in items:
			shape_list.add_item(item.name,item.icon)
			shape_list.set_item_icon_region(item_id,item.icon_region)
			item_id += 1

func _on_export_btn():
	export_dialog.popup_centered()

func _on_export( path ):
	emit_signal("export_requested",path)

func _on_texture_btn(wich):
	if wich == 0: # Add
		texture_dialog.set_mode(FileDialog.MODE_OPEN_FILE)
		texture_dialog.popup_centered()
	if wich == 1: # Remove
		tileset.tileset_data.remove(current_tex_id)
		texture_list.remove_item(current_tex_id)
		current_tex_id = -1
		update()
		print("TODO: Remove texture")

func _on_shape_btn(wich):
	if wich == 0: # Add
		hide()
		shape_picker.import()
	if wich == 1:
		var selected_shapes = Array(shape_list.get_selected_items()) # IntArray -> Array
		selected_shapes.sort()
		selected_shapes.invert() # Go from biggest ID to lowest
		for shape_id in selected_shapes:
			if current_mode == 1: tileset.remove_collision(shape_id); shape_list.remove_item(shape_id)
			elif current_mode == 2: tileset.remove_navpoly(shape_id); shape_list.remove_item(shape_id)
			elif current_mode == 3: tileset.remove_occluder(shape_id); shape_list.remove_item(shape_id)
		print("TODO: Remove shape")

func _on_shape_import_success( import_data ):
	for shape_data in import_data:
		var type = shape_data.type
		shape_data.erase("type")
		if type == "collision": tileset.add_collision( shape_data )
		elif type == "navpoly": tileset.add_navpoly( shape_data )
		elif type == "occluder": tileset.add_occluder( shape_data )
	refresh_toolbox()
	show()
	

func _on_shape_import_cancel():
	show()

func _layout_changed(val):
	if !changing_texture:
		if current_tex_id >= 0 and current_tex_id < tileset.tileset_data.size():
			tileset.tileset_data[current_tex_id].x_off = layout_spinboxes[0].get_value()
			tileset.tileset_data[current_tex_id].y_off = layout_spinboxes[1].get_value()
			tileset.tileset_data[current_tex_id].w = layout_spinboxes[2].get_value()
			tileset.tileset_data[current_tex_id].h = layout_spinboxes[3].get_value()
			tileset.tileset_data[current_tex_id].x_sep = layout_spinboxes[4].get_value()
			tileset.tileset_data[current_tex_id].y_sep = layout_spinboxes[5].get_value()
			overlay.update()

func _on_texture_added(file_path):
	var res = load(file_path)
	if !res extends Texture:
		print("ERROR: El recurso no era una textura!!")
		show()
		return
	var tex = tileset_script.TextureProperties.new()
	tileset.tileset_data.push_back(tex)
	tex.texture=res
	texture_list.add_item(tex.texture.get_name(),tex.texture)
	var w = min(64, tex.texture.get_width())
	var h = min(64, tex.texture.get_height())
	texture_list.set_item_icon_region(tileset.tileset_data.size()-1,Rect2(0,0,w,h))
	show()

func _on_texture_selected(id):
	changing_texture = true
	current_tex_id = id
	var tex = tileset.tileset_data[id]
	texture_view.set_texture(tex.texture)
	var values = [tex.x_off,tex.y_off,tex.w,tex.h,tex.x_sep,tex.y_sep]
	for i in range(values.size()):
		layout_spinboxes[i].set_value(values[i])
	_on_change_mode(current_mode)
	changing_texture = false

func _draw_overlay():
	if current_tex_id < 0 || current_tex_id >= tileset.tileset_data.size():
		return # Nothing to do here
	
	var tex = tileset.tileset_data[current_tex_id]
	# Hide unused area
	overlay.draw_rect(Rect2(0,0,tex.x_off,tex.texture.get_height()), Color(0.273758,0.290014,0.300781,0.764498))
	overlay.draw_rect(Rect2(tex.x_off,0,tex.texture.get_width()-tex.x_off,tex.y_off), Color(0.273758,0.290014,0.300781,0.764498))
	# Fill separation
	var x = int(tex.x_off+tex.w)%int(tex.w+tex.x_sep)
	var y = int(tex.y_off)%int(tex.h+tex.y_sep)
	while x < tex.texture.get_width():
		overlay.draw_rect(Rect2(x,0,tex.x_sep,tex.texture.get_height()), Color(0.835938,0.362457,0.595498))
		x += tex.w+tex.x_sep
	var x = int(tex.x_off)%int(tex.w+tex.x_sep)
	var y = int(tex.y_off+tex.h)%int(tex.h+tex.y_sep)
	while y < tex.texture.get_height():
		overlay.draw_rect(Rect2(0,y,tex.texture.get_width(),tex.y_sep), Color(0.835938,0.362457,0.595498))
		y += tex.h+tex.y_sep
	# Draw Grid
	var x = tex.x_off+tex.w-1
	var y = tex.y_off
	var end = tex.texture.get_height()-(int(tex.texture.get_height()-tex.y_off)%int(tex.h))
	if tex.x_sep==0:
		while x < tex.texture.get_width():
			overlay.draw_line( Vector2(x,y), Vector2 (x,end), Color(0.395508,0.608757,0.75))
			x += tex.w+tex.x_sep
	var x = tex.x_off
	var y = tex.y_off+tex.h-1
	var end = tex.texture.get_width()-(int(tex.texture.get_width()-tex.x_off)%int(tex.w))
	if tex.y_sep==0:
		while y < tex.texture.get_height():
			overlay.draw_line( Vector2(x,y), Vector2 (end,y), Color(0.395508,0.608757,0.75))
			y += tex.h+tex.y_sep
	# Hide not exported
	var grid_width = int((tex.texture.get_width()-tex.x_off)/(tex.w+tex.x_sep))
	var grid_height = int((tex.texture.get_height()-tex.y_off)/(tex.h+tex.y_sep))
	for x in range(grid_width):
		for y in range(grid_height):
			if !tex.data.has(Vector2(x,y)) || !tex.data[Vector2(x,y)]["export"]:
				overlay.draw_rect(Rect2(tex.x_off+x*(tex.w+tex.x_sep),tex.y_off+y*(tex.h+tex.y_sep),tex.w,tex.h),Color(1,0.18,0.1,0.3))

var action = 0 # 0:None 1:Add 2:Remove
var last_coord = Vector2(-1,-1)

func _input_overlay(ev):
	if current_tex_id < 0 || current_tex_id >= tileset.tileset_data.size():
		return # Nothing to do here
	
	var tex = tileset.tileset_data[current_tex_id]
	if current_mode == 0: # Select what to export
		if ev.type==InputEvent.MOUSE_BUTTON&&ev.pressed:
			if action != 0:
				return
			if ev.button_index == 1: # LMB
				action = 1
				if (ev.x < tex.x_off || ev.y < tex.y_off):
					return
				var x = int(ev.x-tex.x_off)/int(tex.w+tex.x_sep)
				var y = int(ev.y-tex.y_off)/int(tex.h+tex.y_sep)
				var coord = Vector2(x,y)
				if !tex.data.has(coord):
					tex.data[coord] = {}
				tex.data[coord]["export"]=true
				overlay.update()
				last_coord = coord
			elif ev.button_index == 2: # LMB
				action = 2
				if (ev.x < tex.x_off || ev.y < tex.y_off):
					return
				var x = int(ev.x-tex.x_off)/int(tex.w+tex.x_sep)
				var y = int(ev.y-tex.y_off)/int(tex.h+tex.y_sep)
				var coord = Vector2(x,y)
				if !tex.data.has(coord):
					tex.data[coord] = {}
				tex.data[coord]["export"]=false
				overlay.update()
				last_coord = coord
		if ev.type==InputEvent.MOUSE_BUTTON&&!ev.pressed:
			action = 0
		if ev.type==InputEvent.MOUSE_MOTION:
			if action == 0 || ev.x < tex.x_off || ev.y < tex.y_off:
				return
			var x = int(ev.x-tex.x_off)/int(tex.w+tex.x_sep)
			var y = int(ev.y-tex.y_off)/int(tex.h+tex.y_sep)
			var coord = Vector2(x,y)
			if coord == last_coord:
				return
			if !tex.data.has(coord):
				tex.data[coord] = {}
			tex.data[coord]["export"]=(action==1)
			overlay.update()
			last_coord = coord

func reload(res):
	tileset=res
	texture_list.clear()
	shape_list.clear()
	texture_view.set_texture(null)
	current_tex_id=-1
	for i in range(res.tileset_data.size()):
		var tex = res.tileset_data[i]
		texture_list.add_item(tex.texture.get_name(),tex.texture)
		var w = min(64, tex.texture.get_width())
		var h = min(64, tex.texture.get_height())
		texture_list.set_item_icon_region(i,Rect2(0,0,w,h))
		show()
