eff UserInput {
    def getCommand(): UserCommand
}

enum UserCommand with ToString {
    case ViewHomePage
    case ViewTodoList  
    case AddTodo(String)
    case ToggleTodo(String)
    case DeleteTodo(String)
    case UnknownCommand
}

eff View {
    def renderMainPage(): Unit
    def renderTodoList(todos: List[Todo]): Unit
    def renderTodoItem(todo: Todo): Unit
    def renderError(message: String): Unit
}

eff TodoStore {
    def getAllTodos(): List[Todo]
    def addTodo(text: String): Todo  
    def toggleTodo(id: String): Option[Todo]
    def deleteTodo(id: String): Bool
}
