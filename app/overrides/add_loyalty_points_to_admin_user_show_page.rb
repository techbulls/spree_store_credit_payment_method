Deface::Override.new(:virtual_path => 'spree/admin/users/_form',
  :name => 'add_loyalty_points_to_admin_user_show_page',
  :insert_after => "[data-hook='admin_user_form_roles']",
  :text => "
  <tr data-hook='loyalty-points'>
    <th><%= Spree.t(:loyalty_points_balance) %></th>
    <td>
      <% if @user.loyalty_points_balance.present? %>
        <%= link_to @user.loyalty_points_balance, spree.admin_user_loyalty_points_path(@user) %>
      <% else %>
        <%= 'No loyalty points yet' %>
      <% end %>
    </td>
  </tr>
  ")
