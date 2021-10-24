extends Spatial

export var player_start: Vector3 = Vector3(0, 1, 0)

export var width: int = 200

export var first_rock_dist: int = 40
export var min_rock_dist: int = 10
export var max_rock_dist: int = 30
export var rock_margin: int = 10
export var rock_scene: PackedScene = preload("res://scenes/instance/obstacles/rock.tscn")

export var first_flag_dist: int = 30
export var min_flag_dist: int = 120
export var max_flag_dist: int = 180
export var flag_margin: int = 30
export var flag_scene: PackedScene = preload("res://scenes/instance/obstacles/flag_pair.tscn")

export var fence_size: int = 2
export var fence_scene: PackedScene = preload("res://scenes/instance/obstacles/fence.tscn")

export var tree_size: int = 50
export var tree_variance: int = 20
export var tree_margin: int = 10
export var tree_scene: PackedScene = preload("res://scenes/instance/obstacles/tree.tscn")

export var obstacle_offset_dist: int = 1000
export var obstacle_delete_dist: int = 30

# Debug vars
export var debug_freq: int = 600
var debug_frame: int = 0

var title_text: String = "Alpine Skiing"
var gameover_text: String = "You Died"

var rand = RandomNumberGenerator.new()

var rocks: Array = []
var next_rock_dist: int

var flags: Array = []
var next_flag_dist: int
var flag_left: bool = true

var fences: Array = []
var next_fence_dist: int = 0

var trees: Array = []
var next_tree_dist: int = 0

var dist_traveled: float = 0

var score: int = 0

var game_started: bool = false
var first_time: bool = true

onready var player: KinematicBody = $Player
onready var title: Label = $Overlay/Title
onready var instruction: Label = $Overlay/Instruction
onready var score_timer: Timer = $ScoreTimer
onready var score_counter: Label = $Overlay/ScoreCounter
onready var fps_counter: Label = $Overlay/FPSCounter


func _ready() -> void:
	# Misc setup
	player.connect("death", self, "_on_player_death")
	score_timer.connect("timeout", self, "_on_timeout")
	score_counter.text = "0"
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	rand.randomize()
	generate_initial_obstacles()


func _input(event) -> void:
	if event.is_action_released("ui_accept") and !game_started:
		if first_time:
			start()
		else:
			reset()
			start()


func start() -> void:
#	print('Start')
	game_started = true
	# Start moving player
	player.move = true
	# Do similar for flags
	for flag in flags:
		flag.velocity = -player.downhill_vel
	# Do similar for fences
	for fence in fences:
		fence.velocity = -player.downhill_vel
	# Start score
	score_timer.start()
	# Hide title elements
	title.visible = false
	instruction.visible = false
	return


func reset() -> void:
#	print('Reset')
	# Delete obstacles and regenerate
	for rock in rocks:
		rock.queue_free()
	rocks = []
	next_rock_dist = first_rock_dist
	for flag in flags:
		flag.queue_free()
	flags = []
	next_flag_dist = first_flag_dist
	for fence in fences:
		fence.queue_free()
	fences = []
	next_fence_dist = 0
	for tree in trees:
		tree.queue_free()
	trees = []
	next_tree_dist = 0
	generate_initial_obstacles()
	# Reset player
	player.reset()
	player.transform.origin = player_start
	dist_traveled = 0
	# Reset score
	score = 0
	score_counter.text = "0"


