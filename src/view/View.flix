eff View {
    def showMainPage(): Unit
    def showTodoList(todos: List[Todo]): Unit
    def showTodoItem(todo: Todo): Unit
    def showAddForm(): Unit
    def showError(message: String): Unit
    def showEmptyState(): Unit
}
