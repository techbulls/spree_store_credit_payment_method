Deface::Override.new(
  virtual_path: 'spree/checkout/_summary',
  name: 'add_store_credit',
  insert_before: '[data-hook="order_total"]',
  partial: 'spree/checkout/store_credits_sidebar'
)

Deface::Override.new(
  virtual_path: 'spree/checkout/_summary',
  name: 'replace_order_total',
  replace_contents: '[data-hook="order_total"]',
  partial: 'spree/checkout/balance_due_sidebar',
)
