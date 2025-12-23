extends Node2D

@onready var game_pictures: AnimatedSprite2D = $Sprite2D
@onready var camera_pictures: AnimatedSprite2D = $Camera/AnimatedSprite2D
@onready var camera: Node2D = $Camera
@onready var scare: AudioStreamPlayer = $scare
@onready var jumpscare: AudioStreamPlayer = $jumpscare
@onready var powerdown: AudioStreamPlayer = $powerdown
@onready var shock: AudioStreamPlayer = $shock
@onready var music_box: AudioStreamPlayer = $music_box

var darkbear_wait_timer := 0.0

# Darkbear AI variables
var darkbear_activation_timer: float = 0.0
var darkbear_movement_timer: float = 0.0
var darkbear_is_active: bool = false

# Jumpscare timer variables
var office_stare_timer: float = 0.0
var camera_up_timer: float = 0.0
var is_jumpscared: bool = false

# Shock system variables
var shock_cooldown: float = 0.0
var shock_ready: bool = true
const SHOCK_COOLDOWN_TIME: float = 5.0
var shock_flash_timer: float = 0.0
var is_shock_flashing: bool = false

# Power outage variables
var power_out_timer: float = 0.0
var is_power_out: bool = false
var power_flicker_timer: float = 0.0
var power_flicker_state: bool = false
var music_box_started: bool = false

# Window shake variables
var is_shaking: bool = false
const SHAKE_DURATION: float = 5.0
const SHAKE_INTENSITY: int = 500

# Konami code variables
var konami_sequence: Array = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_input: Array = []
var debug_overlay_visible: bool = false

# Location connection map
var location_connections = {
	1: [2, 3],
	2: [1, 3],
	3: [1, 2, 4],
	4: []
}

func _ready() -> void:
	print("=== GAME STARTED ===")
	# Initialize Darkbear
	Global.darkbear_location = 1
	Global.darkbear_AIlv = 3
	Global.PowerLV = 100.0  # Reset power to full on game start
	
	darkbear_activation_timer = 60.0 / Global.darkbear_AIlv
	darkbear_movement_timer = 0.0
	
	# Create debug overlay
	create_debug_overlay()
	
	if camera.has_node("../camera_static"):
		var camera_static = camera.get_node("../camera_static")
		if camera_static.stream:
			camera_static.stream.loop = true
	
	print("Darkbear AI Level: ", Global.darkbear_AIlv)
	print("Darkbear Starting Location: ", Global.darkbear_location, " (Main Stage)")
	print("Activation Time: ", darkbear_activation_timer, " seconds")
	print("Movement Check Interval: ", 10.0 / Global.darkbear_AIlv, " seconds")
	print("CONTROLS: Press SPACE to use shock system")
	print("SECRET: Try the Konami code!")
	print("SUPER SECRET: Try the Konami code with LEFT SHIFT held!")
	print("===================")

func _input(event):

		
	# Block all input during jumpscare
	if is_jumpscared:
		return
		
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	
	if event.is_action_pressed("ui_accept"):
		use_shock()
	
	# Konami code detection
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name = ""
		
		if event.keycode == KEY_UP:
			key_name = "up"
		elif event.keycode == KEY_DOWN:
			key_name = "down"
		elif event.keycode == KEY_LEFT:
			key_name = "left"
		elif event.keycode == KEY_RIGHT:
			key_name = "right"
		elif event.keycode == KEY_B:
			key_name = "b"
		elif event.keycode == KEY_A:
			key_name = "a"
		
		if key_name != "":
			konami_input.append(key_name)
			
			if konami_input.size() > 10:
				konami_input.pop_front()
			
			if konami_input == konami_sequence:
				# Check if shift is currently held when code completes
				if Input.is_key_pressed(KEY_SHIFT):
					# Debug overlay version
					print(">>> KONAMI CODE + SHIFT ACTIVATED! DEBUG OVERLAY ENABLED! <<<")
					debug_overlay_visible = !debug_overlay_visible
					if has_node("DebugOverlay"):
						get_node("DebugOverlay").visible = debug_overlay_visible
				else:
					# Normal konami code
					print(">>> KONAMI CODE ACTIVATED! DARKBEAR TELEPORTED TO OFFICE! <<<")
					Global.darkbear_location = 4
					darkbear_is_active = true
					scare.play()
				
				konami_input.clear()

