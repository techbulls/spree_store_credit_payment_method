module SpreeStoreCredits::PaymentDecorator
  def self.included(base)
    base.validates :amount, numericality: { greater_than: 0 }, :if => :by_loyalty_points?
    base.validate :redeemable_user_balance, :if => :by_loyalty_points?
    
    base.scope :state_not, ->(s) { where('state != ?', s) }
    base.delegate :store_credit?, to: :payment_method
    base.scope :store_credits, -> { base.where(source_type: Spree::StoreCredit.to_s) }
    base.scope :not_store_credits, -> { base.where(base.arel_table[:source_type].not_eq(Spree::StoreCredit.to_s).or(base.arel_table[:source_type].eq(nil))) }
    base.after_create :create_eligible_credit_event
    
    fsm = base.state_machines[:state]
    fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :notify_paid_order
    fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :redeem_loyalty_points_into_store_credit
    fsm.after_transition :from => fsm.states.map(&:name) - [:completed], :to => [:completed], :do => :redeem_loyalty_points, :if => :by_loyalty_points?
    fsm.after_transition :from => [:completed], :to => fsm.states.map(&:name) - [:completed] , :do => :return_loyalty_points, :if => :by_loyalty_points?
    
    base.prepend(InstanceMethods)
  end

  module InstanceMethods
    def cancel!
      if store_credit?
        credit!(amount)
      else
        super
      end
    end

  private

    def invalidate_old_payments
      order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
        payment.invalidate!
      end unless by_loyalty_points?
    end

    def redeem_loyalty_points_into_store_credit
      if all_payments_completed?
        #When payment is captured, redeem loyalty points if limit is reached
        order.redeem_loyalty_points_in_store_credit order
      end
    end

    def notify_paid_order
      if all_payments_completed?
        #When payment is captured, award loyalty points to customer.
        order.credit_loyalty_points_to_user_for_current_order order
        order.touch :paid_at
      end
    end

    def all_payments_completed?
      order.payments.state_not('invalid').all? { |payment| payment.completed? }
    end

    def create_eligible_credit_event
      # When cancelling an order, a payment with the negative amount
      # of the payment total is created to refund the customer. That
      # payment has a source of itself (Spree::Payment) no matter the
      # type of payment getting refunded, hence the additional check
      # if the source is a store credit.
      return unless store_credit? && source.is_a?(Spree::StoreCredit)

      # creates the store credit event
      source.update_attributes!({
        action: Spree::StoreCredit::ELIGIBLE_ACTION,
        action_amount: amount,
        action_authorization_code: response_code,
      })
    end

    def invalidate_old_payments
      return if store_credit? # store credits shouldn't invalidate other payment types
      order.payments.with_state('checkout').where("id != ?", self.id).each do |payment|
        payment.invalidate! unless payment.store_credit?
      end
    end
  end
end

Spree::Payment.include SpreeStoreCredits::PaymentDecorator
