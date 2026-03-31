class ItemsController < ApplicationController
  def index
    @shop = current_user.shops.find(params[:shop_id])
    @items = @shop.items
  end

  def new
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.build
  end

  def create
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.build(item_params)

    if @item.save
      redirect_to shop_items_path(@shop), notice: t("flash.item.create.success")
    else
      flash.now[:alert] = t("flash.item.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def item_params
    params.require(:item).permit(:name, :brand, :price, :sammary, :source_platform, :source_author_name, :status)
  end
end
