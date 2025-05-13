require 'sinatra'
require 'slim'
require_relative 'model'
require 'bcrypt'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'sqlite3'
require 'fileutils'
require 'time'

enable :sessions

before do
    restricted_paths = ['/edit','/recipes/new']
    if session[:UserId]==nil && restricted_paths.include?(request.path_info)
        session[:error] = "you need to log in to access"
        redirect('/error')
    end
    guestpaths = ['/login','/register']
    if session[:UserId] && guestpaths.include?(request.path_info)
        session.clear
    end
end
get('/error') do
    p session[:error]
end
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
    if pwd.length>5 && pwd.length<12 && pwd[/\d/] && pwd!=pwd.to_i.to_s
        if pwd==pwd_confirm
            id = user_exist(user)
            if id
                redirect('/login')
            else 
                register_user(user, pwd)
                id = login(user, pwd)
                session[:UserId] = id
                redirect('/home')
            end
        else
            flash[:password]="passwords dont match"
            redirect('/register')
        end
    else
        flash[:password]="password must contain 6-11 character and contain atleast one number and one letter"
        redirect('/register')
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
        slim(:"profile", locals:{info:info, recipes:recipes, user:true})
    else
        redirect('/login')
    end
end
get('/profile/:username') do
    username = params[:username]
    id = user_exist(username)
    if id
        user_info = user_info(id)
        p user_info
        info, recipes = user_info
        slim(:"profile", locals:{info:info, recipes:recipes, user:false})
    else
        redirect('/')
    end
end
get('/edit') do
    id = session[:UserId]
    info = user_info(id)[0]
    slim(:"edit", locals:{info:info})
end

post('/upload') do
    new_file = nil
    if params["profile-pic"]
        file = params["profile-pic"]["filename"]
        tempfile = params["profile-pic"]["tempfile"]
        new_file = "#{session[:UserId]}#{file}"
        dest = File.join('public', 'img', 'profile', new_file)
        unless File.exist?(tempfile.path) && File.readable?(tempfile.path)
            puts "temp file fel"
        end
        
        unless File.writable?(dest)
            puts "No write permission"
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
    id = session[:UserId]
    if id
        title = params["Title"]
        description = params["description"]
        ingredients = params["ingredients"]
        instructions = params["instructions"]
        vegetarian = params["vegetarian"]
        vegan = params["vegan"]
        gluten_free = params["gluten_free"]
        timestamp = Time.now.to_s.split("+")[0]
        new_recipe(title, description, ingredients, instructions, timestamp, id, vegan, vegetarian, gluten_free)
        redirect('/profile')
    end
end
get('/recipes') do
    if params["sort"]
        sort = params["sort"]
    else 
        sort = "receptId"
    end
    vegetarian = params["vegetarian"]
    vegan = params["vegan"]
    gluten_free = params["gluten_free"]
    filter = nil
    if vegetarian 
        filter = "vegetarian='true'"
    end
    if filter && vegan
        filter = filter + "AND vegan='true'"
    elsif vegan
        filter = "vegan='true'"
    end
    if filter && gluten_free
        filter = filter + "AND gluten_free='true'"
    elsif gluten_free
        filter = "gluten_free='true'"
    end
    @recipes = search(filter, sort)
    if params[:q]
        recipes = []
        q = params[:q].downcase
        @recipes.each do|recipe|
            if recipe["Title"].downcase[q]
                recipes<<recipe
            end
        end
        @recipes = recipes
    end
    p @recipes
    slim(:"recipes/search")
end

get('/recipes/:id') do
    id = params[:id]
    if recipe_info(id) == nil
        session[:error] = "no such recipe"
        redirect('/error')
    end
    recipe, username = recipe_info(id)
    p recipe
    reviews = recipe_reviews(id)
    p reviews
    if session[:UserId]
        user = true
    else 
        user = false
    end
    slim(:"recipes/recipe", locals:{recipe:recipe, username:username, reviews:reviews, user:user})
end
get('/recipes/:id/edit') do
    id = params[:id]
    recipe = recipe_info(id)[0]
    if session[:UserId]!=recipe["UserId"]
        session[:error]="error: not your recipe"
        redirect('/error')
    else
        slim(:"recipes/edit", locals:{recipe:recipe})
    end
end
post('/recipes/:id/edit') do
    title = params["Title"]
    description = params["description"]
    ingredients = params["ingredients"]
    instructions = params["instructions"]
    id = params[:id]
    edit_recipe(id, title, description, ingredients, instructions)
    redirect('/profile')
end
post('/recipes/:id/delete') do
    id = params[:id]
    userId = session[:UserId]
    if user_recipe?(id, userId)
        delete_recipe(id)
        redirect('/profile')
    end
    redirect('/home')
end 
post('/recipes/review') do
    id = params["id"]
    reviewsid_array = reviewsid(id)
    if reviewsid_array.include?(session[:UserId])
        flash[:error]="you have already left a review on this recipe"
        redirect('/error')
    else
        rating = params["rating"]
        review = params["review"]
        userid = session[:UserId]
        review(rating, review, id, userid)
        redirect("/recipes/#{id}")
    end
end
