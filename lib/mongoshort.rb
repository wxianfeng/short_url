# 注意这个文件不能格式化，haml根据宿进来的
require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'uri'
require 'digest/md5'
require 'models/url'
require 'haml'

set :public, File.dirname(__FILE__) + "/public"


configure :development do
  MongoMapper.database = 'mongoshort_dev'
end

configure :test do
  MongoMapper.database = 'mongoshort_test'
end

configure :production do
  # If using a database outside of where MongoShort is running (like MongoHQ - http://www.mongohq.com/), specify the connection here.
  # MongoMapper.connection = Mongo::Connection.new('mongo.host.com', 27017)
  MongoMapper.database = 'mongoshort_production'
  # Only necessary if your database needs authentication (strongly recommended in production).
  # MongoMapper.database.authenticate(ENV['mongodb_user'], ENV['mongodb_pass'])
end

get '/' do
  @urls = URL.all
  haml :index
end

get '/:url' do
  url = URL.find_by_url_key(params[:url])
  if url.nil?
    raise Sinatra::NotFound
  else
    url.last_accessed = Time.now
    url.times_viewed += 1
    url.save
    redirect url.full_url, 301
  end
end

post '/' do
  if !params[:url]
    status 400
    { :error => "'url' parameter is missing" }.to_json
  end  
  @url = URL.find_or_create(params[:url])
  @urls = URL.all
  haml :index
end

not_found do
  # Change this URL to wherever you want to be redirected if a non-existing URL key or an invalid action is called.
  # redirect "http://#{Sinatra::Application.bind}/"
  @url = 'this url is not find'
  haml :index
end


# use_in_file_templates! # usage in sinatra 1.0 See : http://irclogger.com/sinatra/2010-04-24
enable :inline_templates

__END__

@@ layout
!!! 1.1
%html
%head
%title Short_url!
%link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Modernist', :type => 'text/css'}
%link{:rel => 'stylesheet', :href => 'style.css', :type => 'text/css'}
%script{:rel => 'javascript', :src => 'uservoice.js', :type => 'text/javascript'}
%link{:rel=>"shortcut icon", :type=>"image/x-icon", :href=>"/favicon.ico"}
= yield

@@ index
%h1.title Short_url!
-unless @url.nil?
  #err.warning=@url
%form{:method => 'post', :action => '/'}
  #short_form
    Short this:
    %input{:type => 'text', :name => 'url', :size => '50'}
    %input{:type => 'submit', :value => 'short!'}
#footer
  %small copyright &copy;
  %a{:href => 'http://wxianfeng.com',:target=>"_blank"}
    wxianfeng
  %br
  %a{:href => 'http://github.com/wxianfeng/short_url',:target=>"_blank"}
    source code
- @urls.each do |ele|
  %a{:href => ele.full_url,:target=>"_blank"}
    =ele.full_url
  shorted to
  %a{:href => ele.short_url,:target=>"_blank"}
    =ele.short_url
  ,viewed
  %strong
    =ele.times_viewed
  times
  - unless ele.created_at.blank?
    ,created_at
    %strong
      =ele.created_at.to_s(:db)
  - unless ele.last_accessed.blank?
    ,last accessed at
    %strong
      =ele.last_accessed.to_s(:db)
  %br