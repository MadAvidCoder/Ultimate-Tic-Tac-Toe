extends Node2D

var child_areas
var child_sprites
var x
var o
var next
var indicator
var indicator_positions
var shown
var anywhere
var cur_big_square
var squares
var big_marks
var big_sprites
var click_buffer
var won
var win_conditions
var state
var winner
var win_overlay
var win_mark
var begin
var mark

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_areas = []
	var child_areas_buf = []
	child_sprites = []
	var child_sprites_buf = []
	for j in ["1","2","3"]:
		for i in ["A","B","C"]:
			for l in ["1","2","3"]:
				for k in ["A","B","C"]:
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
	
	winner = -1
	
	state = 0
	
	mark = preload("res://mark.tscn")
	
	indicator = get_node("Indicator")
	indicator_positions = [Vector2(101,50), Vector2(285,50), Vector2(469,50), Vector2(101,234), Vector2(285,234), Vector2(469,234), Vector2(101,418), Vector2(285,418), Vector2(469,418)]
	indicator.hide()
	
	anywhere = get_node("MoveAnywhere")
	anywhere.show()
	
	cur_big_square = -1
	
	x = 0
	o = 1
	
	won = []
	
	squares = ["A1","B1","C1","A2","B2","C2","A3","B3","C3"]
	
	win_conditions = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
	
	shown = false
	
	big_marks = []
	big_sprites = []
	for j in ["1","2","3"]:
		for i in ["A","B","C"]:
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
	

func _child_clicked(path):
	path = str(path).split("/")[4].split("-")
	var big = squares.find(path[0])
	var small = squares.find(path[1])
	click_buffer = [big,small]

func check_won(search_square: int, player: int) -> bool:
	if search_square == -1:
		for condition in win_conditions:
			var passes = true
			for i in condition:
				if big_sprites[i].frame != player:
					passes = false
			if passes:
				return true
	else:
		for condition in win_conditions:
			var passes = true
			for i in condition:
				if child_sprites[search_square][i].frame != player:
					passes = false
			if passes:
				return true
	return false

func _on_play_pressed() -> void:
	begin.hide()
	anywhere.show()
	state = 1

func _on_again_pressed() -> void:
	win_overlay.hide()
	reset()

func check_full(square: int) -> bool:
	var show_count = 0
	for child in child_sprites[square]:
		if child.visible:
			show_count += 1
	if show_count == 9:
		return true
	else:
		return false

func _process(_delta: float) -> void:
	if state == 0:
		begin.show()
		anywhere.hide()
		click_buffer = 0
	elif state == 1:
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
		if not shown:
			anywhere.hide()
			win_mark.frame = winner
			win_overlay.show()
			shown = true

func eval_game(pos: int) -> int:
	var eval_score = 0
	var big_board = []
	var weight = [1.4, 1, 1.4, 1, 1.75, 1, 1.4, 1, 1.4]
	for square in range(10):
		eval_score += eval_square(square)*1.5*weight[square]
		if square == cur_big_square:
			eval_score += eval_square(square)*weight[square]
		var xhaswon = check_won(square, x)
		var ohaswon = check_won(square, o)
		if xhaswon:
			eval_score -= weight[square]
			big_board.append(0)
		elif ohaswon:
			eval_score += weight[square]
			big_board.append(1)
	
	eval_score -= check_temp(big_board)*1500
	eval_score += eval_temp(big_board)*150
	
	return eval_score

