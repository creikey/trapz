extends Control

export (NodePath) var player_path

onready var player = get_node(player_path)

func _ready():
	player.connect("damaged", self, "_on_player_damaged")

func _process(delta):
	$PickPocketStatus.visible = player.pickpocket_progress >= 0.01
	$PickPocketStatus/ProgressBar.value = player.pickpocket_progress
	$ItemStatus.text = str("Bear traps: ", player.bear_traps)
	if player.got_target:
		$ObjectiveLabel.text = "Objective: Escape to green thing"
	else:
		$ObjectiveLabel.text = "Objective: Pickpocket with e"
	$HealthBar.value = player.health

func _on_player_damaged():
	$DamageEffect.color.a = 1.0
