extends Node2D

var p1Deck : Array[int]
var p1Hand : Array[int]
var p1Discard : Array[int]

var p2Deck : Array[int]
var p2Hand : Array[int]
var p2Discard : Array[int]

var specialPile : Array[int]

func pile(index):
	match pile:
		0: return p1Hand
		1: return p2Hand
		2: return p1Deck
		3: return p2Deck
		4: return p1Discard
		5: return p2Discard
		6: return specialPile
		_: printerr("Tried to access invalid pile. Index ", index)


@export var cards : Array[CardData]

var activeCard : int
var activePlayer : int
var cardStep : int
var currentAction : int
enum Actions {WaitForAnim = 0, SelectP1Hand = 1, SelectP2Hand = 2, SelectP1Deck = 4, SelectP2Deck = 8, SelectP1Discard = 16, SelectP2Discard = 32, SelectSpecial = 64}

# Called when the node enters the scene tree for the first time.
func _ready():
	p1Deck = []
	p1Hand = []
	p1Discard = []
	p2Deck = []
	p2Hand = []
	p2Discard = []

	for i in range(30):
		p1Deck.append(i)
		p2Deck.append(i)

	for i in range(30, 36):
		if p1Deck.size() == 33:
			p2Deck.append(i)
		elif p2Deck.size() == 33:
			p1Deck.append(i)
		elif randi_range(0, 1) == 0:
			p1Deck.append(i)
		else:
			p2Deck.append(i)
	Shuffle(p1Deck)
	Shuffle(p2Deck)
	P1Draw(6)
	P2Draw(6)

	activePlayer = 1
	activeCard = -1

	pass # Replace with function body.

func ProcessCard(selectedCard = null):
	match activeCard:
		0:
			pass
		1:
			pass
		2:
			pass
		3:
			pass
		4:
			pass
		5:
			pass
		6:
			pass
		7:
			pass
		8:
			pass
		9:
			pass
		10:
			pass
		11:
			pass
		12:
			pass
		13:
			pass
		14:
			pass
		15:
			pass
		16:
			pass
		17:
			pass
		18:
			pass
		19:
			pass
		20:
			pass
		21:
			pass
		22:
			pass
		23:
			pass
		24:
			pass
		25:
			pass
		26:
			pass
		27:
			pass
		28:
			pass
		29:
			pass
		30:
			pass
		31:
			pass
		32:
			pass
		33:
			pass
		34:
			pass
		35:
			pass

func Shuffle(arr : Array[int]):
	var elements := arr.duplicate()
	arr.clear()
	while elements.size() > 0:
		var index = randi_range(0, elements.size() - 1)
		arr.append(elements[index])
		elements.remove_at(index)

func P1Draw(num = 1, toHand = true):
	var cards = []

	for i in range(num):
		if(p1Deck.size() == 0):
			p1Deck = p1Discard.duplicate()
			p1Discard.clear()
			Shuffle(p1Deck)
		
		if(p1Deck.size() == 0): #if both the draw and discard piles were empty
			cards.append_array(P2Draw(num-i, false))
			return cards
		cards.append(p1Deck[0])
		p1Deck.remove_at(0)
	
	if toHand:
		p1Hand.append_array(cards)
	return cards

func P2Draw(num = 1, toHand = true):
	var cards = []

	for i in range(num):
		if(p2Deck.size() == 0):
			p2Deck = p2Discard.duplicate()
			p2Discard.clear()
			Shuffle(p2Deck)

		if(p2Deck.size() == 0): #if both the draw and discard piles were empty
			if p1Deck.size() == 0 and p1Discard.size() == 0: #prevent infinite loop
				printerr("All cards disappeared???")
				return cards
			cards.append_array(P1Draw(num-i, false))
			return cards
		
		cards.append(p2Deck[0])
		p2Deck.remove_at(0)
	
	if toHand:
		p2Hand.append_array(cards)
	return cards
