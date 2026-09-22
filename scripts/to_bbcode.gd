extends Node

const HtmlEntites = preload("uid://djdo25jgebmdo")

static func to_bbcode(html, document, link_color="#0000ee", img_color="#ee5f00"):
	# get title
	var title = "Untitled"
	var title_regex = RegEx.create_from_string("(?is)<title[^>]*>(.*?)</title>") 
	var title_match = title_regex.search(html) 
	
	if title_match: 
		title = title_match.get_string(1).strip_edges()
		html = html.erase(title_match.get_start(), title_match.get_end() - title_match.get_start())
	
	# get favicon url
	var favicon
	var favicon_regex = RegEx.create_from_string('(?is)<link\\b[^>]*rel=["\'][^"\']*(?:icon|shortcut icon|apple-touch-icon)[^"\']*["\'][^>]*href=["\']([^"\']+)["\'][^>]*>') 
	var favicon_match = favicon_regex.search(html) 
	
	if favicon_match: 
		favicon = favicon_match.get_string(1).strip_edges()
		html = html.erase(favicon_match.get_start(), favicon_match.get_end() - favicon_match.get_start())
	
	# remove everything outside of body
	var body_regex = RegEx.create_from_string("(?is)^.*?<body[^>]*>(.*?)</body>.*$")
	var cleaned = body_regex.sub(html, "$1", true)
	
	# cleanup for wikipedia
	if title.contains("Wikipedia"):
		var body_content_regex = RegEx.create_from_string('(?is)^.*?<div[^>]*id=["\']bodyContent["\'][^>]*>')
		cleaned = body_content_regex.sub(cleaned, "", true)
	
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
		"del": "s",
		"ol": "ol",
		"li": "ul",
		"code": "code",
		"blockquote": "indent",
		"pre": "p"
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
		"h1": ["[font_size=" + str(font_size * 2.00) + "][b]", "[/b][/font_size]"],
		"h2": ["[font_size=" + str(font_size * 1.50) + "][b]", "[/b][/font_size]"],
		"h3": ["[font_size=" + str(font_size * 1.17) + "][b]", "[/b][/font_size]"],
		"h4": ["[font_size=" + str(font_size * 1.00) + "][b]", "[/b][/font_size]"],
		"h5": ["[font_size=" + str(font_size * 0.83) + "][b]", "[/b][/font_size]"],
		"h6": ["[font_size=" + str(font_size * 0.75) + "][b]", "[/b][/font_size]"]
	}
	
	for heading in html_heading_to_bbcode:
		var bbcode_start = html_heading_to_bbcode[heading][0]
		var bbcode_end = html_heading_to_bbcode[heading][1]
		var p_regex = RegEx.create_from_string("(?is)<" + heading + "[^>]*>(.*?)</" + heading + ">")
		
		cleaned = p_regex.sub(cleaned, bbcode_start + "$1" + bbcode_end, true)
	
	# links
	var link_regex = RegEx.create_from_string('(?is)<a[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>')
	cleaned = link_regex.sub(cleaned, "[url=$1][color=" + link_color + "]$2[/color][/url]", true)
	
	# images link to a page with only the image, as thats easier/possible to display
	var img_regex = RegEx.create_from_string('(?is)<img\\b[^>]*>')
	var img_matches = img_regex.search_all(cleaned)
	
	var src_regex = RegEx.create_from_string('(?i)src=["\']([^"\']+)["\']')
	var alt_regex = RegEx.create_from_string('(?i)alt=["\']([^"\']*)["\']')
	
	for i in range(img_matches.size() - 1, -1, -1):
		var img_match = img_matches[i]
		var img_tag = img_match.get_string()
		
		var src_match = src_regex.search(img_tag)
		var alt_match = alt_regex.search(img_tag)
		
		var src = src_match.get_string(1) if src_match else ""
		var alt = alt_match.get_string(1) if alt_match else "Image"
		
		if src == "":
			continue
			
		if alt == "":
			alt = "Image"
		
		if (
			src.contains(".png")
			or src.contains(".jpg")
			or src.contains(".jpeg")
			or src.contains(".webp")
			or src.contains(".svg")
			or src.contains(".ico")
		):
			var replacement = "[url=" + src + "][color=" + img_color + "][" + alt + "][/color][/url]"
			
			cleaned = ( cleaned.substr(0, img_match.get_start()) + replacement + cleaned.substr(img_match.get_end()))
	
	# html entities
	cleaned = solve_entites(cleaned)
	
	# entites also in title
	title = solve_entites(title)
	
	# br newlines
	var br_regex = RegEx.create_from_string("(?i)<br\\b[^>]*>")
	cleaned = br_regex.sub(cleaned, "[br]", true)
	
	# hr lines
	var hr_regex = RegEx.create_from_string("(?i)<hr\\b[^>]*>")
	cleaned = hr_regex.sub(cleaned, "[br][hr width=100%][br]", true)
	
	# table rows to newlines
	var tr_open_regex = RegEx.create_from_string("(?is)<tr\\b[^>]*>")
	var tr_close_regex = RegEx.create_from_string("(?is)</tr\\s*>")

	cleaned = tr_open_regex.sub(cleaned, "", true)
	cleaned = tr_close_regex.sub(cleaned, "[br]", true)

	# cells get a little spacing
	var td_open_regex = RegEx.create_from_string("(?is)<t[dh]\\b[^>]*>")
	var td_close_regex = RegEx.create_from_string("(?is)</t[dh]\\s*>")

	cleaned = td_open_regex.sub(cleaned, "", true)
	cleaned = td_close_regex.sub(cleaned, " ", true)
	
	# remove any remaining html tags
	var unknown_tag_regex = RegEx.create_from_string("(?is)<[^>]+>")
	cleaned = unknown_tag_regex.sub(cleaned, "", true)
	
	# cleanup duckduckgo serach page, hacker news
	cleaned = clean(cleaned)
	
	# br to newline
	cleaned = cleaned.replace("[br]", "\n")
	
	return {
		"favicon": favicon,
		"title": title, 
		"text": cleaned
	}

