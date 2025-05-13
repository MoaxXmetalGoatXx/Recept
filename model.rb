def database()
    db = SQLite3::Database.new("db/mat.db")
end
def register_user(user, pwd)
    db = database
    pwd_digest=BCrypt::Password.create(pwd)
    db.execute("INSERT INTO users(UserName,
    pw) VALUES(?,?)",[user,pwd_digest])
end
def user_exist(user)
    db = database
    result = db.execute("SELECT UserId FROM users WHERE
    UserName=?",user)
    if result.empty?
        return nil
    else 
        return result
    end
end

def login(user, pwd)
    db = database()
    db.results_as_hash = true
    result=db.execute("SELECT UserId, pw FROM
    users WHERE UserName=?",user)
    if BCrypt::Password.new(result[0]["pw"]) == pwd
        return result[0]["UserId"]
    else
        return nil
    end
end
def user_info(id)
    db = database
    db.results_as_hash = true
    info = db.execute("SELECT * FROM
    users WHERE UserId=?", id).first
    recipes = db.execute("SELECT * FROM recept WHERE UserId=?", id)
    return info, recipes
end
def update_profile(id, file_name, bio)
    db = database
    db.execute("UPDATE users SET bio=? WHERE UserId=?", [bio, id])
    if file_name != nil 
        db.execute("UPDATE users SET profile_pic=? WHERE UserId=?", [file_name, id])
    end
end
def new_recipe(title, description, ingredients, instructions, time, id, vegan, vegetarian, gluten_free)
    db = database
    db.execute("INSERT INTO recept(description, Title, instructions, UserId, timeStamp, ingredients, vegan, vegetarian, gluten_free) VALUES(?,?,?,?,?,?,?,?,?)",[description, title, instructions, id, time, ingredients, vegan, vegetarian, gluten_free])
end
def review(rating,review,recipeId, id)
    db = database
    db.execute("INSERT INTO reviews(rating, review, UserId, receptId) VALUES(?,?,?,?)",[rating,review,id,recipeId])
end
def recipe_reviews(id)
    db = database
    db.results_as_hash = true
    reviews = db.execute("SELECT * FROM reviews WHERE receptId=?", id)
    if reviews.empty?
        return nil
    else 
        db.results_as_hash = false
        reviews.each do|review|
            user = db.execute("SELECT UserName FROM users WHERE UserId=?", review["UserId"]).first[0]
            review["user"] = user
        end
        return reviews
    end
end
def reviewsid(id)
    db = database
    ids = db.execute("SELECT UserId FROM reviews WHERE receptId=?", id).flatten
    p "ids"
    p ids
    return ids
end
def search(filter, sort)
    db = database
    db.results_as_hash = true
    if filter
        return db.execute("SELECT * FROM recept WHERE #{filter} ORDER BY #{sort}")
    else
        return db.execute("SELECT * FROM recept ORDER BY #{sort}")
    end
end
def recipe_info(id)
    db = database
    userid = db.execute("SELECT UserId FROM recept WHERE receptId=?", id).first
    if userid == nil
        return nil
    end
    p "userid"
    p userid[0]
    username = db.execute("SELECT UserName FROM users WHERE UserId=?", userid[0]).first[0]
    p username
    db.results_as_hash = true
    info = db.execute("SELECT * FROM recept WHERE receptId=?", id).first
    return info, username
end
def edit_recipe(id, title, description, ingredients, instructions)
    db = database
    db.execute("UPDATE recept SET Title=? WHERE receptId=?", [title, id])
    db.execute("UPDATE recept SET description=? WHERE receptId=?", [description, id])
    db.execute("UPDATE recept SET ingredients=? WHERE receptId=?", [ingredients, id])
    db.execute("UPDATE recept SET instructions=? WHERE receptId=?", [instructions, id])

end 
def user_recipe?(id, userId)
    db = database
    if userId == db.execute("SELECT UserId FROM recept WHERE receptId=?", id).first
        return true
    else 
        return false
    end
end
def delete_recipe(id)
    db = database
    db.execute("DELETE FROM recept WHERE receptId=?", id).first
end
