extends Sprite2D
## One smiley of the swarm. Flies straight across the screen; touching the player
## is instant death (damage 4 = the whole health bar).

signal hit_player(damage: int)

const SPEED := 105.0
const DAMAGE := 4
const HIT_DIST := 15.0
const ANIM_FPS := 12.0
const FRAME_COUNT := 10

var player: Node2D = null
var dir := 1.0
var anim_t := 0.0


func setup(p: Node2D, from_left: bool, y: float, offset: float) -> void:
	player = p
	dir = 1.0 if from_left else -1.0
	position = Vector2((-20.0 - offset) if from_left else (380.0 + offset), y)
	z_index = 400


func _ready() -> void:
	add_to_group("hazards")
	anim_t = randf() * FRAME_COUNT


func freeze() -> void:
	set_process(false)


func _process(delta: float) -> void:
	position.x += dir * SPEED * delta
	anim_t += delta * ANIM_FPS
	frame = int(anim_t) % FRAME_COUNT
	if player != null and position.distance_to(player.global_position) < HIT_DIST:
		hit_player.emit(DAMAGE)
	if (dir > 0.0 and position.x > 400.0) or (dir < 0.0 and position.x < -40.0):
		queue_free()
