extends CharacterBody2D
## Explorer. Moves with the on-screen joystick (drag any direction) or WASD / arrows.
## Boxes are solid (CharacterBody2D collides with StaticBody2D).

const SPEED := 75.0
const MIN_POS := Vector2(16, 64)    # keeps the explorer on the forest floor
const MAX_POS := Vector2(344, 158)
const FACES_RIGHT := true           # set to false if the sprite looks backwards

var dead := false
var bob := 0.0
var joystick = null                 # assigned by main.gd

@onready var sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	if dead:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO and joystick != null:
		dir = joystick.output
	velocity = dir * SPEED
	move_and_slide()
	position.x = clampf(position.x, MIN_POS.x, MAX_POS.x)
	position.y = clampf(position.y, MIN_POS.y, MAX_POS.y)
	if absf(dir.x) > 0.1:
		sprite.flip_h = (dir.x < 0.0) if FACES_RIGHT else (dir.x > 0.0)
	if dir != Vector2.ZERO:
		bob += delta * 14.0
		sprite.position.y = -absf(sin(bob)) * 2.0
	else:
		bob = 0.0
		sprite.position.y = 0.0
	z_index = int(position.y)


func die() -> void:
	dead = true
	velocity = Vector2.ZERO
	sprite.position.y = 0.0
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", PI / 2.0, 0.3)
	tw.parallel().tween_property(sprite, "modulate", Color(0.35, 0.35, 0.35), 0.3)
