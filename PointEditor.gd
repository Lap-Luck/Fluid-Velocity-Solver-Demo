extends Control
tool


export var pos = PoolVector2Array([Vector2(50.0,90.0)])
var Editor_data={}

##########################################
#decapling editor and runtime behavior
##########################################

func _draw():
	if Engine.is_editor_hint(): 	_draw_editor()
	else:							_draw_runtime()

func _process(delta):
	if Engine.is_editor_hint(): 	_process_editor(delta)
	else:							_process_runtime(delta)
##########################################
#editor code
##########################################

func _draw_editor():
	draw_rect(Rect2(Vector2.ZERO,rect_size),Color.blue)
	for p in pos:
		if Editor_data.has("color"):
			draw_circle(p,10.0,Editor_data["color"])
		else:
			draw_circle(p,10.0,Color.black)

func _process_editor(delta):
	var mouse_pos=get_viewport().get_mouse_position()-rect_global_position
	var click=false
	for p in pos:
		#print(p-mouse_pos)
		if (p-mouse_pos).length()<10.0:
			click=true
	if click:
		Editor_data["color"]=Color.yellow
	else:
		Editor_data["color"]=Color.black
	update()

##########################################
#runtime code
##########################################
func _process_runtime(delta):
	pass

func _draw_runtime():
	draw_rect(Rect2(Vector2.ZERO,rect_size),Color.blue)

