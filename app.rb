#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'socket'
require 'resolv'
require 'json'
require 'date'

class Blog
  attr_accessor :npstring, :articles, :config, :meta

  private
  def initialize
    @articles = {}
    @npstring = ""
    load_config
    load_data
  end

  def load_config
    jsonfile = File.new("config.json")
    jsonfile.set_encoding(Encoding::UTF_8)
    json = JSON.parse(jsonfile.read)
    @config = json
    @meta = {:title => json["title"], :description => json["description"], :links => json["links"]}
  end
  
  def load_data
    files = Dir.entries(@config["mddir"]).sort.reverse
    Dir.chdir(File.join(Dir.pwd, @config["mddir"])) do
      files.each do |file|
        if (file =~ /.+\.md/)
          load_file file
        end
      end
    end
  end

  def load_file file
    lines = File.new(file).set_encoding(Encoding::UTF_8).readlines
    title = lines.shift
    datetime = lines.shift.chomp
    category = lines.shift
    content = Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(lines.join)
    excerpt = Sanitize.clean(content).split(//).first(100).join
    @articles[File.basename(file, ".md")] = {
      :filename => File.basename(file, ".md"), 
      :title => title,
      :date => Date.parse(datetime).strftime('%d %b %Y'),
      :category => category,
      :content => content,
      :excerpt => excerpt,
      :datetime => datetime,
      :link => "/article/#{File.basename(file, ".md")}"
    }
  end
end

class MyBlog < Sinatra::Base
  blog = Blog.new
  config = blog.config
  meta = blog.meta
  articles = blog.articles
  npstring = blog.npstring

  set :bind, '0.0.0.0'
  set :port, config["port"]
  set :static_cache_control, [:public, :max_age => 2592000]

  before do
    response.headers['Cache-Control'] = 'no-cache'
  end
  
  get '/' do
    erb :index, :locals => {:meta => meta, :articles => articles.keys.sort.reverse.first(10).map{ |n| articles[n] }, 
    :page => 1, :pages => (articles.size-1)/config["postinpage"]+1}
  end
  
  get '/page/:page' do |page|
    erb :index, :locals => {:meta => meta, :articles => articles.keys.sort.reverse[(page-1)*10..-1].first(10).map{ |n| articles[n] }, 
    :page => page, :pages => (articles.size-1)/config["postinpage"]+1}
  end
  
  get '/article/:id' do |id|
    if articles.has_key?(id)
      erb :article, :locals => {:meta => meta, :article => articles[id]}
    else
      redirect to('/')
    end
  end
  
  get '/go/:key' do |key|
    redirect to(config["go"][key])
  end
  
  get '/httpinfo' do
    dnsresolver = Resolv::DNS.new()
    serverip = Socket.ip_address_list.detect{|ip| !ip.ipv4_private? and !ip.ipv4_loopback?}.ip_address
    if request.env['HTTP_X_FORWARDED_FOR']
      clientip = request.env['HTTP_X_FORWARDED_FOR']
    else
      clientip = request.ip
    end
    begin
      serverhostname = dnsresolver.getname(serverip)
    rescue Exception
    end
    begin
      clienthostname = dnsresolver.getname(clientip)
    rescue Exception
    end
    erb :httpinfo, :locals => {
      :serverip => serverip,
      :clientip => clientip,
      :serverhostname => serverhostname,
      :clienthostname => clienthostname,
      :useragent => request.user_agent,
      :referrer => request.referrer
    }
  end
  
  get '/notepad' do
    erb :notepad, :locals => { :content => npstring }
  end
  
  post '/notepad' do
    npstring = params[:content]
  end
end
