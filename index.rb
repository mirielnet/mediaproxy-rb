# app.rb

require 'sinatra'
require 'mini_magick'
require 'open-uri'

# /proxy/avatar.webp ルート
get '/proxy/avatar.webp' do
  url = params[:url]
  avatar = true

  unless url
    status 400
    return 'URL parameter is required'
  end

  begin
    io = URI.open(url)
    image = MiniMagick::Image.read(io)

    # avatar パラメータが指定されている場合は、WebP 形式で出力
    if avatar
      content_type 'image/webp'
      image.format 'webp'
    else
      content_type 'image/jpeg'
    end

    # 画像の圧縮
    image.combine_options do |c|
      c.quality '80%' # 画像の品質を指定（0〜100%）
      c.resize '360x360' # 画像のリサイズ
    end

    image.to_blob
  rescue Errno::ECONNREFUSED, OpenURI::HTTPError, Errno::ENOENT => e
    status 500
    body "An error occurred: #{e.class} - #{e.message}"
  end
end

# /proxy ルート
get '/proxy' do
  url = params[:url]
  origin = params[:origin]
  emoji = params[:emoji]
  avatar = params[:avatar]
  static = params[:static]
  preview = params[:preview]

  # /proxy/avatar.webp?url=URL の形式もサポートする
  if params[:path]&.include?('avatar.webp')
    avatar = true
  end

  unless url
    status 400
    return 'URL parameter is required'
  end

  begin
    io = URI.open(url)

    image = MiniMagick::Image.read(io)

    # パラメータに応じて処理を行う
    if origin
      # 外部メディアプロキシへのリダイレクトを行わない
      content_type image.mime_type
      return image.to_blob
    elsif emoji
      # 高さ128px以下のwebpが応答される
      image.resize 'x128'
    elsif avatar
      # 高さ320px以下のwebpが応答される
      image.resize 'x320'
    elsif static
      # アニメーション画像では最初のフレームのみの静止画のwebpが応答される
      image.pages 'x1'
    elsif preview
      # 幅200px・高さ200pxに収まるサイズ以下のwebpが応答される
      image.resize '200x200>'
    else
      # デフォルトの処理
      image.resize '360x360'
    end

    # avatarパラメータが指定されている場合は、webpで出力
    if avatar
      content_type 'image/webp'
      image.format 'webp'
    else
      content_type 'image/jpeg'
      image.quality '80%'
    end

    image.to_blob

  rescue Errno::ECONNREFUSED, OpenURI::HTTPError, Errno::ENOENT => e
    status 500
    body "An error occurred: #{e.class} - #{e.message}"
  end
end

# Sinatraアプリケーションを実行するためのコード
if __FILE__ == $0
  set :bind, '0.0.0.0'
  set :port, 4567
end
