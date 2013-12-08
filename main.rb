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

get '/httpinfo' do
	serverip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
	clientip = request.ip
	begin
		serverhostname = dnsresolver.getname(serverip)
	rescue Exception
	end
	begin
		clienthostname = dnsresolver.getname(clientip)
	rescue Exception
	end
<<<<<<< HEAD
	erb :httpinfo, :locals => {
		:serverip => serverip,
		:clientip => clientip,
		:serverhostname => serverhostname,
		:clienthostname => clienthostname,
		:useragent => request.user_agent,
		:referrer => request.referrer
	}
=======
	"""<b>Client IP</b> #{clientip} #{clienthostname}<br />
	</b>Site IP</b> #{serverip} #{serverhostname}<br />
	UA #{request.user_agent}<br />Referrer #{request.referrer}"""
>>>>>>> 6621aa2f4393b5f0a5f93469e69ecd69655051c9
end

get '/post/:post' do |n|
	if posts.has_key?(n)
		erb :post, :locals => {:meta => meta, :post => posts[n]}
	else
		"No such post."
	end
end
