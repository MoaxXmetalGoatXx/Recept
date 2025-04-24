require 'sinatra'
require 'slim'
require_relative 'model'
require 'bcrypt'
require 'sinatra/reloader'
require 'sqlite3'
require 'fileutils'
require 'time'

enable :sessions

get('/') do
    redirect '/home'
end
get('/home') do
    slim :home
end
get('/register') do
    slim :register
end
post('/register') do
    user = params["user"]
    pwd = params["pwd"]
    pwd_confirm = params["pwd_confirm"]
    if pwd==pwd_confirm
        id = user_exist(user)
        if id
            redirect('/login')
        else 
            register_user(user, pwd)
            session[:UserId] = id
            redirect('/home')
        end
    else
        #flash pasword dont match
    end

end
get('/login') do
    slim :login
end
post('/login') do
    user = params["user"]
    pwd = params["pwd"]
    if user_exist(user)
        id = login(user, pwd)
        if id
            session[:UserId] = id
            redirect('/home')
        else
            redirect('/login')
        end
    else
        redirect('/register')
    end
end
get('/profile') do
    id = session[:UserId]
    if id
        user_info = user_info(id)
        p user_info
        info, recipes = user_info
        p info[0]
        p recipes
        slim(:"profile", locals:{info:info[0], recipes:recipes})
    else
        redirect('/register')
    end
end
get('/edit') do
    id = session[:UserId]
    info = user_info(id)[0][0]
    slim(:"edit" , locals:{info:info})
end

post('/upload') do
    new_file = nil
    if params["profile-pic"]
        file = params["profile-pic"]["filename"]
        tempfile = params["profile-pic"]["tempfile"]
        new_file = "#{session[:UserId]}#{file}"
        dest = File.join('public', 'img', 'profile', new_file)
        puts dest
        unless File.exist?(tempfile.path) && File.readable?(tempfile.path)
            puts "Temporary file is not accessible"
        end
        
        unless File.writable?(dest)
            puts "No write permission in destination directory"
        end
        File.binwrite(dest, tempfile.read)
    end
    bio = params["bio"]
    update_profile(session[:UserId], new_file, bio)
    redirect('/profile')
end
get('/recipes/new') do
    slim(:"recipes/new")
end
post('/recipes/new') do
    title = params["Title"]
    description = params["description"]
    ingredients = params["ingredients"]
    instructions = params["instructions"]
    vegetarian = params["vegetarian"]
    vegan = params["vegan"]
    gluten_free = params["gluten_free"]
    timestamp = Time.now.to_s.split("+")[0]
    p timestamp
    new_recipe(title, description, ingredients, instructions, timestamp, session[:UserId])
    redirect('/profile')
end
get('recipes/search') do
    if params["sort"]
        sort = params["sort"]
    end
    filter=nil
    @recipes = get_recipes(filter, sort)
    if params[:q]
        recipes = []
        q = params[:q].downcase
        @recipes.each do|recipe|
            if recipe["Title"].downcase[q]
                recipes<<[recipe]
            end
        end
        @recipes = recipes
    end
    slim(:"recipes/search")
end