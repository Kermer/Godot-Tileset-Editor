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

var tileset_data = [] #array of TextureProperties
var collisions = []
var occluders = []
var navpolys = []

func _get_property_list():
	var d = {}
	var properties = []
	
	d["name"] = "texture_count"
	d["type"] = TYPE_INT
	d["hint"] = "Amount of textures used in this tileset"
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
		if property == "x_off":
			return data.x_off
		if property == "y_off":
			return data.y_off
		if property == "w":
			return data.w
		if property == "h":
			return data.h
		if property == "x_sep":
			return data.x_sep
		if property == "y_sep":
			return data.y_sep
		if property == "data":
			return data.data
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
			print("curent_count: "+str(tileset_data.size()))
			for i in range(tileset_data.size(),value):
				tileset_data.push_back(TextureProperties.new())
			print("curent_count: "+str(tileset_data.size()))
		else:
			tileset_data.resize(value)
	elif property.begins_with("texture_"):
		var id = int(property.split("/")[0].split("_")[1])
		var data = tileset_data[id]
		property=property.split("/")[1]
		if property == "texture":
			data.texture = value
		if property == "x_off":
			data.x_off = value
		if property == "y_off":
			data.y_off = value
		if property == "w":
			data.w = value
		if property == "h":
			data.h = value
		if property == "x_sep":
			data.x_sep = value
		if property == "y_sep":
			data.y_sep = value
		if property == "data":
			data.data = value
	elif property == "collisions":
		collisions = value
	elif property == "occluders":
		occluders = value
	elif property == "navpolys":
		navpolys = value


func generate_tileset():
	var tileset = TileSet.new()
	var id = 0
	for ts_data in tileset_data:
		var tid = 0 # relative to Texture instead of to Tileset
		for t_pos in ts_data.data:
			if ts_data.data[t_pos]["export"] == true:
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
				# TODO: Attach Collision, Occluder, Navigation
				id += 1; tid += 1
	return tileset
