extends Area2D

signal coin_collected(pts: int)

@export var points: int = 100
var is_collected: bool = false

func _ready() -> void:
	$CoinSprite.play("spin")
	body_entered.connect(_on_body_entered)
	$ClickButton.pressed.connect(collect)

func _on_body_entered(_body: Node2D) -> void:
	collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	coin_collected.emit(points)
	queue_free()
