extends CharacterBody2D

@export var speed = 400.0

var syncPos := Vector2(0.0, 0.0)
var ownid

func _enter_tree():
	# Doing this here instead of on ready prevents bugs.
	set_multiplayer_authority(int(str(name)))

@rpc("call_local")
func _initialize() -> void:
	if is_in_group("shooter"): $AnimatedSprite2D.modulate = Color(0, 0, 0)
	if is_in_group("assistant"): 
		if int(str(name)) == get_multiplayer_authority():
			$ColorRect.show()
			_showui()

func _ready() -> void:
	syncPos = global_position
	$"Player ID".text = name
	GameManager.player_info[int(name)] = {"spawnpoint":syncPos, "node":self}
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	#await get_tree().create_timer(get_physics_process_delta_time(), false, true).timeout
	#Input.action_press("ui_accept")

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		# Making it 30fps (save bandwidth) and lerping with local fps to hide the stutter
		position = lerp(position, syncPos, 0.5)
		return
	
	$ui/Label.text = str(is_multiplayer_authority())
	velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right_1"):
		velocity.x += 1
	if Input.is_action_pressed("left_1"):
		velocity.x -= 1
	if Input.is_action_pressed("down_1"):
		velocity.y += 1
	if Input.is_action_pressed("up_1"):
		velocity.y -= 1
	
	if Input.is_action_just_pressed("ui_accept"):
		_showui()
	$ui.global_position = lerp($ui.global_position, get_tree().get_first_node_in_group("assistant").global_position, 0.2)
	
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	syncPos = global_position
	move_and_slide()


func _on_player_disconnected(pid) -> void:
	if pid == int(name):
		GameManager.player_info.erase(pid)
		queue_free()
	pass

@rpc("call_local")
func _showui() -> void:
	$ui.show()
