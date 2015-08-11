#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'

require 'sinatra/base'
require 'rest-client'
require 'json'
require 'yaml'
require 'csv'

class App < Sinatra::Application

  use Rack::Session::Pool

  set :app_file, __FILE__

  configure :production, :development do
    p 'Reloading'
    require 'sinatra/reloader'
    register Sinatra::Reloader
    enable :logging
  end

  couchdb_config = YAML.load_file File.expand_path(File.join('config', 'couchdb.yml'))
  couchdb_env = couchdb_config[ENV['RACK_ENV'].to_s]
  addr = "http://#{couchdb_env[:host]}:#{couchdb_env[:port]}"
  admin_db = "#{couchdb_env[:admindb]}"
  data_db = "#{couchdb_env[:datadb]}"
  view_base = "_design/#{couchdb_env[:designdoc]}/_view"
  csv_view = "#{couchdb_env[:csv]}"

  hl = YAML.load_file File.expand_path(File.join('config', 'header_label.yml'))

  before do
#    content_type 'application/json'
#      RestClient.log = logger
  end
  
  helpers do
    def admin?
      ! session[:username].nil?
    end

    def rest_get_no_exception(path)
      RestClient.get(path){|response, request, result| response }
    end

    def rest_get(path)
      JSON.parse RestClient.get(path)
    end

    def cv_to_chartdata(path)
      data = {}
      data[:labels], data[:data] = [[],[]]
      cv_to_kv = rest_get(path)['rows']
      if cv_to_kv.size == 1 && cv_to_kv[0]['key'].nil?
        data[:labels] = cv_to_kv[0]['key']
        data[:data] = cv_to_kv[0]['value']
      else
        cv_to_kv.each do |kv|
          data[:labels] << kv['key']
          data[:data] << kv['value'].reduce(:+)
        end
      end
      return data
    end

    def cv_to_tabledata(path, view)
      data = {}
      data[:aaData] = []
      cv_to_kv = rest_get(path)['rows']
      if view == "24h"
        cv_to_kv.each do |kv|
          data[:aaData] << kv['value']
        end
      else
        format = (view == "cartimes" || view == "clienttimes") ? "0" : "2"
        cv_to_kv.each do |kv|
          row = []
          row << kv['key']
          row << sprintf("%.#{format}f", kv['value'].reduce(:+))
          row.concat kv['value'].collect{|x| (x === 0) ? nil : sprintf("%.#{format}f", x)}
          kv['value'].delete(0)
          row.unshift sprintf('%.2f', (kv['value'].reduce(:+) * 100).fdiv(31 * kv['value'].size))
          data[:aaData] << row
        end
      end
      return data
    end

    def round_nonzero(x, y)
      return (x != 0) ? x.round(y) : x
    end

    def json_pretty(json)
      JSON.pretty_generate(json) + "\n"
    end

  end

  get '/' do
    return erb :index unless admin?
    erb :list
  end

  post '/login' do
    begin  
      user_login = rest_get "#{addr}/#{admin_db}/#{params[:username]}"
      if user_login['password'] == params[:password]
        session[:username] = params[:username]
        case params[:username]
        when "test"
          database = "/tar2go_rent"
        else
          database = "/car2go_rent"
        end
      end
    rescue

    end
    redirect '/'
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  get '/download' do
    return erb :index unless admin?
    begin
      data = rest_get("#{addr}/#{data_db}/#{view_base}/#{csv_view}")['rows']
      header = data.first['value'].keys
      header[0] = "\xEF\xBB\xBF""#{header[0]}"
      output = CSV.generate do |csv|
        csv << header
        data.each do |row|
          csv << row['value'].values
        end
      end
      content_type "text/csv"
      attachment "#{couchdb_env[:designdoc]}_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
      return output
    rescue
      redirect '/'
    end 
  end

  get '/api/table/:name' do
    content_type :json
    query = params[:group].nil? ? "" : "?group=#{params[:group]}"
    begin
      data = cv_to_tabledata("#{addr}/#{data_db}/#{view_base}/#{params[:name]}#{query}", params[:name])
      data[:aoColumns] = hl[:table][params[:name]]
    rescue RestClient::ResourceNotFound
      data = { :error => "not_found", :reason => "missing_named_view" }
    end
    json_pretty data
  end

  get '/api/chart/:name' do
    content_type :json
    query = params[:group].nil? ? "" : "?group=#{params[:group]}"
    begin
      data = cv_to_chartdata("#{addr}/#{data_db}/#{view_base}/#{params[:name]}#{query}")
      data[:labels] = hl[:chart][params[:name]] if data[:labels].nil?
      data[:data].collect! {|x| round_nonzero(x, 2)}
      case params[:name]
      when "monthdays"
        data[:data].collect! {|x| round_nonzero(x, 0)}
      when "cardays"
        data[:labels].collect! {|x| x.to_s+'号车'} unless data[:labels].nil?
      end
    rescue RestClient::ResourceNotFound
      data = { :error => "not_found", :reason => "missing_named_view" }
    end
    json_pretty data
  end

  get '/api/view/:name' do
    content_type :json
    query = params[:group].nil? ? "" : "?group=#{params[:group]}"
    rest_get_no_exception "#{addr}/#{data_db}/#{view_base}/#{params[:name]}#{query}"
  end

  get '/show' do
    apiurl = "/api/#{params[:object]}/#{params[:view]}?group=#{params[:group]}"
    return erb "#{params[:object]}".to_sym, :locals => { :apiurl => apiurl } if admin? && !params[:object].nil? && !params[:view].nil? && !params[:group].nil?
    redirect '/'
  end

  not_found do
    redirect '/'
  end
  
  run! if app_file == $0

end