func _process(delta: float) -> void:
	if is_jumpscared:
		return
	
	# Update debug overlay if visible
	if debug_overlay_visible:
		update_debug_overlay()
	
	check_power_status()
	
	if is_power_out:
		handle_power_outage(delta)
		return
	
	if is_shock_flashing:
		shock_flash_timer -= delta
		if shock_flash_timer <= 0:
			is_shock_flashing = false
			print("[SHOCK] Flash effect ended")
		update_office_sprite()
		return
	
	if not shock_ready:
		shock_cooldown -= delta
		if shock_cooldown <= 0:
			shock_ready = true
			print("[SHOCK] Shock system recharged and ready!")
	
	update_office_sprite()
	
	if not darkbear_is_active:
		darkbear_activation_timer -= delta
		
		if int(darkbear_activation_timer) != int(darkbear_activation_timer + delta):
			print("[WAITING] Darkbear activates in: ", int(darkbear_activation_timer), " seconds")
		
		if darkbear_activation_timer <= 0:
			print("*** DARKBEAR ACTIVATED! ***")
			darkbear_is_active = true
			darkbear_move_darkbear()
	
	if darkbear_is_active:
		darkbear_movement_timer += delta
		var movement_interval = 10.0 / Global.darkbear_AIlv
		
		if darkbear_movement_timer >= movement_interval:
			darkbear_movement_timer = 0.0
			print("[CHECK] Movement check triggered!")
			darkbear_attempt_move()
	
	if Global.darkbear_location == 4 and not is_power_out:
		handle_office_jumpscare_mechanics(delta)

func check_power_status() -> void:
	if Global.PowerLV <= 0 and not is_power_out:
		print("!!! POWER OUT !!!")
		powerdown.play()
		is_power_out = true
		power_out_timer = 0.0
		camera.visible = false
		print("[POWER] Power depleted! Darkbear will arrive in 10 seconds...")

func handle_power_outage(delta: float) -> void:
	power_out_timer += delta
	
	if power_out_timer < 10.0:
		game_pictures.frame = 3
		
		if int(power_out_timer) != int(power_out_timer - delta):
			print("[POWER] Darkbear arrives in ", int(10 - power_out_timer), " seconds...")
	
	elif power_out_timer >= 10.0 and Global.darkbear_location != 4:
		print(">>> DARKBEAR APPEARED IN OFFICE DUE TO POWER OUTAGE! <<<")
		Global.darkbear_location = 4
		power_flicker_timer = 0.0
	
	if power_out_timer >= 10.0 and power_out_timer < 20.0:
		# Start music box when flickering begins
		if not music_box_started:
			music_box.play()
			music_box_started = true
			print("[MUSIC BOX] Started playing during power flicker")
		
		power_flicker_timer += delta
		
		if power_flicker_timer >= 0.3:
			power_flicker_timer = 0.0
			power_flicker_state = not power_flicker_state
			
			if power_flicker_state:
				game_pictures.frame = 2
			else:
				game_pictures.frame = 3
		
		if int(power_out_timer - 10.0) != int(power_out_timer - 10.0 - delta):
			print("[POWER] Jumpscare in ", int(20 - power_out_timer), " seconds...")
	
	elif power_out_timer >= 20.0:
		print("!!! POWER OUTAGE JUMPSCARE !!!")
		trigger_jumpscare()