func generate_initial_obstacles() -> void:
	# Generate starting flag
	var initial_flag: KinematicBody = flag_scene.instance()
	initial_flag.transform.origin = Globals.downhill * first_flag_dist
	initial_flag.connect("death", self, "_on_player_death")
	flags.append(initial_flag)
	add_child(initial_flag)
	var i: int = first_rock_dist
	# Generate initial rocks
	while i < obstacle_offset_dist:
		var rock: KinematicBody = rock_scene.instance()
		rock.transform.origin = Globals.downhill * i
		rock.transform.origin += (
			Vector3.RIGHT
			* rand.randi_range(-width / 2 + rock_margin, width / 2 - rock_margin)
		)
		rock.connect("death", self, "_on_player_death")
		rocks.append(rock)
		add_child(rock)
		i += rand.randi_range(min_rock_dist, max_rock_dist)
	next_rock_dist = i - obstacle_offset_dist
	# Generate initial flags
	i = first_flag_dist + rand.randi_range(min_flag_dist, max_flag_dist)
	while i < obstacle_offset_dist:
		var flag: KinematicBody = flag_scene.instance()
		flag.transform.origin = Globals.downhill * i
		if flag_left:
			flag.transform.origin += Vector3.RIGHT * rand.randi_range(-width / 2 + flag_margin, 0)
		else:
			flag.transform.origin += Vector3.RIGHT * rand.randi_range(0, width / 2 - flag_margin)
		flag.connect("death", self, "_on_player_death")
		flags.append(flag)
		add_child(flag)
		i += rand.randi_range(min_flag_dist, max_flag_dist)
		flag_left = !flag_left
	next_flag_dist = i - obstacle_offset_dist
	# Generate initial fences
	i = 0
	while i < obstacle_offset_dist:
		var left_fence: KinematicBody = fence_scene.instance()
		var right_fence: KinematicBody = fence_scene.instance()
		left_fence.transform.origin = Globals.downhill * i - Vector3.RIGHT * width / 2
		right_fence.transform.origin = Globals.downhill * i + Vector3.RIGHT * width / 2
		left_fence.connect("death", self, "_on_player_death")
		right_fence.connect("death", self, "_on_player_death")
		fences.append(left_fence)
		fences.append(right_fence)
		add_child(left_fence)
		add_child(right_fence)
		i += fence_size
	# Generate initial trees
	i = 0
	while i < obstacle_offset_dist:
		var left_tree: Spatial = tree_scene.instance()
		var right_tree: Spatial = tree_scene.instance()
		left_tree.transform.origin = (
			Globals.downhill * (i + rand.randi_range(-tree_variance, tree_variance))
			- Vector3.RIGHT * (width / 2 + tree_margin)
		)
		right_tree.transform.origin = (
			Globals.downhill * (i + rand.randi_range(-tree_variance, tree_variance))
			+ Vector3.RIGHT * (width / 2 + tree_margin)
		)
		left_tree.rotate_x(Globals.slope_angle)
		right_tree.rotate_x(Globals.slope_angle)
		trees.append(left_tree)
		trees.append(right_tree)
		add_child(left_tree)
		add_child(right_tree)
		i += tree_size


func _on_player_death() -> void:
	# Check player isn't already dead and game has actually started
	if !game_started:
		return
#	print('Dead')
	game_started = false
	first_time = false
	# Stop everything
	player.velocity = Vector3()
	for rock in rocks:
		rock.velocity = Vector3()
	for flag in flags:
		flag.velocity = Vector3()
	for fence in fences:
		fence.velocity = Vector3()
	score_timer.stop()
	# Show title elements
	title.text = gameover_text
	title.visible = true
	instruction.visible = true


func _on_timeout() -> void:
	# Increment score
	score += 1
	score_counter.text = str(score)


