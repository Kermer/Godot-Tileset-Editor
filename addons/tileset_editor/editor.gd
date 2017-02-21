
tool

extends WindowDialog

const tileset_script = preload("res://addons/tileset_editor/tileset.gd")
const icon_collider = preload("res://addons/tileset_editor/icons/icon_collision_shape_2d.png")
const icon_occlusion = preload("res://addons/tileset_editor/icons/icon_light_occluder_2d.png")
const icon_navpoly = preload("res://addons/tileset_editor/icons/icon_navigation_polygon_instance.png")

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

export(NodePath) var attach_shapes_path
export(NodePath) var deattach_shapes_path
export(NodePath) var import_shapes_path
export(NodePath) var remove_shapes_path

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
get_node(import_shapes_path),
get_node(remove_shapes_path),
get_node(attach_shapes_path),
get_node(deattach_shapes_path)
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
		if mode == 1: items = tileset.shapes.collision # Collision shape
		elif mode == 2: items = tileset.shapes.occluder # Occluder shape
		elif mode == 3: items = tileset.shapes.navpoly # Navpoly shape
		
		var item_id = 0
		for item in items:
			shape_list.add_item(item.name,item.icon)
			shape_list.set_item_icon_region(item_id,item.icon_region)
			item_id += 1
		refresh_active_shapes()

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

func _on_shape_btn(which):
	if which == 0: # Import
		hide()
		shape_picker.import()
	elif which == 1: # Remove
		var selected_shapes = Array(shape_list.get_selected_items()) # IntArray -> Array
		selected_shapes.sort()
		selected_shapes.invert() # Go from biggest ID to lowest
		for shape_id in selected_shapes:
			if current_mode == 1: tileset.remove_shape("collision",shape_id); shape_list.remove_item(shape_id)
			elif current_mode == 2: tileset.remove_shape("occluder",shape_id); shape_list.remove_item(shape_id)
			elif current_mode == 3: tileset.remove_shape("navpoly",shape_id); shape_list.remove_item(shape_id)
	elif (which == 2 or which == 3): # Attach or Deattach (Add/Remove from tile)
		var selected_shapes = shape_list.get_selected_items()
		var err_text = ""
		if (current_mode==1 and tileset.shapes.collision.size()==0) or (current_mode==2 and tileset.shapes.occluder.size()==0) or (current_mode==3 and tileset.shapes.navpoly.size()==0): 
			err_text += "\n\tThere are no shapes, please import some..."
		elif selected_shapes.size() == 0: err_text += "\n\tNo shapes selected!"
		elif (selected_shapes.size() > 1 and which==2): err_text += "\n\tCurrently you can only add 1 shape per tile :("
		if selected_tiles.size() == 0: err_text += "\n\tNo tiles selected!"
		if err_text != "":
			alert("Failed to Add/Remove shape(s):"+err_text)
			return
		if which == 2: # Attach
			if current_mode == 1:
				for tile in selected_tiles: tileset.attach_shape("collision",current_tex_id,tile,selected_shapes[0])
			elif current_mode == 2:
				for tile in selected_tiles: tileset.attach_shape("occluder",current_tex_id,tile,selected_shapes[0])
			elif current_mode == 3:
				for tile in selected_tiles: tileset.attach_shape("navpoly",current_tex_id,tile,selected_shapes[0])
			refresh_active_shapes(selected_shapes) # Override active selection with 'selected_shapes'
		elif which == 3: # Deattach
			if current_mode == 1:
				for tile in selected_tiles: tileset.deattach_shape("collision",current_tex_id,tile,selected_shapes[0])
			elif current_mode == 2:
				for tile in selected_tiles: tileset.deattach_shape("occluder",current_tex_id,tile,selected_shapes[0])
			elif current_mode == 3:
				for tile in selected_tiles: tileset.deattach_shape("navpoly",current_tex_id,tile,selected_shapes[0])
			refresh_active_shapes()
		

func _on_shape_import_success( import_data ):
	for shape_data in import_data:
		tileset.add_shape(shape_data)
	refresh_toolbox()
	show()
	

func _on_shape_import_cancel():
	show()

