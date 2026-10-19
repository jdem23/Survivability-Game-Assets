extends Sprite2D
## A lightning bolt that travels from the top of the screen to the bottom in 3 seconds.
## If it touches the player it takes half of the health bar (once per bolt).

signal hit_player(damage: int)

const FALL_TIME := 3.0
const DAMAGE := 2
const HIT_RADIUS := 24.0
const START_Y := -26.0
const END_Y := 206.0
const ARM_TIME := 0.3        # bolt can't hurt while it's still "charging up"
const ANIM_FPS := 14.0

var player: Node2D = null
var age := 0.0
var has_hit := false


func setup(p: Node2D, x: float) -> void:
	player = p
	position = Vector2(x, START_Y)
	z_index = 500


func _ready() -> void:
	add_to_group("hazards")


func freeze() -> void:
	set_process(false)


func _process(delta: float) -> void:
	age += delta
	position.y = lerpf(START_Y, END_Y, clampf(age / FALL_TIME, 0.0, 1.0))
	var f := int(age * ANIM_FPS)
	frame = f if f < 10 else 6 + (f % 4)    # grow, then shimmer on the last frames
	if not has_hit and age > ARM_TIME and player != null:
		var center := global_position + Vector2(0, -6)
		if center.distance_to(player.global_position) < HIT_RADIUS:
			has_hit = true
			hit_player.emit(DAMAGE)
	if age >= FALL_TIME:
		queue_free()
