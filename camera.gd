extends Node2D

@onready var camera_pictures: AnimatedSprite2D = $AnimatedSprite2D
@onready var blip: AudioStreamPlayer = $"../blip"
@onready var camera_flip: AudioStreamPlayer = $"../camera_flip"
@onready var camera_static: AudioStreamPlayer = $"../camera_static"
@onready var color_rect: ColorRect = $ColorRect
@onready var bb: Sprite2D = $BB
@onready var offline_system: Control = $OfflineSystem
@onready var label: Label = $"../Power Level/Label"

# Power drain variables
var power_drain_interval: float = 0.3
var power_drain_step: float = 0.7
var power_drain_timer: float = 0.0

# Power recharge variables
var power_recharge_interval: float = 0.2
var power_recharge_step: float = 0.2
var power_recharge_timer: float = 0.0

# Power out state
var power_is_out: bool = false

func _ready() -> void:
	visible = false
	
	camera_static.set_stream_paused(false)
	if camera_static.stream:
		camera_static.stream.loop = true
	
	if not "PowerLV" in Global:
		Global.PowerLV = 100.0
	
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 0.182)
		color_rect.material.set_shader_parameter("color_offset", 0.5)
	
	print("[CAMERA] Power drain settings: Interval=", power_drain_interval, "s, Step=", power_drain_step)
	print("[CAMERA] Power recharge settings: Interval=", power_recharge_interval, "s, Step=", power_recharge_step)

func _process(delta: float) -> void:
	# Check if power has run out for the first time
	if Global.PowerLV <= 0 and not power_is_out:
		power_is_out = true
		visible = false
		camera_static.stop()
		label.visible = false  # Hide the power label
		print("[CAMERA] POWER OUT! Cameras permanently disabled!")
		power_drain_timer = 0.0
		return
	
	# If power is out, don't process anything else
	if power_is_out:
		return
	
	# Handle camera sprite updates
	if Global.current_cam == 1:
		if Global.darkbear_location == 1:
			camera_pictures.frame = 1
		else:
			camera_pictures.frame = 0
			
	if Global.current_cam == 2:
		if Global.darkbear_location == 2:
			camera_pictures.frame = 3
		else:
			camera_pictures.frame = 2
			
	if Global.current_cam == 3:
		if Global.darkbear_location == 3:
			camera_pictures.frame = 5
		else:
			camera_pictures.frame = 4
	
	# Drain power when cameras are up
	if visible:
		power_drain_timer += delta
		power_recharge_timer = 0.0
		
		if power_drain_timer >= power_drain_interval:
			power_drain_timer = 0.0
			Global.PowerLV -= power_drain_step
			
			if Global.PowerLV < 0:
				Global.PowerLV = 0
			
			print("[POWER] Current Power Level: ", snappedf(Global.PowerLV, 0.1), "%")
	else:
		# Recharge power when cameras are closed (only if power isn't out)
		power_drain_timer = 0.0
		power_recharge_timer += delta
		
		if power_recharge_timer >= power_recharge_interval:
			power_recharge_timer = 0.0
			Global.PowerLV += power_recharge_step
			
			if Global.PowerLV > 100:
				Global.PowerLV = 100
			
			if Global.PowerLV < 100 or (Global.PowerLV == 100 and Global.PowerLV - power_recharge_step < 100):
				print("[POWER] Recharging... Power Level: ", snappedf(Global.PowerLV, 0.1), "%")

func _on_button_pressed() -> void:
	if get_parent().is_jumpscared or power_is_out:
		return
	
	Global.current_cam = 1
	blip.play()
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 1.0)
		color_rect.material.set_shader_parameter("color_offset", 75.0)
	await get_tree().create_timer(0.1).timeout
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 0.182)
		color_rect.material.set_shader_parameter("color_offset", 0.5)

func _on_button_2_pressed() -> void:
	if get_parent().is_jumpscared or power_is_out:
		return
	
	Global.current_cam = 2
	blip.play()
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 1.0)
		color_rect.material.set_shader_parameter("color_offset", 75.0)
	await get_tree().create_timer(0.1).timeout
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 0.182)
		color_rect.material.set_shader_parameter("color_offset", 0.5)
	
func _on_button_3_pressed() -> void:
	if get_parent().is_jumpscared or power_is_out:
		return
	
	Global.current_cam = 3
	blip.play()
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 1.0)
		color_rect.material.set_shader_parameter("color_offset", 75.0)
	await get_tree().create_timer(0.1).timeout
	if color_rect.material:
		color_rect.material.set_shader_parameter("flicker_intensity", 0.182)
		color_rect.material.set_shader_parameter("color_offset", 0.5)
	
func _input(event: InputEvent) -> void:
	if get_parent().is_jumpscared or power_is_out:
		return
	
	if event.is_action_pressed("opencams"):
		if Global.PowerLV <= 0:
			print("[CAMERA] Cannot open cameras - No power remaining!")
			return
		
		visible = !visible
		
		if visible:
			camera_flip.play()
			camera_static.play()
			print("[CAMERA] Cameras opened - Power draining!")
		else:
			camera_flip.play()
			camera_static.stop()
			print("[CAMERA] Cameras closed - Power drain stopped")
			power_drain_timer = 0.0
