@tool
@icon("res://addons/barcode/barcode_39_48px.svg")
class_name BarCode39
extends Barcode

const ENCODING_TABLE := {
	"0": "000110100",
	"1": "100100001",
	"2": "001100001",
	"3": "101100000",
	"4": "000110001",
	"5": "100110000",
	"6": "001110000",
	"7": "000100101",
	"8": "100100100",
	"9": "001100100",
	"A": "100001001",
	"B": "001001001",
	"C": "101001000",
	"D": "000011001",
	"E": "100011000",
	"F": "001011000",
	"G": "000001101",
	"H": "100001100",
	"I": "001001100",
	"J": "000011100",
	"K": "100000011",
	"L": "001000011",
	"M": "101000010",
	"N": "000010011",
	"O": "100010010",
	"P": "001010010",
	"Q": "000000111",
	"R": "100000110",
	"S": "001000110",
	"T": "000010110",
	"U": "110000001",
	"V": "011000001",
	"W": "111000000",
	"X": "010010001",
	"Y": "110010000",
	"Z": "011010000",
	"-": "010000101",
	".": "110000100",
	" ": "011000100",
	"$": "010101000",
	"/": "010100010",
	"+": "010001010",
	"%": "000101010",
	"*": "010010100"  # 起始/结束字符
}

func _validate_text(text: String) -> bool:
	var valid_chars := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*"
	for char in text:
		if valid_chars.find(char) == -1:
			return false
	return true

func _generate_bars() -> void:
	# Code39字符编码表：每个字符由9个元素组成（条和空交替）
	# 1表示宽元素，0表示窄元素
	# 格式：条-空-条-空-条-空-条-空-条
	
	var bars := PackedByteArray()
	
	# 添加起始字符 '*'
	var encoded_text := "*" + barcode_text.to_upper() + "*"
	
	for i in range(encoded_text.length()):
		var char := encoded_text[i]
		if not ENCODING_TABLE.has(char):
			push_error("Character '%s' not supported in Code39" % char)
			return PackedByteArray()
		
		var pattern: String = ENCODING_TABLE[char]
		
		# 将模式转换为条形码数据
		# 奇数位置是条（bar），偶数位置是空（space）
		for j in range(pattern.length()):
			var is_bar := (j % 2 == 0)  # 0,2,4,6,8 是条
			var is_wide: bool = (pattern[j] == "1")  # 1表示宽元素
			
			if is_bar:
				# 条：宽条用多个1表示，窄条用单个1
				if is_wide:
					bars.append(1)
					bars.append(1)
					bars.append(1)
				else:
					bars.append(1)
			else:
				# 空：宽空用多个0表示，窄空用单个0
				if is_wide:
					bars.append(0)
					bars.append(0)
					bars.append(0)
				else:
					bars.append(0)
		
		# 字符间间隔（窄空格）
		if i < encoded_text.length() - 1:
			bars.append(0)
	
	_codes = bars
