#+feature dynamic-literals

package trans

import "core:fmt"
import "core:os"

pile :: proc(f: os.Handle, toks: []token, name: string, islvl_0: bool = true) {
	using fmt

	if islvl_0 {
		assert(len(toks) == 2)

		assert(toks[0].type == .label)
		assert(toks[0].name == "self")

		assert(toks[0].data.(param_data).params[0].type == .name)
		assert(toks[0].data.(param_data).params[0].name == "nil")

		fprintf (f, "%s_cel :: struct {{\n", name)
		fprintln(f, "}")

		fprintf (f, "%s_gen := proc() -> cel_str {{\n", name)
		fprintf (f, "	return cel_str {{ func = &%s_func, dat = %s_cel {{}}, }\n", name, name)
		fprintln(f, "}")

		assert(toks[1].type == .label)
		assert(toks[1].name == "func")

		fprintf (f, "%s_func := proc(dat: ^[800][600]cel_str, upd: ^[800][600]bool, x,y: int) {{\n", name)
		pile(f, toks[1].data.(param_data).params, name, false)
		fprintln(f, "}")

		return
	}

	for tok in toks {
		if tok.name == "move" {
			assert(tok.type == .func)
			assert(len(tok.data.(param_data).params) == 1)
			assert(tok.data.(param_data).params[0].type == .name)
			move(f, tok.data.(param_data).params[0].name)
		}

		if tok.name == "rand" {
			assert(tok.type == .switchlike)
			assert(len(tok.data.(param_func_data).params) == 0)
			assert(len(tok.data.(param_func_data).data) != 0)
			rand(f, tok.data.(param_func_data).data)
		}
	}
}

assert :: proc(b: bool) {
	if !b {
		fmt.eprintln("ERROR: FUCK YOU!!!!")
		os.exit(1)
	}
}


// stuff

dir :: enum {
	u,
	d,
	l,
	r,
	ul,
	ur,
	dl,
	dr
}

dir_lut := map[string]dir {
	"u" = .u,
	"d" = .d,
	"l" = .l,
	"r" = .r,
	"ul" = .ul,
	"ur" = .ur,
	"dl" = .dl,
	"dr" = .dr
}

dir_lut_x := map[string]string {
	"u" = "0",
	"d" = "0",
	"l" = "-1",
	"r" = "1",
	"ul" = "-1",
	"ur" = "1",
	"dl" = "-1",
	"dr" = "1"
}

dir_lut_y := map[string]string {
	"u" = "-1",
	"d" = "1",
	"l" = "0",
	"r" = "0",
	"ul" = "-1",
	"ur" = "-1",
	"dl" = "1",
	"dr" = "1"
}

move :: proc(f: os.Handle, d: string) {
	using fmt
	di := dir_lut[d]
	switch di {
		case .u:
			fprintln(f, "if y > 0 {")
		case .d:
			fprintln(f, "if y < 599 {")
		case .l:
			fprintln(f, "if x > 0 {")
		case .r:
			fprintln(f, "if x < 799 {")
		case .ul:
			fprintln(f, "if y > 0 && x > 0 {")
		case .ur:
			fprintln(f, "if y > 0 && x < 799 {")
		case .dl:
			fprintln(f, "if y < 599 && x > 0 {")
		case .dr:
			fprintln(f, "if y < 599 && x < 799 {")
	}

	dx,dy := dir_lut_x[d], dir_lut_y[d]
	
	fprintf (f, "	if dat^[x+%s][y+%s].dat == nil {{\n", dx,dy)
	fprintf (f, "		dat^[x+%s][y+%s] = dat^[x][y]\n", dx,dy)
	fprintln(f, "		dat^[x][y] = cel_str {}")
	fprintf (f, "		upd^[x+%s][y+%s] = true\n", dx,dy)
	fprintln(f, "		return")
	fprintln(f, "	}")
	fprintln(f, "}")
}

rand :: proc(f: os.Handle, data: []token) {
	using fmt

	fprintf (f, "switch rand.int_max(%d) {{", len(data))
	
	for c in data {
		assert(c.name == "case")
		assert(c.type == .label)
	}

	fprintln(f, "}")
}
