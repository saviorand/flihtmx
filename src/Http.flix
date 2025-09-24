import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
import java.net.InetSocketAddress
import java.lang.InterruptedException
import java.lang.Thread
import java.util.Scanner
import java.util.UUID

enum HttpResponse {
    case Ok(String, Map[String, String])
    case Error(Int32, String)
}

def createHandlerWithState(stateRef: Ref[AppState, r]): HttpHandler \ {IO} = new HttpHandler {
    def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \ {r, IO, Net} = {
        processRequest(stateRef, exchange)
    }
}

def startServerWithStateRef(stateRef: Ref[AppState, r], port: Int32): Unit \ {IO, Net, Logger} = {
    let addr = new InetSocketAddress(port);
    let server = JavaHttpServer.create(addr, 0);
    server.createContext("/", createHandlerWithState(stateRef));
    server.start();
    let currentThread = Thread.currentThread();
    try {
        currentThread.join()
    } catch {
        case _: InterruptedException => 
            Logger.info("Server interrupted, shutting down...")
    }
}

def processRequest(stateRef: Ref[AppState, r], exchange: HttpExchange): Unit \ {r, IO, Net} = {
    let method = exchange.getRequestMethod();
    let path = exchange.getRequestURI().getPath();
    let body = readRequestBody(exchange);
    let formData = parseFormData(body);
    let command = parseHttpToCommand(method, path, formData);
    
    let response = match command {
        case UserCommand.ViewHomePage => 
            HttpResponse.Ok(Components.mainPageHtml(), htmlHeaders())
        
        case UserCommand.ViewTodoList => {
            let AppState.AppState(todos) = Ref.get(stateRef);
            HttpResponse.Ok(Components.todoListHtml(todos), htmlHeaders())
        }
        
        case UserCommand.AddTodo(text) => {
            if (not String.isEmpty(String.trim(text))) {
                let AppState.AppState(todos) = Ref.get(stateRef);
                let id = UUID.randomUUID().toString();
                let todo = Todo.Todo(id, String.trim(text), false);
                let newState = AppState.AppState(todo :: todos);
                Ref.put(newState, stateRef);
                HttpResponse.Ok(Components.todoItemHtml(todo), htmlHeaders())
            } else {
                HttpResponse.Ok(Components.errorHtml("Todo text cannot be empty"), htmlHeaders())
            }
        }
        
        case UserCommand.ToggleTodo(todoId) => {
            let AppState.AppState(todos) = Ref.get(stateRef);
            let (maybeTodo, newTodos) = Todo.toggleTodoInList(todoId, todos);
            Ref.put(AppState.AppState(newTodos), stateRef);
            match maybeTodo {
                case Some(todo) => HttpResponse.Ok(Components.todoItemHtml(todo), htmlHeaders())
                case None => HttpResponse.Ok(Components.errorHtml("Todo not found"), htmlHeaders())
            }
        }
        
        case UserCommand.DeleteTodo(todoId) => {
            let AppState.AppState(todos) = Ref.get(stateRef);
            let newTodos = List.filter(todo -> Todo.getId(todo) != todoId, todos);
            Ref.put(AppState.AppState(newTodos), stateRef);
            HttpResponse.Ok("", htmlHeaders())
        }
        
        case UserCommand.UnknownCommand => 
            HttpResponse.Error(404, "Not Found")
    };
    
    writeHttpResponse(exchange, response)
}

def htmlHeaders(): Map[String, String] = 
    Map#{"Content-Type" => "text/html; charset=utf-8"}

def writeHttpResponse(exchange: HttpExchange, response: HttpResponse): Unit \ IO = {
    match response {
        case HttpResponse.Ok(content, headers) => {
            Map.forEach(key -> value -> exchange.getResponseHeaders().set(key, value), headers);
            let responseBytes = content.getBytes();
            exchange.sendResponseHeaders(200, Int32.toInt64(Array.length(responseBytes)));
            let outputStream = exchange.getResponseBody();
            outputStream.write(responseBytes);
            outputStream.close()
        }
        case HttpResponse.Error(code, message) => {
            let responseBytes = message.getBytes();
            exchange.sendResponseHeaders(code, Int32.toInt64(Array.length(responseBytes)));
            let outputStream = exchange.getResponseBody();
            outputStream.write(responseBytes);
            outputStream.close()
        }
    };
    exchange.close()
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

def readRequestBody(exchange: HttpExchange): String \ IO = {
    let inputStream = exchange.getRequestBody();
    let scanner = new Scanner(inputStream);
    if (scanner.hasNext()) scanner.useDelimiter("\\A").next() else ""
}
