eff TodoApp {
    def runApp(): Unit
    def handleCommand(cmd: TodoCommand): Unit  
}

eff TodoStorage {
    def getAllTodos(): List[Todo]
    def saveTodos(todos: List[Todo]): Unit
}

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

mod AppBootstrap {
    pub def createApp(_config: AppConfig): Unit \ TodoApp =
        TodoApp.runApp()
    
    pub def runWithInMemoryStorage(stateRef: Ref[List[Todo], r], f: Unit -> a \ ef): a \ (ef - TodoStorage + r) =
        run {
            f()
        } with handler TodoStorage {
            def getAllTodos(_, k) = {
                let todos = Ref.get(stateRef);
                k(todos)
            }
            
            def saveTodos(todos, k) = {
                Ref.put(todos, stateRef);
                k()
            }
        }
}