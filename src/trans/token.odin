package trans

token :: struct {
	type: tok_type,
	name: string,
	data: type_data
}

tok_type :: enum {
	label,
	func,
	switchlike,
	name,
	comparison,
	string
}

type_data :: union {
	none,
	param_data,
	param_func_data
}

tok_names := [tok_type]string { 
	.label = "label", 
	.func = "func", 
	.switchlike = "switchlike", 
	.name = "name",
	.comparison = "comparison",
	.string = "string"
}

none :: struct { }
param_data :: struct { 
	params: []token
}
param_func_data :: struct {
	params: []token,
	data: []token
}
