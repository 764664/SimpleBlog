#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'socket'
require 'resolv'
require 'json'
#Dir.chdir(File.dirname(__FILE__))

#Read json file and parse it.
jsonfile = File.new("config.json")
json = jsonfile.read
json = JSON.parse(json)

title = json["title"]
subtitle = json["subtitle"]
links = json["link"]
mddir = json["mddir"]
linkprefix = json["linkprefix"]
port = json["port"]
meta = {:title => title, :subtitle => subtitle, :links => links}

#Configure sinatra
set :bind, '0.0.0.0'
set :port, port

#Initialize local variables
posts = {}
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
		posttitle = lines.shift
		content = lines.join
		posts[File.basename(i, ".md")] = {
			:filename => File.basename(i, ".md"), 
			:posttitle => posttitle,
			:content => markdown.render(content), 
			:filterhtml => markdownfilterhtml.render(content),
			:link => "/#{linkprefix}/#{File.basename(i, ".md")}"
		}
	end
end

#Sinatra routes
get '/' do
  	erb :index, :locals => {:meta => meta, :posts => posts}
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

get '/post/:post' do |n|
	if posts.has_key?(n)
		erb :post, :locals => {:meta => meta, :post => posts[n]}
	else
		"No such post."
	end
end

get '/notepad' do
    erb :notepad, :locals => { :content => npstring }
end

post '/notepad' do
    npstring = params[:content]
end