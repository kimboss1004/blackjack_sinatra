require 'rubygems' 
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '1004'

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do

  def culculate_total(cards)
    array_of_values = cards.map{|element| element[0]} # => ['2','King','8','Ace']
    total = 0
    array_of_values.each do |value|
      if value == 'Ace'
        total += 11
      elsif value.to_i == 0
        total += 10
      else
        total += value.to_i
      end
    end
    array_of_values.select{|value| value == 'Ace'}.count.times do
      if total > BLACKJACK_AMOUNT
        total -= 10
      else
        break
      end
    end
    total
  end



  def show_card_pic(card)
    suit = card[1].downcase
    if ["Ace","Jack","Queen","King"].include?(card[0])
      value = card[0].downcase
    else
      value = card[0]
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_pics' />"
  end



  def winner!(msg)
    @winner = "<strong>#{session[:player_name]} won!</strong> #{msg}"
    @play_again = true
  end

  def loser!(msg)
    @loser = "<strong>#{session[:player_name]} lost! </strong> #{msg}"
    @play_again = true
  end

  def tie!(msg)
    @tie = "<strong>It's a tie!</strong>"
    @play_again = true  
  end


  def update_bet_and_message
    if @winner != nil
      session[:money]= session[:money].to_i + session[:how_much].to_i
      @winner += " #{session[:player_name]} now has #{session[:money]}."
    elsif @loser != nil
      session[:money]= session[:money].to_i - session[:how_much].to_i
      @loser += " #{session[:player_name]} now has #{session[:money]}."
    elsif
      @tie += " #{session[:player_name]} has #{session[:money]}."
    end

    
  end

end



#----------------------------------
before do
  @show_hit_or_stay_buttons = true
  @play_again = false
  @error_input = false
  @show_dealer_hit_button = false
  @player_no_bust = true
end



get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end



get '/new_player' do
  erb :new_player
end



post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb :new_player
  end
    session[:player_name] = params[:player_name]
    session[:money] = 500
    redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:how_much].empty? || params[:how_much].to_i <= 0 || params[:how_much].to_i > session[:money].to_i 
    @error = "Must bet in range of 0 - #{session[:money]}."
    halt erb :bet
  end
  session[:how_much] = params[:how_much]
  redirect '/game'
end



get '/game' do

  session[:turn] = "player"
  cards = ['2','3','4','5','6','7','8','9','10','Jack','Queen','King','Ace']
  suits = ["Hearts", "Spades", "Clubs", "Diamonds"]
  session[:deck] = cards.product(suits).shuffle
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  if culculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} got BlackJack!")
    @show_hit_or_stay_buttons = false
    update_bet_and_message
  end

  erb :game
end



post '/game/player/hit' do
   session[:player_cards] << session[:deck].pop
   player_total = culculate_total(session[:player_cards])
    if player_total == BLACKJACK_AMOUNT
      winner!("#{session[:player_name]} got BlackJack!")
      @show_hit_or_stay_buttons = false
      update_bet_and_message
    elsif player_total > BLACKJACK_AMOUNT
      loser!("#{session[:player_name]} busted at #{player_total}!")
      @show_hit_or_stay_buttons = false
      @player_no_bust = false
      update_bet_and_message
    end
  erb :game, layout: false
end



post '/game/player/stay' do
  @winner = "#{session[:player_name]} decided to stay."
  redirect '/game/dealer'
end



get '/game/dealer' do
  session[:turn] = 'dealer'
  @show_hit_or_stay_buttons = false
  dealer_total = culculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit Blackjack.") 
    update_bet_and_message
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
    update_bet_and_message
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  @show_hit_or_stay_buttons = false
  erb :game, layout: false
end



post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end



get '/game/compare' do
  player_total = culculate_total(session[:player_cards])
  dealer_total = culculate_total(session[:dealer_cards])
  @show_hit_or_stay_buttons = false
  if player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
    update_bet_and_message
  elsif player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
    update_bet_and_message 
  else
    tie!("Both got #{player_total}! #{session[:player_name]} now has #{session[:money]}") 

  end
  erb :game, layout: false
end



get '/game_over' do
  if session[:money].to_i > 0
    @title = "You've amassed a final amount of $#{session[:money]}!"
    @paragraph = "Now that you've honed your blackjack skills, there's nothing left to do except go to Vegas."
    erb :game_over
  else
    @title = "Sorry, you're broke!"
    @paragraph = "the only thing left to do is mortgage the house and try again!"
  end
  erb :game_over
end