func _process(delta: float) -> void:
	# Display fps
	fps_counter.text = str(Engine.get_frames_per_second()) + " fps"
	# Check player hasn't died yet and game has actually started
	if !game_started:
		return
	# Keep track of distance traveled
	dist_traveled += player.downhill_vel.length() * delta
	# Once enough distance has been traveled, generate new rock
	if dist_traveled >= next_rock_dist:
		var rock: KinematicBody = rock_scene.instance()
		# Generate out of view using offset
		rock.transform.origin = Globals.downhill * obstacle_offset_dist
		# Give random horizontal offset
		rock.transform.origin += (
			Vector3.RIGHT
			* rand.randi_range(-width / 2 + rock_margin, width / 2 - rock_margin)
		)
		# Finish generating
		rock.connect("death", self, "_on_player_death")
		rocks.append(rock)
		add_child(rock)
		# Calculate where to generate next rock
		next_rock_dist = dist_traveled + rand.randi_range(min_rock_dist, max_rock_dist)
	# Do similar for flags
	if dist_traveled >= next_flag_dist:
		var flag: KinematicBody = flag_scene.instance()
		flag.transform.origin = Globals.downhill * obstacle_offset_dist
		if flag_left:
			flag.transform.origin += Vector3.RIGHT * rand.randi_range(-width / 2 + flag_margin, 0)
		else:
			flag.transform.origin += Vector3.RIGHT * rand.randi_range(0, width / 2 - flag_margin)
		flag.connect("death", self, "_on_player_death")
		flags.append(flag)
		add_child(flag)
		next_flag_dist = dist_traveled + rand.randi_range(min_flag_dist, max_flag_dist)
		flag_left = !flag_left
	# Do similar for fences
	if dist_traveled >= next_fence_dist:
		var left_fence: KinematicBody = fence_scene.instance()
		var right_fence: KinematicBody = fence_scene.instance()
		left_fence.transform.origin = (
			Globals.downhill * (obstacle_offset_dist - (dist_traveled - next_fence_dist))
			- Vector3.RIGHT * width / 2
		)
		right_fence.transform.origin = (
			Globals.downhill * (obstacle_offset_dist - (dist_traveled - next_fence_dist))
			+ Vector3.RIGHT * width / 2
		)
		left_fence.connect("death", self, "_on_player_death")
		right_fence.connect("death", self, "_on_player_death")
		fences.append(left_fence)
		fences.append(right_fence)
		add_child(left_fence)
		add_child(right_fence)
		next_fence_dist += fence_size
	# Do similar for trees
	if dist_traveled >= next_tree_dist:
		var left_tree: Spatial = tree_scene.instance()
		var right_tree: Spatial = tree_scene.instance()
		left_tree.transform.origin = (
			(
				Globals.downhill
				* (
					obstacle_offset_dist
					- (dist_traveled - next_tree_dist)
					+ rand.randi_range(-tree_variance, tree_variance)
				)
			)
			- Vector3.RIGHT * (width / 2 + tree_margin)
		)
		right_tree.transform.origin = (
			(
				Globals.downhill
				* (
					obstacle_offset_dist
					- (dist_traveled - next_tree_dist)
					+ rand.randi_range(-tree_variance, tree_variance)
				)
			)
			+ Vector3.RIGHT * (width / 2 + tree_margin)
		)
		left_tree.rotate_x(Globals.slope_angle)
		right_tree.rotate_x(Globals.slope_angle)
		trees.append(left_tree)
		trees.append(right_tree)
		add_child(left_tree)
		add_child(right_tree)
		next_tree_dist += tree_size
	# Update rock velocities to match current player velocity and delete any that are out of view
	var rocks_to_delete: Array = []
	for rock in rocks:
		rock.velocity = -player.downhill_vel
		# Check if rock is uphill of obstacle delete dist
		if (-Globals.downhill * obstacle_delete_dist).z - rock.transform.origin.z < 0:
			rocks_to_delete.append(rock)
	for rock in rocks_to_delete:
		rocks.erase(rock)
		rock.queue_free()
	# Do similar for flags
	var flags_to_delete: Array = []
	for flag in flags:
		flag.velocity = -player.downhill_vel
		if (-Globals.downhill * obstacle_delete_dist).z - flag.transform.origin.z < 0:
			flags_to_delete.append(flag)
	for flag in flags_to_delete:
		flags.erase(flag)
		flag.queue_free()
	# Do similar for fences
	var fences_to_delete: Array = []
	for fence in fences:
		fence.velocity = -player.downhill_vel
		if (-Globals.downhill * obstacle_delete_dist).z - fence.transform.origin.z < 0:
			fences_to_delete.append(fence)
	for fence in fences_to_delete:
		fences.erase(fence)
		fence.queue_free()
	# Do similar for trees
	var trees_to_delete: Array = []
	for tree in trees:
		tree.transform.origin -= player.downhill_vel * delta
		if (-Globals.downhill * obstacle_delete_dist).z - tree.transform.origin.z < 0:
			trees_to_delete.append(tree)
	for tree in trees_to_delete:
		trees.erase(tree)
		tree.queue_free()
