#!/usr/bin/env ruby
require 'sinatra'
require 'redcarpet'
require 'socket'
require 'resolv.rb'
require './config.rb'

#Configure sinatra
set :bind, '0.0.0.0'
set :port, PORT

#Initialize local variables
posts = {}
mddir = MDDIR
linkprefix = LINKPREFIX
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
markdownfilterhtml = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:filter_html => true))
dnsresolver = Resolv::DNS.new()

#Load markdown files
files = Dir.entries(mddir)
files.sort!.reverse!
files.each do |i|
	if (i =~ /.+\.md/)
		path = mddir + i
		lines = IO.readlines(path)
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
meta = {:title => TITLE, :subtitle => SUBTITLE, :links => LINKS}

#Sinatra routes
get '/' do
  	erb :index, :locals => {:meta => meta, :posts => posts}
end

get '/ip' do
	serverip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
	clientip = request.ip
	begin
		serverhostname = "<b>Hostname" + dnsresolver.getname(serverip) + "</b>"
	rescue Exception => e
		serverhostname = ""
	end
	begin
		clienthostname = "<b>Hostname" + dnsresolver.getname(clientip) + "</b>"
	rescue Exception => e
		clienthostname = ""
	end
	"<b>Client IP</b> #{clientip} #{clienthostname}<br />
	</b>Site IP</b> #{serverip} #{serverhostname}<br />
	UA #{request.user_agent}<br />Referrer #{request.referrer}"
end

get '/post/:post' do |n|
	if posts.has_key?(n)
		erb :post, :locals => {:meta => meta, :post => posts[n]}
	else
		"No such post."
	end
end
