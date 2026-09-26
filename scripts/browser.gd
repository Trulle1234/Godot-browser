extends Node2D

const ToBbCode = preload("uid://duach83yc561m")

const GLOBE = preload("uid://bdtmxuok1p04h")
const SMALL_LOGO = preload("uid://bkyqcrhwvcuc0")

const font_themes = [
	preload("uid://dj7v6k65e8dsi"),
	preload("uid://1qt30pm2eowt"),
	preload("uid://dslkkbml86nd6"),
	preload("uid://v4g80iqeg3p4"),
	preload("uid://bhwyidk3dq8a3")
]
var font_index = 0

@onready var document: RichTextLabel = $Document
@onready var url_bar: LineEdit = $URLBar
@onready var favicon: TextureRect = $Favicon
@onready var page_title: Label = $PageTitle
@onready var reload_button: Button = $ReloadButton
@onready var spinner: TextureProgressBar = $Spinner
@onready var inverted: ColorRect = $Inverted
@onready var home_update_timer: Timer = $HomeUpdateTimer

signal set_home

var current_url = "about:home"

var history = ["about:home"]
var history_index = 0

var hovered_meta = ""

func _ready() -> void:
	var doc_builtin_menu = document.get_menu()
	var bar_builtin_menu = url_bar.get_menu()
	
	bar_builtin_menu.prefer_native_menu = true
	doc_builtin_menu.prefer_native_menu = true
	
	load_history_url(current_url)

# handle input
func _process(_delta) -> void:
	if Input.is_action_just_pressed("enter") and url_bar.has_focus():
		var url_bar_text = url_bar.text.strip_edges()
		var normalized_url = normazlie_url(url_bar_text)
		
		if url_bar_text == "" or url_bar_text == "about:blank":
			to_about_blank()
		elif url_bar_text == "about:home":
			to_home()
		elif normalized_url:
			send_http_request(normalized_url)
		else:
			send_http_request(
				"https://html.duckduckgo.com/html/?q=" +
				url_bar.text.strip_edges().replace(" ", "%20")
			)
	
	elif Input.is_action_just_pressed("back"):
		go_back()
		
	elif Input.is_action_just_pressed("forward"):
		go_forward()
	
	elif Input.is_action_just_pressed("refresh"):
		load_history_url(current_url)
	
	elif Input.is_action_just_pressed("home"):
		to_home()

# keep track of history
func add_to_history(url):
	if history_index < history.size() - 1:
		history.resize(history_index + 1)
	
	if history.is_empty() or history.back() != url:
		history.append(url)
		history_index = history.size() - 1

# load url from history
func load_history_url(url):
	if url == "" or url == "about:blank":
		to_about_blank(false)
	elif url == "about:home":
		to_home(false)
	else:
		send_http_request(url, false)

# request the html from a website
func send_http_request(url, add_history=true):
	reload_button.hide()
	spinner.show()
	url = unwrap_duckduckgo_url(url)
	url = fix_wikipedia_url(url)
	
	if add_history:
		add_to_history(url)
	
	current_url = url
	url_bar.text = current_url
	url_bar.release_focus()
	
	if is_image_url(url):
		load_image(url)
		
		reload_button.show()
		spinner.hide()
		return
	
	var http = HTTPRequest.new()
	http.timeout = 15
	
	add_child(http)

	http.request_completed.connect(_on_request_completed.bind(http))
	var error = http.request(url)

	if error != OK:
		document.clear()
		document.append_text("[br][wave][font_size=24][b]This address is not valid :( [/b][/font_size][/wave]")
		page_title.text = "Adress not valid"
		favicon.texture = GLOBE
		
		reload_button.show()
		spinner.hide()

