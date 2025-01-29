extends Node2D

var child_areas: Array[Array] = []
var child_sprites: Array[Array] = []
const x: int = 0
const o: int = 1
var ai: bool = false
var next: Node
var indicator: Node
const indicator_positions: PackedVector2Array = [Vector2(101,50), Vector2(101,234), Vector2(101,418), Vector2(285,50), Vector2(285,234), Vector2(285,418), Vector2(469,50), Vector2(469,234), Vector2(469,418)]
var shown: bool = false
var anywhere: Node
var cur_big_square: int = -1
var squares: PackedStringArray = ["A1","A2","A3","B1","B2","B3","C1","C2","C3"]
var big_marks: Array[Node] = []
var big_sprites: Array[Node] = []
var click_buffer: Variant
var won: Array[int] = []
var win_conditions: Array[Array] = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
var state: int = 0
var winner: int = -1
var win_overlay: Node
var win_mark: Node
var begin: Node
var difficulty: int = 1

func _ready() -> void:
	var child_areas_buf: Array[Object] = []
	var child_sprites_buf: Array[Object] = []
	for i in ["A","B","C"]:
		for j in ["1","2","3"]:
			for k in ["A","B","C"]:
				for l in ["1","2","3"]:
					child_areas_buf.append(get_node("Marks/"+i+j+"-"+k+l))
					child_sprites_buf.append(get_node("Marks/"+i+j+"-"+k+l+"/"+i+j+"-"+k+l))
			child_areas.append(child_areas_buf)
			child_areas_buf = []
			child_sprites.append(child_sprites_buf)
			child_sprites_buf = []
	for i in child_areas:
		for child in i:
			child.clicked.connect(_child_clicked)
	
	next = get_node("NextMark")
	next.frame = 0
	next.show()
	
	begin = get_node("Begin")
	
	win_overlay = get_node("Win")
	win_overlay.hide()
	
	win_mark = get_node("Win/WinMark")

	indicator = get_node("Indicator")
	indicator.hide()
	
	anywhere = get_node("MoveAnywhere")
	anywhere.show()
	
	for i in ["A","B","C"]:
		for j in ["1","2","3"]:
			big_marks.append(get_node("BigMarks/"+i+j))
			big_sprites.append(get_node("BigMarks/"+i+j+"/Sprite"))

func reset() -> void:
	next.frame = 0
	next.show()
	
	for i in big_marks:
		i.hide()
	
	for i in child_sprites:
		for child in i:
			child.hide()
	
	win_overlay.hide()
	
	winner = -1
	
	state = 0
	
	indicator.hide()
	
	anywhere.show()
	
	cur_big_square = -1
	
	won = []
	
	shown = false
	
	ai = false

func _child_clicked(path: Variant) -> void:
	path = str(path).split("/")[4].split("-")
	var big: int = squares.find(path[0])
	var small: int = squares.find(path[1])
	click_buffer = [big,small]

func check_won(search_square: int, player: int) -> bool:
	if search_square == -1:
		for condition in win_conditions:
			var passes: bool = true
			for i in condition:
				if big_sprites[i].frame != player or big_marks[i].visible == false or big_sprites[i].visible == false:
					passes = false
			if passes:
				return true
	else:
		for condition in win_conditions:
			var passes: bool = true
			for i in condition:
				if child_sprites[search_square][i].frame != player or child_sprites[search_square][i].visible == false:
					passes = false
			if passes:
				return true
	return false

func _on_play_pressed() -> void:
	ai = false
	begin.hide()
	anywhere.show()
	state = 1

func _on_ai_1_pressed() -> void:
	ai = true
	difficulty = 1
	begin.hide()
	anywhere.show()
	state = 1

func _on_ai_2_pressed() -> void:
	ai = true
	difficulty = 2
	begin.hide()
	anywhere.show()
	state = 1

func _on_again_pressed() -> void:
	win_overlay.hide()
	reset()

func check_full(square: int) -> bool:
	var show_count: int = 0
	for child in child_sprites[square]:
		if child.visible:
			show_count += 1
	if show_count == 9:
		return true
	else:
		return false

func allowed_big() -> Array[int]:
	var ret_list: Array[int] = []
	for i in range(0,8):
		if not i in won:
			ret_list.append(i)
	return ret_list

