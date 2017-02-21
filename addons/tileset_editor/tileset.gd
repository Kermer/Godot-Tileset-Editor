tool

extends Resource

const TextureProperties = preload("res://addons/tileset_editor/classes/TextureProperties.gd")
const ShapeData = preload("res://addons/tileset_editor/classes/ShapeData.gd")

var shapes = {
	"collision":[],
	"occluder":[],
	"navpoly":[]
	}
var tileset_data = [] #array of TextureProperties
#var collisions = [] # holds available collision shapes
#var occluders = [] # holds available occluders
#var navpolys = [] # holds available navpolys

static func prop(name,type,hint=""):
	return {"name":name,"type":type,"hint":""}

func _get_property_list():
	var properties = []
	var prop = null
	
	#prop = prop("texture_count",TYPE_INT,"Amount of textures used in this tileset")
	#properties.push_back( prop )
	
	prop = prop("shapes/collision",TYPE_ARRAY)
	properties.push_back( prop )
	prop = prop("shapes/occluder",TYPE_ARRAY)
	properties.push_back( prop )
	prop = prop("shapes/navpoly",TYPE_ARRAY)
	properties.push_back( prop )
	
	prop = prop("textures_data",TYPE_ARRAY)
	properties.push_back( prop )
	
	return properties

func _get(property):
	if property=="texture_count":
		return tileset_data.size()
	elif property == "textures_data":
		return tileset_data
	elif property.begins_with("shapes/"):
		var type = property.split("/")[1]
		return shapes[type]
	return null

func _set(property, value):
	if property == "textures_data":
		tileset_data = value
	elif property.begins_with("shapes/"):
		var type = property.split("/")[1]
		shapes[type] = value

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
				var tex_pos = Vector2(ts_data.tile_size.x+ts_data.tile_sep.x,ts_data.tile_size.y+ts_data.tile_sep.y) * t_pos
				tex_pos += Vector2(ts_data.offset.x,ts_data.offset.y)
				var tex_rect = Rect2(tex_pos, Vector2(ts_data.tile_size.x,ts_data.tile_size.y))
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
func pack_data(data):
	var rvalue = {}
	for tile_pos in data:
		var tile_data = {}
		for key in data[tile_pos]:
			if key in shapes.keys(): # it's a shape
				tile_data[key] = shapes[key].find( data[tile_pos][key] )
			else: # something else ("export", etc.)
				tile_data[key] = data[tile_pos][key]
		if tile_data.size() > 0:
			rvalue[tile_pos] = tile_data
	return rvalue


# Change Shape ID to shape reference and generate Cache
#	Int -> Dictionary
func unpack_data(tex,data):
	for tile in data:
		for key in data[tile]:
			if key in shapes.keys():
				var shape_id = data[tile][key]
				var shape_data = shapes[key][shape_id]
				if !tex.cache.has(shape_data):
					tex.cache[shape_data] = Array()
				data[tile][key] = shape_data
				tex.cache[shape_data].append(data[tile])
	return data

func pack_shapes(shapes):
	var rvalue = {}
	for type in shapes:
		rvalue[type] = []
		for shape_data in shapes[type]:
			rvalue[type].append( shape_data.serialize() )
	return rvalue

func unpack_shapes(shapes):
	var rvalue = {}
	for type in shapes:
		rvalue[type] = []
		for shape in shapes[type]:
			var shape_data = ShapeData.new()
			shape_data.deserialize(shape)
			rvalue[type].append(shape_data)
	return rvalue


func add_shape(data):
	var shape_data = ShapeData.new(data.type,data.name,data.icon,data.icon_region,data.shape,data.offset)
	shapes[data.type].append(shape_data)
	for ts_data in tileset_data:
		ts_data.cache[shape_data] = Array()

func remove_shape(type,shape_id):
	var shape_data = shapes[type][shape_id]
	# Remove that shape from each tile
	print("Remove '",type,"'")
	for ts_data in tileset_data:
		for tile_pos in ts_data.cache[shape_data]:
			ts_data.data[tile_pos].erase(type)
		ts_data.cache.erase(shape_data)
	shapes[type].remove(shape_id)

func attach_shape(type,tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var shape_data = shapes[type][shape_id]
	tex_data.data[tile_pos][type] = shape_data
	var cache = Array()
	if tex_data.cache.has(shape_data):
		cache = tex_data.cache[shape_data]
	cache.push_back( tile_pos )
	tex_data.cache[shape_data] = cache

func deattach_shape(type,tex_id,tile_pos,shape_id):
	var tex_data = tileset_data[tex_id]
	var tile_data = tileset_data[tex_id].data[tile_pos]
	var shape_data = shapes[type][shape_id]
	if tile_data.has(type) and tile_data[type]==shape_data:
		tile_data.erase(type)
	if tex_data.cache.has(shape_data) and tex_data.cache[shape_data].has(tile_pos):
		tex_data.cache[shape_data].erase(tile_pos)