# when compleated, show it
func _on_request_completed(result, response_code, headers, body, http):
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS:
		document.clear()
		document.append_text("[br][wave][font_size=24][b]Could not connect to the website :( [/b][/font_size][/wave]")
		page_title.text = "Could not connect"
		favicon.texture = GLOBE
		
		reload_button.show()
		spinner.hide()
		return
		
	if response_code < 200 or response_code >= 300:
		var error_cat = await load_error_cat(response_code)
		
		if error_cat:
			document.clear()
			document.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
			document.add_image(error_cat, 0, 625, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), "error_cat", false, "")
		else:
			document.clear()
			document.append_text("[br][wave][font_size=24][b]HTTP error " + str(response_code) + " :( [/b][/font_size][/wave]")
		
		page_title.text = "HTTP error " + str(response_code)
		favicon.texture = GLOBE
		
		reload_button.show()
		spinner.hide()
		return
	
	# get content type
	var content_type
	var charset
	
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.substr("content-type:".length()).strip_edges()
	
	var charset_regex = RegEx.create_from_string("(?i)charset\\s*=\\s*[\"']?([^;\"'\\s]+)")
	var charset_match = charset_regex.search(content_type)
	
	if charset_match:
		charset = charset_match.get_string(1).to_lower()
	
	var html = ""
	match charset:
		"utf-8", "utf8", "":
			html = body.get_string_from_utf8()
			
		"iso-8859-1", "latin1", "latin-1":
			for byte in body:
				html += String.chr(byte)
			
		"us-ascii", "ascii":
			html = body.get_string_from_ascii()
			
		_:
			print("unsupported charset: ", charset)
			html = body.get_string_from_utf8()
			
	var bbcode_result
	bbcode_result = ToBbCode.to_bbcode(html, document)
	
	document.clear()
	document.append_text(bbcode_result["text"])

	if bbcode_result["title"]:
		page_title.text = bbcode_result["title"]
	
	await document.finished
	document.scroll_to_line(0)
	
	if bbcode_result["favicon"]:
		call_deferred("load_favicon", resolve_url(bbcode_result["favicon"]))
	else:
		var favicon_link_regex = RegEx.create_from_string("^(https?://[^/]+)")
		var match = favicon_link_regex.search(current_url)
		
		if match:
			call_deferred("load_favicon", match.get_string(1) + "/favicon.ico")
		else:
			favicon.texture = GLOBE
	
	reload_button.show()
	spinner.hide()

# sovle duckduckgo redicrects
func unwrap_duckduckgo_url(url):
	# only hadle duckduckgo redidrects
	if not url.begins_with("https://duckduckgo.com/l/"):
		return url
		
	var query_start = url.find("?")
	if query_start == -1:
		return url
		
	var query = url.substr(query_start + 1)
	
	for part in query.split("&"):
		var pair = part.split("=", true, 1)
	
		if pair.size() == 2 and pair[0] == "uddg":
			return pair[1].uri_decode() 
	
	return url

func fix_wikipedia_url(url):
	var link_regex = RegEx.create_from_string(r"^https://([a-z-]+)\.wikipedia\.org/wiki/([^?#]+)")
	var link_match = link_regex.search(url)
	
	var img_regex = RegEx.create_from_string(r"^https://thumb\.wikimedia\.org/wikipedia/([a-z-]+)/thumb/(.+)/[^/]+$")
	var img_match = img_regex.search(url)
	
	if link_match:
		var lang = link_match.get_string(1)
		var page_name = link_match.get_string(2)
	
		return "https://"+ lang + ".wikipedia.org/w/index.php?title=" + page_name + "&useparsoid=0"
	if img_match:
		var wiki_part = img_match.get_string(1)
		var image_path = img_match.get_string(2)
	
		return "https://upload.wikimedia.org/wikipedia/" + wiki_part + "/" + image_path
		
	else:
		return url

# go to homepage
func to_home(add_history=true, clear_url_bar=true):
	if add_history:
		add_to_history("about:home")
	
	current_url = "about:home"
	if clear_url_bar:
		url_bar.text = ""
	
	set_home.emit()
	
	page_title.text = "Godot browser - home"
	favicon.texture = SMALL_LOGO

# go to about:blank
func to_about_blank(add_history=true):
	if add_history:
		add_to_history("about:blank")
		
	current_url = "about:blank"
		
	document.clear()
	page_title.text = "about:blank"
	favicon.texture = GLOBE
	url_bar.text = ""
	return

# go back in history
func go_back():
	if history_index <= 0:
		return

	history_index -= 1
	load_history_url(history[history_index])

# go forwasrd in history
func go_forward():
	if history_index >= history.size() - 1:
		return

	history_index += 1
	load_history_url(history[history_index])

# go to clicked link
func _on_document_meta_clicked(meta):
	var url = resolve_url(str(meta))
	send_http_request(url)

# show tooltip
func _on_document_meta_hover_started(meta):
	hovered_meta = unwrap_duckduckgo_url(resolve_url(str(meta)))
	hovered_meta = fix_wikipedia_url(hovered_meta)
	document.tooltip_text = hovered_meta

# hide tooltip
func _on_document_meta_hover_ended(_meta):
	hovered_meta = ""
	document.tooltip_text = ""

# urls work without https://
func normazlie_url(url):
	if url.begins_with("http://") or url.begins_with("https://"):
		return url
	
	var regex = RegEx.create_from_string("^(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}(?::\\d+)?(?:/.*)?$")
	if regex.search(url) != null:
		return "https://" + url
	
	return ""

