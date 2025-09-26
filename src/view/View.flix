eff TodoView {
    def showHomePage(): String
    def showTodoList(todos: List[Todo]): String
    def showTodo(todo: Todo): String
    def showError(error: TodoError): String
    def showSuccess(message: String): String
}

mod HtmlView {
    import com.sun.net.httpserver.HttpExchange

    pub def runWithWebView(exchange: HttpExchange, f: Unit -> a \ ef): a \ (ef - TodoView + IO) =
        run {
            f()
        } with handler TodoView {
            def showHomePage(_, k) = {
                let content = ViewComponents.homePage();
                writeHtmlResponse(exchange, content);
                k(content)
            }
            
            def showTodoList(todos, k) = {
                let content = ViewComponents.todoList(todos);
                writeHtmxResponse(exchange, content);
                k(content)
            }
            
            def showTodo(todo, k) = {
                let content = ViewComponents.todoItem(todo);
                writeHtmxResponse(exchange, content);
                k(content)
            }
            
            def showError(error, k) = {
                let content = ViewComponents.errorMessage(error);
                writeErrorResponse(exchange, content);
                k(content)
            }
            
            def showSuccess(message, k) = {
                let content = ViewComponents.successMessage(message);
                writeHtmxResponse(exchange, content);
                k(content)
            }
        }
    
    def writeHtmlResponse(exchange: HttpExchange, content: String): Unit \ IO = 
        writeResponse(exchange, content, Map#{
            "Content-Type" => "text/html; charset=utf-8"
        })
    
    def writeHtmxResponse(exchange: HttpExchange, content: String): Unit \ IO = 
        writeResponse(exchange, content, Map#{
            "Content-Type" => "text/html; charset=utf-8",
            "HX-Trigger" => "todoUpdated"
        })
    
    def writeErrorResponse(exchange: HttpExchange, content: String): Unit \ IO = 
        writeResponse(exchange, content, Map#{
            "Content-Type" => "text/html; charset=utf-8",
            "HX-Reswap" => "innerHTML",
            "HX-Retarget" => "#error-container"
        })
    
    def writeResponse(exchange: HttpExchange, content: String, headers: Map[String, String]): Unit \ IO = {
        Map.forEach(key -> value -> exchange.getResponseHeaders().set(key, value), headers);
        let responseBytes = content.getBytes();
        exchange.sendResponseHeaders(200, Int32.toInt64(Array.length(responseBytes)));
        let outputStream = exchange.getResponseBody();
        outputStream.write(responseBytes);
        outputStream.close();
        exchange.close()
    }
}