extends Node

@onready var spawner: Node = $Spawner
@onready var players: Node = $Players

@export var lightOnlyMaterial: CanvasItemMaterial
@export var player_scene:PackedScene
@export var cam_scene: PackedScene
@onready var player_spawner: MultiplayerSpawner = $world/Players/PlayerSpawner

var is_dedicated = false

func _ready() -> void:
	if NetworkManager.players.is_empty():
		# singleplayer situation
		NetworkManager.players = {1: NetworkManager.connection_type}
		pass
	
	for i in NetworkManager.players:
		if NetworkManager.players[i] == "dedicated":
			is_dedicated = true
			print("Running on Dedicated Server")
	
	# everyone needs to know this
	player_spawner.spawn_function = spawn_player
	if multiplayer.is_server():
		spawn_all_players()
	
	$world/ground.material = lightOnlyMaterial
	$world/enemies.material = lightOnlyMaterial
	$CanvasModulate.show()


func spawn_all_players():
	var spawnpoints := spawner.get_children()
	var pid_array := NetworkManager.players.keys()
	
	if is_dedicated:
		pid_array.erase(1)
		# Removes dedicated server as a player
	pid_array.sort()  
	# this makes sure that the spawnpoints are in order. Not needed, just debug
	
	for i in pid_array.size():
		var pid = pid_array[i]
		var spawnpoint = spawnpoints[i].global_position
		var group
		match i:
			0: group = "shooter"
			1: group = "assistant"
		
		player_spawner.spawn([pid, spawnpoint, group])
	

func spawn_player(data):
	var player
	if data[2] == "shooter": player = player_scene.instantiate()
	if data[2] == "assistant": player = cam_scene.instantiate()
	var pid = data[0]
	var spawnpoint = data[1]
	player.position = spawnpoint
	player.name = str(pid)
	player.add_to_group(data[2])
	player._initialize()
	
	return player
