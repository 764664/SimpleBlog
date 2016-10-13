SimpleBlog
======

A simple blog without a database system.

Reads markdown files in the specific directory and renders them.

## Demo
[https://blog.lvjie.me](https://blog.lvjie.me)

## Docker
```
docker build -t myblog .
docker run -d --name myblog myblog
```

## Deployment

1. Install Ruby 2.*. [rvm](https://rvm.io) is recommended.

2. Install dependencies.

	bundle install

3. Puts the markdown files in the directory (md by default).

4. Modify the config file `config.json` to your needs.

5. Start.

	rackup

6. Enjoy.

##Tips

- The first line of the markdown file is considered as the title of the post.

- The second line of it is considered as the date published. (Format: YYYY-MM-DD)

- The third line of it is considered as the category.

- If you need to host multiple web sites in one vps, use [nginx](http://nginx.org/) for reverse proxy.