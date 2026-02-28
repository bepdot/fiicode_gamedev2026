extends Camera2D

@export var speed = 4000.0

var syncPos := Vector2(0.0, 0.0)
var ui_adjust: Vector2 = Vector2.ZERO
var add_offset: Vector2 = Vector2.ZERO

@export var decay = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func _enter_tree():
	# Doing this here instead of on ready prevents bugs.
	set_multiplayer_authority(int(str(name)))

func _initialize() -> void:
	if is_in_group("shooter"): modulate = Color(0, 0, 0)
	if is_in_group("assistant"): 
		modulate.a = 0.5

func _ready() -> void:
	randomize()
	syncPos = global_position
	$"Player ID".text = name
	GameManager.player_info[int(name)] = {"spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	await get_tree().create_timer(get_physics_process_delta_time(), false, true).timeout
	Input.action_press("ui_accept")

func _physics_process(_delta: float) -> void:
	global_position = get_tree().get_first_node_in_group("shooter").global_position
	if not is_multiplayer_authority():
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		return
	
	$ui/Label.text = str(is_multiplayer_authority())
	if trauma:
		trauma = max(trauma - decay * _delta, 0)
		shake()
	
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right_1"):
		velocity.x += 1
	if Input.is_action_pressed("left_1"):
		velocity.x -= 1
	if Input.is_action_pressed("down_1"):
		velocity.y += 1
	if Input.is_action_pressed("up_1"):
		velocity.y -= 1
	
	if Input.is_action_just_released("ui_accept"):
		_showui()
	if Input.is_key_pressed(KEY_Z):
		add_trauma(1)
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed * _delta
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	syncPos = global_position + offset
	offset = lerp(offset, offset+velocity+add_offset, 0.2)
	$ui.position = offset

@rpc("call_local")
func _showui() -> void:
	if is_in_group("assistant"): 
		$ui.show()

func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	add_offset.x = max_offset.x * amount * randf_range(-1, 1)
	add_offset.y = max_offset.y * amount * randf_range(-1, 1)
