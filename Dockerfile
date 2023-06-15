# Dockerfile from
#
#     https://intercityup.com/blog/how-i-build-a-docker-image-for-my-rails-app.html
#
# See more documentation at the passenger-docker GitHub repo:
#
#     https://github.com/phusion/passenger-docker
#
#
FROM phusion/passenger-ruby27:2.5.0-amd64

MAINTAINER Autolab Development Team "autolab-dev@andrew.cmu.edu"

# Change to your time zone here
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
  sqlite3 \
  tzdata  \
  shared-mime-info

# Start Nginx / Passenger
RUN rm -f /etc/service/nginx/down
# Remove the default site
RUN rm /etc/nginx/sites-enabled/default

# Install gems
WORKDIR /tmp
ADD Gemfile .
ADD Gemfile.lock .

RUN chown app:app Gemfile Gemfile.lock

# Prepare folders
USER app
# Update rubygem to latest version
RUN gem update --system
# Specify bundler version
RUN gem install bundler -v $(tail -n1 Gemfile.lock)
RUN bundle install

RUN mkdir /home/app/webapp
WORKDIR /home/app/webapp

# Add the rails app
ADD . /home/app/webapp

USER root

# Create the log files
# This messes with the mounted volume, so don't create them here.
#RUN mkdir -p /home/app/webapp/log && \
#  touch /home/app/webapp/log/production.log && \
#  chmod 0664 /home/app/webapp/log/production.log && \

# Set app to owner of everything
RUN chown -R app:app .

# Disable Nginx log rotation within the container because it interferes with
# log rotation on the host with the mounted volume
RUN mv /etc/logrotate.d/nginx /etc/logrotate.d/nginx.disabled

# Make MOSS executable
RUN chmod ug+x /home/app/webapp/vendor/mossnet

USER app

# precompile the Rails assets
ENV SECRET_KEY_BASE=dummy_secret_key_base
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Clean up APT when done.
USER root
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
