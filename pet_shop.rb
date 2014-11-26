require 'pg'
require 'rest-client'

response = RestClient.get("pet-shop.api.mks.io")
home = JSON.parse(response)

result = RestClient.get("pet-shop.api.mks.io/shops")
shops = JSON.parse(result)

def connect
  @conn ||= PG::Connection.new(host: 'localhost', dbname: 'petshop_db')
end

def create_shop_table
  result = connect.exec(
    "CREATE TABLE IF NOT EXISTS shops(
      name VARCHAR,
      id SERIAL PRIMARY KEY
    );"
    )
  result.entries
end

def insert_into_shop(name, id)
  sql = "INSERT INTO shops (name, id) VALUES ($1, $2)"

  result = connect.exec_params(sql, [name, id])
  result.entries
end

def add_shops
  result = RestClient.get("pet-shop.api.mks.io/shops")
  shops = JSON.parse(result)

  shops.each do |shop|
    insert_into_shop(shop["name"], shop["id"])
  end
end

def create_dog_table
  result = connect.exec(
    "CREATE TABLE IF NOT EXISTS dogs(
      id SERIAL PRIMARY KEY,
      shopId INTEGER,
      name VARCHAR,
      imageUrl VARCHAR,
      happiness INTEGER
      );"
    )
end 

def insert_into_dog(id, shopId, name, imageUrl, happiness)
  sql = "INSERT INTO dogs (id, shopId, name, imageUrl, happiness) VALUES ($1, $2, $3, $4, $5)"

  result = connect.exec_params(sql, [id, shopId, name, imageUrl, happiness])
  result.entries
end

def add_dogs
  result = connect.exec("SELECT id FROM shops;")
  dogs = []
  result.entries.each do |shop|
    query = "pet-shop.api.mks.io/shops/" + shop['id'] + "/dogs"
    result = RestClient.get(query)
    dogs << JSON.parse(result)
  end
  dogs.flatten!

  dogs.each do |dog|
    result = insert_into_dog(dog["id"], dog["shopId"], dog["name"], dog["imageUrl"], dog["happiness"])
  end
end

def create_cat_table
  result = connect.exec(
    "CREATE TABLE IF NOT EXISTS cats(
      id SERIAL PRIMARY KEY,
      shopId INTEGER,
      name VARCHAR,
      imageUrl VARCHAR
      );"
    )
end 

def insert_into_cat(id, shopId, name, imageUrl)
  sql = "INSERT INTO cats (id, shopId, name, imageUrl) VALUES ($1, $2, $3, $4)"

  result = connect.exec_params(sql, [id, shopId, name, imageUrl])
  result.entries
end

def add_cats
  result = connect.exec("SELECT id FROM shops;")
  cats = []
  result.entries.each do |shop|
    query = "pet-shop.api.mks.io/shops/" + shop['id'] + "/cats"
    result = RestClient.get(query)
    cats << JSON.parse(result)
  end
  cats.flatten!

  cats.each do |cat|
    result = insert_into_cat(cat["id"], cat["shopId"], cat["name"], cat["imageUrl"])
  end
end

def pet_shops
  result = connect.exec("SELECT id, name FROM shops;")
  result.entries
end

def particular_dogs(shopId)
  result = connect.exec_params("SELECT * FROM dogs WHERE shopId = $1", [shopId])
  result.entries
end 

def happiest_dogs
  result = connect.exec("SELECT name, happiness FROM dogs ORDER BY happiness DESC LIMIT 5")
  result.entries
end

def all_pets
  sql = "SELECT dogs.name AS pet_name, shops.name AS shop_name, 'dog' AS type FROM dogs JOIN shops ON dogs.shopId = shops.id"
  sql += " UNION "
  sql += "SELECT c.name AS pet_name, s.name AS shop_name, 'cat' AS type FROM cats c JOIN shops s ON c.shopId = s.id;"

  result = connect.exec(sql)
  result.entries
end

