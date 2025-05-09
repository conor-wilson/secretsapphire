class_name Desktop extends Node2D

signal s_collected(global_pos:Vector2)
signal a_collected(global_pos:Vector2)
signal hammer_man_level_changed

const this_is_actually_fine_message:String = "\"THIS ACTUALLY IS FINE!\nTRY THIS:                      \""

enum Mode {DISABLED, STATIC, ACTIVE}
var mode:Mode = Mode.DISABLED

var hammer_man_in_escape_zone:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	HammerManManager.set_desktop_singleton(self)
	mode = Mode.DISABLED

func _process(delta: float) -> void:
	
	# Check if A1 is collectable
	$DesktopWindows/TurtleMemeWEBP/A.set_can_collect($DesktopWindows/TurtleMemeWEBP/A/BlockingFire.get_children().size() == 0)
	
	# Check if the fire has been completely doused
	if (
		$DesktopWindows/TurtleMemeWEBP/A/BlockingFire.get_children().size() == 0 &&
		$DesktopWindows/TurtleMemeWEBP/Fire.get_children().size() == 0 &&
		$DesktopWindows/TurtleMemeWEBP/Caption.text != this_is_actually_fine_message
	):
		$DesktopWindows/TurtleMemeWEBP/Caption.text = this_is_actually_fine_message
		$DesktopWindows/TurtleMemeWEBP/Arrows.show()

func _on_screen_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	# Confirm that the screen can be interacted with
	if mode == Mode.DISABLED:
		return
	
	if event.is_pressed() && event.is_action("click") && mode == Mode.STATIC:
		$Static.clear_circle(_get_mouse_cell_coords())
		ScreenShakeManager.shake_screen(5,5, $Static.clearing_all)

func set_static_mode():
	mode = Mode.STATIC

func set_active_mode():
	mode = Mode.ACTIVE
	for icon in $DesktopIcons.get_children():
		icon.disabled = false
	for window in $DesktopWindows.get_children():
		window.disabled = false

func _get_mouse_cell_coords() -> Vector2i:
	var coords:Vector2 = get_global_mouse_position() 
	return Vector2i(
		floor(coords.x/$Static.tile_set.tile_size.x),
		floor(coords.y/$Static.tile_set.tile_size.y),
	)

func clear_all_static():
	$Static.clear_all()
	mode = Mode.DISABLED # TODO: Maybe we should wait until the static is cleared to disable the static? This would require a signal.

func _on_screen_body_entered(body: Node2D) -> void:
	if body is RunningLetter:
		body.set_can_enter_desktop(true)
	
	if body is HammerMan:
		HammerManManager.call_deferred("move_to_desktop")


func _on_screen_body_exited(body: Node2D) -> void:
	if body is RunningLetter:
		body.set_can_enter_desktop(false)
	
	if body is HammerMan && body.get_parent() == self: # TODO: Maybe the get_parent() bit of this check should be in the HammerManManager script?
		HammerManManager.call_deferred("move_to_menus")


## HAMMER MAN STUFF

func _on_hammer_man_exe_icon_double_clicked() -> void:
	$DesktopWindows/HammerManEXE/HammerManGame.open()

func _on_a_collect() -> void:
	a_collected.emit($DesktopWindows/TurtleMemeWEBP/A.global_position)

func _on_hammer_man_exe_close_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("click") && !event.is_action_pressed("pan"):
		$DesktopWindows/HammerManEXE/HammerManGame.close()

func _on_hammer_man_game_level_changed() -> void:
	hammer_man_level_changed.emit()

func _on_hammer_man_game_s_collected(global_pos:Vector2) -> void:
	s_collected.emit(global_pos)

func _on_escape_zone_body_entered(body: Node2D) -> void:
	if body is HammerMan:
		hammer_man_in_escape_zone = true

func _on_escape_zone_body_exited(body: Node2D) -> void:
	if body is HammerMan:
		hammer_man_in_escape_zone = false


## VIRUS SCANNER STUFF

func _on_virus_scan_timer_timeout() -> void:
	$DesktopWindows/Antivirus/SeemsFine.text = "seems fine idk."