func handle_office_jumpscare_mechanics(delta: float) -> void:
	# 🚪 DOOR CLOSED — Darkbear waits and leaves
	if Global.door_state == 1:
		# Reset jumpscare-related timers
		camera_up_timer = 0.0
		office_stare_timer = 0.0
		
		darkbear_wait_timer += delta
		
		if int(darkbear_wait_timer) != int(darkbear_wait_timer - delta):
			print("[DOOR CLOSED] Darkbear waiting... ", int(darkbear_wait_timer), "/5")
		
		if darkbear_wait_timer >= 5.0:
			print("[DARKBEAR] Door closed too long, returning.")
			Global.darkbear_location = 1
			darkbear_wait_timer = 0.0
		
		return  # ⛔ stop here, no jumpscare logic
	
	# 🚪 DOOR OPEN — normal jumpscare behavior
	darkbear_wait_timer = 0.0
	var camera_is_up = camera.visible
	
	if camera_is_up:
		office_stare_timer = 0.0
		camera_up_timer += delta
		
		if int(camera_up_timer) != int(camera_up_timer - delta):
			print("[CAMERA UP] Player has camera up for ", int(camera_up_timer), " seconds (jumpscare at 10)")
		
		if camera_up_timer >= 10.0:
			print("!!! CAMERA TIMEOUT JUMPSCARE !!! Player kept cameras up too long!")
			trigger_jumpscare()
	else:
		camera_up_timer = 0.0
		office_stare_timer += delta
		
		if office_stare_timer > 0 and int(office_stare_timer * 10) != int((office_stare_timer - delta) * 10):
			print("[STARING] Player staring at Darkbear for ", office_stare_timer, " seconds (jumpscare at 1.0)")
		
		if office_stare_timer >= 1.0:
			print("!!! STARE JUMPSCARE !!! Player looked at Darkbear too long!")
			trigger_jumpscare()

func trigger_jumpscare() -> void:
	is_jumpscared = true
	game_pictures.frame = 4
	camera.visible = false
	
	# Stop music box if it's playing
	if music_box.playing:
		music_box.stop()
		print("[MUSIC BOX] Stopped for jumpscare")
	
	jumpscare.play()
	print(">>> GAME OVER - JUMPSCARED <<<")
	
	await start_window_shake()
	
	print("[JUMPSCARE] Returning to main menu...")
	get_tree().quit()

func use_shock() -> void:
	# Block shock during power outage
	if is_power_out:
		print("[SHOCK] Cannot use shock - Power is out!")
		return
	
	if not shock_ready:
		print("[SHOCK] Shock on cooldown! ", shock_cooldown, " seconds remaining")
		return
	
	if Global.darkbear_location == 4:
		print("[SHOCK] *** SHOCK ACTIVATED! Darkbear sent back to Main Stage! ***")
		shock.play()
		Global.darkbear_location = 1
		office_stare_timer = 0.0
		camera_up_timer = 0.0
		
		is_shock_flashing = true
		shock_flash_timer = 4.0
		print("[SHOCK] Shock flash effect started (4 seconds)")
		
		shock_ready = false
		shock_cooldown = SHOCK_COOLDOWN_TIME
		print("[SHOCK] Shock on cooldown for ", SHOCK_COOLDOWN_TIME, " seconds")
		
		game_pictures.frame = 3
	else:
		print("[SHOCK] Shock wasted! Darkbear is not in the office (location: ", Global.darkbear_location, ")")
		shock.play()
		shock_ready = false
		shock_cooldown = SHOCK_COOLDOWN_TIME

func update_office_sprite() -> void:
	var old_frame = game_pictures.frame
	
	if is_shock_flashing:
		game_pictures.frame = 3
		return
	
	if is_power_out:
		return
	
	if Global.darkbear_location == 4:
		if Global.door_state == 1:
			game_pictures.frame = 5
		elif Global.door_state == 0:
			game_pictures.frame = 1
	else:
		if Global.door_state == 1:
			game_pictures.frame = 6
		elif Global.door_state == 0:
			game_pictures.frame = 0
	
	if old_frame != game_pictures.frame:
		print("[SPRITE] Office frame changed: ", old_frame, " -> ", game_pictures.frame)

