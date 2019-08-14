require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def complete?(list)
    todos_remaining_count(list) == 0 && todos_count(list) > 0
  end
  
  def list_class(list)
    "complete" if complete?(list)
  end
  
  def todo_class(todo)
    "complete" if todo[:completed]
  end
  
  def todos_remaining_count(list)
    list[:todos].count { |todo| todo[:completed] == false && todo[:trashed] == false }
  end
  
  def todos_count(list)
    list[:todos].count { |todo| todo[:trashed] == false }
  end
  
  def display_and_sort_lists(lists)
    result = []
    lists.each_with_index do |list, index|
      result << { 
        name: list[:name], 
        index: list[:id],
        remaining: todos_remaining_count(list),
        total: todos_count(list),
        completed: complete?(list),
        css_class: list_class(list),
      }
    end
    sort_by_completed(result)
  end
  
  def format_and_sort_todos(list, trashed = false)
    result = []
    todos = list[:todos].select { |todo| todo[:trashed] == trashed }
    
    todos.each_with_index do |todo, index|
      result << {
        name: todo[:name],
        index: todo[:id],
        completed: todo[:completed],
        css_class: todo_class(todo)
      }
    end
    sort_by_completed(result)
  end 
  
  def trashed_todos(list)
    format_and_sort_todos(list, true)
  end
  
  def num_trashed_todos(list)
    trashed_todos(list).size
  end
  
  def sort_by_completed(items)
    items.sort_by { |item| item[:completed] ? 1 : 0 }
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
  redirect "/lists"
end

# View all of the lists
get "/lists" do
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the list name is invalid. Return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the todo name is invalid. Return nil if name is valid
def error_for_todo_name(name)
  if !(1..100).cover?(name.size)
    "Todo name must be between 1 and 100 characters."
  end
end

# Return the maximum id value from either the array of todos, or array of lists
def next_id(items)
  max_id = items.map { |item| item[:id] }.max || 0
  max_id + 1
end

# retrieve todo list based on id
def load_list(id)
  list_to_load = @lists.find { |list| list[:id] == id }
  if !list_to_load
    session[:error] = "The specified list was not found."
    redirect "/lists"
  else
    list_to_load
  end
end

# retrieve todo item based on id
def load_todo(id)
  @list[:todos].find { |todo| todo[:id] == id }
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_id(@lists)
    @lists << { id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a list
get "/lists/:list_index" do
  id = params[:list_index].to_i
  @list = load_list(id)
  # @id = @list[:id]
  
  erb :list
end

# Edit a list
get "/lists/:list_index/edit" do 
  id = params[:list_index].to_i
  @list = load_list(id)

  erb :edit_list
end

# update existing todo list
post "/lists/:list_index" do
  list_name = params[:list_name].strip
  id = params[:list_index].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{@list[:id]}"
  end
end

# delete a todo list
post "/lists/:list_index/destroy" do
  id = params[:list_index].to_i
  @lists.delete_if { |list| list[:id] == id }
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# add a todo item to a list
post "/lists/:list_index/todos" do
  id = params[:list_index].to_i
  @list = load_list(id)

  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)
  
  if error
    session[:error] = error
    erb :list, layout: :layout
  else  
    
    new_id = next_id(@list[:todos])
    @list[:todos] << { id: new_id, name: todo_name, completed: false, trashed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list[:id]}"
  end 
end

# trash a todo item from a list
post "/lists/:list_index/todos/:todo_index/trash" do
  id = params[:list_index].to_i
  @list = load_list(id)

  todo_index = params[:todo_index].to_i
  todo_to_trash = load_todo(todo_index)
  todo_to_trash[:trashed] = true

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been trashed."
    redirect "/lists/#{@list[:id]}"
  end
end

# restore a todo item from a list
post "/lists/:list_index/todos/:todo_index/restore" do
  id = params[:list_index].to_i
  @list = load_list(id)

  todo_index = params[:todo_index].to_i
  todo_to_restore = load_todo(todo_index)
  todo_to_restore[:trashed] = false

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been restored."
    redirect "/lists/#{@list[:id]}/edit"
  end
end

# toggle checked/completed on todo
post "/lists/:list_index/todos/:todo_index/mark" do
  id = params[:list_index].to_i
  @list = load_list(id)

  todo_index = params[:todo_index].to_i
  mark = params[:completed] == "true"
  todo_to_mark = load_todo(todo_index)
  todo_to_mark[:completed] = mark

  session[:success] = "The todo has been marked as #{ mark ? "" : "not " }completed."
  redirect "/lists/#{@list[:id]}"
end

# mark all todo items as completed for a list
post "/lists/:list_index/complete" do
  id = params[:list_index].to_i
  @list = load_list(id)

  @list[:todos].each do |todo|
    todo[:completed] = true unless todo[:trashed]
  end
  
  session[:success] = "All todos have been marked as completed."
  redirect "/lists/#{@list[:id]}"
end

# empty trash for a list
post "/lists/:list_index/emptytrash" do
  id = params[:list_index].to_i
  @list = load_list(id)

  @list[:todos].delete_if do |todo|
    todo[:trashed] == true
  end
  
  session[:success] = "Trashed todos have been deleted forever."
  redirect "/lists/#{@list[:id]}"
end

get "/hello_world" do
  "Hello, world!"
end
