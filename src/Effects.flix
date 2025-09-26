eff TodoStorage {
    def getAllTodos(): List[Todo]
    def saveTodos(todos: List[Todo]): Unit
}

eff TodoView {
    def showHomePage(): String
    def showTodoList(todos: List[Todo]): String  
    def showError(error: TodoError): String
    def showSuccess(message: String): String
}

eff TodoConfig {
    def getInitialTodos(): List[Todo]
}