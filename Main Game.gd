extends Node2D

var p1Deck : Array[int]
var p1Hand : Array[int]
var p1Discard : Array[int]

var p2Deck : Array[int]
var p2Hand : Array[int]
var p2Discard : Array[int]

var specialPile : Array[int]

func piles(index):
	match index:
		0: return p1Hand
		1: return p2Hand
		2: return p1Deck
		3: return p2Deck
		4: return p1Discard
		5: return p2Discard
		6: return specialPile
		_: printerr("Tried to access invalid piles. Index ", index)

@export var cards : Array[CardData]

var activeCard : int
var activePlayer : int
var inactivePlayer:
	get: return activePlayer ^ 1
var cardStep : int
var currentAction : int
var currentTurn : int
var currentEnergy : int
var multiSelectLimit : int
enum {WaitForAnim = 0, SelectP1Hand = 1, SelectP2Hand = 2, SelectP1Deck = 4, SelectP2Deck = 8, SelectP1Discard = 16, SelectP2Discard = 32, SelectSpecial = 64, MultiSelect = 128}
func select(index, multi = false):
	return (1 << index) + (MultiSelect if multi else 0)
enum {HAND = 0, DECK = 2, DISCARD = 4, SPECIAL = 6}

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
	p1Deck.shuffle()
	p2Deck.shuffle()
	P1Draw(6)
	P2Draw(6)

	activePlayer = 1
	activeCard = -1
	currentTurn = 0
	BeginNewTurn()
	currentAction = SelectP1Hand

func BeginNewTurn():
	activePlayer = inactivePlayer
	if(activePlayer == 0):
		currentTurn += 1
	currentEnergy = currentTurn

func UpdateCardDisplay():
	pass

func EndCardAction(discard := true):
	if discard:
		piles(DISCARD + activePlayer).append(activeCard)
	activeCard = -1
	if(p1Hand.size() < 6):
		P1Draw(6 - p1Hand.size())
	if(p2Hand.size() < 6):
		P2Draw(6 - p2Hand.size())
	if(currentEnergy <= 0):
		BeginNewTurn()
	currentAction = select(HAND + activePlayer)
	UpdateCardDisplay()

func ProcessCard(selectIndex): # selectIndex is an int for single selections, and an int array for multi-selections
	match activeCard:
		-1: # None
			var playerHand = piles(HAND + activePlayer)
			var cardID = playerHand[selectIndex]
			var cardData = cards[cardID]
			if(cardData.cost > currentEnergy):
				return
			
			playerHand.remove_at(selectIndex)
			activeCard = cardID
			cardStep = 0
			currentAction = WaitForAnim
			currentEnergy -= cardData.cost

		0: #One with Nothing
			piles(DISCARD + activePlayer).append_array(piles(HAND + activePlayer))
			piles(HAND + activePlayer).clear()
			EndCardAction()
		1: #Swap
			match cardStep:
				0:
					currentAction = select(HAND + inactivePlayer)
					cardStep = 1
				1:
					var swappedCard = piles(HAND + inactivePlayer)[selectIndex]
					piles(HAND+inactivePlayer).remove_at(selectIndex)
					
					piles(HAND+activePlayer).append(swappedCard)
					piles(HAND+inactivePlayer).append(activeCard)
					EndCardAction()
		2, 3: #Stash
			match cardStep:
				0:
					currentAction = select(HAND + activePlayer, true)
					multiSelectLimit = 0
					cardStep = 1
				1:
					specialPile.clear()
					for i in selectIndex:
						specialPile.append(piles(HAND+activePlayer)[i])
					for i in selectIndex: # only remove cards from hand after transferring ALL of them to the special pile
						piles(HAND+activePlayer).remove_at(i)
					currentAction = select(SPECIAL, true)
					# put up ui for inserting cards into deck
					cardStep = 2
				2:
					# specialPile contains all of the cards to be inserted, selectIndex contains the positions to insert them
					# cards later in the special pile can sometimes "push back" cards earlier in the pile; keep this in mind when constructing select indices
					for i in range(specialPile.size()):
						var pos = selectIndex[i]
						var card = specialPile[i]
						piles(DECK+activePlayer).insert(pos, card)
					EndCardAction()
		4: #Snoop
			match cardStep:
				0:
					currentAction = SelectP1Deck | SelectP2Deck | MultiSelect
					multiSelectLimit = 4
					cardStep = 1
				1:
					#reveal cards
					currentAction = WaitForAnim
					cardStep = 2
				2:
					EndCardAction()
		5: #Reset
			match cardStep:
				0:
					#Show "Choose Player" dialog
					currentAction = select(SPECIAL)
					cardStep = 1
				1:
					piles(DECK+selectIndex).append_array(piles(DISCARD+selectIndex))
					piles(DISCARD+selectIndex).clear()
					piles(DECK+selectIndex).shuffle()
					EndCardAction()

		6: #Sleight of Hand
			match cardStep:
				0:
					var deck = piles(DECK+inactivePlayer)
					specialPile.clear()
					specialPile.append_array(deck.slice(0,3))
					deck.assign(deck.slice(3))
					#Show "Insert into deck" dialog [identical to Stash]
					currentAction = select(SPECIAL, true)
					cardStep = 1
				1:
					for i in range(specialPile.size()):
						var pos = selectIndex[i]
						var card = specialPile[i]
						piles(DECK+inactivePlayer).insert(pos, card)
					EndCardAction()
					
		7, 8: #Trash Bandit
			match cardStep:
				0:
					currentAction = SelectP1Discard | SelectP2Discard
					cardStep = 1
				1:
					if selectIndex < p1Discard.size():
						piles(HAND+activePlayer).append(p1Discard[selectIndex])
						p1Discard.remove_at(selectIndex)
					else:
						selectIndex -= p1Discard.size()
						piles(HAND+activePlayer).append(p2Discard[selectIndex])
						p2Discard.remove_at(selectIndex)
					EndCardAction()
		9: #Forced Kindness
			match cardStep:
				0:
					activePlayer = inactivePlayer
					currentAction = select(HAND + activePlayer)
					cardStep = 1
				1:
					var targetHand = piles(HAND+activePlayer)
					for i in range(6):
						if i != selectIndex:
							piles(DISCARD+activePlayer).append(targetHand[i])
					targetHand.assign([targetHand[selectIndex]])
					targetHand.append_array(piles(HAND+inactivePlayer))
					piles(HAND+inactivePlayer).clear()
					activePlayer = inactivePlayer
					EndCardAction()
		10, 11: #Purchase
			pass
		12: #Painted Rock
			pass
		13: #Sharing is Caring
			pass
		14: #I Earned This
			match cardStep:
				0:
					currentAction = SelectP1Deck | SelectP2Deck
					cardStep = 1
				1:
					if selectIndex < p1Deck.size():
						piles(HAND+activePlayer).append(p1Deck[selectIndex])
						p1Deck.remove_at(selectIndex)
					else:
						selectIndex -= p1Deck.size()
						piles(HAND+activePlayer).append(p2Deck[selectIndex])
						p2Deck.remove_at(selectIndex)
					EndCardAction()
		15: #Recycle
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

func P1Draw(num = 1, toHand = true):
	var cards = []

	for i in range(num):
		if(p1Deck.size() == 0):
			p1Deck = p1Discard.duplicate()
			p1Discard.clear()
			p1Deck.shuffle()
		
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
			p2Deck.shuffle()

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
