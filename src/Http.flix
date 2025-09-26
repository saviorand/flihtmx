mod HttpAdapter {
    pub def parseCommand(method: String, path: String, formData: Map[String, String]): TodoCommand =
        match (method, path) {
            case ("GET", "/") => TodoCommand.ViewHomePage
            case ("GET", "/todos") => TodoCommand.ViewTodoList
            case ("GET", "/todos/active") => TodoCommand.ViewActiveTodos
            case ("GET", "/todos/completed") => TodoCommand.ViewCompletedTodos
            case ("POST", "/todos") => 
                Map.get("text", formData) 
                |> Option.getWithDefault("")
                |> TodoCommand.AddTodo
            case ("PUT", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                TodoCommand.ToggleTodo(todoId)
            }
            case ("DELETE", p) if String.startsWith(prefix="/todos/", p) => {
                let todoId = String.drop(7, p);
                TodoCommand.DeleteTodo(todoId)
            }
            case ("POST", "/todos/clear") => TodoCommand.ClearCompleted
            case _ => TodoCommand.ViewHomePage
        }
}

enum HttpRequest {
    case HttpRequest(String, String, Map[String, String])
}

mod HttpRequest {
    import java.net.URI
    import java.util.Scanner
    import com.sun.net.httpserver.HttpExchange
    
    pub def fromExchange(exchange: HttpExchange): HttpRequest \ {IO, Net} = {
        let method = exchange.getRequestMethod();
        let path = exchange.getRequestURI().getPath();
        let body = readRequestBody(exchange);
        let formData = parseFormData(body);
        HttpRequest(method, path, formData)
    }
    
    pub def getMethod(req: HttpRequest): String = 
        let HttpRequest(method, _, _) = req;
        method
    
    pub def getPath(req: HttpRequest): String = 
        let HttpRequest(_, path, _) = req;
        path
    
    pub def getFormData(req: HttpRequest): Map[String, String] = 
        let HttpRequest(_, _, formData) = req;
        formData
    
    def readRequestBody(exchange: HttpExchange): String \ IO = {
        let inputStream = exchange.getRequestBody();
        let scanner = new Scanner(inputStream);
        if (scanner.hasNext()) scanner.useDelimiter("\\A").next() else ""
    }
    
    def parseFormData(body: String): Map[String, String] = {
        if (String.isEmpty(body)) {
            Map.empty()
        } else {
            let pairs = String.split(regex="&", body);
            List.foldLeft((acc, pair) -> {
                let parts = String.split(regex="=", pair);
                match parts {
                    case key :: value :: _ => {
                        let decodedKey = String.replace(src="+", dst=" ", key);
                        let decodedValue = String.replace(src="+", dst=" ", value);
                        Map.insert(decodedKey, decodedValue, acc)
                    }
                    case _ => acc
                }
            }, Map.empty(), pairs)
        }
    }
}

mod HttpHelper {
    import com.sun.net.httpserver.HttpExchange

    pub def writeHtmlResponse(exchange: HttpExchange, content: String): Unit \ IO = 
        writeResponse(exchange, content, Map#{
            "Content-Type" => "text/html; charset=utf-8"
        })
    
    pub def writeHtmxResponse(exchange: HttpExchange, content: String): Unit \ IO = 
        writeResponse(exchange, content, Map#{
            "Content-Type" => "text/html; charset=utf-8",
            "HX-Trigger" => "todoUpdated"
        })
    
    pub def writeErrorResponse(exchange: HttpExchange, content: String): Unit \ IO = 
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