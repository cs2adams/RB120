class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [3, 5, 7]]
  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    draw_row_divider
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    draw_row_divider
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end

  def draw_row_divider
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
  end

  def []=(square, marker)
    @squares[square].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  # returns winning marker or nil
  def winning_marker
    WINNING_LINES.each do |line|
      markers = @squares.values_at(*line).map(&:marker)
      first_marker = markers[0]
      if first_marker != Square::INITIAL_MARKER &&
         markers.all? { |marker| marker == first_marker }
        return first_marker
      end
    end
    nil
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
  attr_reader :marker

  def initialize(marker)
    @marker = marker
  end
end

class TTTGame
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  FIRST_TO_MOVE = 'human'
  attr_reader :board, :human, :computer, :current_player

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @current_player = FIRST_TO_MOVE == 'human' ? @human : @computer
  end

  def clear
    system('clear')
  end

  def display_welcome_message
    clear
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts "You're a #{human.marker}. Computer is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def human_moves
    puts "Choose a square (#{board.unmarked_keys.join(', ')}): "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    board[board.unmarked_keys.sample] = computer.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
    else
      computer_moves
    end
  end

  def next_player
    @current_player = @current_player == @human ? @computer : @human
  end

  def human_turn?
    @current_player == @human
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
    when computer.marker
      puts "Computer won!"
    else
      puts "The board is full!"
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

  def reset
    board.reset
    clear
    @current_player = FIRST_TO_MOVE == 'human' ? @human : @computer
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def play_one_round
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      next_player
      clear_screen_and_display_board if human_turn?
    end
  end

  def main_game
    loop do
      display_board
      play_one_round
      display_result
      break unless play_again?
      reset
      display_play_again_message
    end
  end

  def play
    display_welcome_message
    main_game
    display_goodbye_message
  end
end

game = TTTGame.new
game.play
