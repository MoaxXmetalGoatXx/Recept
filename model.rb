def register_user(user, pwd)
    db = SQLite3::Database.new("db/mat.db")
    pwd_digest=BCrypt::Password.create(pwd)
    db.execute("INSERT INTO users(UserName,
    pw, likes) VALUES(?,?, 0)",[user,pwd_digest])
end
def user_exist(user)
    db = SQLite3::Database.new("db/mat.db")
    result = db.execute("SELECT UserId FROM users WHERE
    UserName=?",user)
    if result.empty?
        return nil
    else 
        return result
    end
end
def login(user, pwd)
    db = SQLite3::Database.new("db/mat.db")
    db.results_as_hash = true
    result=db.execute("SELECT UserId, pw FROM
    users WHERE UserName=?",user)
    p result[0] 
    if BCrypt::Password.new(result[0]["pw"]) == pwd
        return result[0]["UserId"]
    else
        return nil
    end
end
def user_info(id)
    db = SQLite3::Database.new("db/mat.db")
    db.results_as_hash = true
    info = db.execute("SELECT * FROM
    users WHERE UserId=?", id)
    recipes = db.execute("SELECT * FROM recept WHERE UserId=?", id)
    return info, recipes
end
def update_profile(id, file_name, bio)
    db = SQLite3::Database.new("db/mat.db")
    db.execute("UPDATE users SET bio=? WHERE UserId=?", [bio, id])
    if file_name != nil 
        db.execute("UPDATE users SET profile_pic=? WHERE UserId=?", [file_name, id])
    end
end
def new_recipe(title, description, ingredients, instructions, time, id, vegan, vegetarian, gluten_free)
    db = SQLite3::Database.new("db/mat.db")
    db.execute("INSERT INTO recept(description, Title, instructions, UserId, timeStamp, ingredients, vegan, vegetarian, gluten_free, likes) VALUES(?,?,?,?,?,?,?,?,?,0)",[description, title, instructions, id, time, ingredients, vegan, vegetarian, gluten_free])
end
def like(recipeId)
    db = SQLite3::Database.new("db/mat.db")
    likes = db.execute("SELECT likes FROM recept WHERE receptId=?", recipeId)+1
    db.execute("UPDATE recept SET likes=? WHERE receptId=?", likes)
    user_id = db.execute("SELECT UserId FROM recept WHERE receptId=?",recipeId)+1
    likes = db.execute("SELECT likes FROM users WHERE UserId=?", user_id)+1
    db.execute("UPDATE users SET likes=? WHERE UserId=?", likes, user_id)
end
def search(filter, sort)
    db = SQLite3::Database.new("db/mat.db")
    db.results_as_hash = true
    if filter
        db.execute("SELECT * FROM recept WHERE #{filter} ORDER BY #{sort}")
    else
        db.execute("SELECT * FROM recept ORDER BY #{sort}")
    end
end
def recipe_info(id)
    db = SQLite3::Database.new("db/mat.db")
    db.results_as_hash = true
    db.execute("SELECT * FROM recept WHERE receptId=?", id)
end