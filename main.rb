#! /usr/bin/env ruby
require 'sinatra'
require 'redcarpet'
require 'socket'
require './config.rb'

#Variables
dir = "md/"
posts = {}
set :bind, '0.0.0.0'
set :port, PORT
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
markdownfilterhtml = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(:filter_html => true))
#End of Variables

files = Dir.entries(dir)
files.sort!.reverse!
files.each do |i|
	if (i =~ /.+\.md/)
		path = dir + i
		lines = IO.readlines(path)
		posttitle = lines.shift
		content = lines.join
		posts[File.basename(i, ".md")] = {
			:filename => File.basename(i, ".md"), 
			:posttitle => posttitle,
			:content => markdown.render(content), 
			:filterhtml => markdownfilterhtml.render(content)
		}
	end
end
meta = {:title => TITLE, :subtitle => SUBTITLE, :links => LINKS}

get '/' do
  	erb :index, :locals => {:meta => meta, :posts => posts}
end

get '/ip' do
	"Client"<<request.ip<<" "<<"Me"<<Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
end

get '/:post' do |n|
	if posts.has_key?(n)
		erb :post, :locals => {:meta => meta, :post => posts[n]}
	else
		"No such post."
	end
end
