tool

extends Resource

class TextureProperties:
	var texture = null
	var x_off = 0.0
	var y_off = 0.0
	var w = 64.0
	var h = 64.0
	var x_sep = 0.0
	var y_sep = 0.0
	var data = {}
	# Cache holds info about which tiles use each shape, NOT EXPORTED, GENERATED ON RESOURCE LOAD
	#	helpful when removing shapes from the list
	#	{ shape:Array(of tile_data) }
	var collisions_cache = {} 
	var navpolys_cache = {}
	var occluders_cache = {}

var tileset_data = [] #array of TextureProperties
var collisions = [] # holds available collision shapes
var occluders = [] # holds available occluders
var navpolys = [] # holds available navpolys

func _get_property_list():
	var d = {}
	var properties = []
	
	d["name"] = "texture_count"
	d["type"] = TYPE_INT
	d["hint"] = "Amount of textures used in this tileset"
	properties.push_back(d)
	
	d = {}
	d["name"] = "collisions"
	d["type"] = TYPE_ARRAY
	d["hint"] = ""
	properties.push_back(d)
	
	d = {}
	d["name"] = "occluders"
	d["type"] = TYPE_ARRAY
	d["hint"] = ""
	properties.push_back(d)
	
	d = {}
	d["name"] = "navpolys"
	d["type"] = TYPE_ARRAY
	d["hint"] = ""
	properties.push_back(d)
	
	for i in range(tileset_data.size()):
		var basename = "texture_"+str(i)+"/"
		d = {}
		d["name"] = basename+"texture"
		d["type"] = TYPE_OBJECT
		d["hint"] = "Texture"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"x_off"
		d["type"] = TYPE_INT
		d["hint"] = "0,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"y_off"
		d["type"] = TYPE_INT
		d["hint"] = "0,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"w"
		d["type"] = TYPE_INT
		d["hint"] = "1,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"h"
		d["type"] = TYPE_INT
		d["hint"] = "1,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"x_sep"
		d["type"] = TYPE_INT
		d["hint"] = "0,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"y_sep"
		d["type"] = TYPE_INT
		d["hint"] = "0,65535,1"
		properties.push_back(d)
		
		d = {}
		d["name"] = basename+"data"
		d["type"] = TYPE_DICTIONARY
		d["hint"] = ""
		properties.push_back(d)
		
	return properties

func _get(property):
	if property=="texture_count":
		return tileset_data.size()
	elif property.begins_with("texture_"):
		var id = int(property.split("/")[0].split("_")[1])
		var data = tileset_data[id]
		property=property.split("/")[1]
		if property == "texture":
			return data.texture
		elif property == "x_off":
			return data.x_off
		elif property == "y_off":
			return data.y_off
		elif property == "w":
			return data.w
		elif property == "h":
			return data.h
		elif property == "x_sep":
			return data.x_sep
		elif property == "y_sep":
			return data.y_sep
		elif property == "data":
			return pack_data(data.data)
	elif property == "collisions":
		return collisions
	elif property == "occluders":
		return occluders
	elif property == "navpolys":
		return navpolys
	return null

func _set(property, value):
	if property=="texture_count":
		if tileset_data.size() < value:
			#print("curent_count: "+str(tileset_data.size()))
			for i in range(tileset_data.size(),value):
				tileset_data.push_back(TextureProperties.new())
			#print("curent_count: "+str(tileset_data.size()))
		else:
			tileset_data.resize(value)
	elif property.begins_with("texture_"):
		var id = int(property.split("/")[0].split("_")[1])
		var data = tileset_data[id]
		property=property.split("/")[1]
		if property == "texture":
			data.texture = value
		elif property == "x_off":
			data.x_off = value
		elif property == "y_off":
			data.y_off = value
		elif property == "w":
			data.w = value
		elif property == "h":
			data.h = value
		elif property == "x_sep":
			data.x_sep = value
		elif property == "y_sep":
			data.y_sep = value
		elif property == "data":
			data.data = unpack_data(data,value)
	elif property == "collisions":
		collisions = value
	elif property == "occluders":
		occluders = value
	elif property == "navpolys":
		navpolys = value

func generate_tileset():
	var tileset = TileSet.new()
	var id = 0
	print("Exporting tileset...")
	for ts_data in tileset_data:
		var tid = 0 # relative to Texture instead of to Tileset
		for t_pos in ts_data.data:
			var tile_data = ts_data.data[t_pos]
			if tile_data["export"] == true:
				tileset.create_tile(id)
				# Attach texture to tile
				tileset.tile_set_texture(id,ts_data.texture)
				var tex_pos = Vector2(ts_data.w+ts_data.x_sep,ts_data.h+ts_data.y_sep) * t_pos
				tex_pos += Vector2(ts_data.x_off,ts_data.y_off)
				var tex_rect = Rect2(tex_pos, Vector2(ts_data.w,ts_data.h))
				tileset.tile_set_region(id,tex_rect)
				# Name the tile
				var tname = ts_data.texture.get_path().get_file().basename()
				tname += "_"+str(tid).pad_zeros(3)
				tileset.tile_set_name(id,tname)
				# Attach collision
				if tile_data.has("collision"):
					var shape = tile_data.collision.shape
					var offset = tile_data.collision.offset
					print(shape)
					tileset.tile_set_shape(id,shape)
					tileset.tile_set_shape_offset(id,offset)
				# TODO: Attach Collision, Occluder, Navigation
				id += 1; tid += 1
	return tileset





