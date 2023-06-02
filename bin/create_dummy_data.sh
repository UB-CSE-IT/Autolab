#!/bin/bash

env='development'

create_dummy_data()
{
  echo "############## Creating Dummy Data ##############"

  RAILS_ENV=$1 bundle exec rails autolab:populate
}

create_dummy_data $env
