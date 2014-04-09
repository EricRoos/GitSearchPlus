require 'uri'
require 'net/http'
require 'net/https'
require 'redis'
require 'OctoClient'
class SearchController < ApplicationController
  def index
    client_id = "7a3da7b8589d0b94d34b"
    client_secret = "d07e351528d34a59d797d4b9bfdd263faa414e9d"
    if session[:logged] != true and params[:code]
      code = params[:code]
      url = "https://github.com/login/oauth/access_token"
      data_hash = { :client_id => client_id, :client_secret=> client_secret, :code => code}
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Accept"] = "application/json"
      req.set_form_data(data_hash)
      
      @response = JSON.parse(http.request(req).body)
      if @response["access_token"] != nil
        session[:logged] = true
        session[:access_token] = @response["access_token"]
      end
    end
    if params[:code] == nil && session[:logged] != false
      redirect_to "https://github.com/login/oauth/authorize?client_id=#{client_id}"
    else
      redirect_to :query
    end
  end

  def query
    if session[:logged] == nil
      redirect_to "/"
    else
      token = session[:access_token]
      puts "ACCESS_TOKEN: #{token}"
      #return variable set up
      if params[:page] == nil || params[:page].to_i <= 0
        @page = 1
      else
        @page = params[:page].to_i
      end

      @num_items = 0
      @items = []
      @query = params[:q]
      @order = params[:order]
      if @order || @order != ''
        if @order == 'Ascending'
          @order = 'asc'
        elsif @order == 'Descending'
          @order = 'desc'
        else
          @order = ''
        end
      end
      @language = params[:language]
      if @language && @language != ''
        @query = "#{@query}+language:#{@language}"
      end

      if @query
        @items = OctoClient.search(@query,@page,@order, token) 
        @num_items = OctoClient.get_count(@query,@order)
        puts "NUM ITEMS: #{@num_items}"
        @languages = OctoClient.get_languages(@query)
      end
      @order = params[:order]
      respond_to do |format|
        format.html
        format.json {render json: {html_content: render_to_string('view')}}
      end
    end
  end
end