# === === === === === === === === === === === === === === === === === === 
# === === === === === ===                         === === === === === === 
# === === === ===                  CACHE                  === === === === 
# === === === === === ===                         === === === === === === 
# === === === === === === === === === === === === === === === === === === 

# Change Shape Data from ref<Dictionary> to int (shape_id)
#	Dictionary -> int
func pack_data(value):
	var rvalue = {}
	for tile_pos in value:
		var tile_data = {}
		for key in value[tile_pos]:
			if key == "collision":
				tile_data["collision"] = collisions.find( value[tile_pos].collision )
			elif key == "occluder":
				tile_data["occluder"] = occluders.find( value[tile_pos].occluder )
			elif key == "navpoly":
				tile_data["navpoly"] = navpolys.find( value[tile_pos].navpoly )
			else:
				tile_data[key] = value[tile_pos][key]
		if tile_data.size() > 0:
			rvalue[tile_pos] = tile_data
	return rvalue

# Change Shape ID to shape reference and generate Cache
#	Int -> Dictionary
func unpack_data(tex,data):
	for tile in data:
		if data[tile].has("collision"):
			var shape_id = data[tile].collision
			var cache = tex.collisions_cache
			var shape = collisions[ shape_id ]
			if !cache.has(shape):
				cache[shape] = [ ]
			data[tile].collision = shape
			cache[shape].append(data[tile])
		elif data[tile].has("occluder"):
			var shape_id = data[tile].occluder
			var cache = tex.occluders_cache
			var shape = occluders[ shape_id ]
			if !cache.has(shape):
				cache[shape] = [ ]
			data[tile].occluder = shape
			cache[shape].append(data[tile])
		elif data[tile].has("navpoly"):
			var shape_id = data[tile].navpoly
			var cache = tex.navpolys_cache
			var shape = navpolys[ shape_id ]
			if !cache.has(shape):
				cache[shape] = [ ]
			data[tile].navpoly = shape
			cache[shape].append(data[tile])
	return data

func add_collision(shape_data): 
	collisions.append(shape_data)
	for tex_data in tileset_data:
		tex_data.collisions_cache[shape_data] = Array()
func add_navpoly(shape_data): 
	navpolys.append(shape_data)
	for tex_data in tileset_data:
		tex_data.navpolys_cache[shape_data] = Array()
func add_occluder(shape_data): 
	occluders.append(shape_data)
	for tex_data in tileset_data:
		tex_data.occluders_cache[shape_data] = Array()

func remove_collision(shape_id): 
	var shape = collisions[shape_id]
	collisions.remove(shape_id)
	# Remove that shape from each tile
	for ts_data in tileset_data:
		for tile_data in ts_data.collisions_cache[shape]:
			tile_data.erase("collision")
func remove_navpoly(shape_id): 
	var shape = navpolys[shape_id]
	navpolys.remove(shape_id)
	# Remove that shape from each tile
	for ts_data in tileset_data:
		for tile_data in ts_data.navpolys_cache[shape]:
			tile_data.erase("navpoly")
func remove_occluder(shape_id): 
	var shape = occluders[shape_id]
	occluders.remove(shape_id)
	# Remove that shape from each tile
	for ts_data in tileset_data:
		for tile_data in ts_data.occluders_cache[shape]:
			tile_data.erase("occluder")

func attach_collision(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var shape_data = collisions[shape_id]
	tex_data.data[tile_pos]["collision"] = shape_data
	if !tex_data.collisions_cache.has(shape_data):
		tex_data.collisions_cache[shape_data] = []
	tex_data.collisions_cache[shape_data].append( tex_data.data[tile_pos] )
func attach_navpoly(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var shape_data = navpolys[shape_id]
	tex_data.data[tile_pos]["navpoly"] = shape_data
	tex_data.navpolys_cache[shape_data].append( tex_data.data[tile_pos] )
func attach_occluder(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var shape_data = occluders[shape_id]
	tex_data.data[tile_pos]["occluder"] = shape_data
	tex_data.occluders_cache[shape_data].append( tex_data.data[tile_pos] )

func deattach_collision(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var tile_data = tileset_data[tex_id].data[tile_pos]
	var shape = collisions[shape_id]
	if tile_data.has("collision") and tile_data["collision"]==shape:
		tile_data.erase("collision")
	if tex_data.collisions_cache.has(shape) and tex_data.collisions_cache[shape].has(tile_data):
		tex_data.collisions_cache[shape].erase( tile_data )
func deattach_navpoly(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var tile_data = tileset_data[tex_id].data[tile_pos]
	var shape = navpolys[shape_id]
	if tile_data.has("navpoly") and tile_data["navpoly"]==shape:
		tile_data.erase("navpoly")
	if tex_data.navpolys_cache.has(shape) and tex_data.navpolys_cache[shape].has(tile_data):
		tex_data.navpolys_cache[shape].erase( tile_data )
func deattach_occluder(tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var tile_data = tileset_data[tex_id].data[tile_pos]
	var shape = occluders[shape_id]
	if tile_data.has("occluder") and tile_data["occluder"]==shape:
		tile_data.erase("occluder")
	if tex_data.occluders_cache.has(shape) and tex_data.occluders_cache[shape].has(tile_data):
		tex_data.occluders_cache[shape].erase( tile_data )
