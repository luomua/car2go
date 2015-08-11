require File.dirname(__FILE__) + "/../app.rb"

set :app_file, File.expand_path(File.dirname(__FILE__) + '/../app.rb')
set :public,   File.expand_path(File.dirname(__FILE__) + '/../public')
set :views,    File.expand_path(File.dirname(__FILE__) + '/../views')
set :env,      :production

disable :run, :reload

run Sinatra.application