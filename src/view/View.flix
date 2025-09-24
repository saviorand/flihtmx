eff View {
    def showMainPage(): Unit
    def showTodoList(todos: List[Todo]): Unit
    def showTodoItem(todo: Todo): Unit
    def showAddForm(): Unit
    def showError(message: String): Unit
    def showEmptyState(): Unit
}

mod View {
    import com.sun.net.httpserver.HttpExchange
    
    pub def handleWithHttp(exchange: HttpExchange, f: Unit -> a \ ef): a \ (ef - View + IO) =
        run {
            f()
        } with handler View {
            def showMainPage(_, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.mainPageHtml(), htmlHeaders()));
                k()
            }
            def showTodoList(todos, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.todoListHtml(todos), htmlHeaders()));
                k()
            }
            def showTodoItem(todo, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.todoItemHtml(todo), htmlHeaders()));
                k()
            }
            def showAddForm(_, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.addFormHtml(), htmlHeaders()));
                k()
            }
            def showEmptyState(_, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.emptyStateHtml(), htmlHeaders()));
                k()
            }
            def showError(message, k) = {
                writeHttpResponse(exchange, HttpResponse.Ok(Components.errorHtml(message), htmlHeaders()));
                k()
            }
        }
}