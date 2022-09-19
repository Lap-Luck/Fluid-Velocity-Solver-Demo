extends Node2D

func set_shape(shape:Rect2):
	self.position=shape.position
	var shape_scale=Transform2D(Vector2(shape.size.x/50.0,0.0),
								Vector2(0.0,shape.size.y/50.0),
								Vector2.ZERO)
	for c in self.get_children():
		if c is Line2D:
			var l:Line2D=c
			for p_id in range(l.points.size()):
				l.points[p_id]=shape_scale*l.points[p_id]
		if c is Polygon2D:
			var p:Polygon2D=c
			for id in range(p.polygon.size()):
				p.polygon[id]=shape_scale*p.polygon[id]
			

func set_color(color):
	for l in self.get_children():
		if l is Line2D:
			l.default_color=color

var fill_value:float=0.0
func fill(value):
	$Polygon2D.visible=true
	$Polygon2D.scale.y=value

func _ready():
	if false:
		set_shape(Rect2(50.0,50.0,150.0,100.0))
		set_color(Color.darkorange)
		fill(1.0)