func _layout_changed(val):
	if !changing_texture:
		if current_tex_id >= 0 and current_tex_id < tileset.tileset_data.size():
			tileset.tileset_data[current_tex_id].offset.x = layout_spinboxes[0].get_value()
			tileset.tileset_data[current_tex_id].offset.y = layout_spinboxes[1].get_value()
			tileset.tileset_data[current_tex_id].tile_size.x = layout_spinboxes[2].get_value()
			tileset.tileset_data[current_tex_id].tile_size.y = layout_spinboxes[3].get_value()
			tileset.tileset_data[current_tex_id].tile_sep.x = layout_spinboxes[4].get_value()
			tileset.tileset_data[current_tex_id].tile_sep.y = layout_spinboxes[5].get_value()
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
	var values = [tex.offset.x,tex.offset.y,tex.tile_size.x,tex.tile_size.y,tex.tile_sep.x,tex.tile_sep.y]
	for i in range(values.size()):
		layout_spinboxes[i].set_value(values[i])
	selected_tiles.clear()
	_on_change_mode(current_mode)
	changing_texture = false

func _draw_overlay():
	if current_tex_id < 0 || current_tex_id >= tileset.tileset_data.size():
		return # Nothing to do here
	
	var tex = tileset.tileset_data[current_tex_id]
	# Hide unused area
	overlay.draw_rect(Rect2(0,0,tex.offset.x,tex.texture.get_height()), Color(0.273758,0.290014,0.300781,0.764498))
	overlay.draw_rect(Rect2(tex.offset.x,0,tex.texture.get_width()-tex.offset.x,tex.offset.y), Color(0.273758,0.290014,0.300781,0.764498))
	# Fill separation
	var x = int(tex.offset.x+tex.tile_size.x)%int(tex.tile_size.x+tex.tile_sep.x)
	var y = int(tex.offset.y)%int(tex.tile_size.y+tex.tile_sep.y)
	while x < tex.texture.get_width():
		overlay.draw_rect(Rect2(x,0,tex.tile_sep.x,tex.texture.get_height()), Color(0.835938,0.362457,0.595498))
		x += tex.tile_size.x+tex.tile_sep.x
	var x = int(tex.offset.x)%int(tex.tile_size.x+tex.tile_sep.x)
	var y = int(tex.offset.y+tex.tile_size.y)%int(tex.tile_size.y+tex.tile_sep.y)
	while y < tex.texture.get_height():
		overlay.draw_rect(Rect2(0,y,tex.texture.get_width(),tex.tile_sep.y), Color(0.835938,0.362457,0.595498))
		y += tex.tile_size.y+tex.tile_sep.y
	# Draw Grid
	var x = tex.offset.x+tex.tile_size.x-1
	var y = tex.offset.y
	var end = tex.texture.get_height()-(int(tex.texture.get_height()-tex.offset.y)%int(tex.tile_size.y))
	if tex.tile_sep.x==0:
		while x < tex.texture.get_width():
			overlay.draw_line( Vector2(x,y), Vector2 (x,end), Color(0.395508,0.608757,0.75))
			x += tex.tile_size.x+tex.tile_sep.x
	var x = tex.offset.x
	var y = tex.offset.y+tex.tile_size.y-1
	var end = tex.texture.get_width()-(int(tex.texture.get_width()-tex.offset.x)%int(tex.tile_size.x))
	if tex.tile_sep.y==0:
		while y < tex.texture.get_height():
			overlay.draw_line( Vector2(x,y), Vector2 (end,y), Color(0.395508,0.608757,0.75))
			y += tex.tile_size.y+tex.tile_sep.y
	# Hide not exported
	var grid_width = int((tex.texture.get_width()-tex.offset.x)/(tex.tile_size.x+tex.tile_sep.x))
	var grid_height = int((tex.texture.get_height()-tex.offset.y)/(tex.tile_size.y+tex.tile_sep.y))
	for x in range(grid_width):
		for y in range(grid_height):
			if !tex.data.has(Vector2(x,y)) || !tex.data[Vector2(x,y)]["export"]:
				overlay.draw_rect(Rect2(tex.offset.x+x*(tex.tile_size.x+tex.tile_sep.x),tex.offset.y+y*(tex.tile_size.y+tex.tile_sep.y),tex.tile_size.x,tex.tile_size.y),Color(1,0.18,0.1,0.3))
	# Mark selected tile
	for selected_tile in selected_tiles:
		var x = tex.offset.x + (tex.tile_size.x+tex.tile_sep.x)*selected_tile.x
		var y = tex.offset.y + (tex.tile_size.y+tex.tile_sep.y)*selected_tile.y
		overlay.draw_rect(Rect2(x,y,tex.tile_size.x,tex.tile_size.y),Color(0.1,0.1,1,0.3))