func _on_virus_scan_close_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("click") && !event.is_action_pressed("pan") && CursorManager.current_cursor == CursorManager.CURSOR:
		$DesktopWindows/Antivirus/SeemsFine.text = ""

func _on_scan_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (
		mode == Mode.ACTIVE && 
		CursorManager.current_cursor == CursorManager.CURSOR
		):
		
		if (
			CursorManager.current_dragging_object == null && 
			CursorManager.current_hovering_object == $DesktopWindows/Antivirus
			):
			
			if event.is_action_pressed("click") && !event.is_action_pressed("pan"):
				$DesktopWindows/Antivirus/ScanButton.scale = Vector2(1.10, 1.10)
				$DesktopWindows/Antivirus/SeemsFine.text = "scanning..."
				$DesktopWindows/Antivirus/VirusScanTimer.start()
			
			elif event is InputEventMouse:
				$DesktopWindows/Antivirus/ScanButton.scale = Vector2(1.05, 1.05)
		
		elif event is InputEventMouse:
			$DesktopWindows/Antivirus/ScanButton.scale = Vector2(1, 1)

func _on_scan_button_mouse_exited() -> void:
	if mode == Mode.ACTIVE && CursorManager.current_cursor == CursorManager.CURSOR:
		$DesktopWindows/Antivirus/ScanButton.scale = Vector2(1, 1)

func _on_fire_extinguisher_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("click") && !event.is_action_pressed("pan") && mode == Mode.ACTIVE && CursorManager.current_cursor == CursorManager.CURSOR:
		$DesktopWindows/Antivirus/FireExtinguisher.hide()
		CursorManager.set_mouse_cursor(CursorManager.FIRE_EXTINGUISHER)


## RECYCLING BIN STUFF

func _on_recycling_bin_icon_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if mode == Mode.ACTIVE && event is InputEventMouse && CursorManager.current_cursor == CursorManager.CURSOR:
		if CursorManager.current_hovering_object == null && CursorManager.current_dragging_object == null:
			$RecyclingBinIcon.scale = Vector2(1.05, 1.05)
		else: 
			$RecyclingBinIcon.scale = Vector2(1, 1)

func _on_recycling_bin_icon_mouse_exited() -> void:
	if mode == Mode.ACTIVE && CursorManager.current_cursor == CursorManager.CURSOR:
		$RecyclingBinIcon.scale = Vector2(1, 1)

func _on_recycling_bin_icon_click() -> void:
	if (
		mode == Mode.ACTIVE && 
		CursorManager.current_cursor == CursorManager.CURSOR && 
		CursorManager.current_dragging_object == null && 
		CursorManager.current_hovering_object == null
		):
		$RecyclingBinIcon.detatch(5)

func _on_recycling_bin_icon_smash() -> void:
	$RigidScraps.show()
	print("BOOM GOES THE SCRAPS")
	for scrap in $RigidScraps.get_children():
		if scrap is InteractiveElement:
			scrap.detatch()
			scrap.set_collision_mask_value(16, true) # Doing this now prevents HammerMan from hitting them when they're not visible yet
			scrap.apply_random_force(450, 550)


## HOME BUTTON STUFF

func _on_home_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (
		mode == Mode.ACTIVE && 
		CursorManager.current_cursor == CursorManager.CURSOR
		):
		
		if (
			CursorManager.current_dragging_object == null && 
			CursorManager.current_hovering_object == null
			):
			
			if event.is_action_pressed("click") && !event.is_action_pressed("pan"):
				$HomeButton.scale = Vector2(1.10, 1.10)
				for window in $DesktopWindows.get_children():
					window.hide()
			
			elif event is InputEventMouse:
				$HomeButton.scale = Vector2(1.05, 1.05)
		
		elif event is InputEventMouse:
			$HomeButton.scale = Vector2(1, 1)

func _on_home_button_mouse_exited() -> void:
	if mode == Mode.ACTIVE && CursorManager.current_cursor == CursorManager.CURSOR:
		$HomeButton.scale = Vector2(1, 1)
