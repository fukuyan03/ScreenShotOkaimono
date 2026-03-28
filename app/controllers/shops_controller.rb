class ShopsController < ApplicationController
  def index
    @shop = current_user.shops
  end
end
