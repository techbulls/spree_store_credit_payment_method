class AddLoyaltyPointsAwardedToSpreeReferredRecords < ActiveRecord::Migration
  def change
  	add_column :spree_referred_records, :loyalty_points_awarded, :boolean, :default => false
  end
end
