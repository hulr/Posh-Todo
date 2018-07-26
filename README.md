# Posh-Todo

> PowerShell todo list using text files as database

## Usage
```
# import module
Import-Module Posh-Todo.psm1

# add a new todo list item
t add [todo] [category] [priority]

# get existing todo list items
t ls [id] [category] [priority]

# mark todo list item as completed
t rm [id]

# update existing todo list item
t up [id]
```