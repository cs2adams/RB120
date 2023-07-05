module Promptable
  def prompt_valid_user_input(valid_input)
    input = ''
    loop do
      input = gets.chomp
      break if valid_input.include?(input.downcase)
      puts "Input not recognized, please try again."
    end
    input
  end
end

class Player
  include Promptable

  attr_reader :hand, :words

  def initialize
    empty_hand
    @words = set_words
  end

  def show(num_cards = hand.size)
    puts "#{words[:self]} #{words[:have]} the following hand:"
    (0...num_cards).each { |idx| hand[idx].show }
    puts ""
    puts "#{words[:possess]} hand value is: #{total(num_cards)}"
  end

  def play
    action = ''
    loop do
      show
      action = choose_action
      hit if action == 'hit'
      break if action.downcase == 'stay' || busted?
    end
    display_busted_message if busted?
    display_stay_message if action == 'stay'
  end

  def to_s
    words[:self]
  end

  def busted?
    total > Game::MAX_SCORE
  end

  def >(other)
    total > other.total
  end

  def <(other)
    total < other.total
  end

  protected

  attr_accessor :dealer

  def empty_hand
    self.hand = []
  end

  def total(num_cards = hand.size)
    total = hand[0...num_cards].map(&:value).inject(:+)
    num_aces.times { total -= 10 if total > Game::MAX_SCORE }
    total
  end

  private

  attr_writer :hand

  def hit
    dealer.deal(self, 1)
  end

  def num_aces
    hand.select { |card| card.name == 'Ace' }.size
  end

  def set_words
    { self: 'You', have: 'have', possess: 'Your',
      bust: 'bust', draw: 'draw', win: 'win' }
  end

  def choose_action
    prompt_user_action
  end

  def prompt_user_action
    puts "\nWhat action would you like to take? (hit/stay)"
    prompt_valid_user_input(['hit', 'stay'])
  end

  def display_busted_message
    puts ""
    puts "#{words[:self]} #{words[:draw]} a #{hand[-1]}"
    puts "#{words[:self]} #{words[:bust]} with a hand value of #{total}."
  end

  def display_stay_message
    puts "#{words[:self]} chose to stay."
  end
end

class Dealer < Player
  def initialize(deck, player)
    @deck = deck
    @player = player
    player.dealer = self
    @dealer = self
    super()
  end

  def reshuffle
    deck.reset
    player.empty_hand
    dealer.empty_hand
    deal(player, 2)
    deal(self, 2)
  end

  def deal(player, num_cards)
    num_cards.times do
      player.hand << deck.draw_card
    end
  end

  private

  attr_reader :player, :deck

  def set_words
    { self: 'Dealer', have: 'has', possess: "Dealer's",
      bust: 'busts', draw: 'draws', win: 'wins' }
  end

  def choose_action
    sleep(2)
    total >= Game::DEALER_HIT_THRESHOLD ? 'stay' : 'hit'
  end
end

class Deck
  SUITS = ['Clubs', 'Spades', 'Diamonds', 'Hearts']
  FACES = [
    { name: 'Jack', value: 10 }, { name: 'Queen', value: 10 },
    { name: 'King', value: 10 }, { name: 'Ace', value: 11 }
  ]
  NUMBERS = (2..10).each_with_object([]) do |v, arr|
    arr << { name: v.to_s, value: v }
  end

  def initialize
    @deck = reset
  end

  def draw_card
    deck.pop
  end

  def reset
    self.deck = []

    SUITS.each do |suit|
      (NUMBERS + FACES).each do |type|
        deck << Card.new(type[:name], type[:value], suit)
      end
    end

    deck.shuffle!
  end

  private

  attr_accessor :deck
end

class Card
  attr_reader :name, :value

  def initialize(name, value, suit)
    @name = name
    @value = value
    @suit = suit
  end

  def show
    puts self
  end

  def to_s
    "#{name} of #{suit}"
  end

  private

  attr_reader :suit
end

class Game
  include Promptable
  MAX_SCORE = 21
  DEALER_HIT_THRESHOLD = 17

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new(deck, player)
  end

  def play
    display_welcome_message
    loop do
      clear
      play_one_round
      break unless play_again?
    end
    display_goodbye_message
  end

  private

  attr_reader :player, :dealer, :deck

  def play_one_round
    dealer.reshuffle
    show_initial_cards
    player.play
    dealer.play unless player.busted?
    show_result
  end

  def play_again?
    puts "Would you like to play again? (y/n)"
    prompt_valid_user_input(['y', 'n']).downcase == 'y'
  end

  def display_welcome_message
    clear
    puts "Welcome to 21!"
    sleep(1)
  end

  def display_goodbye_message
    puts "\nThanks for playing 21. Goodbye!"
    sleep(1)
    clear
  end

  def display_winner
    if winner
      puts "#{winner} #{winner.words[:win]}!"
    else
      puts "Tie game!"
    end
  end

  def winner
    return player if player > dealer
    return dealer if dealer > player
    nil
  end

  def show_initial_cards
    dealer.show(1)
  end

  # rubocop:disable Metrics/AbcSize
  def show_result
    if player.busted?
      puts "#{dealer.words[:self]} #{dealer.words[:win]}!"
    elsif dealer.busted?
      puts "#{player.words[:self]} #{player.words[:win]}!"
    else
      display_winner
    end
  end
  # rubocop:enable Metrics/AbcSize

  def clear
    system('clear')
  end
end

game = Game.new
game.play
