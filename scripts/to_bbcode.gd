extends Node

const HtmlEntites = preload("uid://djdo25jgebmdo")

static func to_bbcode(html, document, link_color="#0000ee", img_color="ee9700"):
	# get title
	var title = "Untitled"
	var title_regex = RegEx.create_from_string("(?is)<title[^>]*>(.*?)</title>") 
	var title_match = title_regex.search(html) 
	
	if title_match: 
		title = title_match.get_string(1).strip_edges()
		html = html.erase(title_match.get_start(), title_match.get_end() - title_match.get_start())
	
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
		"del": "s",
		"ol": "ol",
		"li": "ul",
		"code": "code",
		"blockquote": "indent",
		"pre": "code"
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
			or src.contains(".png")
			or src.contains(".jpg")
			or src.contains(".jpeg")
			or src.contains(".webp")
			or src.contains(".svg")
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
	cleaned = hr_regex.sub(cleaned, "[br][hr width=100%]", true)
	
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
	
	# cleanup duckduckgo serach page, simple en wikipedia
	cleaned = clean(cleaned)
	
	return {
		"title": title, 
		"text": cleaned
		}

static func solve_entites(text):
	# common text entites
	for entity in HtmlEntites.html_entities:
		text = text.replace(entity, HtmlEntites.html_entities[entity])
	
	# hex html entities
	var hex_entity_regex = RegEx.create_from_string("&#x([0-9a-fA-F]+);")
	var hex_matches = hex_entity_regex.search_all(text)
	
	for i in range(hex_matches.size() - 1, -1, -1):
		var match = hex_matches[i]
		
		text = (text.substr(0, match.get_start()) + "[char=" + str(match.get_string(1)) + "]" + text.substr(match.get_end()))
	
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
	
	# wikipedia
	text = text.replace(
		" [p][/p][url=#bodyContent][color=#0000ee]Jump to content[/color][/url] [p] [p] [p]  [p]   Main menu  [p] [p] [p] [p] [p]Main menu[/p] move to sidebar hide [/p] [p] [p] Getting around [/p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Main page[/color][/url][/ul][ul][url=/wiki/Wikipedia:Simple_start][color=#0000ee]Simple start[/color][/url][/ul][ul][url=/wiki/Wikipedia:Simple_talk][color=#0000ee]Simple talk[/color][/url][/ul][ul][url=/wiki/Special:RecentChanges][color=#0000ee]New changes[/color][/url][/ul][ul][url=/wiki/Special:Random][color=#0000ee]Show any page[/color][/url][/ul][ul][url=/wiki/Help:Contents][color=#0000ee]Help[/color][/url][/ul][ul][url=//simple.wikipedia.org/wiki/Wikipedia:Contact_us][color=#0000ee]Contact us[/color][/url][/ul][ul][url=/wiki/Wikipedia:About][color=#0000ee]About Wikipedia[/color][/url][/ul][ul][url=/wiki/Special:SpecialPages][color=#0000ee]Special pages[/color][/url][/ul]  [/p] [/p] [/p] [/p] [/p] [/p]  [url=/wiki/Main_Page][color=#0000ee] [url=/static/images/icons/wikipedia.png][color=ee9700][Image][/color][/url]  [url=/static/images/mobile/copyright/wikipedia-wordmark-en.svg][color=ee9700][Wikipedia][/color][/url] [url=/static/images/mobile/copyright/wikipedia-tagline-simple.svg][color=ee9700][The Free Encyclopedia][/color][/url]  [/color][/url] [/p] [p] [p] [url=/wiki/Special:Search][color=#0000ee] Search [/color][/url] [p] [p]  [p] [p]   [/p]  [/p] Search  [/p] [/p] [/p]  [p] [p] [p]   [/p] [/p] [p] [p]   [/p] [/p]  [p]   Appearance  [p] [p] [/p] [/p] [/p]  [p] [p]   [/p] [/p] [p] [p]  [ul][url=https://donate.wikimedia.org/?wmf_source=donate&wmf_medium=sidebar&wmf_campaign=simple.wikipedia.org&uselang=en][color=#0000ee]Give to Wikipedia[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:CreateAccount&returnto=Main+Page][color=#0000ee]Create account[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:UserLogin&returnto=Main+Page][color=#0000ee]Log in[/color][/url] [/ul]  [/p] [/p] [/p] [p]   Personal tools  [p] [p] [p]  [ul][url=https://donate.wikimedia.org/?wmf_source=donate&wmf_medium=sidebar&wmf_campaign=simple.wikipedia.org&uselang=en][color=#0000ee] Give to Wikipedia[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:CreateAccount&returnto=Main+Page][color=#0000ee] Create account[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:UserLogin&returnto=Main+Page][color=#0000ee] Log in[/color][/url] [/ul]  [/p] [/p] [/p] [/p]  [/p] [/p] [/p] [p] [p] [p] [p][/p] [/p] [p] [p] [p]  [p] [/p]  [/p] [/p] [/p] [p]  [p] [p][font_size=32.0][b]Main Page[/b][/font_size][/p] [p] [/p] [/p] [p] [p] [p]  [p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Main Page[/color][/url] [/ul] [ul][url=/wiki/Talk:Main_Page][color=#0000ee]Talk[/color][/url] [/ul]  [/p] [/p] [p]  English  [p] [p] [p]   [/p] [/p] [/p] [/p]  [/p] [p]  [p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Read[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=edit][color=#0000ee]View source[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=history][color=#0000ee]View history[/color][/url] [/ul]  [/p] [/p]   [p]   Tools  [p] [p] [p] [p] [p]Tools[/p] move to sidebar hide [/p] [p] [p] Actions [/p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee] Read[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=edit][color=#0000ee] View source[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=history][color=#0000ee] View history[/color][/url] [/ul]  [/p] [/p] [p] [p] General [/p] [p]  [ul][url=/wiki/Special:WhatLinksHere/Main_Page][color=#0000ee]What links here[/color][/url][/ul][ul][url=/wiki/Special:RecentChangesLinked/Main_Page][color=#0000ee]Related changes[/color][/url][/ul][ul][url=//commons.wikimedia.org/wiki/Special:UploadWizard][color=#0000ee]Upload file[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&oldid=10710583][color=#0000ee]Permanent link[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&action=info][color=#0000ee]Page information[/color][/url][/ul][ul][url=/w/index.php?title=Special:CiteThisPage&page=Main_Page&id=10710583&wpFormIdentifier=titleform][color=#0000ee]Cite this page[/color][/url][/ul][ul][url=/w/index.php?title=Special:UrlShortener&url=https%3A%2F%2Fsimple.wikipedia.org%2Fwiki%2FMain_Page][color=#0000ee]Get shortened URL[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&useparsoid=0][color=#0000ee]Switch to legacy parser[/color][/url][/ul]  [/p] [/p] [p] [p] Print/export [/p] [p]  [ul][url=/w/index.php?title=Special:Book&bookcmd=book_creator&referer=Main+Page][color=#0000ee]Make a book[/color][/url][/ul][ul][url=/w/index.php?title=Special:DownloadAsPdf&page=Main_Page&action=show-download-screen][color=#0000ee]Download as PDF[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&printable=yes][color=#0000ee]Page for printing[/color][/url][/ul]  [/p] [/p] [p] [p] In other projects [/p] [p]  [ul][url=https://abstract.wikipedia.org/wiki/Abstract_Wikipedia:Main_page][color=#0000ee]Abstract Wikipedia[/color][/url][/ul][ul][url=https://commons.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikimedia Commons[/color][/url][/ul][ul][url=https://foundation.wikimedia.org/wiki/Home][color=#0000ee]Wikimedia Foundation Governance Wiki[/color][/url][/ul][ul][url=https://www.mediawiki.org/wiki/MediaWiki][color=#0000ee]MediaWiki[/color][/url][/ul][ul][url=https://meta.wikimedia.org/wiki/Main_Page][color=#0000ee]Meta-Wiki[/color][/url][/ul][ul][url=https://outreach.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikimedia Outreach[/color][/url][/ul][ul][url=https://wikisource.org/wiki/Wikisource:Main_Page][color=#0000ee]Multilingual Wikisource[/color][/url][/ul][ul][url=https://species.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikispecies[/color][/url][/ul][ul][url=https://www.wikidata.org/wiki/Wikidata:Main_Page][color=#0000ee]Wikidata[/color][/url][/ul][ul][url=https://www.wikifunctions.org/wiki/Wikifunctions:Main_Page][color=#0000ee]Wikifunctions[/color][/url][/ul][ul][url=https://wikimania.wikimedia.org/wiki/Wikimania][color=#0000ee]Wikimania[/color][/url][/ul][ul][url=https://simple.wiktionary.org/wiki/Main_Page][color=#0000ee]Wiktionary[/color][/url][/ul][ul][url=https://www.wikidata.org/wiki/Special:EntityPage/Q5296][color=#0000ee]Wikidata item[/color][/url][/ul]  [/p] [/p] [/p] [/p] [/p] [/p]  [/p] [/p] [/p] [p] [p]  [p] [/p]   [p] [p] [p] [p]Appearance[/p] move to sidebar hide [/p] [/p] [/p]  [/p] [/p] [p] [p] [p]From Simple English Wikipedia, the free encyclopedia[/p] [/p] [p][p][/p][/p]",
		""
	)
	text = text.replace(
		" [p][/p][url=#bodyContent][color=#0000ee]Jump to content[/color][/url] [p] [p] [p]  [p]   Main menu  [p] [p] [p] [p] [p]Main menu[/p] move to sidebar hide [/p] [p] [p] Navigation [/p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Main page[/color][/url][/ul][ul][url=/wiki/Wikipedia:Contents][color=#0000ee]Contents[/color][/url][/ul][ul][url=/wiki/Portal:Current_events][color=#0000ee]Current events[/color][/url][/ul][ul][url=/wiki/Special:Random][color=#0000ee]Random article[/color][/url][/ul][ul][url=/wiki/Wikipedia:About][color=#0000ee]About Wikipedia[/color][/url][/ul][ul][url=//en.wikipedia.org/wiki/Wikipedia:Contact_us][color=#0000ee]Contact us[/color][/url][/ul]  [/p] [/p] [p] [p] Contribute [/p] [p]  [ul][url=/wiki/Help:Contents][color=#0000ee]Help[/color][/url][/ul][ul][url=/wiki/Help:Introduction][color=#0000ee]Learn to edit[/color][/url][/ul][ul][url=/wiki/Wikipedia:Community_portal][color=#0000ee]Community portal[/color][/url][/ul][ul][url=/wiki/Special:RecentChanges][color=#0000ee]Recent changes[/color][/url][/ul][ul][url=/wiki/Wikipedia:File_upload_wizard][color=#0000ee]Upload file[/color][/url][/ul][ul][url=/wiki/Special:SpecialPages][color=#0000ee]Special pages[/color][/url][/ul]  [/p] [/p] [/p] [/p] [/p] [/p]  [url=/wiki/Main_Page][color=#0000ee] [url=/static/images/icons/enwiki-25.svg][color=ee9700][Image][/color][/url]  [url=/static/images/mobile/copyright/wikipedia-wordmark-en-25.svg][color=ee9700][Wikipedia][/color][/url] [url=/static/images/mobile/copyright/wikipedia-tagline-en-25.svg][color=ee9700][The Free Encyclopedia][/color][/url]  [/color][/url] [/p] [p] [p] [url=/wiki/Special:Search][color=#0000ee] Search [/color][/url] [p] [p]  [p] [p]   [/p]  [/p] Search  [/p] [/p] [/p]  [p] [p] [p]   [/p] [/p] [p] [p]   [/p] [/p]  [p]   Appearance  [p] [p] [/p] [/p] [/p]  [p] [p]   [/p] [/p] [p] [p]  [ul][url=https://donate.wikimedia.org/?wmf_source=donate&wmf_medium=sidebar&wmf_campaign=en.wikipedia.org&uselang=en][color=#0000ee]Donate[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:CreateAccount&returnto=Main+Page][color=#0000ee]Create account[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:UserLogin&returnto=Main+Page][color=#0000ee]Log in[/color][/url] [/ul]  [/p] [/p] [/p] [p]   Personal tools  [p] [p] [p]  [ul][url=https://donate.wikimedia.org/?wmf_source=donate&wmf_medium=sidebar&wmf_campaign=en.wikipedia.org&uselang=en][color=#0000ee] Donate[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:CreateAccount&returnto=Main+Page][color=#0000ee] Create account[/color][/url] [/ul] [ul][url=/w/index.php?title=Special:UserLogin&returnto=Main+Page][color=#0000ee] Log in[/color][/url] [/ul]  [/p] [/p] [/p] [/p]  [/p] [/p] [/p] [p] [p] [p] [p][/p] [/p] [p] [p] [p]  [p] [/p]  [/p] [/p] [/p] [p]  [p] [p][font_size=32.0][b]Main Page[/b][/font_size][/p] [p] [/p] [/p] [p] [p] [p]  [p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Main Page[/color][/url] [/ul] [ul][url=/wiki/Talk:Main_Page][color=#0000ee]Talk[/color][/url] [/ul]  [/p] [/p] [p]  English  [p] [p] [p]   [/p] [/p] [/p] [/p]  [/p] [p]  [p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee]Read[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=edit][color=#0000ee]View source[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=history][color=#0000ee]View history[/color][/url] [/ul]  [/p] [/p]   [p]   Tools  [p] [p] [p] [p] [p]Tools[/p] move to sidebar hide [/p] [p] [p] Actions [/p] [p]  [ul][url=/wiki/Main_Page][color=#0000ee] Read[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=edit][color=#0000ee] View source[/color][/url] [/ul] [ul][url=/w/index.php?title=Main_Page&action=history][color=#0000ee] View history[/color][/url] [/ul]  [/p] [/p] [p] [p] General [/p] [p]  [ul][url=/wiki/Special:WhatLinksHere/Main_Page][color=#0000ee]What links here[/color][/url][/ul][ul][url=/wiki/Special:RecentChangesLinked/Main_Page][color=#0000ee]Related changes[/color][/url][/ul][ul][url=//en.wikipedia.org/wiki/Wikipedia:File_Upload_Wizard][color=#0000ee]Upload file[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&oldid=1358980925][color=#0000ee]Permanent link[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&action=info][color=#0000ee]Page information[/color][/url][/ul][ul][url=/w/index.php?title=Special:CiteThisPage&page=Main_Page&id=1358980925&wpFormIdentifier=titleform][color=#0000ee]Cite this page[/color][/url][/ul][ul][url=/w/index.php?title=Special:UrlShortener&url=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FMain_Page][color=#0000ee]Get shortened URL[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&useparsoid=0][color=#0000ee]Switch to legacy parser[/color][/url][/ul]  [/p] [/p] [p] [p] Print/export [/p] [p]  [ul][url=/w/index.php?title=Special:DownloadAsPdf&page=Main_Page&action=show-download-screen][color=#0000ee]Download as PDF[/color][/url][/ul][ul][url=/w/index.php?title=Main_Page&printable=yes][color=#0000ee]Printable version[/color][/url][/ul]  [/p] [/p] [p] [p] In other projects [/p] [p]  [ul][url=https://abstract.wikipedia.org/wiki/Abstract_Wikipedia:Main_page][color=#0000ee]Abstract Wikipedia[/color][/url][/ul][ul][url=https://commons.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikimedia Commons[/color][/url][/ul][ul][url=https://foundation.wikimedia.org/wiki/Home][color=#0000ee]Wikimedia Foundation[/color][/url][/ul][ul][url=https://www.mediawiki.org/wiki/MediaWiki][color=#0000ee]MediaWiki[/color][/url][/ul][ul][url=https://meta.wikimedia.org/wiki/Main_Page][color=#0000ee]Meta-Wiki[/color][/url][/ul][ul][url=https://outreach.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikimedia Outreach[/color][/url][/ul][ul][url=https://wikisource.org/wiki/Wikisource:Main_Page][color=#0000ee]Multilingual Wikisource[/color][/url][/ul][ul][url=https://species.wikimedia.org/wiki/Main_Page][color=#0000ee]Wikispecies[/color][/url][/ul][ul][url=https://en.wikibooks.org/wiki/Main_Page][color=#0000ee]Wikibooks[/color][/url][/ul][ul][url=https://www.wikidata.org/wiki/Wikidata:Main_Page][color=#0000ee]Wikidata[/color][/url][/ul][ul][url=https://www.wikifunctions.org/wiki/Wikifunctions:Main_Page][color=#0000ee]Wikifunctions[/color][/url][/ul][ul][url=https://wikimania.wikimedia.org/wiki/Wikimania][color=#0000ee]Wikimania[/color][/url][/ul][ul][url=https://en.wikinews.org/wiki/Main_Page][color=#0000ee]Wikinews[/color][/url][/ul][ul][url=https://en.wikiquote.org/wiki/Main_Page][color=#0000ee]Wikiquote[/color][/url][/ul][ul][url=https://en.wikisource.org/wiki/Main_Page][color=#0000ee]Wikisource[/color][/url][/ul][ul][url=https://en.wikiversity.org/wiki/Wikiversity:Main_Page][color=#0000ee]Wikiversity[/color][/url][/ul][ul][url=https://en.wikivoyage.org/wiki/Main_Page][color=#0000ee]Wikivoyage[/color][/url][/ul][ul][url=https://en.wiktionary.org/wiki/Wiktionary:Main_Page][color=#0000ee]Wiktionary[/color][/url][/ul][ul][url=https://www.wikidata.org/wiki/Special:EntityPage/Q5296][color=#0000ee]Wikidata item[/color][/url][/ul]  [/p] [/p] [/p] [/p] [/p] [/p]  [/p] [/p] [/p] [p] [p]  [p] [/p]   [p] [p] [p] [p]Appearance[/p] move to sidebar hide [/p] [/p] [/p]  [/p] [/p] [p] [p] [p]From Wikipedia, the free encyclopedia[/p] [p][p][/p][/p] [/p] [p][p]",
		""
	)
	
	# hacker news
	text = text.replace(
		"[url=https://news.ycombinator.com][color=#0000ee][/color][/url] [b][url=news][color=#0000ee]Hacker News[/color][/url][/b][url=newest][color=#0000ee]new[/color][/url] | [url=front][color=#0000ee]past[/color][/url] | [url=newcomments][color=#0000ee]comments[/color][/url] | [url=ask][color=#0000ee]ask[/color][/url] | [url=show][color=#0000ee]show[/color][/url] | [url=jobs][color=#0000ee]jobs[/color][/url]",
		"[url=https://news.ycombinator.com][color=#0000ee][/color][/url] [b][url=news][color=#0000ee]Hacker News[/color][/url]  [/b][url=newest][color=#0000ee]new[/color][/url] | [url=front][color=#0000ee]past[/color][/url] | [url=newcomments][color=#0000ee]comments[/color][/url] | [url=ask][color=#0000ee]ask[/color][/url] | [url=show][color=#0000ee]show[/color][/url] | [url=jobs][color=#0000ee]jobs[/color][/url]"
	)
	return text
