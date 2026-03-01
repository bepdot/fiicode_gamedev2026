class_name hackableObject
extends Area2D

# this is to be inherited alone by field hazards such as traps, locked doors, landmines, turrets, etc.
# the eventual Enemy object type will inherit this class to create its own (for weapon types, hp, etc

@export var title: String = "Object" # display name
@export var loadDuration: float = 1.0 # how long it should take to load the progress bar

@export var hackOptions: Array[hackData]

func _init() -> void:
	add_to_group("hackable")
