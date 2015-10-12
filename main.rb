# encoding: utf-8

require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'blackjack_helpers'

use Rack::Session::Cookie, key:     'rack.session',
                           path:    '/',
                           secret:  'yachting'

# CONTROLLER

get '/' do
  @error = error_message(params[:error]) if params[:error]
  erb :index
end

post '/start' do
  unless params[:player_name] && !params[:player_name].empty?
    redirect '/?error=empty_name'
  end
  session[:player_name] = params[:player_name].capitalize
  session[:bankroll] = params[:bankroll].to_i || 1000
  redirect '/bet'
end

get '/start' do
  session[:deck] = build_deck # reset deck
  redirect '/bet'
end

get '/bet' do
  redirect '/?error=bankrupt' if session[:bankroll] <= 0
  @error = error_message(params[:error]) if params[:error]
  erb :bet
end

post '/accept_bet' do
  session[:bet] = params[:bet].to_i
  redirect '/bet?error=bet_too_large' if session[:bet] > session[:bankroll]
  redirect '/bet?error=bet_negative' if session[:bet] <= 0
  session[:bankroll] -= session[:bet]
  session[:round] = :open
  reset_hands
  redirect '/end_round' if player_blackjack?
  redirect '/player'
end

get '/player' do
  erb :game, locals: { move: :player }
end

get '/player/hit' do
  session[:player_hand] << deal
  redirect '/end_round' if player_busted?
  redirect '/dealer' if player_points == 21
  redirect '/player'
end

get '/dealer' do
  redirect '/dealer/show' if dealer_points < 17
  redirect '/end_round'
end

get '/dealer/show' do
  erb :game, locals: { move: :dealer }
end

get '/dealer/hit' do
  session[:dealer_hand] << deal
  redirect '/dealer'
end

get '/end_round' do
  pay_winnings if session[:round] == :open
  erb :game, locals: { move: :end }
end

get '/end_game' do
  erb :end
end
