extends Node2D
class_name weapon

@export var type: String = ""
@export var sprite: String = "default"
@export var ammoType: String = "default"
@export var currentAmmoInMag: int = 30
@export var ammoAmountUsed: int = 1
@export var maxAmmoInMag: int = 30
@export var ammoLeft: int = 90
@export var projectileAmount: int = 1
@export var projectileSpread: float = PI/8
@export var fireDelay: float = 0.2
@export var reloadTime: float = 1.0
@export var automatic: bool = false
@export var playerBound: bool = true
var canShoot: bool = true

func _spawn(currentAmmo, remainingAmmo) -> void: # should be called whenever a weapon is initialized/instanced
	find_child("texture").animation = sprite # animation for shooting and stuff
	currentAmmoInMag = currentAmmo # gets these from player object
	ammoLeft = remainingAmmo

func _physics_process(delta: float) -> void:
	if currentAmmoInMag > ammoAmountUsed and ammoLeft != 0:
		match automatic:
			true:
				if Input.is_action_pressed("shoot") and canShoot:
					_shoot()
			false:
				if Input.is_action_just_pressed("shoot") and canShoot:
					_shoot()
	else:
		if Input.is_action_just_pressed("reload") and currentAmmoInMag != maxAmmoInMag:
			#_reload()
			# if playerBound, change reserve_ammo of global.arme[type]["reserve_ammo"]
			# else, simply max out ammo without anything else (enemy weapons)
			pass

func _shoot() -> int:
	_shoot_delay()
	currentAmmoInMag -= ammoAmountUsed
	return currentAmmoInMag

func _shoot_delay() -> void:
	canShoot = false
	await get_tree().create_timer(fireDelay, false, true).timeout
	canShoot = true
