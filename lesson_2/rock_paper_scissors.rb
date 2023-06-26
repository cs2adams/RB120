# rock_paper_scissors.rb

class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']

  def initialize(value)
    @value = value
  end

  def scissors?
    @value == 'scissors'
  end

  def rock?
    @value == 'rock'
  end

  def paper?
    @value == 'paper'
  end

  def lizard?
    @value == 'lizard'
  end

  def spock?
    @value == 'spock'
  end

  def rock_wins?(other_move)
    other_move.scissors? || other_move.lizard?
  end

  def paper_wins?(other_move)
    other_move.rock? || other_move.spock?
  end

  def scissors_wins?(other_move)
    other_move.paper? || other_move.lizard?
  end

  def spock_wins?(other_move)
    other_move.scissors? || other_move.rock?
  end

  def lizard_wins?(other_move)
    other_move.paper? || other_move.spock?
  end

  def rock_loses?(other_move)
    !rock_wins?(other_move?) && !other_move.rock?
  end

  def paper_loses?(other_move)
    !paper_wins?(other_move) && !other_move.paper?
  end

  def scissors_loses?(other_move)
    !scissors_wins?(other_move) && !other_move.scissors?
  end

  def spock_loses?(other_move)
    !spock_wins?(other_move) && !other_move.spock?
  end

  def lizard_loses?(other_move)
    !lizard_wins?(other_move) && !other_move.lizard?
  end

  def >(other_move)
    (rock? && rock_wins?(other_move)) ||
      (paper? && paper_wins?(other_move)) ||
      (scissors? && scissors_wins?(other_move)) ||
      (spock? && spock_wins?(other_move)) ||
      (lizard? && lizard_wins?(other_move))
  end

  def <(other_move)
    (rock? && rock_loses?(other_move)) ||
      (paper? && paper_loses?(other_move)) ||
      (scissors? && scissors_loses?(other_move)) ||
      (spock? && spock_loses?(other_move)) ||
      (lizard? && lizard_loses?(other_move))
  end

  def to_s
    @value
  end
end

class Player
  attr_accessor :move, :name

  def initialize
    set_name
  end
end

class Human < Player
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

  def choose
    choice = nil
    loop do
      puts "Please choose #{joinor(Move::VALUES)}:"
      choice = gets.chomp
      break if Move::VALUES.include? choice.downcase
      puts "Sorry, invalid choice."
    end
    self.move = Move.new(choice)
  end

  private

  def joinor(words)
    "#{words[0..-2].join(', ')} or #{words[-1]}"
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def choose
    self.move = Move.new(Move::VALUES.sample)
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
    output_str = "\n #{horizontal_line} \n" \
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

class RPSGame
  attr_accessor :human, :computer, :score, :game_winner

  def initialize
    @human = Human.new
    @computer = Computer.new
    @game_winner = nil
    @score = Score.new([@human, @computer])
  end

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
    self.game_winner = nil
  end

  def display_goodbye_message
    puts "Thanks for playing Rock, Paper, Scissors. Good bye!"
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

  def play_one_round
    human.choose
    computer.choose
    display_moves
    determine_winner
    display_winner
    update_score
    score.display
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
  end
end

RPSGame.new.play
