class ItemsController < ApplicationController
  before_action :set_shop
  before_action :set_item, only: %i[show edit update destroy update_status]

  def index
    @items = @shop.items.order(:status, :created_at)
    @items_by_status = @items.group_by(&:status)
  end

  def new
    analyzed_attributes = session.delete(:analyzed_item_attributes) || {}

    @item = @shop.items.build(analyzed_attributes)
    @shop_candidates = session.delete(:shop_candidates) || []
  end

  def show; end

  def analyze
    @item = @shop.items.build(item_attributes)

    if invalid_uploaded_image?
      flash[:alert] = "PNG、JPEG、WebP形式かつ10MB以下の画像を選択してください"
      return redirect_to new_shop_item_path(@shop)
    end

    image_blob = uploaded_image_blob

    unless image_blob.present?
      flash[:alert] = "画像を選択してください"
      return redirect_to new_shop_item_path(@shop)
    end

    result = analyze_image(image_blob)
    return if performed?

    session[:analyzed_item_attributes] = result.except(:shop_candidates)
    session[:shop_candidates] = result[:shop_candidates] || []

    flash[:notice] = "AI解析結果を反映しました"
    redirect_to new_shop_item_path(@shop)

  ensure
    image_blob&.purge if image_blob&.persisted?
  end

  def create
    @item = @shop.items.build(item_attributes)

    if @item.save
      redirect_to shop_items_path(@shop), notice: t("flash.item.create.success")
    else
      @shop_candidates = []
      flash.now[:alert] = t("flash.item.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @shop_candidates = []
  end

  def update
    if @item.update(item_attributes)
      redirect_to shop_items_path(@shop), notice: t("flash.item.update.success")
    else
      @shop_candidates = []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy!
    redirect_to shop_items_path(@shop), notice: t("flash.item.destroy.success"), status: :see_other
  end

  def update_status
    if @item.update(status: status_update_params[:status])
      redirect_back fallback_location: shops_path, notice: t("flash.item.update.success")
    else
      redirect_back fallback_location: shops_path, alert: t("flash.item.update.failure")
    end
  end

  private

  def set_shop
    @shop = current_user.shops.find(params[:shop_id])
  end

  def set_item
    @item = @shop.items.find(params[:id])
  end

  def item_attributes
    params.require(:item).permit(:name, :brand, :price, :summary, :source_platform, :source_author_name, :status)
  end

  def status_update_params
    params.require(:item).permit(:status)
  end

  def uploaded_image
    params.dig(:item, :image)
  end

  def uploaded_image_blob
    return if uploaded_image.blank?
    return if uploaded_image.is_a?(String)

    uploaded_image.tempfile.rewind
    ActiveStorage::Blob.create_and_upload!(
      io: uploaded_image.tempfile,
      filename: uploaded_image.original_filename,
      content_type: uploaded_image.content_type
    )
  end

  def invalid_uploaded_image?
    return false if uploaded_image.blank? || uploaded_image.is_a?(String)

    !uploaded_image.content_type.in?(%w[image/png image/jpeg image/webp]) || uploaded_image.size > 10.megabytes
  end

  def analyze_image(image_blob)
    result = ItemImageAnalyzer.call(image: image_blob)

    if result.except(:shop_candidates).compact_blank.blank?
      flash[:alert] = "AI解析できましたが、商品情報を抽出できませんでした"
      redirect_to new_shop_item_path(@shop)
      return
    end

    result
  rescue ItemImageAnalyzer::AnalysisError => e
    flash[:alert] = e.message
    redirect_to new_shop_item_path(@shop)
  end
end
