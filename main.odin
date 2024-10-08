package snake

import "core:fmt"
import time "core:time"
import "core:math/rand"
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
	tick_count: i32,
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

Apple :: struct {
	x,y: i32,
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

drawApples :: proc(apples: ^[dynamic]Apple) {
	for apple in apples{
		x:=(apple.x + 1) * CELL_SIZE
		y:=(apple.y + 1 )* CELL_SIZE
		rl.DrawCircle(
			x, 
			y,
			CELL_SIZE/3-2,
			rl.RED 
		);
	}
}

moveSnake :: proc(cell: ^SnakeCell, dir:Direction) {
	 #partial switch cell.dir{
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

processUserInput :: proc(input:Input, inputBuf: ^[dynamic]Input){
	size := len(inputBuf);
	#partial switch rl.GetKeyPressed(){
		case .LEFT, .A, .H :
			if (size <= 0 && input.dir != .LEFT && input.dir != .RIGHT)  || (size > 0 && inputBuf[0].dir != .LEFT && inputBuf[0].dir != .RIGHT)  {
				inject_at(inputBuf,0, Input{.LEFT})
			}
		case .RIGHT, .D, .L :
			if (size <= 0 && input.dir != .RIGHT && input.dir != .LEFT)  || (size > 0 && inputBuf[0].dir != .LEFT && inputBuf[0].dir != .RIGHT)  {
				inject_at(inputBuf,0, Input{.RIGHT})
			}
		case .UP, .W, .K :
			if (size <= 0 && input.dir != .UP && input.dir != .DOWN)  || (size > 0 && inputBuf[0].dir != .UP && inputBuf[0].dir != .DOWN)  {
				inject_at(inputBuf,0, Input{.UP})
			}
		case .DOWN, .S, .J :
			if (size <= 0 && input.dir != .DOWN && input.dir != .UP)  || (size > 0 && inputBuf[0].dir != .UP && inputBuf[0].dir != .DOWN)  {
				inject_at(inputBuf,0, Input{.DOWN})
			}
	}
	for len(inputBuf) > 2 {
		pop(inputBuf);
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
	inputBuf : [dynamic]Input;

	apples : [dynamic]Apple;

	//game loop
	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		drawSnake(snakeHead, game)
		drawApples(&apples)
		processUserInput(input, &inputBuf)

		if time.since(game.last_tick) > game.tick_rate {
			game.last_tick = time.now()
			game.tick_count += 1;
			if(len(inputBuf) != 0){
				input = pop(&inputBuf)
			}
			moveSnake(snakeHead, input.dir)

			if(game.tick_count % 5 == 0 && len(apples)<5){
				append(
					&apples,
					Apple{
						i32(rand.float32() * GAME_WIDTH + 1),
						i32(rand.float32() * GAME_HEIGHT + 1)
					}
				)
			}
		}
	}

}