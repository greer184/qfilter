Rails.application.routes.draw do
  
  root 'demo#stake'

  get '/stake',          to: 'demo#stake'
  get '/reputation',     to: 'demo#reputation'
  get '/participation',   to: 'demo#participation'

  get 'contributors/show'
end
