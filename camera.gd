extends Node2D

@onready var camera_pictures: AnimatedSprite2D = $AnimatedSprite2D
@onready var blip: AudioStreamPlayer = $"../blip"
@onready var camera_flip: AudioStreamPlayer = $"../camera_flip"
@onready var camera_static: AudioStreamPlayer = $"../camera_static"

# Power drain variables
var power_drain_interval: float = 0.3  # How often to drain power (in seconds)
var power_drain_step: float = 0.7  # How much power to drain per step
var power_drain_timer: float = 0.0

# Power recharge variables
var power_recharge_interval: float = 0.2  # How often to recharge power (in seconds)
var power_recharge_step: float = 0.2  # How much power to recharge per step
var power_recharge_timer: float = 0.0

func _ready() -> void:
	visible = false  # Start with this node (Camera) hidden
	
	# Set camera_static to loop
	camera_static.set_stream_paused(false)
	if camera_static.stream:
		camera_static.stream.loop = true
	
	# Initialize power if not already set
	if not "PowerLV" in Global:
		Global.PowerLV = 100.0
	
	print("[CAMERA] Power drain settings: Interval=", power_drain_interval, "s, Step=", power_drain_step)
	print("[CAMERA] Power recharge settings: Interval=", power_recharge_interval, "s, Step=", power_recharge_step)

func _process(delta: float) -> void:
	# Check if power has run out and cameras are still open
	if Global.PowerLV <= 0 and visible:
		visible = false
		camera_static.stop()  # Stop static sound when cameras forced closed
		print("[CAMERA] Power depleted! Cameras forced closed!")
		power_drain_timer = 0.0
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
		power_recharge_timer = 0.0  # Reset recharge timer while draining
		
		if power_drain_timer >= power_drain_interval:
			power_drain_timer = 0.0
			Global.PowerLV -= power_drain_step
			
			# Clamp power to not go below 0
			if Global.PowerLV < 0:
				Global.PowerLV = 0
			
			# Print power level (rounded to 1 decimal place)
			print("[POWER] Current Power Level: ", snappedf(Global.PowerLV, 0.1), "%")
	else:
		# Recharge power when cameras are closed
		power_drain_timer = 0.0  # Reset drain timer while recharging
		power_recharge_timer += delta
		
		if power_recharge_timer >= power_recharge_interval:
			power_recharge_timer = 0.0
			Global.PowerLV += power_recharge_step
			
			# Clamp power to not go above 100
			if Global.PowerLV > 100:
				Global.PowerLV = 100
			
			# Only print if we actually recharged (not at max)
			if Global.PowerLV < 100 or (Global.PowerLV == 100 and Global.PowerLV - power_recharge_step < 100):
				print("[POWER] Recharging... Power Level: ", snappedf(Global.PowerLV, 0.1), "%")

func _on_button_pressed() -> void:
	Global.current_cam = 1
	blip.play()

func _on_button_2_pressed() -> void:
	Global.current_cam = 2
	blip.play()
	
func _on_button_3_pressed() -> void:
	Global.current_cam = 3
	blip.play()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("opencams"):
		# Check if power is depleted before allowing cameras to open
		if Global.PowerLV <= 0:
			print("[CAMERA] Cannot open cameras - No power remaining!")
			return
		
		visible = !visible  # Toggle visibility of this node
		
		if visible:
			camera_flip.play()  # Play camera flip sound when opening
			camera_static.play()  # Play static sound when cameras are up
			print("[CAMERA] Cameras opened - Power draining!")
		else:
			camera_flip.play()  # Play camera flip sound when closing
			camera_static.stop()  # Stop static sound when cameras close
			print("[CAMERA] Cameras closed - Power drain stopped")
			power_drain_timer = 0.0  # Reset timer when cameras close