func darkbear_attempt_move() -> void:
	if Global.darkbear_location == 4:
		return
	
	var roll = randf()
	print("  [ROLL] Movement roll: ", roll, " (needs < 0.25 to move)")
	
	if roll < 0.25:
		print("  [SUCCESS] Movement succeeded!")
		darkbear_move_darkbear()
	else:
		print("  [FAIL] Movement failed, Darkbear stays at location ", Global.darkbear_location)

func darkbear_move_darkbear() -> void:
	var old_location = Global.darkbear_location
	var location_names = {
		1: "Main Stage",
		2: "Party Room",
		3: "Play Room",
		4: "Office"
	}
	
	var possible_moves = location_connections[Global.darkbear_location]
	
	if possible_moves.size() == 0:
		print("[ERROR] No valid moves from location ", Global.darkbear_location)
		return
	
	var new_location = possible_moves[randi() % possible_moves.size()]
	Global.darkbear_location = new_location
	
	if Global.darkbear_location == 4:
		scare.play()
		print(">>> DARKBEAR REACHED OFFICE! Use shock to send him away or get jumpscared! <<<")
	
	print(">>> DARKBEAR MOVED: ", location_names[old_location], " (", old_location, ") -> ", location_names[Global.darkbear_location], " (", Global.darkbear_location, ") <<<")
	print("    Possible next moves from location ", Global.darkbear_location, ": ", location_connections[Global.darkbear_location])

func start_window_shake() -> void:
	if is_shaking:
		return
	
	is_shaking = true
	var window = get_window()
	var original_pos = window.position
	
	var elapsed := 0.0
	
	while elapsed < SHAKE_DURATION:
		var shake_x = randi_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		var shake_y = randi_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		window.position = original_pos + Vector2i(shake_x, shake_y)
		
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	
	window.position = original_pos
	is_shaking = false
	print("[SHAKE] Window shake complete!")

