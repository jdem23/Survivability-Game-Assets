extends Node2D
## Game controller.
##  - Smiley swarm every 5s (left->right or right->left): instant kill
##  - Lightning bolt falls top->bottom every 3s (takes 3s to cross): half health
##  - Jug spawns every 10s: heals one quarter
##  - R to restart after dying

const MAX_HEALTH := 4              # 4 quarters of the bar
const HEAL_AMOUNT := 1             # one quarter per jug
const PICKUP_DIST := 18.0
const MAX_JUGS := 3                # max jugs lying around at once
const BOX_COUNT := 5
const SWARM_COUNT := 11            # smileys per swarm
const SWARM_GAP_HALF := 30.0       # guaranteed safe lane half-height
const BOLT_SPAWN_JITTER := 70.0    # bolts fall near the player (+/- this many px)
const PLAY_MIN := Vector2(24, 66)
const PLAY_MAX := Vector2(336, 156)

var jug_scene: PackedScene = preload("res://scenes/Jug.tscn")
var box_scene: PackedScene = preload("res://scenes/Box.tscn")
var slime_scene: PackedScene = preload("res://scenes/Slime.tscn")
var bolt_scene: PackedScene = preload("res://scenes/Bolt.tscn")

@onready var player = $Player
@onready var jugs = $Jugs
@onready var boxes = $Boxes
@onready var hazards = $Hazards
@onready var swarm_timer: Timer = $SwarmTimer
@onready var lightning_timer: Timer = $LightningTimer
@onready var jug_timer: Timer = $JugTimer
@onready var health_bar = $UI/HealthBar
@onready var score_label: Label = $UI/ScoreLabel
@onready var flash: ColorRect = $UI/Flash
@onready var game_over = $UI/GameOver
@onready var joystick = $UI/Joystick

var health := MAX_HEALTH
var jugs_collected := 0
var survive_time := 0.0
var alive := true
var rng := RandomNumberGenerator.new()
var box_positions: Array[Vector2] = []


func _ready() -> void:
	_setup_input()
	rng.randomize()
	player.joystick = joystick
	game_over.visible = false
	health_bar.set_health(health, true)
	_spawn_boxes()
	swarm_timer.timeout.connect(_on_swarm_timer_timeout)
	lightning_timer.timeout.connect(_on_lightning_timer_timeout)
	jug_timer.timeout.connect(_on_jug_timer_timeout)
	swarm_timer.start(5.0)
	lightning_timer.start(3.0)
	jug_timer.start(10.0)
	_update_label()


# ---------------------------------------------------------------- input
func _setup_input() -> void:
	_set_key_action("move_up", [KEY_W, KEY_UP])
	_set_key_action("move_down", [KEY_S, KEY_DOWN])
	_set_key_action("move_left", [KEY_A, KEY_LEFT])
	_set_key_action("move_right", [KEY_D, KEY_RIGHT])
	_set_key_action("restart", [KEY_R])


func _set_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _unhandled_input(event: InputEvent) -> void:
	if not alive and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
	if not alive:
		return
	survive_time += delta
	_update_label()
	if health < MAX_HEALTH:
		for jug in jugs.get_children():
			if jug.collected:
				continue
			if player.global_position.distance_to(jug.global_position) < PICKUP_DIST:
				jug.collect()
				health = mini(health + HEAL_AMOUNT, MAX_HEALTH)
				health_bar.set_health(health)
				jugs_collected += 1
				break


func _update_label() -> void:
	score_label.text = "Jugs: %d   Time: %.1f" % [jugs_collected, survive_time]


# ---------------------------------------------------------------- hazards
func _on_swarm_timer_timeout() -> void:
	if not alive:
		return
	var from_left := rng.randf() < 0.5
	var gap_y := rng.randf_range(84.0, 140.0)
	for i in SWARM_COUNT:
		var y := rng.randf_range(54.0, 168.0)
		if absf(y - gap_y) < SWARM_GAP_HALF:
			var push := SWARM_GAP_HALF + rng.randf_range(0.0, 8.0)
			y = gap_y + (push if y >= gap_y else -push)
		var slime = slime_scene.instantiate()
		slime.setup(player, from_left, y, rng.randf_range(0.0, 120.0))
		hazards.add_child(slime)
		slime.hit_player.connect(_on_player_hit)


func _on_lightning_timer_timeout() -> void:
	if not alive:
		return
	var x := player.global_position.x + rng.randf_range(-BOLT_SPAWN_JITTER, BOLT_SPAWN_JITTER)
	x = clampf(x, 24.0, 336.0)
	var bolt = bolt_scene.instantiate()
	bolt.setup(player, x)
	hazards.add_child(bolt)
	bolt.hit_player.connect(_on_player_hit)


func _on_player_hit(damage: int) -> void:
	if not alive:
		return
	health = maxi(health - damage, 0)
	health_bar.set_health(health)
	flash.modulate.a = 0.6
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.3)
	if health <= 0:
		_die()


func _die() -> void:
	alive = false
	swarm_timer.stop()
	lightning_timer.stop()
	jug_timer.stop()
	get_tree().call_group("hazards", "freeze")
	player.die()
	health_bar.shatter()
	await get_tree().create_timer(1.2).timeout
	game_over.play()


# ---------------------------------------------------------------- spawning
func _spawn_boxes() -> void:
	var tries := 0
	while box_positions.size() < BOX_COUNT and tries < 300:
		tries += 1
		var p := Vector2(rng.randf_range(40.0, 320.0), rng.randf_range(80.0, 148.0))
		if p.distance_to(player.position) < 60.0:
			continue
		var ok := true
		for q in box_positions:
			if p.distance_to(q) < 60.0:
				ok = false
		if not ok:
			continue
		box_positions.append(p)
		var b = box_scene.instantiate()
		b.position = p
		b.z_index = int(p.y)
		boxes.add_child(b)


func _spot_is_free(pos: Vector2) -> bool:
	if pos.distance_to(player.global_position) < 40.0:
		return false
	for q in box_positions:
		if pos.distance_to(q) < 36.0:
			return false
	return true


func _on_jug_timer_timeout() -> void:
	if not alive or jugs.get_child_count() >= MAX_JUGS:
		return
	var pos := Vector2.ZERO
	for i in 40:
		pos = Vector2(
			rng.randf_range(PLAY_MIN.x, PLAY_MAX.x),
			rng.randf_range(PLAY_MIN.y, PLAY_MAX.y))
		if _spot_is_free(pos):
			break
	var jug = jug_scene.instantiate()
	jug.position = pos
	jugs.add_child(jug)
