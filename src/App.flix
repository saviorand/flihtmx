enum TodoCommand with Eq, ToString {
    case ViewHomePage,
    case ViewTodoList,
    case ViewActiveTodos,
    case ViewCompletedTodos,
    case AddTodo(String),
    case ToggleTodo(String),
    case DeleteTodo(String),
    case ClearCompleted
}

mod TodoApplication {
    pub def handleCommand(cmd: TodoCommand): Unit \ {TodoStorage, TodoView, IO} = 
        match cmd {
            case TodoCommand.ViewHomePage => {
                discard TodoView.showHomePage();
                ()
            }
            
            case TodoCommand.ViewTodoList => {
                let todos = TodoStorage.getAllTodos();
                discard TodoView.showTodoList(todos);
                ()
            }
            
            case TodoCommand.ViewActiveTodos => {
                let todos = TodoStorage.getAllTodos();
                let activeTodos = TodoService.getActiveTodos(todos);
                discard TodoView.showTodoList(activeTodos);
                ()
            }
            
            case TodoCommand.ViewCompletedTodos => {
                let todos = TodoStorage.getAllTodos();
                let completedTodos = TodoService.getCompletedTodos(todos);
                discard TodoView.showTodoList(completedTodos);
                ()
            }
            
            case TodoCommand.AddTodo(text) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.addTodo(text, currentTodos) {
                    case Ok((_, updatedTodos)) => {
                        TodoStorage.saveTodos(updatedTodos);
                        discard TodoView.showTodoList(updatedTodos);
                        ()
                    }
                    case Err(error) => {
                        discard TodoView.showError(error);
                        ()
                    }
                }
            }
            
            case TodoCommand.ToggleTodo(idStr) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.updateTodo(idStr, Todo.toggle, currentTodos) {
                    case Ok((_, newTodos)) => {
                        TodoStorage.saveTodos(newTodos);
                        discard TodoView.showTodoList(newTodos);
                        ()
                    }
                    case Err(error) => {
                        discard TodoView.showError(error);
                        ()
                    }
                }
            }
            
            case TodoCommand.DeleteTodo(idStr) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.deleteTodo(idStr, currentTodos) {
                    case Ok(updatedTodos) => {
                        TodoStorage.saveTodos(updatedTodos);
                        discard TodoView.showTodoList(updatedTodos);
                        ()
                    }
                    case Err(error) => {
                        discard TodoView.showError(error);
                        ()
                    }
                }
            }
            
            case TodoCommand.ClearCompleted => {
                let currentTodos = TodoStorage.getAllTodos();
                let activeTodos = TodoService.getActiveTodos(currentTodos);
                TodoStorage.saveTodos(activeTodos);
                discard TodoView.showTodoList(activeTodos);
                ()
            }
        }
}

mod AppHandler {
    pub def handleRequest(method: String, path: String, formData: Map[String, String]): String \ {TodoStorage, TodoView, IO} = {
        let cmd = HttpAdapter.parseCommand(method, path, formData);
        match cmd {
            case TodoCommand.ViewHomePage => TodoView.showHomePage()
            
            case TodoCommand.ViewTodoList => {
                let todos = TodoStorage.getAllTodos();
                TodoView.showTodoList(todos)
            }
            
            case TodoCommand.ViewActiveTodos => {
                let todos = TodoStorage.getAllTodos();
                let activeTodos = TodoService.getActiveTodos(todos);
                TodoView.showTodoList(activeTodos)
            }
            
            case TodoCommand.ViewCompletedTodos => {
                let todos = TodoStorage.getAllTodos();
                let completedTodos = TodoService.getCompletedTodos(todos);
                TodoView.showTodoList(completedTodos)
            }
            
            case TodoCommand.AddTodo(text) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.addTodo(text, currentTodos) {
                    case Ok((_, updatedTodos)) => {
                        TodoStorage.saveTodos(updatedTodos);
                        TodoView.showTodoList(updatedTodos)
                    }
                    case Err(error) => TodoView.showError(error)
                }
            }
            
            case TodoCommand.ToggleTodo(idStr) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.updateTodo(idStr, Todo.toggle, currentTodos) {
                    case Ok((_, newTodos)) => {
                        TodoStorage.saveTodos(newTodos);
                        TodoView.showTodoList(newTodos)
                    }
                    case Err(error) => TodoView.showError(error)
                }
            }
            
            case TodoCommand.DeleteTodo(idStr) => {
                let currentTodos = TodoStorage.getAllTodos();
                match TodoService.deleteTodo(idStr, currentTodos) {
                    case Ok(updatedTodos) => {
                        TodoStorage.saveTodos(updatedTodos);
                        TodoView.showTodoList(updatedTodos)
                    }
                    case Err(error) => TodoView.showError(error)
                }
            }
            
            case TodoCommand.ClearCompleted => {
                let currentTodos = TodoStorage.getAllTodos();
                let activeTodos = TodoService.getActiveTodos(currentTodos);
                TodoStorage.saveTodos(activeTodos);
                TodoView.showTodoList(activeTodos)
            }
        }
    }
}