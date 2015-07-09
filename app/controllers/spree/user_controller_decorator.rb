Spree::UserRegistrationsController.class_eval do
  after_filter :credit_loyalty_points_to_referral_user, :only => :create
  
  def credit_loyalty_points_to_referral_user
  	referred_records = Spree::ReferredRecord.where(:user_id => @user.id)
  	referred_records.each do |referred_record|
  		if !referred_record.loyalty_points_awarded
	  		referral_user_id = referred_record.referral_id
	  		referral_user = Spree::User.find_by(:id => referral_user_id)
	  		referral_user.loyalty_points_balance += Spree::Config.loyalty_points_per_referred_user
			referral_user.save!
	  		referred_record.loyalty_points_awarded = true
	  		referred_record.save!
  		end
  	end	
  end
end
