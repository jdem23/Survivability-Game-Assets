extends Sprite2D
## Health bar sheet (3 x 4 cells). Steps through frames so the bar visibly drains/refills.
## Frames: 0 full ... 7 empty, 8-9 broken.

# frame to show for health 0,1,2,3,4 (quarters left)
const FRAMES := [7, 5, 3, 2, 0]

var target_frame := 0
var step_timer := 0.0
var locked := false


func set_health(h: int, instant := false) -> void:
	target_frame = FRAMES[clampi(h, 0, 4)]
	if instant:
		frame = target_frame


func shatter() -> void:
	locked = true
	# let the bar finish draining first
	while frame < 7:
		frame += 1
		await get_tree().create_timer(0.06).timeout
	await get_tree().create_timer(0.2).timeout
	frame = 8
	await get_tree().create_timer(0.15).timeout
	frame = 9


func _process(delta: float) -> void:
	if locked:
		return
	step_timer += delta
	if step_timer < 0.06:
		return
	step_timer = 0.0
	if frame < target_frame:
		frame += 1
	elif frame > target_frame:
		frame -= 1
