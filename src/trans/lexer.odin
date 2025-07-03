package trans

import "core:fmt"
import "core:strings"
import "core:os"

lex :: proc(f: os.Handle, file: string) -> []token {
	toks: [dynamic]token
	index, indent: int
	builder := strings.builder_make()
	for index < len(file) {
		tokenize(file, &toks, &index, &indent, &builder)
	}

	fmt.fprintf(f, "/*\n")
	index = 0
	tabs := ""
	for index < len(toks) {
		term := pretty_print(f, toks[:], &index, tabs)
		fmt.println(term)
		fmt.fprintln(f, term)
	}
	fmt.fprintf(f, "*/\n")

	return toks[:]
}

pretty_print :: proc(f: os.Handle, toks: []token, i: ^int, tabs: string) -> string {
    if i^ >= len(toks) {
        return ""
    }

    tok := toks[i^]
    i^ += 1

    result := ""

    switch d in tok.data {
		case none:
			conc := fmt.aprintf("[type:%s, name:%s]\n", tok_names[tok.type], tok.name)
			result = strings.concatenate([]string{tabs, conc})
		case param_data:
			conc := fmt.aprintf("[type:%s, name:%s, params:{{\n", tok_names[tok.type], tok.name)
			result = strings.concatenate([]string{tabs, conc})

			new_tabs := strings.concatenate([]string{tabs, "\t"})

			j := 0
			for j < len(tok.data.(param_data).params) {
				nested := pretty_print(f, tok.data.(param_data).params, &j, new_tabs)
				result = strings.concatenate([]string{result, nested})
			}

			result = strings.concatenate([]string{result, tabs, "}]\n"})
		case param_func_data:
			conc := fmt.aprintf("[type:%s, name:%s, params:{{\n", tok_names[tok.type], tok.name)
			result = strings.concatenate([]string{tabs, conc})

			new_tabs := strings.concatenate([]string{tabs, "\t"})

			j := 0
			for j < len(tok.data.(param_func_data).params) {
				nested := pretty_print(f, tok.data.(param_func_data).params, &j, new_tabs)
				result = strings.concatenate([]string{result, nested})
			}

			result = strings.concatenate([]string{result, tabs, "}, data:{\n"})

			j = 0
			for j < len(tok.data.(param_func_data).data) {
				nested := pretty_print(f, tok.data.(param_func_data).data, &j, new_tabs)
				result = strings.concatenate([]string{result, nested})
			}

			result = strings.concatenate([]string{result, tabs, "}]\n"})
    }

    return result
}

tokenize :: proc(file: string, toks: ^[dynamic]token, i: ^int, indent: ^int, builder: ^strings.Builder) {
	defer i^ += 1

	if i^ >= len(file) {
		indent^ = 0
		strings.write_rune(builder, 'a')
		i^ += 1
		return
	}

	char := rune(file[i^])

	if char == '#' {
		for file[i^] != '\n' { i^ += 1 }
		return
	}

	switch char {
		case '(':
			dat: [dynamic]token

			builder_2 := strings.builder_make()
			indent_2 := indent^

			i^ += 1
			for file[i^] != ')' { 
				tokenize(file, &dat, i, &indent_2, &builder_2)
			}
			i^ += 1

			word := strings.to_string(builder_2)
			if word != "" {
				append(&dat, token {
					type = .name,
					name = strings.clone(word),
					data = none {}
				})
			}
			
			type :tok_type= file[i^] == ':'? .switchlike : .func
			if file[i^] == ':' { 
				i^ += 1 
				// do the shit that : does
				dat_2: [dynamic]token

				strings.builder_reset(&builder_2)
				indent_2 = 0

				i^ += 1
				for !(strings.to_string(builder_2) != "" && indent_2 <= indent^) { 
					tokenize(file, &dat_2, i, &indent_2, &builder_2)
				}
				i^ -= 2

				append(toks, token {
					type = .switchlike,
					name = strings.clone(strings.to_string(builder^)),
					data = param_func_data { params = dat[:], data = dat_2[:] }
				})
			} else {
				append(toks, token {
					type = type,
					name = strings.clone(strings.to_string(builder^)),
					data = param_data { params = dat[:] }
				})
			}

			strings.builder_reset(builder)
			strings.builder_destroy(&builder_2)
		case '"':
			i^ += 1
			for file[i^] != '"' {
				strings.write_rune(builder, rune(file[i^]))
				i^ += 1
			}
			i^ += 1

			append(toks, token {
				type = .string,
				name = strings.clone(strings.to_string(builder^)),
				data = none {}
			})

			strings.builder_reset(builder)
		case ':':
			dat: [dynamic]token

			builder_2 := strings.builder_make()
			indent_2 := 0

			i^ += 1
			for  { 
				tokenize(file, &dat, i, &indent_2, &builder_2)

				if strings.to_string(builder_2) != "" && indent_2 <= indent^ {
					break
				}
			}
			i^ -= 2

			append(toks, token {
				type = .label,
				name = strings.clone(strings.to_string(builder^)),
				data = param_data { params = dat[:] }
			})

			strings.builder_reset(builder)
			strings.builder_destroy(&builder_2)
		case '\t':
			indent^ += 1
		case ' ':
			if strings.to_string(builder^) != "" { return }

			times := 0
			for file[i^] == ' ' {
				if times == 1 {
					times = 0
					indent^ += 1
				}

				times += 1
				i^ += 1
			}
		case '\n':
			word := strings.to_string(builder^)
			if word != "" {
				append(toks, token {
					type = .name,
					name = strings.clone(word),
					data = none {}
				})
				strings.builder_reset(builder)
			}

			indent^ = 0

		case 'a'..='z', 'A'..='Z':
			strings.write_rune(builder, char)
		case '&':
			if file[i^+1]=='&' {
				append(toks, token {
					type = .comparison,
					name = "&&",
					data = none {}
				})
			}
	}
}
