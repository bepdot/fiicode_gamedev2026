class_name hackData
extends Node2D

@export var type: String = "Type"
@export var cost: float = 1
@export var callable: String = "_default"

func _debug() -> void:
	_debug_rpc.rpc()

@rpc("any_peer", "call_local")
func _debug_rpc() -> void:
	print("affected object: ", self)
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property($"../..", "scale", $"../..".scale, 1).from(Vector2($"../..".scale.x * 2, $"../..".scale.y / 2))
	$"../.."._set_cooldown(3.0)

func _blind() -> void:
	_blind_rpc.rpc()

@rpc("any_peer", "call_local")
func _blind_rpc() -> void:
	print("affected object: ", self)
	var tw = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property($"../..", "scale", $"../..".scale, 1).from(Vector2($"../..".scale.x / 2, $"../..".scale.y * 2))
	$"../.."._set_cooldown(3.0)

func _disarm_trap() -> void: _disarm_trap_rpc.rpc()

@rpc("any_peer", "call_local")
func _disarm_trap_rpc() -> void:
	print("trap disarmed")
	$"../..".monitoring = false
	$"../..".modulate = Color(0.5, 0.5, 0.5)
	$"../.."._set_cooldown(999999.0)