func create_debug_overlay() -> void:
	"""Create the debug overlay panel with interactive controls"""
	var overlay = Panel.new()
	overlay.name = "DebugOverlay"
	overlay.visible = false
	overlay.z_index = 100
	
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(380, 628)
	
	# Style the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.85)
	style_box.border_color = Color(0, 1, 0, 1)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	overlay.add_theme_stylebox_override("panel", style_box)
	
	# Create scroll container for content
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.position = Vector2(8, 8)
	scroll.size = Vector2(364, 612)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	
	# Create VBox for content
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	scroll.add_child(vbox)
	
	# Create label for debug info
	var label = RichTextLabel.new()
	label.name = "DebugLabel"
	label.bbcode_enabled = true
	label.add_theme_color_override("default_color", Color(0, 1, 0, 1))
	label.add_theme_font_size_override("normal_font_size", 11)
	label.custom_minimum_size = Vector2(340, 0)
	label.scroll_active = false
	label.fit_content = true
	vbox.add_child(label)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	# Create buttons container
	var buttons_container = VBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	vbox.add_child(buttons_container)
	
	# Add section header
	var header = Label.new()
	header.text = "=== DEBUG CONTROLS ==="
	header.add_theme_color_override("font_color", Color(1, 1, 0, 1))
	header.add_theme_font_size_override("font_size", 12)
	buttons_container.add_child(header)
	
	# Create buttons with improved styling
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.1, 0.3, 0.1, 1)
	button_style.border_color = Color(0, 1, 0, 1)
	button_style.border_width_left = 1
	button_style.border_width_right = 1
	button_style.border_width_top = 1
	button_style.border_width_bottom = 1
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.2, 0.5, 0.2, 1)
	button_hover.border_color = Color(0, 1, 0, 1)
	button_hover.border_width_left = 1
	button_hover.border_width_right = 1
	button_hover.border_width_top = 1
	button_hover.border_width_bottom = 1
	
	# Button: Trigger Jumpscare
	var btn_jumpscare = Button.new()
	btn_jumpscare.text = "Trigger Jumpscare"
	btn_jumpscare.custom_minimum_size = Vector2(340, 30)
	btn_jumpscare.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_jumpscare.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_jumpscare.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_jumpscare.pressed.connect(_debug_trigger_jumpscare)
	buttons_container.add_child(btn_jumpscare)
	
	# Button: Force Power Out
	var btn_powerout = Button.new()
	btn_powerout.text = "Force Power Outage"
	btn_powerout.custom_minimum_size = Vector2(340, 30)
	btn_powerout.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_powerout.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_powerout.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_powerout.pressed.connect(_debug_force_powerout)
	buttons_container.add_child(btn_powerout)
	
	# Button: Restore Power
	var btn_restore_power = Button.new()
	btn_restore_power.text = "Restore Power (Set 100%)"
	btn_restore_power.custom_minimum_size = Vector2(340, 30)
	btn_restore_power.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_restore_power.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_restore_power.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_restore_power.pressed.connect(_debug_restore_power)
	buttons_container.add_child(btn_restore_power)
	
	# Button: Teleport to Office
	var btn_tp_office = Button.new()
	btn_tp_office.text = "Teleport Darkbear to Office"
	btn_tp_office.custom_minimum_size = Vector2(340, 30)
	btn_tp_office.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_tp_office.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_tp_office.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_tp_office.pressed.connect(_debug_tp_office)
	buttons_container.add_child(btn_tp_office)
	
	# Button: Teleport to Main Stage
	var btn_tp_stage = Button.new()
	btn_tp_stage.text = "Send Darkbear to Main Stage"
	btn_tp_stage.custom_minimum_size = Vector2(340, 30)
	btn_tp_stage.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_tp_stage.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_tp_stage.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_tp_stage.pressed.connect(_debug_tp_stage)
	buttons_container.add_child(btn_tp_stage)
	
	# Button: Activate Darkbear
	var btn_activate = Button.new()
	btn_activate.text = "Activate Darkbear Now"
	btn_activate.custom_minimum_size = Vector2(340, 30)
	btn_activate.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_activate.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_activate.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_activate.pressed.connect(_debug_activate_darkbear)
	buttons_container.add_child(btn_activate)
	
	# Button: Reset Shock Cooldown
	var btn_reset_shock = Button.new()
	btn_reset_shock.text = "Reset Shock Cooldown"
	btn_reset_shock.custom_minimum_size = Vector2(340, 30)
	btn_reset_shock.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_reset_shock.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_reset_shock.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_reset_shock.pressed.connect(_debug_reset_shock)
	buttons_container.add_child(btn_reset_shock)
	
	# Button: Increase AI Level
	var btn_ai_up = Button.new()
	btn_ai_up.text = "AI Level +1"
	btn_ai_up.custom_minimum_size = Vector2(165, 30)
	btn_ai_up.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_ai_up.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_ai_up.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_ai_up.pressed.connect(_debug_ai_increase)
	
	# Button: Decrease AI Level
	var btn_ai_down = Button.new()
	btn_ai_down.text = "AI Level -1"
	btn_ai_down.custom_minimum_size = Vector2(165, 30)
	btn_ai_down.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_ai_down.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_ai_down.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_ai_down.pressed.connect(_debug_ai_decrease)
	
	# Add AI buttons in horizontal container
	var ai_hbox = HBoxContainer.new()
	ai_hbox.add_child(btn_ai_down)
	ai_hbox.add_child(btn_ai_up)
	buttons_container.add_child(ai_hbox)
	
	# Button: Toggle Camera
	var btn_toggle_cam = Button.new()
	btn_toggle_cam.text = "Toggle Camera"
	btn_toggle_cam.custom_minimum_size = Vector2(340, 30)
	btn_toggle_cam.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_toggle_cam.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_toggle_cam.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_toggle_cam.pressed.connect(_debug_toggle_camera)
	buttons_container.add_child(btn_toggle_cam)
	
	# Button: Test Window Shake
	var btn_shake = Button.new()
	btn_shake.text = "Test Window Shake"
	btn_shake.custom_minimum_size = Vector2(340, 30)
	btn_shake.add_theme_stylebox_override("normal", button_style.duplicate())
	btn_shake.add_theme_stylebox_override("hover", button_hover.duplicate())
	btn_shake.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	btn_shake.pressed.connect(_debug_test_shake)
	buttons_container.add_child(btn_shake)
	
	add_child(overlay)
	
	# Position the overlay in top left after adding to tree
	call_deferred("_position_debug_overlay")
	
	print("[DEBUG] Debug overlay created with interactive controls!")

