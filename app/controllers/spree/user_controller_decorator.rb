Spree::UserRegistrationsController.class_eval do
  after_filter :after_create, :only => :create
  def after_create
  	puts "********************** in after_create method"
  	referred_records = Spree::ReferredRecord.where(:user_id => current_user.id)
  	referred_records.each do |referred_record|
  		puts "INSIDE LOOP"
  		referral_user_id = referred_record.referral_id
  		referral_user = Spree::User.find_by(:id => referral_user_id)
  		referral_user.loyalty_points_balance = referral_user.loyalty_points_balance + Spree::Config.loyalty_points_per_referred_user
  		referred_record.loyalty_points_awarded = true
  		referred_record.save!
  	end	
  end
end
