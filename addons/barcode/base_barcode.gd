@icon("res://addons/barcode/barcode_48px.svg")
@abstract
class_name Barcode
extends Control

@export var barcode_text: String = "":
    set(value):
        barcode_text = value
        if is_inside_tree():
            _update_view()
@export var bar_color: Color = Color.BLACK:
    set(value):
        bar_color = value
        if is_inside_tree():
            _update_view()
@export var space_color: Color = Color.WHITE:
    set(value):
        space_color = value
        if is_inside_tree():
            _update_view()
@export var quiet_zone_percentage: int = 10:
    set(value):
        quiet_zone_percentage = value
        if is_inside_tree():
            _update_view()

@export_group("Human Readable Text", "human_readable")
@export var human_readable_enabled: bool = true:
    set(value):
        human_readable_enabled = value
        if is_inside_tree():
            _update_view()
@export var human_readable_font: Font = preload("res://addons/barcode/system_font_monospace.tres"):
    set(value):
        human_readable_font = value
        if is_inside_tree():
            _update_view()
@export var human_readable_font_size: int = 16:
    set(value):
        human_readable_font_size = value
        if is_inside_tree():
            _update_view()

var _codes: PackedByteArray = PackedByteArray()

func _ready() -> void:
    _update_view()
    resized.connect(queue_redraw)

func _update_view() -> void:
    if barcode_text.is_empty():
        _codes.clear()
        queue_redraw()
        return
    
    if not _validate_text(barcode_text):
        push_error("Invalid barcode text: '%s'" % barcode_text)
        return
    
    _generate_bars()
    queue_redraw()

func set_text(text: String) -> void:
    barcode_text = text

## Validate the input text for the specific barcode type
@abstract func _validate_text(text: String) -> bool


## Generate the bar and space patterns for the barcode.[br]
## Returns a PackedByteArray where[br]- 1 represents a bar and[br]- 0 represents a space.
@abstract func _generate_bars() -> void


func _draw() -> void:
    if _codes.is_empty():
        return

    var available_width := size.x
    var available_height := size.y
    
    if available_width <= 0 or available_height <= 0:
        return
    
    # 计算文本高度
    var text_height := 0.0
    var text_margin := 4.0
    if human_readable_enabled and human_readable_font:
        text_height = human_readable_font.get_height() + text_margin
    
    var barcode_height := available_height - text_height
    
    # 计算条形码的总单位数（包括静区）
    var total_bars := _codes.size()
    var quiet_zone_units := (total_bars * quiet_zone_percentage) / 100.0
    var total_units := total_bars + 2.0 * quiet_zone_units
    
    # 计算每个单位的实际宽度（拉伸填充）
    var unit_width := available_width / total_units
    
    # 绘制背景（空白区域）
    draw_rect(Rect2(0, 0, available_width, barcode_height), space_color, true)
    
    # 绘制条形码
    var x_pos := quiet_zone_units * unit_width
    for i in range(_codes.size()):
        if _codes[i] == 1:  # 绘制条
            var bar_rect := Rect2(x_pos, 0, unit_width, barcode_height)
            draw_rect(bar_rect, bar_color, true)
        # 如果是0（空），不需要绘制，因为背景已经是space_color
        x_pos += unit_width
    
    # 绘制人类可读文本
    if human_readable_enabled and human_readable_font and not barcode_text.is_empty():
        var text_to_display := barcode_text
        var text_size := human_readable_font.get_string_size(text_to_display)
        var text_x := (available_width - text_size.x) / 2.0
        var text_y := barcode_height + human_readable_font.get_ascent() + text_margin / 2.0
        draw_string(human_readable_font, Vector2(text_x, text_y), text_to_display, HORIZONTAL_ALIGNMENT_CENTER, -1, human_readable_font_size, bar_color)