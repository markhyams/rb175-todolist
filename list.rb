lists = [
  { name: "Hello0", todos: [{name: 1, completed: false}, 
                            {name: 2, completed: false},
                            {name: 3, completed: true}] },
  { name: "Goodby1", todos: [{name: 1, completed: true}, 
                            {name: 2, completed: true},
                            {name: 3, completed: true}] },
  { name: "Costco2", todos: [{name: 1, completed: false}, 
                            {name: 2, completed: false},
                            {name: 3, completed: true}] },
  { name: "Ruby3", todos: [{name: 1, completed: false}, 
                            {name: 2, completed: false},
                            {name: 3, completed: true}] },
  ]
  
def add_index_field(lists)
  lists.each_with_index do |list, index|
    list[:id] = index
  end
end
lists
add_index_field(lists)

p lists.sort_by { |list| list[:name] }