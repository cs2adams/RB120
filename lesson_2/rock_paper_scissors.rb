# rock_paper_scissors.rb
require 'pry'
require 'pry-byebug'
class Move
  def <(other_move)
    !(self > other_move) && !(other_move.instance_of?(self.class))
  end
end

class Rock < Move
  def >(other_move)
    other_move.instance_of?(Scissors) || other_move.instance_of?(Lizard)
  end

  def to_s
    'rock'
  end
end

class Paper < Move
  def >(other_move)
    other_move.instance_of?(Rock) || other_move.instance_of?(Spock)
  end

  def to_s
    'paper'
  end
end

class Scissors < Move
  def >(other_move)
    other_move.instance_of?(Paper) || other_move.instance_of?(Lizard)
  end

  def to_s
    'scissors'
  end
end

class Lizard < Move
  def >(other_move)
    other_move.instance_of?(Paper) || other_move.instance_of?(Spock)
  end

  def to_s
    'lizard'
  end
end

class Spock < Move
  def >(other_move)
    other_move.instance_of?(Scissors) || other_move.instance_of?(Rock)
  end

  def to_s
    'spock'
  end
end

class Player
  attr_accessor :move, :name

  def initialize
    set_name
  end

  def to_s
    name
  end
end

class Human < Player
  def choose
    choice = nil
    loop do
      puts "Please choose #{joinor(RPSGame::MOVES.keys)}:"
      choice = gets.chomp.downcase
      break if RPSGame::MOVES.keys.include? choice
      puts "Sorry, invalid choice."
    end
    move = RPSGame::MOVES[choice]
    self.move = move.new
  end

  private

  def set_name
    n = ''

    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end

    self.name = n
  end

  def joinor(words)
    "#{words[0..-2].join(', ')} or #{words[-1]}"
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def choose
    move = RPSGame::MOVES[RPSGame::MOVES.keys.sample]
    self.move = move.new
  end
end

class Score
  attr_accessor :board

  def initialize(players)
    @board = {}

    players.each do |player|
      @board[player] = 0
    end
  end

  def update(winner)
    return unless winner
    scoreboard[winner] += 1
  end

  def display
    puts self
  end

  def to_s
    output_str = "\n#{horizontal_line} \n" \
                 "#{'SCOREBOARD'.center(board_width)}" \
                 "\n#{horizontal_line}\n"

    board.each do |player, score|
      name = player.name
      player_score = score.to_s
      num_spaces = board_width - name.size - player_score.size

      output_str << "#{name}#{' ' * num_spaces}#{player_score}\n"
    end

    "#{output_str}\n"
  end

  private

  def board_width
    width = 'Scoreboard'.size

    board.keys.each do |player|
      new_width = player.name.size + 3
      width = new_width if new_width > width
    end

    width
  end

  def horizontal_line
    '-' * board_width
  end
end

class GameHistory
  attr_accessor :human_moves, :computer_moves, :game_winners

  def initialize(human, computer)
    @human = human
    @computer = computer
    @human_moves = []
    @computer_moves = []
    @game_winners = []
  end

  def to_s
    "#{human_moves.join(', ')}\n#{computer_moves.join(', ')}\n" \
      "#{game_winners.join(', ')}"
  end

  def display
    puts header
    puts horizontal_line
    human_moves.each_index { |idx| puts row(idx) }
  end

  private

  attr_reader :human, :computer

  def first_column_header
    ' Round '
  end

  def second_column_header
    " #{human.name}'s Move "
  end

  def third_column_header
    " #{computer.name}'s Move"
  end

  def fourth_column_header
    ' Winner '
  end

  def column_width
    all_words = RPSGame::MOVES.keys + [
      first_column_header, second_column_header,
      third_column_header, fourth_column_header
    ]
    all_words.max_by(&:size).size
  end

  def header
    width = column_width
    "#{first_column_header.center(width)}|" \
      "#{second_column_header.center(width)}" \
      "|#{third_column_header.center(width)}|" \
      "#{fourth_column_header.center(width)}"
  end

  def horizontal_line
    line = '-' * column_width
    "#{line}|#{line}|#{line}|#{line}"
  end

  def row(i)
    width = column_width
    "#{(i + 1).to_s.center(width)}|" \
      "#{human_moves[i].to_s.center(width)}|" \
      "#{computer_moves[i].to_s.center(width)}|" \
      "#{game_winners[i].to_s.center(width)}"
  end
end

class RPSGame
  MOVES = {
    'rock' => Rock, 'paper' => Paper, 'scissors' => Scissors,
    'lizard' => Lizard, 'spock' => Spock
  }

  def initialize
    @human = Human.new
    @computer = Computer.new
    @game_winner = nil
    @score = Score.new([@human, @computer])
    @game_history = GameHistory.new(human, computer)
  end

  def play
    display_welcome_message

    loop do
      play_one_round
      break if match_winner?
      break unless play_again?
    end

    display_match_winner if match_winner?
    display_goodbye_message
    game_history.display
  end

  private

  attr_accessor :human, :computer, :score, :game_winner, :game_history

  def display_welcome_message
    puts "Welcome to Rock, Paper, Scissors!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}"
    puts "#{computer.name} chose #{computer.move}"
  end

  def determine_winner
    self.game_winner = if human.move > computer.move
                         human
                       elsif human.move < computer.move
                         computer
                       end
  end

  def display_winner
    if game_winner
      puts "#{game_winner.name} won!"
    else
      puts "It's a tie!"
    end
  end

  def update_score
    score.board[game_winner] += 1 unless game_winner.nil?
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors. Good bye!\n\n"
  end

  def play_again?
    answer = nil

    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Sorry, must be y or n."
    end

    answer == 'y'
  end

  def match_winner?
    score.board.values.any? { |n| n >= 10 }
  end

  def match_winner
    score.board.select { |_, v| v >= 10 }.keys[0]
  end

  def display_match_winner
    puts "#{match_winner.name} has won 10 games."
  end

  def update_game_history
    game_history.human_moves << human.move
    game_history.computer_moves << computer.move
    game_history.game_winners << (game_winner.nil? ? 'Tie' : game_winner)
    self.game_winner = nil
  end

  def play_one_round
    human.choose
    computer.choose
    display_moves
    determine_winner
    display_winner
    update_score
    update_game_history
    score.display
  end
end

RPSGame.new.play
