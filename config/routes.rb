Rails.application.routes.draw do

  root 'demo#participation'

  get '/stake',          to: 'demo#stake'
  get '/reputation',     to: 'demo#reputation'
  get '/participation',  to: 'demo#participation'
  get '/showcase',       to: 'demo#showcase' 

  get 'participants',      to: 'contributors#index'
  get 'participants/:id',  to: 'contributors#show'

  get 'cat/:id',    to: 'categories#show'
end
