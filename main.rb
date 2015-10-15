# encoding: utf-8

require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'blackjack_helpers'

use Rack::Session::Cookie, key:     'rack.session',
                           path:    '/',
                           secret:  'yachting'

BLACKJACK = 21
DEALER_MIN = 17

# CONTROLLER

get '/' do
  @error = error_message(params[:error]) if params[:error]
  erb :index
end

post '/start' do
  redirect '/?error=empty_name' if params[:player_name].empty?
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
  redirect '/bet?error=bet_too_large' if params[:bet].to_i > session[:bankroll]
  redirect '/bet?error=bet_negative' if params[:bet].to_i <= 0
  session[:bet] = params[:bet].to_i
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
  redirect '/dealer' if player_points == BLACKJACK
  redirect '/player'
end

get '/dealer' do
  halt erb(:game, locals: { move: :dealer }) if dealer_points < DEALER_MIN
  redirect '/end_round'
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
