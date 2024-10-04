package snake

import "core:fmt"
import time "core:time"
import rl "vendor:raylib"

CELL_SIZE :: 20

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

drawSnake :: proc(cell: ^SnakeCell) {
	sc:=cell^;

	rl.DrawCircle(
		(sc.x + 1) * CELL_SIZE, 
		(sc.y + 1 )* CELL_SIZE,
		CELL_SIZE-5,
		rl.GREEN 
	);
	
	if sc.next != {} {
		drawSnake(sc.next)
	}
}

moveSnake :: proc(cell: ^SnakeCell, dir:Direction) {
	sc:=cell^;
	
	 switch dir{
		case .LEFT:
			cell^.x -= 1
		case .RIGHT:
			cell^.x += 1
		case .UP:
			cell^.y -= 1
		case .DOWN:
			cell^.y +=1
	}
	
	if sc.next != {} {
		moveSnake(sc.next, sc.dir)
	}
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

	snakeHead := SnakeCell{0,0,.RIGHT,{}}
	input := Input{.RIGHT}

	//game loop
	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		drawSnake(&snakeHead)
		processUserInput(&input)

		if time.since(game.last_tick) > game.tick_rate {
			game.last_tick = time.now()
			moveSnake(&snakeHead, input.dir)
		}
	}

}