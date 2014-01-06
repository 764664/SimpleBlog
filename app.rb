#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'socket'
require 'resolv'
require 'json'
require 'date'

#Read json file and parse it.
jsonfile = File.new("config.json")
jsonfile.set_encoding(Encoding::UTF_8)
json = jsonfile.read
json = JSON.parse(json)

title = json["title"]
description = json["description"]
links = json["link"]
go = json["go"]
mddir = json["mddir"]
port = json["port"]
postinpage = json["postinpage"]
meta = {:title => title, :description => description, :links => links}

#Configure sinatra
set :bind, '0.0.0.0'
set :port, port
set :static_cache_control, [:public, :max_age => 2592000]

#Initialize local variables
articles = Hash.new()
npstring = "Initial string."
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
markdownfilterhtml = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:filter_html => true))
dnsresolver = Resolv::DNS.new()

#Load markdown files
files = Dir.entries(mddir)
files.sort!.reverse!
files.each do |i|
	if (i =~ /.+\.md/)
		path = mddir + i
		f = File.new(path)
		f.set_encoding(Encoding::UTF_8)
		lines = f.readlines()
		title = lines.shift
		datetime = lines.shift.chomp
		date = Date.parse(datetime).strftime('%d %b %Y')
		category = lines.shift
		content = markdown.render(lines.join)
		excerpt = Sanitize.clean(content).split(//).first(100).join
		articles[File.basename(i, ".md")] = {
			:filename => File.basename(i, ".md"), 
			:title => title,
			:content => content,
            :excerpt => excerpt,
            :date => date,
		:datetime => datetime,
            :category => category,
			:link => "/article/#{File.basename(i, ".md")}"
		}
	end
end

#Sinatra routes
before do
	response.headers['Cache-Control'] = 'no-cache'
end

get '/' do
  	erb :index, :locals => {:meta => meta, :articles => articles.keys.sort.reverse.first(10).map{ |n| articles[n] }, 
  	:page => 1, :pages => (articles.size-1)/postinpage+1}
end

get '/page/:page' do |page|
    erb :index, :locals => {:meta => meta, :articles => articles.keys.sort.reverse[(page-1)*10..-1].first(10).map{ |n| articles[n] }, 
    :page => page, :pages => (articles.size-1)/postinpage+1}
end

get '/article/:id' do |id|
	if articles.has_key?(id)
		erb :article, :locals => {:meta => meta, :article => articles[id]}
	else
		redirect to('/')
	end
end

get '/go/:key' do |key|
	redirect to(go[key])
end

get '/httpinfo' do
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