static func solve_entites(text):
	# common text entites
	for entity in HtmlEntites.html_entities:
		text = text.replace(entity, HtmlEntites.html_entities[entity])
	
	# hex html entities
	var hex_regex = RegEx.create_from_string("&#[xX]([0-9a-fA-F]+);")
	var hex_matches = hex_regex.search_all(text)
	
	for i in range(hex_matches.size() - 1, -1, -1):
		var m = hex_matches[i]
		var hex_val = m.get_string(1).to_lower()
		text = text.substr(0, m.get_start()) + "[char=" + hex_val + "]" + text.substr(m.get_end())
	
	# int html enties
	var int_regex = RegEx.create_from_string("&#([0-9]+);")
	var int_matches = int_regex.search_all(text)
	
	for i in range(int_matches.size() - 1, -1, -1):
		var m = int_matches[i]
		var int_val = int(m.get_string(1))
		var hex_val = "%x" % int_val
		text = text.substr(0, m.get_start()) + "[char=" + hex_val + "]" + text.substr(m.get_end())
		
	return text
	
static func clean(text):
	# duckduckgo
	text = text.replace(
		"[p] [p][/p] [p] [url=/html/][color=#0000ee][/color][/url]  [p]   [/p] [p]  All Regions Argentina Australia Austria Belgium (fr) Belgium (nl) Brazil Bulgaria Canada (en) Canada (fr) Catalonia Chile China Colombia Croatia Czech Republic Denmark Estonia Finland France Germany Greece Hong Kong Hungary Iceland India (en) Indonesia (en) Ireland Israel (en) Italy Japan Korea Latvia Lithuania Malaysia (en) Mexico Netherlands New Zealand Norway Pakistan (en) Peru Philippines (en) Poland Portugal Romania Russia Saudi Arabia Singapore Slovakia Slovenia South Africa Spain (ca) Spain (es) Sweden Switzerland (de) Switzerland (fr) Taiwan Thailand (en) Turkey US (English) US (Spanish) Ukraine United Kingdom Vietnam (en)  [/p] [p]  Any Time Past Day Past Week Past Month Past Year  [/p]  [/p] [p] [p] [p]",
		""
		)
	text = text.replace(
		"[url=//duckduckgo.com/feedback.html][color=#0000ee]Feedback[/color][/url] [/p] [p][/p] [/p] [/p] [/p] [/p] [p][/p]",
		"[url=//duckduckgo.com/feedback.html][color=#0000ee]Feedback[/color][/url]"
	)
	
	# hacker news
	text = text.replace(
		"[url=https://news.ycombinator.com][color=#0000ee][url=y18.svg][color=#ee5f00][Image][/color][/url][/color][/url] [b][url=news][color=#0000ee]Hacker News[/color][/url][/b][url=newest][color=#0000ee]new[/color][/url] | [url=front][color=#0000ee]past[/color][/url] | [url=newcomments][color=#0000ee]comments[/color][/url]",
		"[url=https://news.ycombinator.com][color=#0000ee][url=y18.svg][color=#ee5f00][Image][/color][/url][/color][/url] [b][url=news][color=#0000ee]Hacker News[/color][/url][/b] [url=newest][color=#0000ee]new[/color][/url] | [url=front][color=#0000ee]past[/color][/url] | [url=newcomments][color=#0000ee]comments[/color][/url]"
	)
	return text
