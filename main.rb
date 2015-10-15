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
DEFAULT_BANKROLL = 1000
DEFAULT_BET = 100

# CONTROLLER

get '/' do
  @error = error_message(params[:error]) if params[:error]
  erb :index
end

post '/start' do
  redirect '/?error=empty_name' if params[:player_name].empty?
  session[:player_name] = params[:player_name].capitalize
  session[:bankroll] = params[:bankroll].to_i || DEFAULT_BANKROLL
  session[:bet] = nil
  redirect '/bet'
end

get '/start' do
  session[:deck] = build_deck # reset deck
  session[:bet] = nil
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
  halt erb(:game, locals: { move: :player }, layout: false) if request.xhr?
  erb :game, locals: { move: :player }
end

get '/dealer' do
  if dealer_points < DEALER_MIN
    halt erb(:game, locals: { move: :dealer }, layout: false) if request.xhr?
    halt erb(:game, locals: { move: :dealer })
  end
  redirect '/end_round'
end

get '/dealer/hit' do
  session[:dealer_hand] << deal
  redirect '/dealer'
end

get '/end_round' do
  pay_winnings if session[:round] == :open
  halt erb(:game, locals: { move: :end }, layout: false) if request.xhr?
  erb :game, locals: { move: :end }
end

get '/end_game' do
  erb :end
end
