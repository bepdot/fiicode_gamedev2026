extends Node2D
class_name bullet

@export var type: String = "default"
@export var decayRange: float = 800.0
@export var piercing: bool = false
@export var damage: float = 10.0
@export var speed: float = 80.0
@export var angle: float = 0
@export var targetGroups: Array[String]
var designatedArea

func _ready() -> void:
	find_child(type).show()
	designatedArea = find_child(type).find_child("Area2D")

func _physics_process(delta: float) -> void:
	position += speed * Vector2(cos(angle), sin(angle))
	for i in designatedArea.get_overlapping_bodies():
		for k in targetGroups.size():
			if i.is_in_group(targetGroups[k]):
				_hit(i)

func _hit(on_what) -> void:
	if on_what.is_in_group("wall"): 
		designatedArea.monitoring = false
	else: # this is guaranteed to be a player or enemy
		on_what._damage(damage)
	_stop()

func _stop() -> void:
	match type:
		"default": 
			set_physics_process(false)
			hide()
			# other particle stuff
			await get_tree().create_timer(1.0, false).timeout
			queue_free()
		"missile":
			set_physics_process(false)
			# boom bang boom
			await get_tree().create_timer(1.0, false).timeout
			queue_free()
		"piercing":
			pass # only stops at walls
