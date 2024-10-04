package snake

import "core:fmt"
import time "core:time"
import rl "vendor:raylib"

CELL_SIZE :: 20
INITIAL_SNAKE_SIZE :: 4

Direction:: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

Window :: struct {
	name: cstring,
	width, height: i32,
	fps: i32,
	controlFlags: rl.ConfigFlags,
}

Game :: struct {
	tick_rate: time.Duration,
	last_tick: time.Time,
	width, height: i32,
}

Input :: struct {
	dir: Direction,
}

SnakeCell :: struct {
	x,y: i32,
	dir: Direction,
	next: ^SnakeCell,
}

createSnake :: proc(size: i32) -> ^SnakeCell {
	cell := new(SnakeCell)
	cell.x = 0 + size;
	cell.dir = .RIGHT
	cell.next = createSnake(size-1)
	return cell
}

freeSnake :: proc (cell:^SnakeCell) {
	if(cell.next != {}){
		freeSnake(cell.next)
	}
	free(cell);
}

drawSnake :: proc(cell: ^SnakeCell) {
	rl.DrawCircle(
		(cell.x + 1) * CELL_SIZE, 
		(cell.y + 1 )* CELL_SIZE,
		CELL_SIZE/2-2,
		rl.GREEN 
	);
	
	if cell.next != {} {
		drawSnake(cell.next)
	}
}

moveSnake :: proc(cell: ^SnakeCell, dir:Direction) {
	 switch cell.dir{
		case .LEFT:
			cell.x -= 1
		case .RIGHT:
			cell.x += 1
		case .UP:
			cell.y -= 1
		case .DOWN:
			cell.y +=1
	}

	if cell.next != {} {
		moveSnake(cell.next, cell.dir)
	}
	cell.dir=dir
}

processUserInput :: proc(input: ^Input){
	#partial switch rl.GetKeyPressed(){
		case .LEFT, .A, .H :
			input.dir = .LEFT
		case .RIGHT, .D, .L :
			input.dir = .RIGHT
		case .UP, .W, .K :
			input.dir = .UP
		case .DOWN, .S, .J :
			input.dir = .DOWN
	}
}

main :: proc() {
	
	//initialize window
	{
		window := Window{"Snake",1000,900,60,rl.ConfigFlags{}}
		rl.InitWindow(window.width, window.height, window.name)
		rl.SetWindowState(window.controlFlags)
		rl.SetTargetFPS(window.fps)
	}

	//initialize game
	game := Game{
		tick_rate = 300 * time.Millisecond,
		last_tick = time.now(),
		width = 64, 
		height = 64,
	}

	snakeHead := createSnake(INITIAL_SNAKE_SIZE)
	defer freeSnake(snakeHead);

	input := Input{.RIGHT}

	//game loop
	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		drawSnake(snakeHead)
		processUserInput(&input)

		if time.since(game.last_tick) > game.tick_rate {
			game.last_tick = time.now()
			moveSnake(snakeHead, input.dir)
		}
	}

}