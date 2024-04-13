extends Control


@onready var bar = $ProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_stamina_changed(sprint_stamina):
	bar.value=sprint_stamina*10

