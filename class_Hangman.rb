# Class definition for the hangman game
require 'yaml'
class Hangman
  @word = nil
  @min_word_length = nil
  @max_word_length = nil
  @display = nil
  @guess = nil
  @previous_guesses = nil
  @turns = nil
  @max_turns = nil
  @save_progress = nil

  def initialize()
    @min_word_length = 5
    @max_word_length = 12
    @turns = 1
    @max_turns = 12
    @previous_guesses = []
    @save_progress = false
    puts
    puts "Welcome... Prepare yourself for a game of Hangman!"
    puts
  end

  # The in-game functionality
  def play_game
    if new_game?
      print_rules
      computer_select_word
    else
      load_game
    end
    
    until game_over?
      player_input
      evaluate_guess
      @turns += 1
    end

    game_end
  end

  # Prints the rules of hangman
  def print_rules
    puts 'The rules are as follows...'
    puts
    puts "The computer will randomly select a word from the dictionary between #{@min_word_length} and #{@max_word_length} letters long."
    puts
    puts "You will have #{@max_turns} turns to guess the word."
    puts
    puts 'Good luck!!'
    puts
  end

  private
  # Initial prompt to either start a new game or load a previous one
  def new_game?
    begin
      puts "Would you like to load a previous game? (Y/N)>>"
      rgx_inp = /^[YN]{1}$/i
      user_choice = gets.chomp.match(rgx_inp)[0].downcase
    rescue
      puts 'Invalid input! Try again...'
      retry
    end
    user_choice == 'y' ? false : true
  end

# Check if game has ended
  def game_over?
    player_victory? || player_defeat? || save_game?
  end

  # Check if player has won
  def player_victory?
    @guess == @word || @display.split(' ').join('') == @word
  end

  # Check if player has lost
  def player_defeat?
    @turns > @max_turns
  end

  def save_game?
    @save_progress == true
  end

  # Define end of game scenarios of win/loss
  def game_end
    if player_victory?
      puts "You won! You guessed the word '#{@word}'!"
    elsif player_defeat?
      puts "You lost! You didn't guess the word '#{@word}' in time!"
    elsif save_game?
      puts "See ya next time ;)"
    end
    @save_progress = false
    puts
  end

  # Computer reads in the dictionary and randomly chooses a word
  def computer_select_word
    word_dict = File.readlines('word_dictionary.txt')
    word_dict.select! { |word| word.strip.length >= @min_word_length && word.strip.length <= @max_word_length}

    @word = word_dict.sample.strip
    @display = ('_'*@word.length).split('').join(' ')
  end

  # Player inputs guess for secret @word or saves game
  def player_input
    begin
      puts 'Current progress:'
      puts "#{@display}"
      puts
      puts 'Already guessed:'
      puts "#{@previous_guesses.join(', ')}"
      puts
      puts "Please enter your letter OR word guess now OR type SAVE to save your progress (turn ##{@turns})>>"
      rgx_inp = /^[a-zA-Z]{1,#{@max_word_length}}$/
      user_choice = gets.chomp
      if user_choice.match?(/^save$/i)
        save_game
      else
        user_choice = user_choice.match(rgx_inp)[0]
      end
    rescue
      puts 'Invalid input! Try again...'
      retry
    else
      @guess = user_choice.downcase
    end
  end

  # Evaluate @guess for exact, partial, and no matches
  def evaluate_guess
    new_display = @display.split(' ').join('')
    if @guess.length == 1
      @word.split('').each_with_index do |chr, idx|
        if chr == @guess
          new_display[idx] = chr
        end
      end
      @display = new_display.split('').join(' ')
    end
    @previous_guesses.push(@guess)
  end

  # Save yaml file of current progress
  def save_game
    yaml_file = YAML.dump({
      word: @word,
      min_word_length: @min_word_length,
      max_word_length: @max_word_length,
      display: @display,
      previous_guesses: @previous_guesses,
      turns: @turns,
      max_turns: @max_turns
    })
    
    Dir.mkdir("saved_games") unless Dir.exist?("saved_games")

    filename = "saved_games/#{Time.now.strftime('%Y%m%d-%H%M%S')}.yaml"

    File.open(filename, 'w') do |file|
      file.puts yaml_file
    end

    @save_progress = true
  end

  # List and load saved game files
  def load_game
    Dir.glob("saved_games/*.{yaml}").each_with_index do |fname, idx|
      puts "#{idx + 1}. #{fname}"
    end

    begin
      puts "What game would you like to load? >>"
      rgx_inp = /^\d+$/i
      user_choice = gets.chomp.match(rgx_inp)[0].to_i - 1
    rescue
      puts 'Invalid input! Try again...'
      retry
    end

    loaded_yaml = File.read(Dir.glob("saved_games/*.{yaml}")[user_choice])

    loaded_data = YAML.load(loaded_yaml)

    @word = loaded_data[:word]
    @min_word_length = loaded_data[:min_word_length]
    @max_word_length = loaded_data[:max_word_length]
    @display = loaded_data[:display]
    @previous_guesses = loaded_data[:previous_guesses]
    @turns = loaded_data[:turns]
    @max_turns = loaded_data[:max_turns]
  end
end
