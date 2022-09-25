extends PopupMenu


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.

	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PopupMenu2_id_pressed(id):
	$"..".solver=get_item_text(id)


func _on_Button_pressed():
	popup()
