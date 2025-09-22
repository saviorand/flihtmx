use Int32.toInt64
import com.sun.net.httpserver.{HttpServer, HttpHandler, HttpExchange}
import java.net.InetSocketAddress
import java.lang.Thread
import java.util.Scanner
import java.io.InputStream

// ===== DATA TYPES =====

enum Todo {
    case Todo(Int32, String, Bool) // id, text, completed
}

struct AppState[r] {
    mut todos: MutList[Todo, r],
    mut nextId: Int32
}

mod AppState {
    pub def create(rc: Region[r]): AppState[r] \ r = 
        new AppState @ rc {
            todos = MutList.empty(rc) !>
                    MutList.push(Todo.Todo(1, "Learn Flix", false)) !>
                    MutList.push(Todo.Todo(2, "Build a web app", false)) !>
                    MutList.push(Todo.Todo(3, "Master HTMX", false)),
            nextId = 4
        }

    pub def getAllTodos(appState: AppState[r]): List[Todo] \ r = 
        MutList.toList(appState->todos)

    pub def addTodo(text: String, appState: AppState[r]): Todo \ r = {
        let id = appState->nextId;
        let todo = Todo.Todo(id, text, false);
        MutList.push(todo, appState->todos);
        appState->nextId = id + 1;
        todo
    }

    pub def toggleTodo(todoId: Int32, appState: AppState[r]): Option[Todo] \ r = {
        let todos = MutList.toList(appState->todos);
        let updated = List.map(todo -> match todo {
            case Todo.Todo(id, text, completed) if id == todoId => 
                Todo.Todo(id, text, not completed)
            case t => t
        }, todos);
        
        MutList.clear(appState->todos);
        List.forEach(t -> MutList.push(t, appState->todos), updated);
        
        List.find(todo -> match todo {
            case Todo.Todo(id, _, _) => id == todoId
        }, updated)
    }

    pub def deleteTodo(todoId: Int32, appState: AppState[r]): Bool \ r = {
        let todos = MutList.toList(appState->todos);
        let filtered = List.filter(todo -> match todo {
            case Todo.Todo(id, _, _) => id != todoId
        }, todos);
        
        MutList.clear(appState->todos);
        List.forEach(t -> MutList.push(t, appState->todos), filtered);
        
        List.length(filtered) < List.length(todos)
    }
}

enum HttpResponse {
    case Ok(String, Map[String, String])
    case Binary(Vector[Int8], String, String)
    case Error(Int32, String)
}

// ===== EFFECTS =====

eff JavaHttpServer {
    def getPath(): String
    def getMethod(): String
    def getBody(): String
    def sendResponse(response: HttpResponse): Unit
}

// ===== BUSINESS LOGIC =====

def renderMainPage(): String = String.unlines(List#{
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "    <title>Effect-Oriented Todo App</title>",
    "    <script src='https://unpkg.com/htmx.org@1.9.10'></script>",
    "    <style>",
    "        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }",
    "        .todo-item { display: flex; align-items: center; gap: 10px; padding: 10px; border: 1px solid #ddd; margin-bottom: 5px; border-radius: 4px; }",
    "        .todo-item.completed { opacity: 0.6; }",
    "        .todo-text.completed { text-decoration: line-through; }",
    "        .delete-btn { color: red; border: none; background: none; cursor: pointer; padding: 5px; }",
    "        .add-form { margin-bottom: 30px; display: flex; gap: 10px; }",
    "        .add-form input { flex: 1; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }",
    "        .add-form button { padding: 10px 20px; background: #007bff; color: white; border: none; border-radius: 4px; }",
    "        h1 { color: #333; }",
    "    </style>",
    "</head>",
    "<body>",
    "    <h1>Effect-Oriented Todo App</h1>",
    "    ",
    "    <form class='add-form' ",
    "          hx-post='/todos' ",
    "          hx-target='#todo-list' ",
    "          hx-swap='afterbegin'",
    "          hx-on::after-request='this.reset()'>",
    "        <input type='text' name='text' placeholder='What needs to be done?' required>",
    "        <button type='submit'>Add Todo</button>",
    "    </form>",
    "    ",
    "    <div id='todo-list' hx-get='/todos' hx-trigger='load'>",
    "        Loading todos...",
    "    </div>",
    "</body>",
    "</html>"
})

def renderTodoItem(todo: Todo): String = {
    let Todo.Todo(id, text, completed) = todo;
    let checkedAttr = if (completed) "checked" else "";
    let completedClass = if (completed) "completed" else "";
    String.unlines(List#{
        "<div class='todo-item ${completedClass}' id='todo-${id}'>",
        "    <input type='checkbox' ${checkedAttr}",
        "           hx-put='/todos/${id}'",
        "           hx-target='#todo-${id}'",
        "           hx-swap='outerHTML'>",
        "    <span class='todo-text ${completedClass}'>${text}</span>",
        "    <button class='delete-btn'",
        "            hx-delete='/todos/${id}'",
        "            hx-target='#todo-${id}'",
        "            hx-swap='outerHTML'>",
        "        ✗",
        "    </button>",
        "</div>"
    })
}

def renderTodoList(todos: List[Todo]): String = {
    if (List.isEmpty(todos)) {
        "<div style='text-align: center; color: #666; padding: 40px;'>No todos yet. Add one above!</div>"
    } else {
        let todoItems = List.map(renderTodoItem, todos) |> String.intercalate("");
        todoItems
    }
}

