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
    list[:todos].count { |todo| todo[:completed] == false }
  end
  
  def todos_count(list)
    list[:todos].size
  end
  
  def display_and_sort_lists(lists)
    result = []
    lists.each_with_index do |list, index|
      result << { 
        name: list[:name], 
        index: index, 
        remaining: todos_remaining_count(list),
        total: todos_count(list),
        completed: complete?(list),
        css_class: list_class(list)
      }
    end
    sort_by_completed(result)
  end
  
  def format_and_sort_todos(list)
    result = []
    list[:todos].each_with_index do |todo, index|
      result << {
        name: todo[:name],
        index: index,
        completed: todo[:completed],
        css_class: todo_class(todo)
      }
    end
    sort_by_completed(result)
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

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @lists << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a list
get "/lists/:list_index" do
  @id = params[:list_index].to_i
  @list = @lists[@id]
  
  if !@list
    session[:error] = "The specified list was not found."
    redirect "/lists"
  else
    erb :list
  end
end

# Edit a list
get "/lists/:list_index/edit" do 
  @id = params[:list_index].to_i
  @list = @lists[@id]
  
  erb :edit_list
end

# update existing todo list
post "/lists/:list_index" do
  list_name = params[:list_name].strip
  @id = params[:list_index].to_i

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    @list = @lists[@id]
    erb :edit_list, layout: :layout
  else
    @lists[@id][:name] = list_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{@id}"
  end
end

# delete a todo list
post "/lists/:list_index/destroy" do
  @lists.delete_at(params[:list_index].to_i)
  session[:success] = "The list has been deleted."
  
  redirect "/lists"
end

# add a todo item to a list
post "/lists/:list_index/todos" do
  @id = params[:list_index].to_i
  @list = @lists[@id]
  
  todo_name = params[:todo].strip
  error = error_for_todo_name(todo_name)
  
  if error
    session[:error] = error
    erb :list, layout: :layout
  else  
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@id}"
  end 
end

# delete a todo item from a list
post "/list/:list_index/todos/:todo_index/destroy" do
  @id = params[:list_index].to_i
  todo_index = params[:todo_index].to_i
  @list = @lists[@id]
  @list[:todos].delete_at(todo_index)
  
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@id}"
end

# toggle checked/completed on todo
post "/list/:list_index/todos/:todo_index/mark" do
  @id = params[:list_index].to_i
  todo_index = params[:todo_index].to_i
  @list = @lists[@id]
  mark = params[:completed] == "true"
  @list[:todos][todo_index][:completed] = mark

  session[:success] = "The todo has been marked as #{ mark ? "" : "not " }completed."
  redirect "/lists/#{@id}"
end

# mark all todo items as completed for a list
post "/lists/:list_index/complete" do
  @id = params[:list_index].to_i
  @list = @lists[@id]
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  
  session[:success] = "All todos have been marked as completed."
  redirect "/lists/#{@id}"
end
