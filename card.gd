@tool
extends Node2D

var frame : TextureRect
var title : Label
var desc : RichTextLabel

@export var data : CardData

# Called when the node enters the scene tree for the first time.
func _ready():
	frame = $Frame
	title = $Frame/Title
	desc = $Frame/Description


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Engine.is_editor_hint():
		return
	if not title:
		_ready()
	if data:
		SetData(data)

func SetData(cardData : CardData):
	if cardData.customFrame:
		frame.texture = cardData.customFrame
	title.text = cardData.title
	desc.text = "[center]" + cardData.description
