module Spree::UserDecorator

  validates :loyalty_points_balance, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  has_many :loyalty_points_transactions
  has_many :loyalty_points_debit_transactions
  has_many :loyalty_points_credit_transactions

  def self.included(base)
    base.has_many :store_credits, -> { includes(:credit_type) }
    base.has_many :store_credit_events, through: :store_credits

    base.prepend(InstanceMethods)
  end

  module InstanceMethods
    def total_available_store_credit
      store_credits.reload.to_a.sum{ |credit| credit.amount_remaining }
    end
  end

  def loyalty_points_balance_sufficient?
    loyalty_points_balance >= Spree::Config.loyalty_points_redeeming_balance
  end

  def has_sufficient_loyalty_points?(order)
    loyalty_points_equivalent_currency >= order.total
  end

  def loyalty_points_equivalent_currency
    loyalty_points_balance * Spree::Config.loyalty_points_conversion_rate
  end
end

Spree::User.include(Spree::UserDecorator)
