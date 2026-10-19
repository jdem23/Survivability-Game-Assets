extends Node2D
## On-screen joystick. Press on it and drag in any direction (up, down, left, right,
## and every diagonal in between). The knob snaps back to the center on release.
## Works with mouse and touch (touch is emulated as mouse by default).

const MAX_DIST := 16.0       # how far the knob can travel (screen px)
const GRAB_RADIUS := 42.0    # how close to the center you must press to grab it
const DEADZONE := 0.2

var output := Vector2.ZERO   # direction read by the player (length 0..1)
var dragging := false
var snap_tween: Tween

@onready var knob: Sprite2D = $Knob


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_local_mouse_position().length() <= GRAB_RADIUS:
				dragging = true
				if snap_tween != null:
					snap_tween.kill()
				_update_knob()
		elif dragging:
			_release()
	elif event is InputEventMouseMotion and dragging:
		_update_knob()


func _update_knob() -> void:
	var offset := get_local_mouse_position().limit_length(MAX_DIST)
	knob.position = offset
	var strength := offset / MAX_DIST
	output = strength if strength.length() > DEADZONE else Vector2.ZERO


func _release() -> void:
	dragging = false
	output = Vector2.ZERO
	snap_tween = create_tween()
	snap_tween.tween_property(knob, "position", Vector2.ZERO, 0.08)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# translucent fills so the black rings are visible over the dark forest
	draw_circle(Vector2.ZERO, 27.0, Color(1, 1, 1, 0.35))
	if knob != null:
		draw_circle(knob.position, 12.0, Color(1, 1, 1, 0.7))
