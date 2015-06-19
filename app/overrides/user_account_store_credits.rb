Deface::Override.new(
  :virtual_path => "spree/users/show",
  :name => "user_account_store_credits",
  :insert_after => "[data-hook='account_my_orders']",
  :partial => "spree/users/store_credits",
  :disabled => false
  )