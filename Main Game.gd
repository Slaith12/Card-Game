extends Node2D

class GameCard:
	var cardID : int
	var revealState : int
	func isRevealedTo(playerNum):
		return (revealState & (1 << playerNum)) != 0
	
	func Scry(playerNum):
		revealState |= 1 << playerNum

	func _init(id):
		cardID = id
		revealState = 0

# Piles
var p1Deck : Array[GameCard]
var p1Hand : Array[GameCard]
var p1Discard : Array[GameCard]

var p2Deck : Array[GameCard]
var p2Hand : Array[GameCard]
var p2Discard : Array[GameCard]

var specialPile : Array[GameCard]

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

# Game State
@export var cards : Array[CardData]
@export var deckSize : int

var activeCard : int
var activePlayer : int
var inactivePlayer:
	get: return activePlayer ^ 1
var playingAs : int
var cardStep : int
var currentAction : int
var currentTurn : int
var currentEnergy : int
var multiSelectLimit : int
enum {WaitForAnim = 0, SelectP1Hand = 1, SelectP2Hand = 2, SelectP1Deck = 4, SelectP2Deck = 8, SelectP1Discard = 16, SelectP2Discard = 32, SelectSpecial = 64, MultiSelect = 128}
func select(index, multi = false):
	return (1 << index) + (MultiSelect if multi else 0)
enum {HAND = 0, DECK = 2, DISCARD = 4, SPECIAL = 6}
enum {P1 = 0, P2 = 1}

# Display
const base_card : PackedScene = preload("res://card.tscn")
const blank_card : CardData = preload("res://Blank Card.tres")
const hand_spacing := 90.0 + 35

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#initialize piles
	p1Deck = []
	p1Hand = []
	p1Discard = []
	p2Deck = []
	p2Hand = []
	p2Discard = []

	#insert standard cards
	for i in range(deckSize):
		p1Deck.append(GameCard.new(i))
		p2Deck.append(GameCard.new(i))
	
	#shuffle and draw starting hands
	Shuffle(p1Deck)
	Shuffle(p2Deck)
	P1Draw(6)
	P2Draw(6)

	#shuffle in stones
	for i in range(deckSize, deckSize+6):
		if p1Deck.size() == deckSize+3:
			p2Deck.append(GameCard.new(i))
		elif p2Deck.size() == deckSize+3:
			p1Deck.append(GameCard.new(i))
		elif randi_range(0, 1) == 0:
			p1Deck.append(GameCard.new(i))
		else:
			p2Deck.append(GameCard.new(i))
		
	Shuffle(p1Deck)
	Shuffle(p2Deck)

	UpdateRevealedCards()
	UpdateCardDisplay()

	playingAs = P1 # hardcoded to p1 for now

	#initialize game state
	#setting activePlayer to player 2 and currentTurn to 0 before calling BeginNewTurn() will start the game on turn 1 on player 1's turn
	activePlayer = P2
	activeCard = -1
	currentTurn = 0
	BeginNewTurn()
	currentAction = SelectP1Hand

func _input(event):
	if event.is_action_pressed("reveal"):
		for card in p2Hand:
			card.revealState ^= 1
		UpdateCardDisplay()

	if event.is_action_pressed("dump_known"):
		var line = "Your hand (size " + str(p1Hand.size()) + "): "
		for card in p1Hand:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)
		line = "Enemy hand (size " + str(p2Hand.size()) + "): "
		for card in p2Hand:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)
		line = "Your discard (size " + str(p1Discard.size()) + "): "
		for card in p1Discard:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)
		line = "Enemy discard (size " + str(p2Discard.size()) + "): "
		for card in p2Discard:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)
		line = "Your deck (size " + str(p1Deck.size()) + "): "
		for card in p1Deck:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)
		line = "Enemy deck (size " + str(p1Deck.size()) + "): "
		for card in p2Deck:
			line += (cards[card.cardID].title + " [" + str(card.cardID) + "], ") if card.isRevealedTo(P1) else "Unknown, "
		print(line)

	if event.is_action_pressed("dump_all"):
		var line = "Your hand (size " + str(p1Hand.size()) + "): "
		for card in p1Hand:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)
		line = "Enemy hand (size " + str(p2Hand.size()) + "): "
		for card in p2Hand:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)
		line = "Your discard (size " + str(p1Discard.size()) + "): "
		for card in p1Discard:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)
		line = "Enemy discard (size " + str(p2Discard.size()) + "): "
		for card in p2Discard:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)
		line = "Your deck (size " + str(p1Deck.size()) + "): "
		for card in p1Deck:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)
		line = "Enemy deck (size " + str(p1Deck.size()) + "): "
		for card in p2Deck:
			line += cards[card.cardID].title + " [" + str(card.cardID) + "], "
		print(line)

func BeginNewTurn():
	activePlayer = inactivePlayer
	if(activePlayer == P1):
		currentTurn += 1
	currentEnergy = currentTurn

func UpdateCardDisplay():
	UpdatePileSpread($PlayHand, piles(HAND + playingAs))
	UpdatePileSpread($OppHand, piles(HAND + (playingAs^1)))

