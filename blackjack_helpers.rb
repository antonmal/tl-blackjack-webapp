# encoding: utf-8

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

  def get_card_points(card)
    get_rank_points[card[0..-2]]
  end

  def get_suits
    { "♠" => "spades", "♥" => "hearts", "♦" => "diamonds", "♣" => "clubs" }
  end

  def image(card)
    "/images/cards/#{get_suits[card[-1]]}_#{get_ranks[card[0..-2]]}.jpg"
  end

  def get_points(hand)
    # Calculate the sum of all card values, aces as 11s
    points = hand.map {|card| get_card_points(card)}.inject(:+)

    # If the sum is greater than 21 (busted), re-calculate one or more aces as 1s
    aces = hand.count {|card| card[0..-2] == "A"}.times do
      break if points <= 21
      points -= 10
    end

    points
  end

  def player_points
    get_points(session[:player_hand])
  end

  def dealer_points
    get_points(session[:dealer_hand])
  end

  def player_blackjack?
    player_points == 21 && session[:player_hand].size == 2
  end

  def player_busted?
    player_points > 21
  end

  def dealer_blackjack?
    dealer_points == 21 && session[:dealer_hand].size == 2
  end

  def dealer_busted?
    dealer_points > 21
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
    if !session[:deck] || session[:deck].empty?
      session[:deck] = build_deck
    end
    session[:deck].pop
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

  def player
    session[:player_name]
  end

  def result_heading
    case won?
    when 'tie'  then "It's a push."
    when 'lost' then "#{player} lost!!!"
    else "#{player} won!!!"
    end
  end

  def result_body
    case result
    when 'tie busted'       then "Both busted"
    when 'tie blackjack'    then "Both have blackjack."
    when 'tie points'       then "Both have equal number of points."
    when 'player won'       then "You have more points."
    when 'player blackjack' then "You got blackjack."
    when 'dealer busted'    then "Dealer busted."
    when 'player busted'    then "You busted."
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
    session[:result] =  case won?
                        when 'tie'        then  0
                        when 'blackjack'  then  session[:bet]*1.5
                        when 'won'        then  session[:bet]
                        when 'lost'       then -session[:bet]
                        end

    session[:bankroll] = session[:bankroll] + session[:bet] + session[:result]
    session[:round] = :closed
  end

  def round_result
    case won?
    when 'tie'                then "You got your bet back."
    when 'blackjack', 'won'   then "You won:  " + tagged("$#{session[:result] + session[:bet]}", 'success')
    else "Your lost:  " + tagged("$#{-session[:result]}", 'danger')
    end
  end

  def tagged(str, color = 'default')
    "<span class=\"label label-#{color} label-lg\">#{str}</span>"
  end

  def error_message(error)
    messages = {
      bet_too_large: "Bet cannot be higher than $#{session[:bankroll]} (your bankroll).",
      empty_name: "Please, enter a name.",
      bet_negative: "Bet must be greater than zero.",
      bankrupt: "You lost all you money and cannot bet anymore. All you can do is start over."
    }
    messages[error.to_sym] || error
  end

end # helpers