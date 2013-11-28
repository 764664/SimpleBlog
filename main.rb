#! /usr/bin/env ruby
require 'sinatra'
require 'redcarpet'

#Configuration
title = "吕杰's Blog"
subtitle = "Coder & Software User"
links = [{:name => "我的Github", :link => "https://github.com/764664/"}]
#End of Configuration

#Variables
dir = "md/"
posts = {}
set :bind, '0.0.0.0'
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
meta = {:title => title, :subtitle => subtitle, :links => links}

get '/' do
  	erb :index, :locals => {:meta => meta, :posts => posts}
end

get '/:post' do |n|
	if posts.has_key?(n)
		erb :post, :locals => {:post => posts[n]}
	else
		"No such post."
	end
end