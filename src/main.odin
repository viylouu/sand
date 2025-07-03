package main

import "core:fmt"
import "core:math"

import "cels"

import "../eng"
import "../eng/draw"
import "../eng/time"
import "../eng/input"

import frfr "vendor:glfw"

data: [800][600]cels.cel_str
upd:  [800][600]bool

lmcx, lmcy, mcx, mcy: f32

main :: proc() {
	using eng
	init("sand", 800,600)
	defer end()

	vsync(false)

	loop(
		proc() /* update */ {
			using input

			lmcx = math.clamp(lmouse_x, 0, 799)
			lmcy = math.clamp(lmouse_y, 0, 599)
			mcx = math.clamp(mouse_x, 0, 799)
			mcy = math.clamp(mouse_y, 0, 599)

			if get_mouse(frfr.MOUSE_BUTTON_LEFT) == mstate.hold { 
				dx,dy := mcx - lmcx, mcy - lmcy
				if dx == 0 && dy == 0 { 
					data[int(mcx)][int(mcy)] = cels.gens[1]^()
				} else {
					dir := math.atan2(dy, dx)
					dst := math.sqrt(dx*dx + dy*dy)

					cosd := math.cos(dir)
					sind := math.sin(dir)

					for i in 0..<i32(math.ceil(dst)) {
						px,py := int(lmcx + cosd*f32(i)), int(lmcy + sind*f32(i))
						data[px][py] = cels.gens[1]^()
					}
				}
			}

			upd = [800][600]bool{}

			for x in 0..<800 { for y in 0..<600 {
				if data[x][y].dat == nil { continue }
				if upd[x][y] { continue }

				data[x][y].func^(&data, &upd, x,y)
			} }
		},
		proc() /* render */ {
			using draw

			clear(0,0,0)

			for x in 0..<800 { for y in 0..<600 {
				if data[x][y].dat == nil { continue }

				rect(x,y, 1,1, [3]u8 { 255, 0, 0 })
			} }

			fmt.println(math.round(1/time.delta))
		}
	)
}
