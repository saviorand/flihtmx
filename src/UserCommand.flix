eff UserCommands {
    def getCurrentCommand(): UserCommand
}

enum UserCommand {
    case ViewHomePage
    case ViewTodoList  
    case AddTodo(String)
    case ToggleTodo(String)
    case DeleteTodo(String)
    case UnknownCommand
}

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
            if (not String.isEmpty(String.trim(text))) {
                let todo = TodoState.addTodo(String.trim(text));
                View.showTodoItem(todo)
            } else {
                View.showError("Todo text cannot be empty")
            }
        }
        
        case UserCommand.ToggleTodo(todoId) => {
            let maybeTodo = TodoState.toggleTodo(todoId);
            match maybeTodo {
                case Some(todo) => View.showTodoItem(todo)
                case None => View.showError("Todo not found")
            }
        }
        
        case UserCommand.DeleteTodo(todoId) => {
            let _ = TodoState.deleteTodo(todoId);
            ()
        }
        
        case UserCommand.UnknownCommand => 
            View.showError("Unknown command")
    }
}

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
