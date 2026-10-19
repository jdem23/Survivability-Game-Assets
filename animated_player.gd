extends CharacterBody2D

signal jumped
signal state_changed(anim_name: String, direction_str: String)

@export var move_speed: float = 240.0
@export var jump_strength: float = -420.0
@export var gravity: float = 980.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sfx: AudioStreamPlayer2D = $JumpSFX

var external_dir: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Horizontal Movement (Keyboard + On-screen buttons)
	var dir = external_dir
	if dir == 0.0:
		dir = Input.get_axis("ui_left", "ui_right")

	if dir != 0.0:
		velocity.x = dir * move_speed
		# SPRITE FLIPPING: Turn sprite left or right
		anim_sprite.flip_h = (dir < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)

	# 3. Jump (Space, Up Arrow, or mobile button)
	if is_on_floor() and (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")):
		perform_jump()

	move_and_slide()
	update_animation_state()

func perform_jump() -> void:
	if is_on_floor():
		velocity.y = jump_strength
		# Play Positional 2D Sound Effect!
		jump_sfx.play()
		jumped.emit()

func update_animation_state() -> void:
	var current_anim: String
	if not is_on_floor():
		current_anim = "jump"
	elif abs(velocity.x) > 10.0:
		current_anim = "walk"
	else:
		current_anim = "idle"

	# Switch animation only if not already playing
	if anim_sprite.animation != current_anim:
		anim_sprite.play(current_anim)

	var dir_str = "Facing Left" if anim_sprite.flip_h else "Facing Right"
	state_changed.emit(current_anim, dir_str)
