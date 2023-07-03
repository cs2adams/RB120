module Promptable
  def prompt_valid_user_input(valid_input = 'all')
    return gets.chomp if valid_input == 'all'

    input = ''
    loop do
      input = gets.chomp
      break if valid_input.include? input
      puts "Invalid input, please try again."
    end

    input
  end
end

module Playable
  def next_player
    players = Player.players
    return players[0] if current_player == players[-1]
    players[current_player.index + 1]
  end
end

class Board
  attr_reader :width, :squares

  def initialize(width)
    @squares = {}
    @width = width
    reset
  end

  def reset
    (1..(width**2)).each { |key| squares[key] = Square.new }
  end

  def winning_lines
    winning_rows + winning_cols + winning_diagonals
  end

  def winning_marker # returns winning marker or nil
    winning_lines.each do |line|
      markers = squares.values_at(*line).map(&:marker)
      first_marker = markers[0]
      if first_marker != Square::INITIAL_MARKER &&
         markers.all? { |marker| marker == first_marker }
        return first_marker
      end
    end
    nil
  end

  def []=(square, marker)
    squares[square].marker = marker
  end

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def copy
    new_board = clone
    new_board.squares = {}
    squares.each do |k, v|
      new_board.squares[k] = v.dup
    end
    new_board
  end

  def draw
    starting_square = 1
    width.times do
      draw_top_row(starting_square)
      draw_row(starting_square)
      draw_blank_row
      draw_horizontal_line unless starting_square + width > (width**2)
      starting_square += width
    end
  end

  protected

  attr_writer :squares

  private

  def winning_rows
    rows = []

    1.upto(width) do |i|
      current_row = []

      1.upto(width) do |j|
        current_row << ((width * (i - 1)) + j)
      end

      rows << current_row
    end

    rows
  end

  def winning_cols
    cols = []

    1.upto(width) do |i|
      current_col = []

      1.upto(width) do |j|
        current_col << ((width * (j - 1)) + i)
      end
      cols << current_col
    end

    cols
  end

  def winning_diagonals
    diagonals = [[], []]

    1.upto(width) do |i|
      diagonals[0] << (width + ((i - 1) * (width - 1)))
      diagonals[1] << (1 + ((i - 1) * (width + 1)))
    end

    diagonals
  end

  def draw_top_row(starting_square)
    starting_square.upto(starting_square + width - 1) do |square|
      print "#{square}   "
      print " " unless square >= 10
      print "|" unless square == starting_square + width - 1
    end
    puts ""
  end

  def draw_row(starting_square)
    starting_square.upto(starting_square + width - 1) do |square|
      print "  #{squares[square].marker}  "
      print "|" unless square == starting_square + width - 1
    end
    puts ""
  end

  def draw_blank_row
    puts "     |" * (width - 1)
  end

  def draw_horizontal_line
    puts "#{'-----+' * (width - 1)}-----"
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_reader :marker, :name

  POSSIBLE_MARKERS = ('a'..'z').to_a + ('A'..'Z').to_a

  @@taken_markers = []
  @@taken_names = []
  @@players = []

  def initialize
    @@taken_markers << @marker
    @@taken_names << @name
    @@players << self
  end

  def index
    @@players.each_with_index do |player, idx|
      return idx if player == self
    end
  end

  def to_s
    name
  end

  def ==(other)
    return false if other.nil?
    name == other.name
  end

  def self.taken_markers
    @@taken_markers
  end

  def self.players
    @@players
  end

  def self.display_player_markers
    @@players.each do |player|
      print "#{player.name} is #{player.marker}. "
    end
    puts ""
  end

  private

  def taken_names
    @@taken_names
  end

  def available_markers
    POSSIBLE_MARKERS.select do |marker|
      !@@taken_markers.include?(marker)
    end
  end
end

class Human < Player
  include Promptable

  @@num_humans = 0

  def initialize
    @@num_humans += 1
    @player_number = @@num_humans
    @marker = prompt_player_marker
    @name = player_name
    super
  end

  private

  attr_reader :player_number

  def prompt_player_marker
    puts "\nPlayer #{player_number}, please enter a single character " \
         "to use as your marker"
    prompt_valid_user_input(available_markers)
  end

  def player_name
    puts "Player #{player_number}, please enter your name."
    prompt_player_name
  end

  def prompt_player_name
    name = ''
    loop do
      name = gets.chomp.strip
      break unless name.empty? || taken_names.include?(name)
      puts "Input not recognized. Please enter a valid name." if name.empty?

      display_name_taken_message if taken_names.include?(name)
    end
    name
  end

  def prompt_valid_user_input(valid_input = 'all')
    return gets.chomp if valid_input == 'all'

    input = ''
    loop do
      input = gets.chomp
      break if valid_input.include? input
      puts "Invalid input, please try again."
    end

    input
  end

  def display_name_taken_message
    puts "That name has already been chosen by a different player."
    puts "Please select a new name."
  end
end

