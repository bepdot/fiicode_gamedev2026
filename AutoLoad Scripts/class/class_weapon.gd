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
@export var syncRot: float = 0.0

var is_reloading: bool = false
@onready var muzzle = $MuzzleName

func _spawn(currentAmmo, remainingAmmo) -> void: # should be called whenever a weapon is initialized/instanced
	find_child("texture").animation = sprite # animation for shooting and stuff
	currentAmmoInMag = currentAmmo # gets these from player object
	ammoLeft = remainingAmmo
	print("Arma " + type + " initializata: " + str(currentAmmoInMag) + "/" + str(ammoLeft))
	
	#await get_tree().create_timer(get_physics_process_delta_time(), false, true).timeout
	#_rotate_to_mouse()

@rpc("call_local")
func _physics_process(delta: float) -> void:
	#print(" I AM HERE")
	if not is_multiplayer_authority():
		global_rotation = lerp_angle(global_rotation, syncRot, 0.5)
		return
	syncRot = global_rotation
	look_at(get_global_mouse_position())
	#print(global_rotation)
	#if global_rotation_degrees > 90 or global_rotation_degrees < -90:
		#scale.y = -1
	#else:
		#scale.y = 1
	
	if Input.is_action_just_pressed("reload") and not is_reloading:
		if currentAmmoInMag < maxAmmoInMag and ammoLeft > 0:
			_reload()
	
	if currentAmmoInMag >= ammoAmountUsed and not is_reloading:
		match automatic:
			true:
				if Input.is_action_pressed("shoot") and canShoot:
					_shoot()
			false:
				if Input.is_action_just_pressed("shoot") and canShoot:
					_shoot()
	else:
		if Input.is_action_just_pressed("reload") and currentAmmoInMag != maxAmmoInMag:
			if Input.is_action_just_pressed("shoot"): 
				_reload()
			pass

func _shoot() -> int:
	canShoot = false
	currentAmmoInMag -= 1
	
	if playerBound:
		Global.arme[type]['ammo'] = currentAmmoInMag
	
	#for i in range(projectileAmount):
		# creeaza bullet, unghi, adaugare in scena root
	
	_shoot_delay()
	currentAmmoInMag -= ammoAmountUsed
	return currentAmmoInMag

func _shoot_delay() -> void:
	canShoot = false
	await get_tree().create_timer(fireDelay, false, true).timeout
	canShoot = true

func _reload() -> void:
	print("Reloading...")
	is_reloading = true
	canShoot = false

	await get_tree().create_timer(reloadTime).timeout
	
	var ammo_needed = maxAmmoInMag - currentAmmoInMag
	var ammo_to_load = 0
	
	if playerBound:
		var reserve = Global.arme[type]["reserve_ammo"]
		ammo_to_load = min(ammo_needed, reserve)
		Global.arme[type]["reserve_ammo"] -= ammo_to_load
		ammoLeft = Global.arme[type]["reserve_ammo"]
	#else: for enemy
	#	ammo_to_load = ammo_needed 
	
	currentAmmoInMag += ammo_to_load
	
	if playerBound:
		Global.arme[type]["ammo"] = currentAmmoInMag
	
	print("Reload complet. Ammo: ", currentAmmoInMag, "/", ammoLeft)
	
	is_reloading = false
	canShoot = true
