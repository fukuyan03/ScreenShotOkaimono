class ShopsController < ApplicationController
  def index
    @shops = current_user.shops.includes(:items)
    @want_items = Item.joins(:shop)
                      .where(shops: { user_id: current_user.id })
                      .want
                      .limit(10)
    @shop_card_items = Item.joins(:shop)
                           .where(shops: { user_id: current_user.id }, status: %i[want interest])
                           .order(:status, :created_at)
                           .group_by(&:shop_id)
  end

  def show
    @shop = current_user.shops.find(params[:id])
    @items = @shop.items.order(:status, :created_at)
    @items_by_status = @items.group_by(&:status)
  end

  def new
    @shop = Shop.new
  end

  def create
    @shop = current_user.shops.build(shop_params)

    if @shop.save
      redirect_to shops_path, notice: t("flash.shop.create.success")
    else
      flash.now[:alert] = t("flash.shop.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @shop = current_user.shops.find(params[:id])
  end

  def update
    @shop = current_user.shops.find(params[:id])

    if @shop.update(shop_params)
      redirect_to shops_path, notice: t("flash.shop.update.success")
    else
      flash.now[:alert] = t("flash.shop.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @shop = current_user.shops.find(params[:id])
    @shop.destroy
    redirect_to shops_path, notice: t("flash.shop.destroy.success")
  end

  private

  def shop_params
    params.require(:shop).permit(:name)
  end
end
