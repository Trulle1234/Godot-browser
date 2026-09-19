extends Node

const HtmlEntites = preload("uid://djdo25jgebmdo")

static func to_bbcode(html, document):
	# get title
	var title = "Untitled"
	var title_regex = RegEx.create_from_string("(?is)<title[^>]*>(.*?)</title>") 
	var title_match = title_regex.search(html) 
	
	if title_match: 
		title = title_match.get_string(1).strip_edges()
	
	# remove everything outside of body
	var body_regex = RegEx.create_from_string("(?is)^.*?<body[^>]*>(.*?)</body>.*$")
	var cleaned = body_regex.sub(html, "$1", true)
	
	# remove scripts and styles
	var tags_to_remove = ["script", "style"]
	for tag in tags_to_remove:
		var tag_remove_regex = RegEx.create_from_string("(?is)<" + tag + "[^>]*>.*?</" + tag + ">")
		cleaned = tag_remove_regex.sub(cleaned, "", true)
	
	# remove comments 
	var comment_regex = RegEx.create_from_string("(?s)<!--.*?-->") 
	cleaned = comment_regex.sub(cleaned, "", true)
	
	# collapse html whitespace
	var whitespace_regex = RegEx.create_from_string("\\s+")
	cleaned = whitespace_regex.sub(cleaned, " ", true)
		
	# text formating
	var html_to_bbcode = {
		"p": "p",
		"div": "p",
		"header": "p",
		"b": "b",
		"strong": "b",
		"i": "i",
		"em": "i",
		"u": "u",
		"s": "s",
		"del": "s"
	}

	for tag in html_to_bbcode:
		var bbcode_tag = html_to_bbcode[tag]
		
		var open_regex = RegEx.create_from_string("(?is)<" + tag + "\\b[^>]*>")
		var close_regex = RegEx.create_from_string("(?is)</" + tag + "\\s*>")
		
		cleaned = open_regex.sub(cleaned, "[" + bbcode_tag + "]", true)
		cleaned = close_regex.sub(cleaned, "[/" + bbcode_tag + "]", true)
	
	# headings
	var font_size = document.get_theme_font_size("normal_font_size")
	
	var html_heading_to_bbcode = {
		"h1": ["[p][font_size=" + str(font_size * 2.00) + "][b]", "[/b][/font_size][/p]"],
		"h2": ["[p][font_size=" + str(font_size * 1.50) + "][b]", "[/b][/font_size][/p]"],
		"h3": ["[p][font_size=" + str(font_size * 1.17) + "][b]", "[/b][/font_size][/p]"],
		"h4": ["[p][font_size=" + str(font_size * 1.00) + "][b]", "[/b][/font_size][/p]"],
		"h5": ["[p][font_size=" + str(font_size * 0.83) + "][b]", "[/b][/font_size][/p]"],
		"h6": ["[p][font_size=" + str(font_size * 0.75) + "][b]", "[/b][/font_size][/p]"]
	}
	
	for heading in html_heading_to_bbcode:
		var bbcode_start = html_heading_to_bbcode[heading][0]
		var bbcode_end = html_heading_to_bbcode[heading][1]
		var p_regex = RegEx.create_from_string("(?is)<" + heading + "[^>]*>(.*?)</" + heading + ">")
		
		cleaned = p_regex.sub(cleaned, bbcode_start + "$1" + bbcode_end, true)
	
	# links
	var link_regex = RegEx.create_from_string('(?is)<a[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>')
	cleaned = link_regex.sub(cleaned, "[url=$1][color=#0000ee]$2[/color][/url]", true)
	
	# common html entities
	
	for entity in HtmlEntites.html_entities:
		cleaned = cleaned.replace(entity, HtmlEntites.html_entities[entity])
	
	# br newlines
	var br_regex = RegEx.create_from_string("(?i)<br\\b[^>]*>")
	cleaned = br_regex.sub(cleaned, "[br]", true)
	
	# hr lines
	var hr_regex = RegEx.create_from_string("(?i)<hr\\b[^>]*>")
	cleaned = hr_regex.sub(cleaned, "[hr width=100%]", true)
	
	# remove any remaining html tags
	var unknown_tag_regex = RegEx.create_from_string("(?is)<[^>]+>")
	cleaned = unknown_tag_regex.sub(cleaned, "", true)
	
	# remove whitespace around newlines
	var newline_space_regex = RegEx.create_from_string("[ \\t]*\\n[ \\t]*")
	cleaned = newline_space_regex.sub(cleaned, "\n", true)
	
	return {
		"title": title, 
		"text": cleaned
		}
