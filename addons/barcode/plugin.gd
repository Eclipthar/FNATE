@tool
extends EditorPlugin

const CLASSES := [
	{
		"name": "BarCode39",
		"base": "Control",
		"script": "res://addons/barcode/code_39.gd",
		"icon": "res://addons/barcode/barcode_39_48px.svg"
	},
	{
		"name": "BarCode128A",
		"base": "Control",
		"script": "res://addons/barcode/code_128_a.gd",
		"icon": "res://addons/barcode/barcode_128a_48px.svg"
	},
	{
		"name": "BarCode128B",
		"base": "Control",
		"script": "res://addons/barcode/code_128_b.gd",
		"icon": "res://addons/barcode/barcode_128b_48px.svg"
	},
	{
		"name": "BarCode128C",
		"base": "Control",
		"script": "res://addons/barcode/code_128_c.gd",
		"icon": "res://addons/barcode/barcode_128c_48px.svg"
	}
]

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass
	for class_info in CLASSES:
		var script := load(class_info["script"])
		add_custom_type(class_info["name"], class_info["base"], script, load(class_info["icon"]))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
	for class_info in CLASSES:
		remove_custom_type(class_info["name"])
