extends Node2D
## Healing jug: pops in, bobs gently, shrinks away when collected.

var t := 0.0
var collected := false
@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	z_index = int(position.y) - 1
	scale = Vector2(0.01, 0.01)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	t += delta
	sprite.position.y = sin(t * 3.0) * 2.0


func collect() -> void:
	collected = true
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)
