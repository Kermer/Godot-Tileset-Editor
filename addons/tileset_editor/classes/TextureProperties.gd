tool
extends Resource

var texture = null
var offset = Vector2()
var tile_size = Vector2(64,64)
var tile_sep = Vector2()
var data = {}
# Cache holds info about which tiles use each shape, NOT EXPORTED, GENERATED ON RESOURCE LOAD
#	helpful when removing shapes from the list
#	{ shape:Array(of tile_data) }
var cache = {}

static func prop(name,type,hint=""):
	return {"name":name,"type":type,"hint":""}
func _get_property_list():
	var properties = []
	var prop = null
	prop = prop("texture",TYPE_OBJECT); properties.push_back(prop)
	prop = prop("offset",TYPE_VECTOR2); properties.push_back(prop)
	prop = prop("tile_size",TYPE_VECTOR2); properties.push_back(prop)
	prop = prop("tile_sep",TYPE_VECTOR2); properties.push_back(prop)
	prop = prop("data",TYPE_DICTIONARY); properties.push_back(prop)
	return properties
func _set(property,value):
	if property == "data":
		data = value
		refresh_cache()
	else:
		set(property,value)

func refresh_cache():
	for tile_pos in data:
		for key in data[tile_pos]:
			if key in ["collision","occluder","navpoly"]:
				var shape_data = data[tile_pos][key]
				var _cache = Array()
				if cache.has( shape_data ):
					_cache = cache[shape_data]
				_cache.push_back(tile_pos)
				cache[shape_data] = _cache