func UpdatePileSpread(spread, handData):
	while spread.get_child_count() < handData.size():
		spread.add_child(base_card.instantiate())
	while spread.get_child_count() > handData.size():
		spread.get_child(0).free() # may cause problems later but it should be fine for now since nothing else references the card objects

	if handData.size() == 0: return

	var cardPos = hand_spacing * (handData.size() - 1) / -2.0
	var cardObjects = spread.get_children()
	for i in range(cardObjects.size()):
		var display = cardObjects[i]
		var card = handData[i]
		var data = cards[card.cardID] if card.isRevealedTo(playingAs) else blank_card # will need to be changed; card display will need to know reveal info and other info later
		display.position.x = cardPos
		display.SetData(data)
		cardPos += hand_spacing

func EndCardAction(discard := true):
	#place the used card in the discard pile (unless the card effect already placed it somewhere)
	if discard:
		piles(DISCARD + activePlayer).append(activeCard)


	#draw to minimum hand size
	if(p1Hand.size() < 6):
		P1Draw(6 - p1Hand.size())
	if(p2Hand.size() < 6):
		P2Draw(6 - p2Hand.size())
	
	UpdateRevealedCards()

	#check if turn should pass
	if(currentEnergy <= 0):
		BeginNewTurn()

	#reset card state to "Waiting for card"
	activeCard = -1
	currentAction = select(HAND + activePlayer)

	UpdateCardDisplay()

func UpdateRevealedCards():
	for card in p1Hand:		card.revealState |= 1
	for card in p2Hand:		card.revealState |= 2
	for card in p1Discard: 	card.revealState = 3
	for card in p2Discard: 	card.revealState = 3


func ProcessCard(selectIndex): # selectIndex is an int for single selections, and an int array for multi-selections
	match activeCard:
		-1: # None
			var playerHand = piles(HAND + activePlayer)
			var cardID = playerHand[selectIndex]
			var cardData = cards[cardID]

			# check if card can be played (negative cost = unplayable/hide cost)
			if cardData.cost > currentEnergy or cardData.cost < 0:
				return
			
			# remove card from hand before playing it (don't put in discard pile yet)
			playerHand.remove_at(selectIndex)

			# initialize card state variables
			activeCard = cardID
			cardStep = 0
			currentAction = WaitForAnim

			#subtract energy cost
			currentEnergy -= cardData.cost

		0: #One with Nothing [Discard your hand]
			piles(DISCARD + activePlayer).append_array(piles(HAND + activePlayer))
			piles(HAND + activePlayer).clear()
			EndCardAction()
		1: #Swap [take card from opp, opp takes this card]
			match cardStep:
				0:
					#prompt player to select card from opponent's hand
					currentAction = select(HAND + inactivePlayer)
					cardStep = 1
				1:
					#move selected card to player's hand
					var swappedCard = piles(HAND + inactivePlayer)[selectIndex]
					piles(HAND+inactivePlayer).remove_at(selectIndex)					
					piles(HAND+activePlayer).append(swappedCard)

					#move "swap" card to opponent's hand
					piles(HAND+inactivePlayer).append(activeCard)

					EndCardAction()
		2, 3: #Emergency Stash [store a card]
			match cardStep:
				0:
					#prompt player to select card from hand
					currentAction = select(HAND + activePlayer)
					cardStep = 1
				1:
					#transfer card to special pile [stores it for the next step]
					specialPile.clear()
					specialPile.append(piles(HAND+activePlayer)[selectIndex])
					piles(HAND+activePlayer).remove_at(selectIndex)

					currentAction = select(SPECIAL)
					# put up ui for inserting cards into deck
					cardStep = 2
				2:
					# specialPile contains the card to be inserted, selectIndex contains the position to insert it
					var pos = selectIndex
					var card = specialPile[0]
					piles(DECK+activePlayer).insert(pos, card)

					EndCardAction()
		4: #Snoop [scry 4 deck cards]
			match cardStep:
				0:
					#prompt player to select 4 cards from decks
					currentAction = SelectP1Deck | SelectP2Deck | MultiSelect
					multiSelectLimit = 4
					cardStep = 1
				1:
					#reveal cards
					#select indices start with p1 deck, then p2 deck
					for i in selectIndex:
						#determine which deck the card is in, then scry
						var card
						if i < p1Deck.size():
							card = p1Deck[i]
						else:
							i -= p1Deck.size()
							card = p2Deck[i]
						
						card.Scry(activePlayer)

					#give player time to look at cards before continuing
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
					#Transfer all discard cards to deck, then shuffle
					piles(DECK+selectIndex).append_array(piles(DISCARD+selectIndex))
					piles(DISCARD+selectIndex).clear()

					Shuffle(piles(DECK+selectIndex))
					EndCardAction()

		6: #Sleight of Hand
			match cardStep:
				0:
					#transfer top 3 cards of opponent's deck to the special pile
					var deck = piles(DECK+inactivePlayer)
					specialPile.clear()
					specialPile.append_array(deck.slice(0,3))
					#remove top 3 cards from deck
					deck.assign(deck.slice(3))

					#scry selected cards
					for card in specialPile:
						card.Scry(activePlayer)
					#Show stash dialog
					#multiCardLimit doesn't need to be set for SelectSpecial
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

func Shuffle(pile):
	if pile.size() < 2: return

	pile.shuffle()
	
	for card in pile:
		card.revealState = 0
