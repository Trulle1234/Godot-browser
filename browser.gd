extends Node

const ToBbCode = preload("uid://duach83yc561m")

@onready var document: RichTextLabel = $Document

var current_url = ""
var last_url = ""

# send a http request on ready
func _ready():
	send_http_request("https://wikipedia.org/")

# request the html from a website
func send_http_request(url):
	current_url = url
	
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_request_completed)
	var error = http.request(url)

	if error != OK:
		document.text = "[wave][font_size=24][b]This address is not valid :( [/b][/font_size][/wave]"

# when compleated, show it
func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		document.text = "[wave][font_size=24][b]Could not connect to the website :( [/b][/font_size][/wave]"
		return
		
	if response_code != 200:
		var error_cat = await load_error_cat(response_code)
		
		if error_cat:
			document.clear()
			document.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
			document.add_image(error_cat, 0, 0, Color.WHITE, INLINE_ALIGNMENT_CENTER, Rect2(), "error_cat", false, "")
		else:
			document.text = "[wave][font_size=24][b]HTTP error " + str(response_code) + " :( [/b][/font_size][/wave]"
		return

	var html = (body.get_string_from_utf8())
	var in_bbcode = ToBbCode.to_bbcode(html, document)["text"]
	
	document.text = in_bbcode

# go to clicked link
func _on_document_meta_clicked(meta):
	var url = resolve_url(str(meta), current_url)
	send_http_request(url)

# show tooltip
func _on_document_meta_hover_started(meta):
	document.tooltip_text = str(meta)

# hide tooltip
func _on_document_meta_hover_ended():
	document.tooltip_text = ""

func resolve_url(url, current_url):
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
	var http = HTTPRequest.new()
	add_child(http)

	var error = http.request("https://http.cat/" + str(code) + ".jpg")
	
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
	error = image.load_jpg_from_buffer(body)

	if error != OK:
		return null

	# return the img
	return ImageTexture.create_from_image(image)
