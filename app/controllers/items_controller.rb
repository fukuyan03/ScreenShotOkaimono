class ItemsController < ApplicationController
  def index
    @shop = current_user.shops.find(params[:shop_id])
    @items = @shop.items
  end
end