func _position_debug_overlay() -> void:
	"""Position the debug overlay in the top left corner"""
	if not has_node("DebugOverlay"):
		return
	
	var overlay = get_node("DebugOverlay")
	overlay.position = Vector2(10, 10)
	print("[DEBUG] Overlay positioned at: ", overlay.position)

# Debug button callbacks
func _debug_trigger_jumpscare() -> void:
	print("[DEBUG] Force triggering jumpscare!")
	trigger_jumpscare()

func _debug_force_powerout() -> void:
	print("[DEBUG] Forcing power outage!")
	Global.PowerLV = 0
	is_power_out = false  # Reset so check_power_status can trigger it
	check_power_status()

func _debug_restore_power() -> void:
	print("[DEBUG] Restoring power to 100%!")
	Global.PowerLV = 100
	is_power_out = false
	power_out_timer = 0.0
	power_flicker_timer = 0.0
	music_box_started = false
	if music_box.playing:
		music_box.stop()
	update_office_sprite()

func _debug_tp_office() -> void:
	print("[DEBUG] Teleporting Darkbear to Office!")
	Global.darkbear_location = 4
	darkbear_is_active = true
	scare.play()

func _debug_tp_stage() -> void:
	print("[DEBUG] Sending Darkbear to Main Stage!")
	Global.darkbear_location = 1
	office_stare_timer = 0.0
	camera_up_timer = 0.0

func _debug_activate_darkbear() -> void:
	if darkbear_is_active:
		print("[DEBUG] Darkbear is already active!")
	else:
		print("[DEBUG] Activating Darkbear immediately!")
		darkbear_is_active = true
		darkbear_activation_timer = 0.0
		darkbear_move_darkbear()

func _debug_reset_shock() -> void:
	print("[DEBUG] Resetting shock cooldown!")
	shock_ready = true
	shock_cooldown = 0.0
	is_shock_flashing = false
	shock_flash_timer = 0.0

func _debug_ai_increase() -> void:
	Global.darkbear_AIlv += 1
	print("[DEBUG] Increased AI level to: ", Global.darkbear_AIlv)

func _debug_ai_decrease() -> void:
	if Global.darkbear_AIlv > 0:
		Global.darkbear_AIlv -= 1
		print("[DEBUG] Decreased AI level to: ", Global.darkbear_AIlv)
	else:
		print("[DEBUG] AI level already at minimum (0)")

func _debug_toggle_camera() -> void:
	camera.visible = !camera.visible
	print("[DEBUG] Camera toggled: ", camera.visible)

func _debug_test_shake() -> void:
	print("[DEBUG] Testing window shake!")
	start_window_shake()

