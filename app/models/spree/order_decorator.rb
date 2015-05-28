module SpreeStoreCredits::OrderDecorator
  def self.included(base)
    # Address and Complete are required to show store credit is covering order
    # and get the amount of store credit correct
    base.state_machine.before_transition to: [:address, :delivery, :payment, :complete], do: :charge_as_much_store_credit_as_possible
    base.state_machine.before_transition to: :confirm, do: :add_store_credit_payments
    base.state_machine.after_transition to: :confirm, do: :create_gift_cards
    base.state_machine.after_transition to: :complete, do: :capture_store_credit

    base.prepend(InstanceMethods)
  end

  module InstanceMethods
    def create_gift_cards
      line_items.each do |item|
        item.quantity.times do
          Spree::VirtualGiftCard.create!(amount: item.price, currency: item.currency, purchaser: user, line_item: item) if item.gift_card?
        end
      end
    end

    def charge_as_much_store_credit_as_possible
      payments.where(state: 'invalid').collect(&:destroy!)
      payments.store_credits.where(state: 'checkout').map(&:invalidate!)

      remaining_total = outstanding_balance

      if user && user.store_credits.any?
        payment_methods = Spree::PaymentMethod.where(type: 'Spree::PaymentMethod::StoreCredit', environment: Rails.env)
        raise "Too many store credit payment methods found" if payment_methods.length > 1

        payment_method = payment_methods[0]
        raise "Store credit payment method could not be found" unless payment_method

        user.store_credits.order_by_priority.each do |credit|
          break if remaining_total.zero?
          next if credit.amount_remaining.zero?

          amount_to_take = store_credit_amount(credit, remaining_total)
          create_store_credit_payment(payment_method, credit, amount_to_take)
          remaining_total -= amount_to_take
        end
      end

      remaining_total
    end

    def add_store_credit_payments

      remaining_total = charge_as_much_store_credit_as_possible

      reconcile_with_credit_card(existing_credit_card_payment, remaining_total)

      if payments.valid.sum(:amount) != total
        errors.add(:base, Spree.t("store_credits.errors.unable_to_fund")) and return false
      end
    end

    def covered_by_store_credit?
      return false unless user
      user.total_available_store_credit >= total
    end
    alias_method :covered_by_store_credit, :covered_by_store_credit?

    def payment_required?
      !covered_by_store_credit?
    end

    def total_available_store_credit
      return 0.0 unless user
      user.total_available_store_credit
    end

    def order_total_after_store_credit
      total - total_applicable_store_credit
    end

    def using_store_credit?
      total_applicable_store_credit > 0
    end

    def total_applicable_store_credit
      if confirm? || complete?
        payments.store_credits.valid.sum(:amount)
      else
        [total, (user.try(:total_available_store_credit) || 0.0)].min
      end
    end

    def display_total_applicable_store_credit
      Spree::Money.new(-total_applicable_store_credit, { currency: currency })
    end

    def display_order_total_after_store_credit
      Spree::Money.new(order_total_after_store_credit, { currency: currency })
    end

    def display_total_available_store_credit
      Spree::Money.new(total_available_store_credit, { currency: currency })
    end

    def display_store_credit_remaining_after_capture
      Spree::Money.new(total_available_store_credit - total_applicable_store_credit, { currency: currency })
    end

    private

    def after_cancel
      super

      # Free up authorized store credits
      payments.store_credits.pending.each { |payment| payment.void! }

      # payment_state has to be updated because after_cancel on
      # super does an update_column on the payment_state to set
      # it to 'credit_owed' but that is not correct if the
      # payments are captured store credits that get totally refunded

      reload
      updater.update_payment_state
      updater.persist_totals
    end

    def existing_credit_card_payment
      other_payments = payments.valid.where.not(state: 'completed').not_store_credits
      raise "Found #{other_payments.size} payments and only expected 1" if other_payments.size > 1
      other_payments.first
    end

    def reconcile_with_credit_card(other_payment, amount)
      return unless other_payment

      if amount.zero?
        other_payment.invalidate! and return
      else
        other_payment.update_attributes!(amount: amount)
      end

      unless other_payment.source.is_a?(Spree::CreditCard)
        raise "Found unexpected payment method. Credit cards are the only other supported payment type"
      end
    end

    def create_store_credit_payment(payment_method, credit, amount)
      payments.create!(source: credit,
                       payment_method: payment_method,
                       amount: amount,
                       state: 'checkout',
                       response_code: credit.generate_authorization_code)
    end

    def store_credit_amount(credit, total)
      [credit.amount_remaining, total].min
    end

    def capture_store_credit
      payments.store_credits.valid.collect(&:capture!)
    end
  end
end

Spree::Order.include SpreeStoreCredits::OrderDecorator
