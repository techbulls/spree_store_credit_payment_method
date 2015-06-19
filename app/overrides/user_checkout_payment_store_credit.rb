Deface::Override.new(
  virtual_path: 'spree/checkout/_payment',
  name: 'insert_store_credit_instructions',
  insert_before: 'erb:contains("@payment_sources.present?")',
  partial: 'spree/checkout/payment_through_store_credit'
)

