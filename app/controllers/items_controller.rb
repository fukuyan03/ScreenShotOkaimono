class ItemsController < ApplicationController
  def index
    @shop = current_user.shops.find(params[:shop_id])
    @items = @shop.items
  end

  def new
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.build
  end

  def show
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.find(params[:id])
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

  def edit
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.find(params[:id])
  end

  def update
    @shop = current_user.shops.find(params[:shop_id])
    @item = @shop.items.find(params[:id])

    if @item.update(item_params)
      redirect_to shop_items_path, notice: t("flash.item.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    shop = current_user.shops.find(params[:shop_id])
    item = shop.items.find(params[:id])
    item.destroy!
    redirect_to shop_items_path(shop), notice: t("flash.item.destroy.success"), status: :see_other
  end

  private

  def item_params
    params.require(:item).permit(:name, :brand, :price, :summary, :source_platform, :source_author_name, :status, :image)
  end
end
