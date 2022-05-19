require 'sinatra'
require 'sinatra/namespace'

# set sinatra default port to 3000
set :port, 3000



# Models
class Recipe
  attr_accessor :recipe_name, :ingredients, :instructions, :numSteps

  def initialize(recipe_name, ingredients, instructions)
    @recipe_name = recipe_name  # string
    @ingredients = ingredients  # array of strings
    @instructions = instructions # array of strings

    @numSteps = @instructions.length
  end

end



# Source
recipes = File.read('./data.json')
my_recipes = {}  # store all recipes in a hash instead of a database for simplicity

data = JSON.parse(recipes)
data['recipes'].map {|recipe|
  my_recipes[recipe['name']] = Recipe.new(recipe['name'], recipe['ingredients'], recipe['instructions'])
}


# Endpoints
get '/' do
  my_recipes.map {|r_name, recipe|
    {
      name:recipe.recipe_name,
      ingredients:recipe.ingredients,
      instructions:recipe.instructions
    }
  }.to_json
end

# use namespace to enable different versions
namespace '/v1' do

  before do
    content_type 'application/json'
  end

  ###############################################
  # helper functions
  # helpers do
  #   def base_url
  #     @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  #   end

  #   def json_params
  #     begin
  #       JSON.parse(request.body.read)
  #     rescue
  #       halt 400, {message:'Invalid JSON'}.to_json
  #     end
  #   end
  # end

   # access the recipe
  # def recipe
  #   r_name = params["name"]
  #   @recipe = my_recipes[r_name]
  # end

   # if recipe not Found
  # def halt_if_not_found!
  #   halt(404, { message:'Recipe Not Found'}.to_json) unless recipe
  # end
  ###############################################

  # show
  get '/recipes' do
    {'recipeNames':
      my_recipes.map {|recipe_name, recipe| recipe_name} }.to_json
  end

  # show
  get '/details/:name' do
    r_name = params["name"]
    recipe = my_recipes[r_name]

    #halt(404, { message:'Recipe Not Found'}.to_json) unless recipe
    halt 200, {} unless recipe
    #halt_if_not_found!

    { "details":
      {
        ingredients:recipe.ingredients,
        numSteps:recipe.numSteps
      }
    }.to_json
  end

  # create
  # test:
  # curl -i -X POST -H "Content-Type: application/json" -d'{"name": "butteredBagel",
  # "ingredients": ["1 bagel","butter"],"instructions": ["cut the bagel","spread butter on bagel"]}'
  #  http://localhost:3000/v1/recipes
  post '/recipes' do
    json_params = JSON.parse(request.body.read)
    halt 400, {"error": "Recipe already exists"} if my_recipes.has_key?(json_params["name"])

    recipe = Recipe.new(json_params["name"], json_params["ingredients"], json_params["instructions"])
    my_recipes[recipe.recipe_name] = recipe

    base_url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    response.headers['Location'] = "#{base_url}/v1/details/#{recipe.recipe_name}"
    status 201
  end

  # update
  # test:
  # curl -i -X PATCH -H "Content-Type: application/json" -d'{"name": "butteredBagel",
  # "ingredients": ["1 bagel","2 tbsp butter"],"instructions": ["cut the bagel","spread butter on bagel"]}'
  #  http://localhost:3000/v1/recipes
  patch '/recipes' do
    json_params = JSON.parse(request.body.read)
    halt 404, {"error": "Recipe does not exist"} unless my_recipes.has_key?(json_params["name"])

    recipe = my_recipes[json_params["name"]]
    recipe.ingredients = json_params["ingredients"]
    recipe.instructions = json_params["instructions"]
    status 204

  end



end