class Computer < Player
  DEFAULT_MARKER = 'O'
  NAMES = ['iRobot', 'Terminator', 'The Matrix', 'J.A.R.V.I.S.', 'WALL-E']

  attr_writer :marker

  def initialize
    @marker = choose_marker
    @name = choose_name
    super
  end

  private

  def choose_marker
    return DEFAULT_MARKER if available_markers.include?(DEFAULT_MARKER)
    available_markers.sample
  end

  def choose_name
    NAMES.reject { |name| taken_names.include?(name) }.sample
  end
end

class Minimaxer
  include Playable

  attr_reader :best_square

  def initialize(board, minimaxing_player, current_player, depth = nil)
    @board = board
    @minimaxing_player = minimaxing_player
    @current_player = current_player
    @depth = depth.nil? ? max_algo_depth : depth
    @value = minimaxer_turn? ? -Float::INFINITY : Float::INFINITY
    @best_square = nil
    @possible_moves = @board.unmarked_keys
  end

  def choose_square
    minimax
    best_square
  end

  protected

  attr_accessor :value
  attr_reader :possible_moves
  attr_writer :best_square

  def minimax
    return_value = algo_return_value
    return return_value unless return_value.nil?

    possible_moves.each do |square|
      current_value = square_value(square)

      if better_value?(current_value)
        self.best_square = square
        self.value = current_value
      end
    end
    value
  end

  private

  attr_reader :board, :minimaxing_player, :current_player, :depth

  def square_value(square)
    new_board = board.copy
    new_board[square] = current_player.marker
    Minimaxer.new(new_board, minimaxing_player, next_player, depth - 1).minimax
  end

  def better_value?(new_value)
    return new_value >= value if minimaxer_turn?
    new_value <= value
  end

  def heuristic_square_value(move)
    case num_winning_lines(move)
    when 4 then 10000
    when 3 then 1000
    when 2 then 100
    when 1 then 10
    else        0
    end
  end

  def heuristic_board_value
    possible_moves = board.unmarked_keys
    value = 0

    possible_moves.each do |move|
      current_value = heuristic_square_value(move)
      value = current_value if current_value > value
    end

    value *= -1 unless minimaxer_turn?
    value
  end

  def max_algo_depth
    algo_depth = 0
    num_iters = board.width**2 # Number of possible moves at start of game
    num_empty_squares = num_iters

    loop do
      num_empty_squares -= 1
      num_iters *= num_empty_squares unless num_empty_squares == 0

      break if num_iters > TTTGame::MAX_ALGO_ITERS || num_empty_squares == 0
      algo_depth += 1
    end

    algo_depth
  end

  def algo_return_value
    winning_marker = board.winning_marker

    if winning_marker == minimaxing_player.marker
      return Float::INFINITY
    end

    return -Float::INFINITY if !winning_marker.nil?
    return 0 if board.full?

    if depth == 0
      return heuristic_board_value
    end

    nil
  end

  def num_winning_lines(move)
    num = 0
    other_player_markers = other_markers
    board.winning_lines.each do |line|
      if line.include?(move) && !board.squares.values_at(*line).any? do |marker|
           other_player_markers.include?(marker)
         end
        num += 1
      end
    end
    num
  end

  def other_markers
    Player.taken_markers.reject do |marker|
      marker == current_player.marker
    end
  end

  def minimaxer_turn?
    current_player == minimaxing_player
  end
end

class Scoreboard
  def initialize(players, num_games_to_win)
    @scoreboard = {}
    @num_games_to_win = num_games_to_win

    players.each do |player|
      @scoreboard[player] = 0
    end
  end

  def update(winner)
    return unless winner
    scoreboard[winner] += 1
  end

  def match_winner
    scoreboard.select { |_, v| v >= num_games_to_win }.keys.first
  end

  def display
    puts self
  end

  def to_s
    output_str = "#{horizontal_line} \n" \
                 "#{'SCOREBOARD'.center(width)}" \
                 "\n#{horizontal_line}\n"

    scoreboard.each do |player, score|
      name = player.name
      player_score = score.to_s
      num_spaces = width - name.size - player_score.size

      output_str << "#{name}#{' ' * num_spaces}#{player_score}\n"
    end

    "#{output_str}\n"
  end

  private

  attr_reader :scoreboard, :num_games_to_win

  def width
    width = 'Scoreboard'.size

    scoreboard.keys.each do |player|
      new_width = player.name.size + 3
      width = new_width if new_width > width
    end

    width
  end

  def horizontal_line
    '-' * width
  end
end

