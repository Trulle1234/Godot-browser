extends Node

@onready var document: RichTextLabel = $"../Document"

const TEXT_TEMPLATE = "
[wave][font_size=32][b]Godot browser[/b][/font_size][/wave]
[i][font_size=18.72][time][/font_size][/i]

[font_size=24][b]Shortcuts[/b][/font_size]

[font_size=18.72][b][url=https://text.npr.org][color=#0000ee]NPR Text[/color][/url]  •  [url=https://news.ycombinator.com/][color=#0000ee]Hacker News[/color][/url]  •  [url=https://brutalist.report/][color=#0000ee]The Brutalist Report[/color][/url]  •  [url=https://en.wikipedia.org/wiki/Main_Page][color=#0000ee]English Wikipedia[/color][/url]  •  [url=https://apod.nasa.gov/apod/astropix.html][color=#0000ee]Astronomy Picture of the Day[/color][/url]  •  [url=https://www.gutenberg.org/][color=#0000ee]Project Gutenberg[/color][/url][/b][/font_size]
"


# get and format date and clock
func get_clock():
	var dt = Time.get_datetime_dict_from_system()
	
	var month_str = str(dt.month) if dt.month >= 10 else "0" + str(dt.month)
	var day_str = str(dt.day) if dt.day >= 10 else "0" + str(dt.day)
	var minute_str = str(dt.minute) if dt.minute >= 10 else "0" + str(dt.minute)
	
	var date = str(dt.year) + "-" + month_str + "-" + day_str
	var time = str(dt.hour) + ":" + minute_str
	
	return date + " - " + time

func _on_browser_set_home() -> void:
	document.clear()
	document.append_text(TEXT_TEMPLATE.replace("[time]", get_clock()))
