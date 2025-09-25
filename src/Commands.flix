def handleUserCommand(): Unit \ {TodoStore, UserInput, View} = {
    match UserInput.getCommand() {
        case UserCommand.ViewHomePage => 
            View.renderMainPage()
        
        case UserCommand.ViewTodoList => {
            let todos = TodoStore.getAllTodos();
            View.renderTodoList(todos)
        }
        
        case UserCommand.AddTodo(text) => {
            let trimmedText = String.trim(text);
            if (String.isEmpty(trimmedText)) {
                View.renderError("Todo text cannot be empty")
            } else {
                let newTodo = TodoStore.addTodo(trimmedText);
                View.renderTodoItem(newTodo)
            }
        }
        
        case UserCommand.ToggleTodo(todoId) => {
            match TodoStore.toggleTodo(todoId) {
                case Some(updatedTodo) => View.renderTodoItem(updatedTodo)
                case None => View.renderError("Todo not found")
            }
        }
        
        case UserCommand.DeleteTodo(todoId) => {
            if (TodoStore.deleteTodo(todoId)) {
                () // HTMX will remove the element
            } else {
                View.renderError("Todo not found")
            }
        }
        
        case UserCommand.UnknownCommand => 
            View.renderError("Unknown command")
    }
}