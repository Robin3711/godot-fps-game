extends Node3D

@onready var animPlayer = $AnimationPlayer
var bullet
var instance

# Called when the node enters the scene tree for the first time.
func _ready():
	bullet = preload("res://bullet.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("shoot"):
		if !animPlayer.is_playing():
			animPlayer.play("shooting")
			instance = bullet.instantiate()
			instance.position = get_parent().get_parent().position
			instance.transform.basis = get_parent().get_parent().transform.basis
			get_parent().get_parent().get_parent().add_child(instance)