func resolve_url(url):
	# in-page link, does not acctualy work
	if url.begins_with("#"):
		return current_url.split("#")[0] + url
	
	# already absolute
	if url.begins_with("http://") or url.begins_with("https://"):
		return url

	# protocol-relative
	if url.begins_with("//"):
		var scheme = current_url.get_slice(":", 0)
		return scheme + ":" + url

	# get scheme and host
	var regex = RegEx.create_from_string("^(https?://[^/]+)")
	var match = regex.search(current_url)

	if not match:
		return url

	var origin = match.get_string(1)

	# root-relative
	if url.begins_with("/"):
		return origin + url

	# directory-relative
	var base = current_url.split("?")[0].split("#")[0]
	var slash = base.rfind("/")

	if slash != -1:
		base = base.substr(0, slash + 1)

	return base + url

# load page favicon
func load_favicon(url):
	var page_favicon = await get_img(url)
	
	if page_favicon:
		favicon.texture = page_favicon
	else:
		favicon.texture = GLOBE

# get http error cat
func load_error_cat(code):
	return await get_img("https://http.cat/" + str(code) + ".jpg")

func load_image(url):
	var img = await get_img(url)
	
	var size = Vector2(img.get_width(), img.get_height())
	
	var display_size = size * min(1270 / size.x, 625 / size.y, 1.0)
	
	page_title.text = "Image - " + url
	document.clear()
	document.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	document.append_text("[br][br]")
	document.add_image(img, int(display_size.x), int(display_size.y), Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), "Image", false, "")

func is_image_url(url: String) -> bool:
	var clean_url = url
	
	return ( 
		clean_url.contains(".png")
		or clean_url.contains(".jpg")
		or clean_url.contains(".jpeg")
		or clean_url.contains(".webp")
		or clean_url.contains(".svg")
		or clean_url.contains(".ico")
	)

func get_img(url):
	if url.contains("data:"):
		return null
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var error = http.request(url)
	
	# check for errors
	if error != OK:
		http.queue_free()
		return null
	
	var result_data = await http.request_completed
	http.queue_free()
	
	var result = result_data[0]
	var response_code = result_data[1]
	var body = result_data[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		return null
	
	if response_code < 200 or response_code >= 300:
		return null
		
	var image = Image.new()
	
	if url.to_lower().contains(".ico"):
		var ico_image = load_ico_from_buffer(body)
	
		if ico_image:
			return ImageTexture.create_from_image(ico_image)
	
		return null
	
	var img_error = image.load_svg_from_buffer(body, 2.0)
	
	if img_error != OK:
		img_error = image.load_png_from_buffer(body)
		
	if img_error != OK:
		img_error = image.load_jpg_from_buffer(body)
	
	if img_error != OK:
		img_error = image.load_webp_from_buffer(body)
	
	if img_error != OK:
		return null
	
	# return the img
	return ImageTexture.create_from_image(image)

# custom load from buffer, tries to find png data in ico file
func load_ico_from_buffer(body):
	# ico header
	if body.size() < 6:
		return null
	
	var reserved = body.decode_u16(0)
	var icon_type = body.decode_u16(2)
	var count = body.decode_u16(4)
	
	if reserved != 0 or icon_type != 1 or count == 0:
		return null
	
	var best_image = null
	var best_area = 0
	
	for i in range(count):
		var entry_offset = 6 + i * 16
		
		if body.size() < entry_offset + 16:
			continue
		
		var image_size = body.decode_u32(entry_offset + 8)
		var image_offset = body.decode_u32(entry_offset + 12)
		
		if image_offset + image_size > body.size():
			continue
		
		var image_data = body.slice(image_offset, image_offset + image_size)
		
		# only support png entries
		if image_data.size() < 8:
			continue
		
		if not (image_data[0] == 0x89 and image_data[1] == 0x50 and image_data[2] == 0x4e and image_data[3] == 0x47):
			continue
		
		var image = Image.new()
		
		if image.load_png_from_buffer(image_data) != OK:
			continue
		
		var area = image.get_width() * image.get_height()
		
		if area > best_area:
			best_area = area
			best_image = image
	
	return best_image

# swap fonts
func swap_font():
	font_index += 1
	font_index %= font_themes.size()
	document.theme = font_themes[font_index]

# go home on home button press
func _on_home_button_pressed() -> void:
	to_home()

func _on_reload_button_pressed() -> void:
	load_history_url(current_url)

func _on_inver_button_pressed() -> void:
	if inverted.visible:
		inverted.hide()
	else:
		inverted.show()

func _on_font_button_pressed() -> void:
	swap_font()

func _on_back_button_pressed() -> void:
	go_back()

func _on_forward_button_pressed() -> void:
	go_forward()

func _on_home_update_timer_timeout() -> void:
	if current_url == "about:home":
		to_home(true, false)
