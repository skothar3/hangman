# Class definition for the hangman game
require 'yaml'
class Hangman

  def initialize()
    @min_word_length = 5
    @max_word_length = 12
    @turns = 1
    @max_turns = 12
    @previous_guesses = []
    @save_progress = false
    print_rules
  end

  # The in-game functionality
  def play_game
    if new_game?
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
    puts <<~HEREDOC

    Welcome... Prepare yourself for a game of Hangman!"

    The rules are as follows...
    
    The computer will randomly select a word from the dictionary between \e[32m#{@min_word_length}\e[0m and \e[32m#{@max_word_length}\e[0m letters long.
    
    You will have \e[32m#{@max_turns}\e[0m turns to guess the word.
    
    Good luck!!
    
    HEREDOC
  end

  private
  # Initial prompt to either start a new game or load a previous one
  def new_game?
    begin
      puts "Would you like to load a previous game? \e[32m[Y]/[N]\e[0m>>"
      rgx_inp = /^[YN]{1}$/i
      user_choice = gets.chomp.match(rgx_inp)[0].downcase
    rescue
      puts 'Invalid input! Try again...'
      retry
    end
    user_choice == 'y' ? false : true
  end

  # Computer reads in the dictionary and randomly chooses a word
  def computer_select_word
    word_dict = File.readlines('word_dictionary.txt')
    word_dict.select! { |word| word.strip.length >= @min_word_length && word.strip.length <= @max_word_length}

    @word = word_dict.sample.strip
    @display = '_'*@word.length
  end

  # Player inputs guess for secret @word or saves game
  def player_input
    current_progress
    
    puts "\nPlease enter your letter OR word guess now OR type SAVE to save your progress (turn #\e[32m#{@turns}\e[0m)>>"

    begin
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
    puts
  end

  # Prints game progress to console
  def current_progress
    puts "\nCurrent progress:\n\n"
    
    @display.each_char do |slot|
          if slot == '_'
            print "#{slot} "
          else
            print "\e[32m#{slot}\e[0m "
          end
        end
    puts "\n\nAlready guessed:\n"
    @previous_guesses.each do |guess|
      if @word.include?(guess) 
        print "\e[32m#{guess}\e[0m, "
      else
        print "#{guess}, "
      end
    end
    puts
  end

  # Evaluate @guess for exact, partial, and no matches
  def evaluate_guess
    new_display = @display
    if @guess.length == 1
      @word.split('').each_with_index do |chr, idx|
        if chr == @guess
          new_display[idx] = chr
        end
      end
      @display = new_display
    end
    @previous_guesses.push(@guess)
  end

  # Check if game has ended
  def game_over?
    player_victory? || player_defeat? || save_game?
  end

  # Check if player has won
  def player_victory?
    @guess == @word || @display == @word
  end

  # Check if player has lost
  def player_defeat?
    @turns > @max_turns
  end

  # Check to save game
  def save_game?
    @save_progress == true
  end

  # Define end of game scenarios of win/loss
  def game_end
    if player_victory?
      puts "You won! You guessed the word '\e[32m#{@word}\e[0m'!"
    elsif player_defeat?
      puts "You lost! You didn't guess the word '\e[32m#{@word}\e[0m' in time!"
    elsif save_game?
      puts "See ya next time ;)"
      @save_progress = false
    end
    puts
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
    puts
    Dir.glob("saved_games/*.{yaml}").each_with_index do |fname, idx|
      puts "#{idx + 1}. #{fname}"
    end

    begin
      puts "\nWhat game would you like to load? >>"
      rgx_inp = /^\d+$/i
      user_choice = gets.chomp.match(rgx_inp)[0].to_i - 1
    rescue
      puts 'Invalid input! Try again...'
      retry
    end
    
    load_file(user_choice)
  end

  # Load the selected yaml file
  def load_file(user_choice)
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