def parseFormData(body: String, key: String): Option[String] = {
    let pairs = String.split(regex="&", body);
    let keyValue = List.findLeft(pair -> String.startsWith(prefix="${key}=", pair), pairs);
    match keyValue {
        case Some(kv) => 
            let value = String.drop(String.length(key) + 1, kv);
            Some(String.replace(src="+", dst=" ", value))
        case None => None
    }
}

def handleTodoApp(appState: AppState[r]): HttpResponse \ {JavaHttpServer, r} = {
    let path = JavaHttpServer.getPath();
    let method = JavaHttpServer.getMethod();
    
    match (method, path) {
        case ("GET", "/") => 
            HttpResponse.Ok(renderMainPage(), Map#{"Content-Type" => "text/html"})
            
        case ("GET", "/todos") => 
            let todos = AppState.getAllTodos(appState);
            HttpResponse.Ok(renderTodoList(todos), Map#{})
            
        case ("POST", "/todos") => {
            let body = JavaHttpServer.getBody();
            let text = parseFormData(body, "text");
            match text {
                case Some(todoText) if not String.isEmpty(String.trim(todoText)) => {
                    let todo = AppState.addTodo(String.trim(todoText), appState);
                    HttpResponse.Ok(renderTodoItem(todo), Map#{})
                }
                case _ => 
                    HttpResponse.Ok("<div class='error'>Todo text cannot be empty</div>", Map#{})
            }
        }
            
        case ("PUT", p) if String.startsWith(prefix="/todos/", p) => {
            let idStr = String.drop(7, p);
            match Int32.parse(10, idStr) {
                case Ok(todoId) => 
                    match AppState.toggleTodo(todoId, appState) {
                        case Some(todo) => HttpResponse.Ok(renderTodoItem(todo), Map#{})
                        case None => HttpResponse.Ok("<div class='error'>Todo not found</div>", Map#{})
                    }
                case Err(_) => 
                    HttpResponse.Ok("<div class='error'>Invalid todo ID</div>", Map#{})
            }
        }
            
        case ("DELETE", p) if String.startsWith(prefix="/todos/", p) => {
            let idStr = String.drop(7, p);
            match Int32.parse(10, idStr) {
                case Ok(todoId) => {
                    AppState.deleteTodo(todoId, appState);
                    HttpResponse.Ok("", Map#{})
                }
                case Err(_) => 
                    HttpResponse.Ok("<div class='error'>Invalid todo ID</div>", Map#{})
            }
        }
            
        case _ => HttpResponse.Error(404, "Not Found")
    }
}

// ===== SERVER SETUP =====

def main(): Unit \ {IO, Net} = 
    run {
        region rc {
            let appState = AppState.create(rc);
            startServer(8080, appState)
        }
    } with Logger.runWithIO

def startServer(port: Int32, appState: AppState[r]): Unit \ {IO, Net, Logger} = {
    let addr = new InetSocketAddress(port);
    let server = HttpServer.create(addr, 0);

    server.createContext("/", createHandler(appState));

    Logger.info("Starting Todo HTTP server on port ${port}...");
    server.start();
    Logger.info("Server started! Visit http://localhost:${port}");

    unsafe Thread.currentThread().join()
}

def createHandler(appState: AppState[r]): HttpHandler \ IO = new HttpHandler {
    def $handle(_this: HttpHandler, exchange: HttpExchange): Unit = {
        unsafe run {
            let response = handleTodoApp(appState);
            JavaHttpServer.sendResponse(response)
        } 
        with Logger.runWithIO
        with handler JavaHttpServer {
            def getPath(_, resume) = resume(exchange.getRequestURI().getPath())
            def getMethod(_, resume) = resume(exchange.getRequestMethod())
            def getBody(_, resume) = {
                let inputStream = exchange.getRequestBody();
                let scanner = new Scanner(inputStream);
                let body = if (scanner.hasNext()) scanner.useDelimiter("\\A").next() else "";
                resume(body)
            }
            def sendResponse(response, resume) = {
                match response {
                    case HttpResponse.Ok(content, headers) => {
                        sendStringResponseWithHeaders(exchange, 200, content, headers);
                        resume()
                    }
                    case HttpResponse.Binary(bytes, contentType, fileName) => {
                        exchange.getResponseHeaders().set("Content-Type", contentType);
                        exchange.getResponseHeaders().set("Content-Disposition", "attachment; filename=\"${fileName}\"");
                        sendBinaryResponse(exchange, 200, bytes);
                        resume()
                    }
                    case HttpResponse.Error(code, message) => {
                        sendStringResponse(exchange, code, message);
                        resume()
                    }
                }
            }
        } 
    }
}

def sendStringResponse(exchange: HttpExchange, code: Int32, content: String): Unit \ IO = {
    let responseBytes = content.getBytes();
    exchange.sendResponseHeaders(code, toInt64(String.length(content)));
    let outputStream = exchange.getResponseBody();
    outputStream.write(responseBytes);
    outputStream.close();
    exchange.close()
}

def sendStringResponseWithHeaders(exchange: HttpExchange, code: Int32, content: String, headers: Map[String, String]): Unit \ IO = {
    Map.forEach(k -> v -> exchange.getResponseHeaders().set(k, v), headers);
    let responseBytes = content.getBytes();
    exchange.sendResponseHeaders(code, toInt64(String.length(content)));
    let outputStream = exchange.getResponseBody();
    outputStream.write(responseBytes);
    outputStream.close();
    exchange.close()
}

def sendBinaryResponse(exchange: HttpExchange, code: Int32, content: Vector[Int8]): Unit \ IO = {
    exchange.sendResponseHeaders(code, toInt64(Vector.length(content)));
    let outputStream = exchange.getResponseBody();
    outputStream.write(content);
    outputStream.close();
    exchange.close()
}