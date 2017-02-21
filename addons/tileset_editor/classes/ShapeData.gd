tool
extends Resource

var type = ""
var name = ""
var icon = null
var icon_region = Rect2(0,0,0,0)
var shape = null
var offset = Vector2()
func _init(_type=null,_name=null,_icon=null,_icon_region=null,_shape=null,_offset=null):
	type=_type;name=_name;icon=_icon;icon_region=_icon_region;shape=_shape;offset=_offset

static func prop(name,type,hint=""):
	return {"name":name,"type":type,"hint":""}
func _get_property_list():
	var properties = []
	var prop = null
	prop = prop("type",TYPE_STRING); properties.push_back(prop)
	prop = prop("name",TYPE_STRING); properties.push_back(prop)
	prop = prop("icon",TYPE_OBJECT); properties.push_back(prop)
	prop = prop("icon_region",TYPE_RECT2); properties.push_back(prop)
	prop = prop("shape",TYPE_OBJECT); properties.push_back(prop)
	prop = prop("offset",TYPE_VECTOR2); properties.push_back(prop)
	return properties