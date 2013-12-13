SimpleBlog
======

A Simple Blog System without a database system.

The programme reads markdown files in the specific directory and shows them.

Written with Ruby. Using Sinatra as web server and redcarpet as markdown parser.

##Installation

1. Install Ruby. [rvm](https://rvm.io) is recommended.

2. Install dependencies.

	bundle install

3. Start.

	ruby main.rb

4. If you need to host multiple web sites in one vps, use nginx for reverse proxy.

##Tips

- The first line of the markdown file is considered as the title of the post.

- Make sure the LANG variable is *.UTF-8