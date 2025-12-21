@tool
@icon("res://addons/barcode/barcode_128b_48px.svg")
class_name BarCode128B
extends Barcode

# Code128 编码表：每个字符由11个模块组成（6个条，5个空）
# 格式：条-空-条-空-条-空（每个数字表示模块数）
const CODE_PATTERNS := [
    "11011001100", "11001101100", "11001100110", "10010011000", "10010001100",
    "10001001100", "10011001000", "10011000100", "10001100100", "11001001000",
    "11001000100", "11000100100", "10110011100", "10011011100", "10011001110",
    "10111001100", "10011101100", "10011100110", "11001110010", "11001011100",
    "11001001110", "11011100100", "11001110100", "11101101110", "11101001100",
    "11100101100", "11100100110", "11101100100", "11100110100", "11100110010",
    "11011011000", "11011000110", "11000110110", "10100011000", "10001011000",
    "10001000110", "10110001000", "10001101000", "10001100010", "11010001000",
    "11000101000", "11000100010", "10110111000", "10110001110", "10001101110",
    "10111011000", "10111000110", "10001110110", "11101110110", "11010001110",
    "11000101110", "11011101000", "11011100010", "11011101110", "11101011000",
    "11101000110", "11100010110", "11101101000", "11101100010", "11100011010",
    "11101111010", "11001000010", "11110001010", "10100110000", "10100001100",
    "10010110000", "10010000110", "10000101100", "10000100110", "10110010000",
    "10110000100", "10011010000", "10011000010", "10000110100", "10000110010",
    "11000010010", "11001010000", "11110111010", "11000010100", "10001111010",
    "10100111100", "10010111100", "10010011110", "10111100100", "10011110100",
    "10011110010", "11110100100", "11110010100", "11110010010", "11011011110",
    "11011110110", "11110110110", "10101111000", "10100011110", "10001011110",
    "10111101000", "10111100010", "11110101000", "11110100010", "10111011110",
    "10111101110", "11101011110", "11110101110", "11010000100", "11010010000",
    "11010011100", "11000111010"
]

const START_A := 103
const START_B := 104
const START_C := 105
const STOP := 106

func _validate_text(text: String) -> bool:
    # Code128 支持所有ASCII字符 (0-127)
    for i in range(text.length()):
        var char_code := text.unicode_at(i)
        if char_code > 127:
            return false
    return true

func _generate_bars() -> void:
    if barcode_text.is_empty():
        return
    
    var values: Array[int] = []
    
    # 选择最优的起始字符集（简化版：使用Start B处理可打印字符）
    var start_code := START_B
    values.append(start_code)
    
    # 编码文本
    for i in range(barcode_text.length()):
        var char_code := barcode_text.unicode_at(i)
        var value := _char_to_value_b(char_code)
        if value >= 0:
            values.append(value)
    
    # 计算校验和
    var checksum := start_code
    for i in range(1, values.size()):
        checksum += values[i] * i
    checksum = checksum % 103
    values.append(checksum)
    
    # 添加停止符
    values.append(STOP)
    
    # 转换为条码模式
    var bars := PackedByteArray()
    
    for value in values:
        if value >= 0 and value < CODE_PATTERNS.size():
            var pattern: String = CODE_PATTERNS[value]
            # 解析模式字符串，转换为条和空
            for j in range(0, pattern.length(), 2):
                # 条
                var bar_count := int(pattern[j])
                for k in range(bar_count):
                    bars.append(1)
                # 空
                if j + 1 < pattern.length():
                    var space_count := int(pattern[j + 1])
                    for k in range(space_count):
                        bars.append(0)
    
    # 添加终止条
    bars.append(1)
    bars.append(1)
    
    _codes = bars

# 将字符转换为Code Set B的值
func _char_to_value_b(char_code: int) -> int:
    if char_code >= 32 and char_code <= 127:
        return char_code - 32
    elif char_code >= 0 and char_code <= 31:
        # 控制字符，需要使用Shift或Code Set A
        return -1
    return -1