func allowed_small(square: int) -> Array[int]:
	var ret_list: Array[int] = []
	for i in range(0,8):
		if not child_sprites[square][i].visible:
			ret_list.append(i)
	return ret_list

func _process(_delta: float) -> void:
	if state == 0:
		begin.show()
		anywhere.hide()
		click_buffer = 0
	elif state == 1:
		if (not ai) or (next.frame == 0):
			if click_buffer:
				if child_sprites[click_buffer[0]][click_buffer[1]].visible == false and cur_big_square in [click_buffer[0], -1] and not click_buffer[0] in won:
					child_sprites[click_buffer[0]][click_buffer[1]].frame = next.frame
					child_sprites[click_buffer[0]][click_buffer[1]].show()
					if check_won(click_buffer[0], next.frame):
						won.append(click_buffer[0])
						big_sprites[click_buffer[0]].frame = next.frame
						big_marks[click_buffer[0]].show()
						if check_won(-1, next.frame):
							state = 2
							winner = next.frame
					elif check_full(click_buffer[0]):
						won.append(click_buffer[0])
						big_sprites[click_buffer[0]].visible = false
						big_marks[click_buffer[0]].show()
						if len(won) == 9:
							state = 2
							winner = 2
					if winner == -1:
						next.frame = not next.frame
						cur_big_square = click_buffer[1]
						if cur_big_square in won:
							cur_big_square = -1
							anywhere.show()
							indicator.hide()
						else:
							anywhere.hide()
							indicator.position = indicator_positions[cur_big_square]
							indicator.show()
				click_buffer = 0
		else:
			## Random Move
			if difficulty == 1:
				var chosen: int
				var big: int = cur_big_square
				if cur_big_square == -1:
					big = allowed_big().pick_random()
				chosen = allowed_small(big).pick_random()
				child_sprites[big][chosen].frame = next.frame
				child_sprites[big][chosen].show()
				if check_won(big, next.frame):
					won.append(big)
					big_sprites[big].frame = next.frame
					big_marks[big].show()
					if check_won(-1, next.frame):
						state = 2
						winner = next.frame
				elif check_full(big):
					won.append(big)
					big_sprites[big].visible = false
					big_marks[big].show()
					if len(won) == 9:
						state = 2
						winner = 2
				if winner == -1:
					next.frame = not next.frame
					cur_big_square = chosen
					if cur_big_square in won:
						cur_big_square = -1
						anywhere.show()
						indicator.hide()
					else:
						anywhere.hide()
						indicator.position = indicator_positions[cur_big_square]
						indicator.show()
			elif difficulty == 2:
				var chosen: int
				var big: int = cur_big_square
				if cur_big_square == -1:
					big = allowed_big().pick_random()
				for choice in allowed_small(big):
					child_sprites[big][choice].frame = next.frame
					child_sprites[big][choice].show()
					if check_won(big, next.frame):
						chosen = choice
						break
					child_sprites[big][choice].hide()
				if not chosen:
					for choice in allowed_small(big):
						child_sprites[big][choice].frame = not next.frame
						child_sprites[big][choice].show()
						if check_won(big, not next.frame):
							chosen = choice
							child_sprites[big][choice].frame = next.frame
							break
						child_sprites[big][choice].hide()
				if not chosen:
					chosen = allowed_small(big).pick_random()
					child_sprites[big][chosen].frame = next.frame
					child_sprites[big][chosen].show()
				if check_won(big, next.frame):
					won.append(big)
					big_sprites[big].frame = next.frame
					big_marks[big].show()
					if check_won(-1, next.frame):
						state = 2
						winner = next.frame
				elif check_full(big):
					won.append(big)
					big_sprites[big].visible = false
					big_marks[big].show()
					if len(won) == 9:
						state = 2
						winner = 2
				if winner == -1:
					next.frame = not next.frame
					cur_big_square = chosen
					if cur_big_square in won:
						cur_big_square = -1
						anywhere.show()
						indicator.hide()
					else:
						anywhere.hide()
						indicator.position = indicator_positions[cur_big_square]
						indicator.show()
				
	else:
		if not shown:
			anywhere.hide()
			win_mark.frame = winner
			win_overlay.show()
			shown = true
