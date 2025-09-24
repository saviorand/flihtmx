///
/// User command abstraction
///
eff UserCommands {
    def getCurrentCommand(): UserCommand
}

enum UserCommand with ToString {
    case ViewHomePage
    case ViewTodoList  
    case AddTodo(String)
    case ToggleTodo(String)
    case DeleteTodo(String)
    case UnknownCommand
}

mod UserCommands {
    ///
    /// HTTP interpreter for user commands
    ///
    pub def handleWithHttp(method: String, path: String, formData: Map[String, String], 
                          f: Unit -> a \ ef): a \ (ef - UserCommands) =
        run {
            f()
        } with handler UserCommands {
            def getCurrentCommand(_, k) = {
                let command = parseHttpToCommand(method, path, formData);
                k(command)
            }
        }

    ///
    /// Parse HTTP request into domain command
    ///
    def parseHttpToCommand(method: String, path: String, formData: Map[String, String]): UserCommand = {
        match (method, path) {
            case ("GET", "/") => UserCommand.ViewHomePage
            case ("GET", "/todos") => UserCommand.ViewTodoList
            case ("POST", "/todos") => 
                match Map.get("text", formData) {
                    case Some(text) => UserCommand.AddTodo(text)
                    case None => UserCommand.UnknownCommand
                }
            case ("PUT", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                UserCommand.ToggleTodo(todoId)
            }
            case ("DELETE", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                UserCommand.DeleteTodo(todoId)
            }
            case _ => UserCommand.UnknownCommand
        }
    }
}

///
/// Pure business logic - the heart of the application
/// Notice: No HTTP, no database, no concrete concerns - just effects!
///
def handleUserCommand(): Unit \ {TodoState, View, UserCommands} = {
    let command = UserCommands.getCurrentCommand();
    match command {
        case UserCommand.ViewHomePage => 
            View.showMainPage()
        
        case UserCommand.ViewTodoList => {
            let todos = TodoState.getAllTodos();
            View.showTodoList(todos)
        }
        
        case UserCommand.AddTodo(text) => {
            let trimmedText = String.trim(text);
            if (not String.isEmpty(trimmedText)) {
                let newTodo = TodoState.addTodo(trimmedText);
                View.showTodoItem(newTodo)
            } else {
                View.showError("Todo text cannot be empty")
            }
        }
        
        case UserCommand.ToggleTodo(todoId) => {
            match TodoState.toggleTodo(todoId) {
                case Some(updatedTodo) => View.showTodoItem(updatedTodo)
                case None => View.showError("Todo not found")
            }
        }
        
        case UserCommand.DeleteTodo(todoId) => {
            if (TodoState.deleteTodo(todoId)) {
                // Successfully deleted - HTMX will remove the element
                () 
            } else {
                View.showError("Todo not found")
            }
        }
        
        case UserCommand.UnknownCommand => 
            View.showError("Unknown command")
    }
}