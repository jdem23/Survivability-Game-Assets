extends Control
## Fades to black, then plays the dih_over sheet (4 x 5 cells, 17 frames).

const LAST_FRAME := 16
const FPS := 12.0

@onready var dim: ColorRect = $Dim
@onready var text: Sprite2D = $Text
@onready var hint: Label = $Hint


func play() -> void:
	visible = true
	hint.visible = false
	text.frame = 0
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 1.0)
	for i in range(LAST_FRAME + 1):
		text.frame = i
		await get_tree().create_timer(1.0 / FPS).timeout
	hint.visible = true
