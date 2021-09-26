extends Spatial

# Player
onready var player: KinematicBody = $Player
export var player_start: Vector3 = Vector3(0, 1, 0)

# UI nodes
onready var title: Label = $Overlay/Title
onready var instruction: Label = $Overlay/Instruction
onready var score_timer: Timer = $ScoreTimer
onready var score_counter: Label = $Overlay/ScoreCounter
onready var fps_counter: Label = $Overlay/FPSCounter

var title_text: String = 'Alpine Skiing'
var gameover_text: String = 'You Died'

# Physical characteristics
export var width: int = 200

# Procedural gen
export var first_rock_dist: int = 0
export var min_rock_dist: int = 10
export var max_rock_dist: int = 50
export var rock_margin: int = 10

export var first_flag_dist: int = 30
export var min_flag_dist: int = 100
export var max_flag_dist: int = 200
export var flag_margin: int = 40

export var fence_size: int = 2

export var obstacle_offset_dist: int = 500
export var obstacle_delete_dist: int = 30

var rand = RandomNumberGenerator.new()

export var rock_scene: PackedScene = preload('res://Scenes/InstanceScenes/Rock.tscn')
var rocks: Array = []
var next_rock_dist: int = first_rock_dist

export var flag_scene: PackedScene = preload('res://Scenes/InstanceScenes/FlagPair.tscn')
var flags: Array = []
var next_flag_dist: int = first_flag_dist
var flag_left: bool = true

export var fence_scene: PackedScene = preload('res://Scenes/InstanceScenes/Fence.tscn')
var fences: Array = []
var next_fence_dist: int = 0

var dist_traveled: float = 0

# Score
var score: int = 0

# Level loading
var game_started: bool = false
var first_time: bool = true

# Debug vars
export var debug_freq: int = 600
var debug_frame: int = 0

func _ready() -> void:
	# Misc setup
	player.connect('death', self, '_on_player_death')
	score_timer.connect('timeout', self, '_on_timeout')
	score_counter.text = '0'
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	rand.randomize()
	generate_initial_obstacles()

func _input(event) -> void:
	if event.is_action_released('ui_accept') and !game_started:
		if first_time:
			start()
		else:
			reset()

func reset() -> void:
	# Reset player
	player.reset()
	player.transform.origin = player_start
	dist_traveled = 0
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
	generate_initial_obstacles()
	start()

func generate_initial_obstacles() -> void:
	# Generate initial fences
	for i in range(0, obstacle_offset_dist, fence_size):
		var left_fence: KinematicBody = fence_scene.instance()
		var right_fence: KinematicBody = fence_scene.instance()
		left_fence.transform.origin = Globals.downhill * i - Vector3.RIGHT * width / 2
		right_fence.transform.origin = Globals.downhill * i + Vector3.RIGHT * width / 2
		left_fence.connect('death', self, '_on_player_death')
		right_fence.connect('death', self, '_on_player_death')
		fences.append(left_fence)
		fences.append(right_fence)
		add_child(left_fence)
		add_child(right_fence)
	# Generate starting flag
	var flag: KinematicBody = flag_scene.instance()
	flag.transform.origin = Globals.downhill * first_flag_dist
	flag.connect('death', self, '_on_player_death')
	flags.append(flag)
	add_child(flag)

func start() -> void:
	game_started = true
	# Start moving player
	player.move = true
	# Do similar for flags
	for flag in flags:
		flag.velocity = -player.downhill_vel
	# Do similar for fences
	for fence in fences:
		fence.velocity = -player.downhill_vel
	# Reset score
	score = 0
	score_counter.text = '0'
	score_timer.start()
	# Hide title elements
	title.visible = false
	instruction.visible = false
	return

func _on_player_death() -> void:
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
	# Check player hasn't died yet and game has actually started
	if !is_instance_valid(player) or !game_started:
		return
	# Keep track of distance traveled
	dist_traveled += player.downhill_vel.length() * delta
	# Once enough distance has been traveled, generate new rock
	if dist_traveled >= next_rock_dist:
		var rock: KinematicBody = rock_scene.instance()
		# Generate out of view using offset
		rock.transform.origin = Globals.downhill * obstacle_offset_dist
		# Give random horizontal offset
		rock.transform.origin += Vector3.RIGHT * rand.randi_range(-width / 2 + rock_margin, width / 2 - rock_margin)
		# Finish generating
		rock.velocity = -player.downhill_vel
		rock.connect('death', self, '_on_player_death')
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
		flag.velocity = -player.downhill_vel
		flag.connect('death', self, '_on_player_death')
		flags.append(flag)
		add_child(flag)
		next_flag_dist = dist_traveled + rand.randi_range(min_flag_dist, max_flag_dist)
		flag_left = !flag_left
	# Do similar for fences
	if dist_traveled >= next_fence_dist:
		var left_fence: KinematicBody = fence_scene.instance()
		var right_fence: KinematicBody = fence_scene.instance()
		left_fence.transform.origin = Globals.downhill * (obstacle_offset_dist - (dist_traveled - next_fence_dist)) - Vector3.RIGHT * width / 2
		right_fence.transform.origin = Globals.downhill * (obstacle_offset_dist - (dist_traveled - next_fence_dist)) + Vector3.RIGHT * width / 2
		left_fence.velocity = -player.downhill_vel
		right_fence.velocity = -player.downhill_vel
		left_fence.connect('death', self, '_on_player_death')
		right_fence.connect('death', self, '_on_player_death')
		fences.append(left_fence)
		fences.append(right_fence)
		add_child(left_fence)
		add_child(right_fence)
		next_fence_dist += fence_size
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
	# Display fps
	fps_counter.text = str(Engine.get_frames_per_second()) + ' fps'
#	debug_frame += 1
#	if debug_frame == debug_freq:
#		debug_frame = 0
#		print('Num rocks: ' + str(rocks.size()))
#		print('Num flags: ' + str(flags.size()))
#		print('----')
	
