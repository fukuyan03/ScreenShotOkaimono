class ItemsController < ApplicationController
  before_action :set_shop
  before_action :set_item, only: %i[show edit update destroy]

  def index
    @items = @shop.items
  end

  def new
    @item = @shop.items.build
    @shop_candidates = []
  end

  def show; end

  def analyze
    @item = @shop.items.build(item_attributes)
    @shop_candidates = []

    if invalid_uploaded_image?
      flash.now[:alert] = "PNG、JPEG、WebP形式かつ10MB以下の画像を選択してください"
      return render :new, status: :unprocessable_entity
    end

    image_blob = uploaded_image_blob

    unless image_blob.present?
      flash.now[:alert] = "画像を選択してください"
      return render :new, status: :unprocessable_entity
    end

    unless analyzable_image?(image_blob)
      flash.now[:alert] = "PNG、JPEG、WebP形式かつ10MB以下の画像を選択してください"
      return render :new, status: :unprocessable_entity
    end

    result = ItemImageAnalyzer.call(image: image_blob)

    @shop_candidates = result[:shop_candidates] || []
    analysis_attributes = result.except(:shop_candidates).compact_blank

    if analysis_attributes.blank?
      flash.now[:alert] = "AI解析できましたが、商品情報を抽出できませんでした"
      return render :new, status: :unprocessable_entity
    end

    @item.assign_attributes(analysis_attributes)

    flash.now[:notice] = "AI解析結果を反映しました"
    render :new, status: :unprocessable_entity
  rescue ItemImageAnalyzer::AnalysisError => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
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

  def analyzable_image?(blob)
    blob.content_type.in?(%w[image/png image/jpeg image/webp]) && blob.byte_size <= 10.megabytes
  end
end
