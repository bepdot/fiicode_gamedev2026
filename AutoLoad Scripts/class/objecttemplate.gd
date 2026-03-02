extends hackableObject
class_name objectTemplate

@export var duration: float
@onready var hackArray: Array
var canBeHacked: bool = true

func _ready() -> void:
	for i in $hack_types.get_children():
		hackArray.append(i)

func _set_cooldown(time) -> void:
	canBeHacked = false
	find_child("Overlay").color = Color(0, 1, 0, 0)
	await get_tree().create_timer(time, false, true).timeout
	canBeHacked = true
	find_child("Overlay").color = Color(0, 1, 0, 1)
