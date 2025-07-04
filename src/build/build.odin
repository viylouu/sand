package build

import "../trans"

import "../../eng/error"

import "core:os"
import "core:os/os2"
import "core:fmt"
import "core:strings"

main :: proc() {
	// generate cels

	file := "src/cels/cels.odin"

	f, err := os.open(file, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	error.critical("failed to open/create cels.odin!", err != nil)

	using fmt
	fprintln(f, "// AUTOGENERATED BY src/build/build.odin")
	fprintln(f, "// DO NOT OVERWRITE UNLESS YOU KNOW WHAT YOU ARE DOING \n\n\n")

	fprintln(f, "package cels")
	fprintln(f, "import \"core:fmt\"")
	fprintln(f, "import \"core:math/rand\"")

	fprintln(f, "cel_str :: struct {")
	fprintln(f, "	func: ^proc(^[800][600]cel_str, ^[800][600]bool, int,int),")
	fprintln(f, "	dat: cel")
	fprintln(f, "}")

	handle, herr := os.open("data/cels")
	error.critical("failed to open data/cels!", herr != nil)

	entries, eerr := os.read_dir(handle, 65536)
	error.critical("failed to get files in data/cels!", eerr != nil)

	fprintln(f, "list :: enum {")
	for entry in entries { fprintf(f, "	%s,\n", strings.trim_suffix(entry.name, ".cel")) }
	fprintln(f, "}")

	fprintln(f, "gens := [?]^proc()->cel_str {")
	for entry in entries { fprintf(f, "	&%s_gen,\n", strings.trim_suffix(entry.name, ".cel")) }
	fprintln(f, "}")

	fprintln(f, "cel :: union {")
	for entry in entries { fprintf(f, "	%s_cel,\n", strings.trim_suffix(entry.name, ".cel")) }
	fprintln(f, "}")
	
	for entry in entries {
		data, err := os.read_entire_file(entry.fullpath)
		str := string(data)

		println("	", entry.name)
		fprintln(f, "//", entry.name)

		toks := trans.lex(f, str)
		trans.pile(f, toks, strings.trim_suffix(entry.name, ".cel"))
	}

	os.close(handle)

	os.close(f)

	cmd := []string {
		"odin",
		"build",
		"src",
		"-out:build/sand.game"
	}

	process, start_err := os2.process_start(os2.Process_Desc{
		command=cmd,
		stdout=os2.stdout,
		stderr=os2.stderr
	})

	error.critical("INITAIL ERROR", start_err != nil)

	_, wait_err := os2.process_wait(process)
	error.critical("RUNTIME ERROR", wait_err != nil)
}
