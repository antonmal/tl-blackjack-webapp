require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'sailing' 

# HELPERS

helpers do

  def get_ranks
    ranks = {}
    ('2'..'10').each { |num_str| ranks[num_str] = num_str }
    ranks.merge!({ "J" => "jack", "Q" => "queen", "K" => "king", "A" => "ace" })
  end

  def get_rank_points
    rank_points = {}
    (2..10).each { |num| rank_points[num.to_s] = num }
    rank_points.merge!({ "J" => 10, "Q" => 10, "K" => 10, "A" => 11 })
  end

  def get_suits
    { "♠" => "spades", "♥" => "hearts", "♦" => "diamonds", "♣" => "clubs" }
  end

  def image(card)
    "/images/cards/#{get_suits[card[-1]]}_#{get_ranks[card[0..-2]]}.jpg"
  end

  def get_points(hand)
    # Calculate the sum of all card values, aces as 11s
    points = hand.map { |card| get_card_points(card) }.inject(:+)

    # If the sum is greater than 21 (busted), re-calculate one or more aces as 1s
    if points > 21
      aces = hand.count { |card| card[0..-2] == "A" }
      aces.times do
        points -= 10
        break if points <= 21
      end
    end
    points
  end

  def player_points
    get_points(session[:player_hand])
  end

  def dealer_points
    get_points(session[:dealer_hand])
  end

  def get_card_points(card)
    get_rank_points[card[0..-2]]
  end

  def build_deck
    new_deck = []
    2.times do
      get_ranks.keys.each do |rank|
        get_suits.keys.each { |suit| new_deck.push "#{rank}#{suit}" }
      end
    end
    new_deck.shuffle!
  end

  def deal
    session[:deck] ||= build_deck
    build_deck if session[:deck].empty?
    session[:deck].pop
  end

  def player_blackjack?
    player_points == 21 && session[:player_hand].size == 2
  end

  def dealer_blackjack?
    dealer_points == 21 && session[:dealer_hand].size == 2
  end

  def result
    player = player_points
    dealer = dealer_points

    if player > 21
      dealer > 21 ? "tie busted" : "player busted"
    elsif dealer > 21
      player > 21 ? "tie busted" : "dealer busted"
    elsif player_blackjack?
      dealer_blackjack? ? "tie blackjack" : "player blackjack"
    elsif dealer_blackjack?
      player_blackjack? ? "tie blackjack" : "dealer blackjack"
    elsif player == dealer
      "tie points"
    else
      player > dealer ? "player won" : "dealer won"
    end
  end

  def won?
    case result
    when 'tie busted', 'tie blackjack', 'tie points'        then "tie"
    when 'player blackjack'                                 then "blackjack"
    when 'player won', 'dealer busted'                      then "won"
    when 'player busted', 'dealer blackjack', 'dealer won'  then "lost"
    end
  end

  def result_heading
    case won?
    when 'tie'  then "It's a push."
    when 'lost' then "#{player} lost!!!"
    else "#{player} won!!!"
    end
  end

  def player
    session[:player_name]
  end

  def result_body
    case result
    when 'tie busted'       then "Both busted"
    when 'tie blackjack'    then "Both have blackjack."
    when 'tie points'       then "Both have equal number of points."
    when 'player won'       then "#{player} has more points."
    when 'player blackjack' then "#{player} has blackjack."
    when 'dealer busted'    then "Dealer busted."
    when 'player busted'    then "#{player} busted."
    when 'dealer blackjack' then "Dealer has blackjack."
    when 'dealer won'       then "Dealer has more points"
    end
  end

  def result_color
    case won?
    when 'tie'  then "warning"
    when 'lost' then "danger"
    else "success" end
  end

  def reset_hands
    session[:player_hand], session[:dealer_hand] = [], []
    2.times do
      session[:player_hand] << deal
      session[:dealer_hand] << deal
    end
  end

  def pay_winnings
    case won?
    when 'tie'        then session[:bankroll] += session[:bet]
    when 'blackjack'  then session[:bankroll] += session[:bet]*2.5
    when 'won'        then session[:bankroll] += session[:bet]*2
    end
    session[:round] = :closed
  end

  def error_message(error)
    messages = {
      bet_too_large: "Bet cannot be higher than $#{session[:bankroll]} (your bankroll)."
    }
    messages[error.to_sym] || error
  end

end # helpers


# CONTROLLER

get '/' do
  erb :index
end

post '/start' do
  session[:player_name] = params[:player_name].capitalize || "Mr.Incognito"
  session[:bankroll] = params[:bankroll].to_i || 1000
  redirect '/bet'
end

get '/start' do
  session[:deck] = build_deck # reset deck
  redirect '/bet'
end

get '/bet' do
  @error = error_message(params[:error]) if params[:error]
  erb :bet
end

post '/accept_bet' do
  session[:bet] = params[:bet].to_i
  redirect '/bet?error=bet_too_large' if session[:bet] > session[:bankroll]
  session[:bankroll] -= session[:bet]
  session[:round] = :open
  reset_hands
  redirect '/player'
end

get '/player' do
  erb :game, locals: { :move => :player }
end

get '/player/hit' do
  session[:player_hand] << deal
  redirect '/dealer' if player_points >= 21
  redirect '/player'
end

get '/dealer' do
  redirect '/dealer/show' if dealer_points < 17
  redirect '/end_round'
end

get '/dealer/show' do
  erb :game, locals: { :move => :dealer }
end

get '/dealer/hit' do
  session[:dealer_hand] << deal
  redirect '/dealer'
end

get '/end_round' do
  pay_winnings if session[:round] == :open
  erb :game, locals: { :move => :end }
end

get '/end_game' do
  erb :end
end
