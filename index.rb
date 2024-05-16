# app.rb

require 'sinatra'
require 'mini_magick'
require 'open-uri'

# Misskey Media Proxy
get '/proxy' do
  url = params[:url]

  unless url
    status 400
    return 'URL parameter is required'
  end

  begin
    io = URI.open(url)

    image = MiniMagick::Image.read(io)

    # 画像の圧縮
    image.combine_options do |c|
      c.quality '80%' # 画像の品質を指定（0〜100%）
      c.resize '360x360' # 画像のリサイズ
    end

    content_type 'image/jpeg'
    image.to_blob
  rescue => e
    status 500
    body "An error occurred: #{e.message}"
  end
end
