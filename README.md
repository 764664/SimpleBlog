SimpleBlog
======

A simple blog without a database system.

Reads markdown files in the specific directory and renders them.

##Demo
[lvjie.me](http://lvjie.me)

##Installation

1. Install Ruby 2.*. [rvm](https://rvm.io) is recommended.

2. Install dependencies.

	bundle install

3. Puts the markdown files in the directory (md by default).

4. Start.

	rackup

5. Enjoy.

##Configuration

All configurations are in config.json.

You can modify it by yourself.

##Tips

- The first line of the markdown file is considered as the title of the post.

- The second line of it is considered as the date published. (Format: YYYY-MM-DD)

- The third line of it is considered as the category.

- If you need to host multiple web sites in one vps, use [nginx](http://nginx.org/) for reverse proxy.

##Thanks

Thanks to Ghost for providing the theme.