func eval_temp(temp_square: Array) -> int :
	var eval = 0
	var weights = [0.2, 0.17, 0.2, 0.17, 0.22, 0.17, 0.2, 0.17, 0.2]
	for square in range(9):
		eval -= temp_square[square]*weights[square]
	if check(b_square, x, [0,1,2], 2) or check(b_square, x, [3,4,5], 2) or check(b_square, x, [6,7,8], 2) or check(b_square, x, [0,3,6], 2) or check(b_square, x, [1,4,7], 2) or check(b_square, x, [2,5,8], 2):
		eval -= 6;
	if check(b_square, x, [0,4,8], 2) or check(b_square, x, [2,4,6], 2):
		eval -= 7
	
	if (check(b_square, o, [0,1], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [1,2], 2) and check(b_square, x, [0], 1)) or (check(b_square, o, [0,2], 2) and check(b_square, x, [1], 1)) or (check(b_square, o, [3,4], 5) and check(b_square, x, [2], 1)) or (check(b_square, o, [3,5], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,5], 2) and check(b_square, x, [3], 1)) or (check(b_square, o, [6,7], 2) and check(b_square, x, [2], 8)) or (check(b_square, o, [6,8], 2) and check(b_square, x, [7], 1)) or (check(b_square, o, [7,8], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [0,3], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [0,6], 2) and check(b_square, x, [3], 1)) or (check(b_square, o, [3,6], 2) and check(b_square, x, [0], 1)) or (check(b_square, o, [1,4], 2) and check(b_square, x, [7], 1)) or (check(b_square, o, [1,7], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,7], 2) and check(b_square, x, [1], 1)) or (check(b_square, o, [2,5], 2) and check(b_square, x, [8], 1)) or (check(b_square, o, [2,8], 2) and check(b_square, x, [5], 1)) or (check(b_square, o, [5,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [0,4], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [0,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [4,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [2,4], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [2,6], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,6], 2) and check(b_square, x, [2], 1)):
		eval -= 9
	
	if check(b_square, o, [0,1,2], 2) or check(b_square, o, [3,4,5], 2) or check(b_square, o, [6,7,8], 2) or check(b_square, o, [0,3,6], 2) or check(b_square, o, [1,4,7], 2) or check(b_square, o, [2,5,8], 2):
		eval += 6;
	if check(b_square, o, [0,4,8], 2) or check(b_square, o, [2,4,6], 2):
		eval += 7
	
	if (check(b_square, x, [0,1], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [1,2], 2) and check(b_square, o, [0], 1)) or (check(b_square, x, [0,2], 2) and check(b_square, o, [1], 1)) or (check(b_square, x, [3,4], 5) and check(b_square, o, [2], 1)) or (check(b_square, x, [3,5], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,5], 2) and check(b_square, o, [3], 1)) or (check(b_square, x, [6,7], 2) and check(b_square, o, [2], 8)) or (check(b_square, x, [6,8], 2) and check(b_square, o, [7], 1)) or (check(b_square, x, [7,8], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [0,3], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [0,6], 2) and check(b_square, o, [3], 1)) or (check(b_square, x, [3,6], 2) and check(b_square, o, [0], 1)) or (check(b_square, x, [1,4], 2) and check(b_square, o, [7], 1)) or (check(b_square, x, [1,7], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,7], 2) and check(b_square, o, [1], 1)) or (check(b_square, x, [2,5], 2) and check(b_square, o, [8], 1)) or (check(b_square, x, [2,8], 2) and check(b_square, o, [5], 1)) or (check(b_square, x, [5,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [0,4], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [0,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [4,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [2,4], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [2,6], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,6], 2) and check(b_square, o, [2], 1)):
		eval += 9
	
	if check_won(b_square,x):
		eval -= 12
	elif check_won(b_square,o):
		eval += 12
	
	return eval

func eval_square(b_square) -> int :
	var eval = 0
	var weights = [0.2, 0.17, 0.2, 0.17, 0.22, 0.17, 0.2, 0.17, 0.2]
	for square in range(9):
		eval -= child_sprites[square]*weights[square]
	if check(b_square, x, [0,1,2], 2) or check(b_square, x, [3,4,5], 2) or check(b_square, x, [6,7,8], 2) or check(b_square, x, [0,3,6], 2) or check(b_square, x, [1,4,7], 2) or check(b_square, x, [2,5,8], 2):
		eval -= 6;
	if check(b_square, x, [0,4,8], 2) or check(b_square, x, [2,4,6], 2):
		eval -= 7
	
	if (check(b_square, o, [0,1], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [1,2], 2) and check(b_square, x, [0], 1)) or (check(b_square, o, [0,2], 2) and check(b_square, x, [1], 1)) or (check(b_square, o, [3,4], 5) and check(b_square, x, [2], 1)) or (check(b_square, o, [3,5], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,5], 2) and check(b_square, x, [3], 1)) or (check(b_square, o, [6,7], 2) and check(b_square, x, [2], 8)) or (check(b_square, o, [6,8], 2) and check(b_square, x, [7], 1)) or (check(b_square, o, [7,8], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [0,3], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [0,6], 2) and check(b_square, x, [3], 1)) or (check(b_square, o, [3,6], 2) and check(b_square, x, [0], 1)) or (check(b_square, o, [1,4], 2) and check(b_square, x, [7], 1)) or (check(b_square, o, [1,7], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,7], 2) and check(b_square, x, [1], 1)) or (check(b_square, o, [2,5], 2) and check(b_square, x, [8], 1)) or (check(b_square, o, [2,8], 2) and check(b_square, x, [5], 1)) or (check(b_square, o, [5,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [0,4], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [0,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [4,8], 2) and check(b_square, x, [2], 1)) or (check(b_square, o, [2,4], 2) and check(b_square, x, [6], 1)) or (check(b_square, o, [2,6], 2) and check(b_square, x, [4], 1)) or (check(b_square, o, [4,6], 2) and check(b_square, x, [2], 1)):
		eval -= 9
	
	if check(b_square, o, [0,1,2], 2) or check(b_square, o, [3,4,5], 2) or check(b_square, o, [6,7,8], 2) or check(b_square, o, [0,3,6], 2) or check(b_square, o, [1,4,7], 2) or check(b_square, o, [2,5,8], 2):
		eval += 6;
	if check(b_square, o, [0,4,8], 2) or check(b_square, o, [2,4,6], 2):
		eval += 7
	
	if (check(b_square, x, [0,1], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [1,2], 2) and check(b_square, o, [0], 1)) or (check(b_square, x, [0,2], 2) and check(b_square, o, [1], 1)) or (check(b_square, x, [3,4], 5) and check(b_square, o, [2], 1)) or (check(b_square, x, [3,5], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,5], 2) and check(b_square, o, [3], 1)) or (check(b_square, x, [6,7], 2) and check(b_square, o, [2], 8)) or (check(b_square, x, [6,8], 2) and check(b_square, o, [7], 1)) or (check(b_square, x, [7,8], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [0,3], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [0,6], 2) and check(b_square, o, [3], 1)) or (check(b_square, x, [3,6], 2) and check(b_square, o, [0], 1)) or (check(b_square, x, [1,4], 2) and check(b_square, o, [7], 1)) or (check(b_square, x, [1,7], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,7], 2) and check(b_square, o, [1], 1)) or (check(b_square, x, [2,5], 2) and check(b_square, o, [8], 1)) or (check(b_square, x, [2,8], 2) and check(b_square, o, [5], 1)) or (check(b_square, x, [5,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [0,4], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [0,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [4,8], 2) and check(b_square, o, [2], 1)) or (check(b_square, x, [2,4], 2) and check(b_square, o, [6], 1)) or (check(b_square, x, [2,6], 2) and check(b_square, o, [4], 1)) or (check(b_square, x, [4,6], 2) and check(b_square, o, [2], 1)):
		eval += 9
	
	if check_won(b_square,x):
		eval -= 12
	elif check_won(b_square,o):
		eval += 12
	
	return eval

func check_temp(temp_board: Array) -> int:
	var passes = true
	for condition in win_conditions:
		for i in condition:
			if temp_board[i].frame != x:
				passes = false
	if passes:
		return 1
	passes = true
	for condition in win_conditions:
		for i in condition:
			if temp_board[i].frame != o:
				passes = false
	if passes:
		return -1
	return 0

func check(search_square: int, player: int, conds: Array, thresh: int) -> bool:
	var passes = 0
	if search_square == -1:
		for condition in conds:
			for i in condition:
				if big_sprites[i].frame == player:
					passes += 1
	else:
		for condition in conds:
			for i in condition:
				if child_sprites[search_square][i].frame == player:
					passes += 1
	if passes == thresh:
		return true
	else:
		return false
