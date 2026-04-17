require "base64"
require "json"
require "openai"

class ItemImageAnalyzer
  class AnalysisError < StandardError; end

  PROMPT = <<~TEXT
    SNSの商品スクリーンショットから商品情報を抽出してください。
    必ずJSONのみを返してください。説明文は不要です。

    {
      "name": null,
      "brand": null,
      "price": null,
      "summary": null,
      "source_platform": null,
      "source_author_name": null,
      "shop_candidates": []
    }

    ルール:

    【基本ルール】
    - 画像内に明確な根拠がある情報のみを使用する
    - 不明な値は null
    - JSON以外の文字を一切含めない

    【商品選定ルール】
    - 商品が複数存在する場合は、最も主要な商品を1つだけ抽出する
    - 判断できない場合は、以下の優先順位で選ぶ
      1. 最も大きく表示されている商品
      2. 左側に配置されている商品
      3. テキスト情報が最も多い商品

    【各項目ルール】
    - name は商品名のみを入れる（キャッチコピーは含めない）
    - brand はメーカー・ブランド名のみ（投稿者名と混同しない）
    - price は数値のみ（通貨記号・カンマ・税込表記などは除去）
    - price が複数ある場合は最も代表的な1つ。不明なら null

    【summary（商品特徴）ルール】
    - summary は「商品特徴」として出力する
    - 以下の2つを必ず統合する
      1. 画像内のテキスト（キャッチコピー・説明文・特徴）
      2. 商品の特徴を簡潔にまとめた説明

    - 画像内の有用なテキストはできるだけ残す
    - ただし以下は除外する
      - UI要素（いいね、返信、ボタンなど）
      - 投稿文（キャプション）
      - ハッシュタグ
      - 日付やキャンペーン期限など商品本質でない情報

    - 同じ意味の重複は整理する（コピペ羅列は禁止）
    - 情報を削りすぎず、重要ワードは残す
    - 1〜2文の自然な日本語でまとめる
    - 有用な情報がない場合のみ null

    【SNS情報】
    - source_platform は Instagram, X, TikTok, YouTube, Pinterest など判別できる場合のみ
    - source_author_name は投稿者名・アカウント名

    【shop_candidates】
    - 商品名・ブランドから購入できそうなショップを最大3件まで推測
    - 確信が低い場合は空配列でもよい
  TEXT

  def self.call(image:)
    new(image).call
  end

  def initialize(image)
    @image = image
  end

  def call
    text = request_analysis
    json = JSON.parse(extract_json(text))

    {
      name: json["name"],
      brand: json["brand"],
      price: normalize_price(json["price"]),
      summary: json["summary"],
      source_platform: json["source_platform"],
      source_author_name: json["source_author_name"],
      shop_candidates: Array(json["shop_candidates"]).compact
    }
  rescue JSON::ParserError
    raise AnalysisError, "AI解析結果を読み取れませんでした"
  rescue KeyError
    raise AnalysisError, "OPENAI_API_KEYが設定されていません"
  rescue OpenAI::Errors::APIError => e
    raise AnalysisError, openai_error_message(e)
  end

  private

  attr_reader :image

  def request_analysis
    response = client.responses.create(
      model: "gpt-4.1-mini",
      request_options: { max_retries: 0, timeout: 60.0 },
      input: [
        {
          role: "user",
          content: [
            { type: "input_text", text: PROMPT },
            { type: "input_image", image_url: image_data_url }
          ]
        }
      ]
    )

    response.output_text
  end

  def client
    @client ||= OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
  end

  def image_data_url
    encoded_image = Base64.strict_encode64(image.download)
    "data:#{image.content_type};base64,#{encoded_image}"
  end

  def extract_json(text)
    text.to_s[/\{.*\}/m] || "{}"
  end

  def normalize_price(value)
    return nil if value.blank?

    value.to_s.gsub(/[^\d]/, "").presence&.to_i
  end

  def openai_error_message(error)
    code = error.body.dig(:error, :code) if error.body.respond_to?(:dig)

    if code == "insufficient_quota"
      "OpenAI APIの利用枠または課金設定が不足しています"
    else
      "OpenAI APIでエラーが発生しました"
    end
  end
end
