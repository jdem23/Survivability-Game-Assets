extends Node2D

const COIN_SCENE = preload("res://animated_coin.tscn")

@onready var player: CharacterBody2D = $Player
@onready var bgm_player: AudioStreamPlayer = $MusicPlayer
@onready var coin_sfx: AudioStreamPlayer = $CoinSFX
@onready var anim_label: Label = $HUD/InfoPanel/VBox/AnimStatus
@onready var facing_label: Label = $HUD/InfoPanel/VBox/FacingStatus
@onready var audio_label: Label = $HUD/InfoPanel/VBox/AudioStatus
@onready var score_label: Label = $HUD/TopRight/ScoreLabel
@onready var music_btn: Button = $HUD/MusicControls/HBox/BtnToggleMusic
@onready var volume_slider: HSlider = $HUD/MusicControls/HBox/VolSlider

var score: int = 0
var is_music_playing: bool = true

func _ready() -> void:
	# Start background music
	bgm_player.play()

	# Connect Player signals
	player.state_changed.connect(_on_player_state_changed)
	player.jumped.connect(func(): audio_label.text = "SFX: Jump (AudioStreamPlayer2D)")

	# Connect HUD Controls
	music_btn.pressed.connect(_toggle_music)
	volume_slider.value_changed.connect(_on_volume_changed)

	$HUD/ResetCoinsBtn.pressed.connect(spawn_coins)
	$HUD/MobileControls/BtnLeft.button_down.connect(func(): player.external_dir = -1.0)
	$HUD/MobileControls/BtnLeft.button_up.connect(func(): if player.external_dir < 0: player.external_dir = 0.0)
	$HUD/MobileControls/BtnRight.button_down.connect(func(): player.external_dir = 1.0)
	$HUD/MobileControls/BtnRight.button_up.connect(func(): if player.external_dir > 0: player.external_dir = 0.0)
	$HUD/MobileControls/BtnJump.pressed.connect(func(): player.perform_jump())

	spawn_coins()

func _on_player_state_changed(anim_name: String, dir_str: String) -> void:
	anim_label.text = "Current Animation: %s" % anim_name.to_upper()
	facing_label.text = "Sprite Direction: %s" % dir_str

func spawn_coins() -> void:
	for child in $CoinContainer.get_children():
		child.queue_free()

	for i in range(5):
		var coin = COIN_SCENE.instantiate()
		coin.position = Vector2(320.0 + (i * 120.0), 440.0 + (sin(i * 1.5) * 50.0))
		coin.coin_collected.connect(_on_coin_collected)
		$CoinContainer.add_child(coin)

func _on_coin_collected(pts: int) -> void:
	score += pts
	score_label.text = "Coins Collected: %d" % score
	# Play global coin chime
	coin_sfx.play()
	audio_label.text = "SFX: Coin Chime (AudioStreamPlayer)"

func _toggle_music() -> void:
	if bgm_player.playing:
		bgm_player.stop()
		music_btn.text = "Play Music"
	else:
		bgm_player.play()
		music_btn.text = "Pause Music"

func _on_volume_changed(val: float) -> void:
	# Convert slider (0.0 to 1.0) into decibels (-30 dB to 0 dB)
	if val <= 0.01:
		bgm_player.volume_db = -80.0 # Muted
	else:
		bgm_player.volume_db = linear_to_db(val)
