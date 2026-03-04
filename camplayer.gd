extends Camera2D

@export var speed = 4000.0

var syncPos := Vector2(0.0, 0.0)
var ui_adjust: Vector2 = Vector2.ZERO
var add_offset: Vector2 = Vector2.ZERO

@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var targettedObject: hackableObject
var targettedObject_option: int = 0
var currentLoadProgress: float = 0.0
var canExecuteCommand: bool = false
var executionLayer: int = 0 # 0 = can start command | 1 = input code

var keyArr = ["Up", "Down", "Left", "Right"]
var code: Array[String]
var currentCode: Array[String]

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func _enter_tree():
	# Doing this here instead of on ready prevents bugs.
	set_multiplayer_authority(int(str(name)))

func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass

func _initialize() -> void:
	pass

func _ready() -> void:
	randomize()
	syncPos = global_position
	$"Player ID".text = name
	GameManager.player_info[int(name)] = {"spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	await get_tree().create_timer(get_physics_process_delta_time(), false, true).timeout
	Input.action_press("ui_accept")

func _physics_process(_delta: float) -> void:
	global_position = get_tree().get_first_node_in_group("shooter").syncPos
	if not is_multiplayer_authority():
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		#position = lerp(position, syncPos, 0.1)
		return
	if trauma:
		trauma = max(trauma - decay * _delta, 0)
		shake()
	
	if targettedObject != _check_for_hackable():
		_alter_progress_bar(0)
	targettedObject = _check_for_hackable()
	if targettedObject != null:
		_show_loading_ui(true)
	else:
		_show_loading_ui(false)
	
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right_2"):
		velocity.x += 1
	if Input.is_action_pressed("left_2"):
		velocity.x -= 1
	if Input.is_action_pressed("down_2"):
		velocity.y += 1
	if Input.is_action_pressed("up_2"):
		velocity.y -= 1
	
	if Input.is_action_just_released("ui_accept"):
		_showui()
	if Input.is_key_pressed(KEY_Z): add_trauma(0.1)
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed * _delta
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	syncPos = global_position + offset
	offset = lerp(offset, offset+velocity+add_offset, 0.2)
	$ui.position = offset

func _check_for_hackable() -> hackableObject:
	for i in $ui/hover.get_overlapping_areas():
		if i.is_in_group("hackable"): 
			#i.hack_array[0].call(i.hack_array[0].callable)
			return i
	return null

func _input(event: InputEvent) -> void:
	if canExecuteCommand:
		
		if executionLayer == 1:
			if Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("left_1") or Input.is_action_just_pressed("right_1") or Input.is_action_just_pressed("up_1"):
				print(event.as_text())
				currentCode.append(event.as_text())
				_match_input_code()
		
		if targettedObject.canBeHacked:
			if executionLayer == 0:
				if Input.is_action_just_pressed("cycle_right"): targettedObject_option += 1
				if Input.is_action_just_pressed("cycle_left"): targettedObject_option -= 1
				if targettedObject_option > targettedObject.hackArray.size()-1: targettedObject_option = 0
				if targettedObject_option < 0: targettedObject_option = targettedObject.hackArray.size()-1
			
			if Input.is_action_just_pressed("ui_accept"):
				if targettedObject.hackArray[targettedObject_option].codeLength == 0: _match_input_code(true)
				match executionLayer:
					0:
						print("executing ..")
						_randomize_input_code(targettedObject.hackArray[targettedObject_option].codeLength)
						executionLayer = 1
						#targettedObject.hackArray[targettedObject_option].call(targettedObject.hackArray[targettedObject_option].callable)
		
		else: print("cannot be hacked right now")

func _randomize_input_code(length) -> void:
	code.clear()
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	tw.tween_property($ui/arrow, "position:y", -380, 1).from(-400)
	tw.tween_property($ui/arrow, "modulate:a", 1, 1).from(0)
	
	for i in $ui/arrow.get_children():
		if i.get_index() > 0: i.queue_free()
	var size = (length-1)*60
	var start = -size / 2
	for i in length:
		var k = randi_range(0, 3)
		code.append(keyArr[k])
		var arw = $ui/arrow/Sprite2D2.duplicate()
		$ui/arrow.add_child(arw)
		arw.show()
		arw.position.x = start
		match keyArr[k]:
			"Down": arw.rotation = PI
			"Left": arw.rotation = -PI/2
			"Right": arw.rotation = PI/2
		start += 60
	print(code)

func _match_input_code(skip: bool = false) -> void:
	if !skip:
		var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
		print(currentCode.size())
		
		for i in currentCode.size():
			if code[i] != currentCode[i]:
				print("diff", code[i], " ", currentCode[i])
				currentCode.clear()
				tw.tween_property($ui/arrow, "position:y", -380, 1).from(-360)
				for k in $ui/arrow.get_children(): if k.get_index() > 0: k.modulate = Color(0.5, 0.5, 0.5)
				return
		
		$ui/arrow.get_child(currentCode.size()).modulate = Color(1, 1, 1)
		tw.tween_property($ui/arrow.get_child(currentCode.size()), "position:y", 0, 1).from(20)
		
		if currentCode.size() != code.size(): return
	
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	tw.tween_property($ui/arrow, "position:y", -400, 0.5).from(-380)
	tw.tween_property($ui/arrow, "modulate:a", 0, 0.5)
	
	await get_tree().create_timer(0.5, false, true).timeout
	
	for i in $ui/arrow.get_children():
		if i.get_index() > 0: i.queue_free()
	
	targettedObject.hackArray[targettedObject_option].call(targettedObject.hackArray[targettedObject_option].callable)

@rpc("call_local")
func _showui() -> void:
	if is_in_group("assistant"): 
		show()
		$ui.show()

func _show_loading_ui(type: bool = false) -> void:
	# tweens here
	if type:
		#print(canExecuteCommand, " ", currentLoadProgress, " ", targettedObject.duration)
		$ui/bar.modulate.a = lerpf($ui/bar.modulate.a, 1, 0.2)
		if targettedObject != null: 
			$ui/bar/TextureProgressBar.max_value = targettedObject.duration
			if currentLoadProgress < targettedObject.duration:
				_alter_progress_bar(currentLoadProgress + get_physics_process_delta_time())
				$ui/bar/Label.text = "Loading..."
			else: 
				_alter_progress_bar(targettedObject.duration)
				canExecuteCommand = true
				$ui/bar/Label.text = "Q <   " + targettedObject.title + " :: " + targettedObject.hackArray[targettedObject_option].type  + "   > E"
	else:
		$ui/bar.modulate.a = lerpf($ui/bar.modulate.a, 0, 0.1)
		$ui/bar/Label.text = "Exiting..."
		_alter_progress_bar(0)
		canExecuteCommand = false

func _alter_progress_bar(value) -> void:
		currentLoadProgress = value
		$ui/bar/TextureProgressBar.value = lerpf($ui/bar/TextureProgressBar.value, value, 0.1)

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	add_offset.x = max_offset.x * amount * randf_range(-1, 1)
	add_offset.y = max_offset.y * amount * randf_range(-1, 1)
