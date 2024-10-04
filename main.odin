package snake

import "core:fmt"
import time "core:time"
import rl "vendor:raylib"

CELL_SIZE :: 25
GAME_WIDTH :: 30
GAME_HEIGHT :: 30
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
	if(size <=0 ){
		return {}
	}
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

drawSnake :: proc(cell: ^SnakeCell, game: Game) {
	tickPercentage : f64 = f64(time.duration_nanoseconds(time.since(game.last_tick))) / f64(time.duration_nanoseconds(game.tick_rate))
	x:=(cell.x + 1) * CELL_SIZE
	y:=(cell.y + 1 )* CELL_SIZE

	switch cell.dir{
		case .LEFT:
			x -= i32(tickPercentage*CELL_SIZE)
		case .RIGHT:
			x += i32(tickPercentage*CELL_SIZE)
		case .UP:
			y -= i32(tickPercentage*CELL_SIZE)
		case .DOWN:
			y += i32(tickPercentage*CELL_SIZE)
	}

	rl.DrawCircle(
		x, 
		y,
		CELL_SIZE/2-2,
		rl.GREEN 
	);
	
	if cell.next != {} {
		drawSnake(cell.next, game)
	}
}

moveSnake :: proc(cell: ^SnakeCell, dir:Direction) {
	 switch cell.dir{
		case .LEFT:
			cell.x -= 1
			if(cell.x < 0){
				cell.x = GAME_WIDTH
			}
		case .RIGHT:
			cell.x += 1
			if(cell.x >= GAME_WIDTH){
				cell.x = 0
			}
		case .UP:
			cell.y -= 1
			if(cell.y < 0){
				cell.y = GAME_HEIGHT
			}
		case .DOWN:
			cell.y +=1
			if(cell.y >= GAME_HEIGHT){
				cell.y = 0
			}
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
		window := Window{
			"Snake",
			GAME_WIDTH * CELL_SIZE,
			GAME_HEIGHT * CELL_SIZE,
			60,
			rl.ConfigFlags{}
		}
		rl.InitWindow(window.width, window.height, window.name)
		rl.SetWindowState(window.controlFlags)
		rl.SetTargetFPS(window.fps)
	}

	//initialize game
	game := Game{
		tick_rate = 300 * time.Millisecond,
		last_tick = time.now(),
		width = GAME_WIDTH, 
		height = GAME_HEIGHT,
	}

	snakeHead := createSnake(INITIAL_SNAKE_SIZE)
	defer freeSnake(snakeHead);

	input := Input{.RIGHT}

	//game loop
	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		drawSnake(snakeHead, game)
		processUserInput(&input)
		//todo: input buffer

		if time.since(game.last_tick) > game.tick_rate {
			game.last_tick = time.now()
			moveSnake(snakeHead, input.dir)
			//todo: spawn apples
		}
	}

}