class TTTGame
  include Promptable
  include Playable

  MAX_ALGO_ITERS = 1_000_000
  MIN_BOARD_WIDTH = 3
  MAX_BOARD_WIDHTH = 7
  MAX_MATCH_LENGTH = 20

  def initialize
    setup_game
  end

  def play
    clear if human_turn?
    main_game
    display_goodbye_message
  end

  def num_games_to_win
    (match_length / 2) + 1
  end

  private

  attr_reader :board, :human, :computer, :scoreboard, :max_players,
              :min_computers, :max_computers, :num_humans, :match_length
  attr_accessor :current_player

  def setup_game
    display_welcome_message
    @match_length = prompt_match_length
    display_num_games_to_win
    width = prompt_board_width
    @board = Board.new(width)
    initialize_players
    @current_player = Player.players.first
    @scoreboard = Scoreboard.new(Player.players, num_games_to_win)
  end

  def initialize_players
    @max_players = max_allowable_players
    @num_humans = prompt_num_human_players
    display_no_humans_message if @num_humans == 0

    @min_computers = min_computer_players
    @max_computers = @max_players - @num_humans
    num_computers = prompt_num_computer_players
    display_no_computers_message if num_computers == 0

    num_humans.times { Human.new }
    num_computers.times { Computer.new }
  end

  def min_computer_players
    case num_humans
    when 0
      2
    when 1
      1
    else
      0
    end
  end

  def max_allowable_players
    (board.width / 2) + (board.width % 2)
  end

  def prompt_match_length
    puts "How many games would you like to play?"
    puts "You can play a match of up to twenty games."
    prompt_valid_user_input(('1'..MAX_MATCH_LENGTH.to_s).to_a).to_i
  end

  def prompt_board_width
    puts "Please enter the width of the board. The width can " \
         "be between #{MIN_BOARD_WIDTH} and #{MAX_BOARD_WIDHTH}."

    valid_input = (MIN_BOARD_WIDTH.to_s..MAX_BOARD_WIDHTH.to_s).to_a
    prompt_valid_user_input(valid_input).to_i
  end

  def prompt_num_human_players
    puts "\nBased on the selected board size, the game can " \
         "accommodate up to #{max_players} players."
    puts 'The players can be any combination of humans and computers.'
    puts 'How many human players will be playing?'

    prompt_valid_user_input(('0'..max_players.to_s).to_a).to_i
  end

  def prompt_num_computer_players
    return min_computers if min_computers == max_computers

    puts 'How many AI opponents would you like in the game?'
    prompt_valid_user_input((min_computers.to_s..max_computers.to_s).to_a).to_i
  end

  def display_no_computers_message
    puts "\nYou have selected a game with #{num_humans} human players."
    puts 'This is the maximum allowable number of players for a ' \
         "#{board.width} x #{board.width} board."
    puts 'There will be no AI opponents in this game.'
  end

  def display_no_humans_message
    clear
    puts "You have selected a game with no human players."
    puts 'You will be a passive observer ' \
         'of your AI overlords.'
    puts ''
  end

  def play_one_round
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      self.current_player = next_player
      clear_screen_and_display_board
    end
  end

  def main_game
    loop do
      display_board
      play_one_round
      display_result
      scoreboard.update(winner)
      break unless !scoreboard.match_winner && play_again?
      reset
      scoreboard.display
      display_play_again_message
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def display_result
    clear_screen_and_display_board

    if winner
      puts "#{winner} won!"
    else
      puts "The board is full!"
    end
  end

  def display_welcome_message
    clear
    puts "Welcome to Tic Tac Toe!"
  end

  def display_num_games_to_win
    print "\nThis match will consist of "
    puts match_length == 1 ? "1 game." : "up to #{match_length} games."
    print "The first player to win #{num_games_to_win} game"
    print match_length == 1 ? '' : 's'
    puts " will win the match."
    puts "You can choose to exit the match at any time."
    puts ""
  end

  def display_goodbye_message
    puts ""
    scoreboard.display
    match_winner = scoreboard.match_winner
    if match_winner
      puts "#{match_winner} has won #{num_games_to_win} rounds. " \
           "This ends the match."
    end
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    Player.display_player_markers
    puts ""
    board.draw
    puts ""
  end

  def human_moves
    puts "#{current_player.name}, it is your turn."
    puts "Choose a square (#{joinor(board.unmarked_keys)}): "
    square = prompt_valid_user_input(board.unmarked_keys.map(&:to_s)).to_i
    board[square] = current_player.marker
  end

  def computer_moves
    puts "It is #{current_player.name}'s turn."
    sleep(1)
    minimaxer = Minimaxer.new(board.copy, current_player, current_player)
    square = minimaxer.choose_square
    board[square] = current_player.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
    else
      computer_moves
    end
  end

  def human_turn?
    current_player.instance_of? Human
  end

  def winner
    winning_marker = board.winning_marker
    return if winning_marker.nil?

    Player.players.each do |player|
      return player if player.marker == winning_marker
    end
  end

  def reset
    board.reset
    clear
    self.current_player = Player.players.first
  end

  def clear
    system('clear')
  end

  def joinor(arr, delimeter = ', ', oxford_word = 'or')
    return '' if arr.empty?
    return arr[0].to_s if arr.size == 1
    "#{arr[0..-2].join(delimeter)}#{delimeter[0] if arr.size > 2} " \
      "#{oxford_word} #{arr[-1]}"
  end
end

game = TTTGame.new
game.play
