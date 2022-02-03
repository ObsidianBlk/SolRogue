extends Node
tool


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------

func int_to_hex(v : int, minlen : int = 0) -> String:
	var s = sign(v)
	v = abs(v)
	var hex = ""
	while hex == "" or v > 0:
		var code = v & 0xF
		match code:
			10:
				hex = "A" + hex
			11:
				hex = "B" + hex
			12:
				hex = "C" + hex
			13:
				hex = "D" + hex
			14:
				hex = "E" + hex
			15:
				hex = "F" + hex
			_:
				hex = String(code) + hex
		v = v >> 4
	while hex.length() < minlen:
		hex = "0" + hex
	return hex


func uuidv4(no_seperate : bool = false) -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var uuid = ""
	for i in range(0, 16):
		var byte = rng.randi_range(0, 256)
		if i == 6:
			byte = 0x40 | (0x0F & byte)
		elif i == 9:
			byte = 0x80 | (0x3F & byte)
		uuid += int_to_hex(byte, 2)
		if not no_seperate and (i == 3 or i == 5 or i == 7 or i == 9):
			uuid += "-"
	return uuid


