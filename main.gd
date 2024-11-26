extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var child_areas = []
	var child_sprites = []
	for i in ["A","B","C"]:
		for j in ["1","2","3"]:
			for k in ["A","B","C"]:
				for l in ["1","2","3"]:
					child_areas.append(get_node("Marks/"+i+j+"-"+k+l))
					child_sprites.append(get_node("Marks/"+i+j+"-"+k+l+"/"+i+j+"-"+k+l))
	for child in child_areas:
		child.clicked.connect(_child_clicked)

func _child_clicked(path):
	path = str(path).split("/")[4]
	print(path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