var action = 0 # 0:None 1:Add 2:Remove
var last_coord = Vector2(-1,-1)
var selected_tiles = [] # Array of Vector2, currently selected tiles

func _input_overlay(ev):
	if current_tex_id < 0 || current_tex_id >= tileset.tileset_data.size():
		return # Nothing to do here
	var tex = tileset.tileset_data[current_tex_id]
	
#	if current_mode == 0: # Select what to export
	if true: # allow tiles selection in every mode
		if ev.type==InputEvent.MOUSE_BUTTON&&ev.pressed:
			if action != 0:
				return
			if ev.button_index == 1: # LMB
				action = 1
				if (ev.x < tex.offset.x || ev.y < tex.offset.y):
					return
				var x = int(ev.x-tex.offset.x)/int(tex.tile_size.x+tex.tile_sep.x)
				var y = int(ev.y-tex.offset.y)/int(tex.tile_size.y+tex.tile_sep.y)
				var coord = Vector2(x,y)
				_tile_selected(coord,action,(ev.control))
				overlay.update()
				last_coord = coord
			elif ev.button_index == 2: # RMB
				action = 2
				if (ev.x < tex.offset.x || ev.y < tex.offset.y):
					return
				var x = int(ev.x-tex.offset.x)/int(tex.tile_size.x+tex.tile_sep.x)
				var y = int(ev.y-tex.offset.y)/int(tex.tile_size.y+tex.tile_sep.y)
				var coord = Vector2(x,y)
				_tile_selected(coord,action,(ev.control))
				overlay.update()
				last_coord = coord
		if ev.type==InputEvent.MOUSE_BUTTON&&!ev.pressed:
			action = 0
		if ev.type==InputEvent.MOUSE_MOTION:
			if action == 0 || not is_inside_tex(tex,ev.x,ev.y):
				return
			var x = int(ev.x-tex.offset.x)/int(tex.tile_size.x+tex.tile_sep.x)
			var y = int(ev.y-tex.offset.y)/int(tex.tile_size.y+tex.tile_sep.y)
			var coord = Vector2(x,y)
			if coord == last_coord:
				return
			_tile_selected(coord,action,true)
			overlay.update()
			last_coord = coord

func is_inside_tex(tex,arg0,arg1=null):
	var pos = Vector2(-1,-1)
	if arg1 != null: pos = Vector2(arg0,arg1)
	else: pos = arg0
	return (pos.x>=tex.offset.x && pos.y>=tex.offset.y) && (pos.x<tex.texture.get_size().x && pos.y<tex.texture.get_size().y)

func _tile_selected(coord,action,append):
	var tex = tileset.tileset_data[current_tex_id]
	if !tex.data.has(coord): tex.data[coord] = {}
	
	if (action==1): # LMB
		if (not append and selected_tiles.size() > 0): selected_tiles.clear()
		if !selected_tiles.has(coord): selected_tiles.append(coord)
		tex.data[coord]["export"] = true
	elif (action==2): # RMB
		if (selected_tiles.size() > 0):
			if not append: selected_tiles.clear()
			elif (append and selected_tiles.has(coord)): selected_tiles.erase(coord)
		tex.data[coord]["export"] = false
	refresh_active_shapes()

func alert( text, title="Alert!" ):
	get_parent().alert(text,title)

func refresh_active_shapes(forced=null):
	var active_shapes = []
	if forced!=null and (typeof(forced)==TYPE_ARRAY or typeof(forced)==TYPE_INT_ARRAY):
		active_shapes = Array(forced)
	else:
		if selected_tiles.size() == 1:
			var tile = selected_tiles[0]
			var tile_data = tileset.tileset_data[current_tex_id].data[tile]
			print(tile_data)
			var type = ""
			if current_mode == 1: type = "collision"
			elif current_mode == 2: type = "occluder"
			elif current_mode == 3: type = "navpoly"
			if tile_data.has(type):
				var shape_data = tile_data[type]
				var shape_id = tileset.shapes[type].find(shape_data)
				active_shapes = [ shape_id ]
	for shape_id in range(shape_list.get_item_count()):
		shape_list.set_item_custom_bg_color(shape_id,Color(1,1,1,0))
	for shape_id in active_shapes:
		shape_list.set_item_custom_bg_color(shape_id,Color(0.1,0.1,1,0.4))
	shape_list.update()

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
