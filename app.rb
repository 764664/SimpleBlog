#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'action_controller'
require 'net/http'
require 'resolv'
require 'json'
require 'date'

class Blog
  attr_accessor :npstring, :articles, :config, :meta

  def initialize
    @articles = {}
    @npstring = ""
    load_config
    load_data
  end

  def load_config
    File.open("config.json") do |f|
      f.set_encoding(Encoding::UTF_8)
      @config = JSON.parse(f.read)
    end
    @meta = {:title => @config["title"], :description => @config["description"], :links => @config["links"]}
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
    lines = ""
    File.open(file) do |f|
      lines = f.set_encoding(Encoding::UTF_8).readlines
    end
    File.new(file).set_encoding(Encoding::UTF_8).readlines
    title = lines.shift
    datetime = lines.shift.chomp
    category = lines.shift
    contentold = Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(lines.join)
    content = lines.join
    #excerpt = ActionController::Base.helpers.sanitize(content, tags: %w(br))[0..200] + "..."
    excerpt = Sanitize.fragment(contentold)[0..200] + "..."
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

  def add_article content
    id = @articles.keys.sort[-1].to_i + 1
    filename = sprintf("%04d", id) + ".md"
    File.open(@config["mddir"] + filename, "wb") do |f|
      f.set_encoding(Encoding::UTF_8).write(content)
      f.close
    end
    Dir.chdir(File.join(Dir.pwd, @config["mddir"])) do
      load_file filename
    end
  end
end

class MyBlog < Sinatra::Base
  use Rack::GoogleAnalytics, :tracker => 'UA-46808684-1'

  blog = Blog.new
  config = blog.config
  meta = blog.meta
  articles = blog.articles
  npstring = blog.npstring

  set :bind, '0.0.0.0'
  #set :static_cache_control, [:public, :max_age: 3600]

  def get_hostname(ip)
    begin
      Resolv::DNS.new().getname(ip)
    rescue
    end
  end

  def client_ip
    if request.env['HTTP_X_FORWARDED_FOR']
      client_ip = request.env['HTTP_X_FORWARDED_FOR']
    else
      client_ip = request.ip
    end
  end

  def server_ip
    server_ip_list = Socket.ip_address_list.detect{|ip| ip.ipv4? and !ip.ipv4_private? and !ip.ipv4_loopback?}
    server_ip = if server_ip_list
      server_ip_list.ip_address
    else
      JSON.parse( Net::HTTP.get( URI ("http://httpbin.org/ip" ) ) )["origin"]
    end
  end

  before do
    response.headers['Cache-Control'] = 'no-cache'
  end

  get '/' do
    #redirect to 'http://en.lvjie.me' if request.env["HTTP_ACCEPT_LANGUAGE"] != "zh-cn"
    haml :index, :locals => {:title => meta[:title], :meta => meta, :articles => articles.keys.sort.reverse.first(10).map{ |n| articles[n] },
                             :page => 1, :pages => (articles.size-1)/config["post_per_page"]+1}
  end

  get '/page/:page' do |page|
    page = page.to_i
    haml :index, :locals => {:title => meta[:title], :meta => meta, :articles => articles.keys.sort.reverse[(page-1)*10..-1].first(10).map{ |n| articles[n] },
    :page => page, :pages => (articles.size-1)/config["post_per_page"]+1}
  end

  get '/article/add' do
    erb :addarticle
  end

  post '/article/add' do
    if params[:password] == config["pass"]
      blog.add_article(params[:content])
    end
    redirect to('/')
  end

  get '/article/:id' do |id|
    if articles.has_key?(id)
      haml :article, :locals => {:title => articles[id][:title], :meta => meta, :article => articles[id]}
    else
      redirect to('/')
    end
  end

  get '/go/:key' do |key|
    redirect to(config["go"][key])
  end

  get '/httpinfo' do
    erb :httpinfo, :locals => {
      :serverip => self.server_ip,
      :clientip => self.client_ip,
      :serverhostname => self.get_hostname(self.server_ip),
      :clienthostname => self.get_hostname(self.client_ip),
      :useragent => request.user_agent,
      :referrer => request.referrer,
      :rubyversion => RUBY_VERSION
    }
  end

  get '/notepad' do
    erb :notepad, :locals => { :content => npstring }
  end

  post '/notepad' do
    npstring = params[:content]
  end

end
