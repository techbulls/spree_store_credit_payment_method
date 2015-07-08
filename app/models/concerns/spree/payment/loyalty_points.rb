require 'active_support/concern'

module Spree
  class Payment
    module LoyaltyPoints
      extend ActiveSupport::Concern

      included do
        scope :by_loyalty_points, -> { joins(:payment_method).readonly(false).where(:spree_payment_methods => { type: 'Spree::PaymentMethod::LoyaltyPoints'}) }
      end

        module ClassMethods

          def any_with_loyalty_points?
            by_loyalty_points.size != 0
          end
        end

      private

        def redeem_loyalty_points
          loyalty_points_redeemed = loyalty_points_for(amount, 'redeem')
          order.create_debit_transaction(loyalty_points_redeemed)
        end

        def return_loyalty_points
          loyalty_points_redeemed = loyalty_points_for(amount, 'redeem')
          order.create_credit_transaction(loyalty_points_redeemed)
        end

        def by_loyalty_points?
          payment_method.type == "Spree::PaymentMethod::LoyaltyPoints"
        end

        def redeemable_loyalty_points_balance?
          order.user.loyalty_points_balance >= Spree::Config.loyalty_points_redeeming_balance
        end

        def redeemable_user_balance
          unless redeemable_loyalty_points_balance?
            min_balance = Spree::Config.loyalty_points_redeeming_balance
            errors.add :loyalty_points_balance, "should be atleast #{ min_balance.to_s + " " + "point".pluralize(min_balance) } for redeeming Loyalty Points"
          end
        end

    end
  end
end