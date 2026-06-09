extends Node3D

@export var player: Node3D
@export var canopy_scene: PackedScene
@export var tile_size := 50.0
@export var render_distance := 2
@export var canopy_height := 15.0


var spawned_tiles := {}


func _process(delta):
	if player == null:
		return

	var player_tile_x = int(
		floor(player.global_position.x / tile_size)
	)
	var player_tile_z = int(
		floor(player.global_position.z / tile_size)
	)

	for x in range(
		player_tile_x - render_distance,
		player_tile_x + render_distance + 1
	):
		for z in range(
			player_tile_z - render_distance,
			player_tile_z + render_distance + 1
		):

			var key = Vector2i(x, z)

			if not spawned_tiles.has(key):

				spawn_tile(x, z)

	var remove_list = []
	for key in spawned_tiles.keys():
		var dx = abs(key.x - player_tile_x)
		var dz = abs(key.y - player_tile_z)

		if dx > render_distance or dz > render_distance:
			spawned_tiles[key].queue_free()
			remove_list.append(key)

	for key in remove_list:
		spawned_tiles.erase(key)

func spawn_tile(x, z):
	var tile = canopy_scene.instantiate()
	add_child(tile)

	tile.global_position = Vector3(
		x * tile_size,
		canopy_height,
		z * tile_size
	)

	tile.rotation.y = randf() * TAU
	spawned_tiles[Vector2i(x, z)] = tile
