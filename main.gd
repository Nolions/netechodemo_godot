extends Node

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var line_edit: LineEdit = $CenterContainer/VBoxContainer/LineEdit
@onready var label: Label =  $CenterContainer/VBoxContainer/Label

var ws := WebSocketPeer.new()


func _ready():
	http_request.request_completed.connect(_on_request_completed)
	var err = ws.connect_to_url("wss://ws.postman-echo.com/raw")
	if err != OK:
		print("❌ 無法連線: ", err)
		
func _process(_delta):
	# 你需要持續呼叫 poll 才能收發訊息
	ws.poll()
	
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count() > 0:
		var packet = ws.get_packet()
		var msg = packet.get_string_from_utf8()
		print("📨 收到訊息: ", msg)

func _on_htt_button_pressed():
	print("_on_htt_button_pressed")
	
	var message = line_edit.text.strip_edges()
	if message.is_empty():
		label.text = "❗請輸入訊息"
		return

	# 建立 JSON 資料
	var payload = {
		"message": message
	}
	var json_body = JSON.stringify(payload)

	ws.send_text(json_body)

	# 設定 headers
	var headers = [
		"Content-Type: application/json"
	]

	var url = "https://postman-echo.com/post"
	var result = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if result != OK:
		label.text = "❌ 發送失敗，錯誤代碼: %s" % result
	else:
		label.text = "📤 正在送出請求..."

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()

	if json.parse(response_text) == OK:
		var server_data = json.data
		var echoed_message = server_data.get("json", {}).get("message", "（沒有回傳 message）")
		label.text = "✅ 回應: %s" % echoed_message
	else:
		label.text = "⚠️ 回應解析失敗"
