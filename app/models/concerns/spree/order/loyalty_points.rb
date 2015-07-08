require 'active_support/concern'

module Spree
  class Order
    module LoyaltyPoints
      extend ActiveSupport::Concern

      def loyalty_points_total
        loyalty_points_credit_transactions.sum(:loyalty_points) - loyalty_points_debit_transactions.sum(:loyalty_points)
      end

      def award_loyalty_points
        loyalty_points_earned = loyalty_points_for(item_total)
        if !loyalty_points_used?
          create_credit_transaction(loyalty_points_earned)
        end
      end

      def award_loyalty_points_into_store_credit
        loyalty_points_earned = loyalty_points_for(item_total)
        user.loyalty_points_balance = user.loyalty_points_balance + loyalty_points_earned
        user.save!
      end

      def loyalty_points_awarded?
        loyalty_points_credit_transactions.count > 0
      end

      def loyalty_points_used?
        payments.any_with_loyalty_points?
      end

      module ClassMethods
        
        def credit_loyalty_points_to_user
          points_award_period = Spree::Config.loyalty_points_award_period
          uncredited_orders = Spree::Order.with_uncredited_loyalty_points(points_award_period)
          uncredited_orders.each do |order|
            order.award_loyalty_points
          end
        end

      end

      def credit_loyalty_points_to_user_for_current_order(order)
        order.award_loyalty_points_into_store_credit
      end

      def redeem_loyalty_points_in_store_credit(order)
        unless check_redeemable_loyalty_points_balance?(order)
          min_balance = Spree::Config.loyalty_points_redeeming_balance
          #errors.add :loyalty_points_balance, "should be atleast #{ min_balance.to_s + " " + "point".pluralize(min_balance) } for redeeming Loyalty Points"
        else
          loyalty_points_count = order.user.loyalty_points_balance
          mininum_loyalty_points_to_redeem = Spree::Config.loyalty_points_redeeming_balance
          amount = mininum_loyalty_points_to_redeem * Spree::Config.loyalty_points_conversion_rate

          if redeem(order.user, amount)  
            new_loyalty_points_balance = loyalty_points_count - mininum_loyalty_points_to_redeem
            user.loyalty_points_balance = new_loyalty_points_balance
            user.save!
          end
        end
      end

      def redeem(redeemer, amount)
        store_credit_type = Spree::StoreCreditType.find_by(:name => "Non-expiring")
        store_credit_category = Spree::StoreCreditCategory.first
        store_credit = Spree::StoreCredit.new({
          amount: amount,
          currency: currency,
          memo: "Loyalty Points",
          user: redeemer,
          created_by: redeemer,
          type_id: store_credit_type.id,
          category_id: store_credit_category.id,
        })
        store_credit.save!
      end

      def check_redeemable_loyalty_points_balance?(order)
        order.user.loyalty_points_balance >= Spree::Config.loyalty_points_redeeming_balance
      end
      
      def create_credit_transaction(points)
        user.loyalty_points_credit_transactions.create(source: self, loyalty_points: points)
      end

      def create_debit_transaction(points)
        user.loyalty_points_debit_transactions.create(source: self, loyalty_points: points)
      end

      private

        def complete_loyalty_points_payments
          payments.by_loyalty_points.with_state('checkout').each { |payment| payment.complete! }
        end

    end
  end
end