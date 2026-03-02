extends Node

var speed = 300.0
var run_speed = 600.0
var hp = 100
var max_hp = 100
var stamina = 100
var arme = {
	"pistol" : {
		"unlocked" : true,
		"ammo" : 8,
		"reserve_ammo" : 24,
	},
	"shotgun" : {
		"unlocked" : false,
		"ammo" : 4,
		"reserve_ammo" : 24,
	},
	"ar" : {
		"unlocked" : false,
		"ammo" : 30,
		"reserve_ammo" : 60,
	},
	"sniper" : {
		"unlocked" : false,
		"ammo" : 3,
		"reserve_ammo" : 12,
	},
	"bomb" : {
		"unlocked" : false,
		"uses" : 3
	}
}

var current_weapon = "pistol"


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
