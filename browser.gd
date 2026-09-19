extends Node2D

const ToBbCode = preload("uid://duach83yc561m")

@onready var document: RichTextLabel = $Document
@onready var url_bar: LineEdit = $URLBar
@onready var page_title: Label = $PageTitle

var current_url = ""
var last_url = ""

var hovered_meta = ""

# handle input
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		var url_bar_text = url_bar.text.strip_escapes()
		
		if url_bar_text.begins_with("http"):
			send_http_request(url_bar_text)
		else:
			send_http_request("https://html.duckduckgo.com/html/?q=" + url_bar_text)
	
	if Input.is_action_just_pressed("back"):
		send_http_request(last_url)

# request the html from a website
func send_http_request(url):
	url = unwrap_duckduckgo_url(url)
	last_url = current_url
	
	current_url = url
	url_bar.text = current_url
	url_bar.release_focus()
	
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_request_completed)
	var error = http.request(url)

	if error != OK:
		document.clear()
		document.append_text("[br][wave][font_size=24][b]This address is not valid :( [/b][/font_size][/wave]")
		page_title.text = "Adress not valid"

# when compleated, show it
func _on_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		document.clear()
		document.append_text("[br][wave][font_size=24][b]Could not connect to the website :( [/b][/font_size][/wave]")
		page_title.text = "Could not connect"
		return
		
	if response_code != 200:
		var error_cat = await load_error_cat(response_code)
		
		if error_cat:
			document.clear()
			document.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
			document.add_image(error_cat, 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), "error_cat", false, "")
		else:
			document.clear()
			document.append_text("[br][wave][font_size=24][b]HTTP error " + str(response_code) + " :( [/b][/font_size][/wave]")
		
		page_title.text = "HTTP error " + str(response_code)
		return

	var html = (body.get_string_from_utf8())
	var bbcode_result = ToBbCode.to_bbcode(html, document)
	
	document.clear()
	document.append_text(bbcode_result["text"])
	
	if bbcode_result["title"]:
		page_title.text = bbcode_result["title"]
	else:
		page_title.text = "Untitled"
	
	await document.finished
	document.scroll_to_line(0)

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

# go to clicked link
func _on_document_meta_clicked(meta):
	var url = resolve_url(str(meta))
	send_http_request(url)

# show tooltip
func _on_document_meta_hover_started(meta):
	hovered_meta = str(meta)
	document.tooltip_text = hovered_meta

# hide tooltip
func _on_document_meta_hover_ended(_meta):
	hovered_meta = ""
	document.tooltip_text = ""

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

# get http error cat
func load_error_cat(code):
	return await get_img("https://http.cat/" + str(code) + ".jpg")

func get_img(url):
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

	var img_error = image.load_jpg_from_buffer(body)

	if img_error != OK:
		return null

	# return the img
	return ImageTexture.create_from_image(image)
