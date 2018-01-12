namespace :utility do
  task :checkpoint => :environment do
    Contributor.all.each do |con|
      con.update_attribute(:checkpoint, con.score)
    end
  end
  
  task :distribute => :environment do

    # Prepare information for all transfers
    api = Radiator::Api.new
    total = Contributor.all.sum{|x| x.score - x.checkpoint } 
    active_key = Permission.find_by_name('qfilter-active-key').key
    total_cash = qfilter.sbd_balance.to_f

    # Perform each transfer 
    Contributor.all.each do |con|

      # Calculate allocated amount
      proportion = (con.point - con.checkpoint) / total.to_f
      money = proportion * total_cash

      transaction = Radiator::Transaction.new(wif: active_key)
      transfer = {
        type: :transfer,
        from: 'qfilter',
        to: con.name,
        amount: money.round(3).to_s + ' SBD',
        memo: 'qfilter monthly distribution reward'
      }
 
      # Process Transaction
      tx.operations << transfer
      tx.process(true)

    end
  end
end