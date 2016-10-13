FROM ruby:onbuild
CMD /usr/local/bundle/bin/rackup --host 0.0.0.0 --port 80
EXPOSE 80
ENV VIRTUAL_HOST blog.lvjie.me