func update_debug_overlay() -> void:
	"""Update the debug overlay with current game state"""
	if not has_node("DebugOverlay/ScrollContainer/VBox/DebugLabel"):
		return
	
	var label = get_node("DebugOverlay/ScrollContainer/VBox/DebugLabel")
	
	var location_names = {
		1: "Main Stage",
		2: "Party Room", 
		3: "Play Room",
		4: "Office"
	}
	
	var debug_text = "[color=lime]=== DEBUG OVERLAY ===[/color]\n\n"
	
	# Power Info
	debug_text += "[color=yellow]POWER SYSTEM:[/color]\n"
	debug_text += "  Power Level: " + str(snappedf(Global.PowerLV, 0.1)) + "%\n"
	debug_text += "  Power Out: " + str(is_power_out) + "\n"
	if is_power_out:
		debug_text += "  Power Out Timer: " + str(snappedf(power_out_timer, 0.1)) + "s\n"
	debug_text += "\n"
	
	# Camera Info
	debug_text += "[color=yellow]CAMERA SYSTEM:[/color]\n"
	debug_text += "  Cameras Open: " + str(camera.visible) + "\n"
	debug_text += "  Current Camera: " + str(Global.current_cam) + "\n"
	debug_text += "\n"
	
	# Darkbear AI
	debug_text += "[color=yellow]DARKBEAR AI:[/color]\n"
	debug_text += "  AI Level: " + str(Global.darkbear_AIlv) + "\n"
	debug_text += "  Location: " + str(Global.darkbear_location) + " (" + location_names.get(Global.darkbear_location, "Unknown") + ")\n"
	debug_text += "  Active: " + str(darkbear_is_active) + "\n"
	if not darkbear_is_active:
		debug_text += "  Activation Timer: " + str(snappedf(darkbear_activation_timer, 0.1)) + "s\n"
	else:
		debug_text += "  Movement Timer: " + str(snappedf(darkbear_movement_timer, 0.1)) + "s\n"
		debug_text += "  Movement Interval: " + str(snappedf(10.0 / Global.darkbear_AIlv, 0.1)) + "s\n"
	debug_text += "\n"
	
	# Office/Jumpscare
	debug_text += "[color=yellow]OFFICE MECHANICS:[/color]\n"
	debug_text += "  Office Stare Timer: " + str(snappedf(office_stare_timer, 0.1)) + "s / 1.0s\n"
	debug_text += "  Camera Up Timer: " + str(snappedf(camera_up_timer, 0.1)) + "s / 10.0s\n"
	debug_text += "  Is Jumpscared: " + str(is_jumpscared) + "\n"
	debug_text += "\n"
	
	# Shock System
	debug_text += "[color=yellow]SHOCK SYSTEM:[/color]\n"
	debug_text += "  Shock Ready: " + str(shock_ready) + "\n"
	if not shock_ready:
		debug_text += "  Cooldown: " + str(snappedf(shock_cooldown, 0.1)) + "s / " + str(SHOCK_COOLDOWN_TIME) + "s\n"
	debug_text += "  Shock Flashing: " + str(is_shock_flashing) + "\n"
	if is_shock_flashing:
		debug_text += "  Flash Timer: " + str(snappedf(shock_flash_timer, 0.1)) + "s\n"
	debug_text += "\n"
	
	# Sprite/Visual
	debug_text += "[color=yellow]VISUAL STATE:[/color]\n"
	debug_text += "  Office Sprite Frame: " + str(game_pictures.frame) + "\n"
	debug_text += "  Camera Sprite Frame: " + str(camera_pictures.frame) + "\n"
	debug_text += "  Window Shaking: " + str(is_shaking) + "\n"
	debug_text += "\n"
	
	# FPS
	debug_text += "[color=yellow]PERFORMANCE:[/color]\n"
	debug_text += "  FPS: " + str(Engine.get_frames_per_second()) + "\n"
	debug_text += "  Delta: " + str(snappedf(get_process_delta_time() * 1000, 0.1)) + "ms\n"
	
	label.text = debug_text
