extends Panel

signal retry_pressed
signal menu_pressed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Conectar botones (asumiendo nombres exactos)
	$VBoxContainer/RetryButton.pressed.connect(_on_retry_pressed)
	$VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func _on_retry_pressed():
	retry_pressed.emit()

func _on_menu_pressed():
	menu_pressed.emit()

func set_score(value: int):
	$VBoxContainer/FinalScoreLabel.text = "Score: " + str(value)
