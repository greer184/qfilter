Rails.application.routes.draw do
  root 'demo#stake'
  get '/stake',          to: 'demo#stake'
  get '/reputation',     to: 'demo#reputation'
  get '/contribution',   to: 'demo#contribution'
end
