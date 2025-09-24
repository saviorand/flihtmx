import com.sun.net.httpserver.{HttpServer => JavaHttpServer, HttpHandler, HttpExchange}
import java.lang.InterruptedException
import java.net.InetSocketAddress
import java.lang.Thread
import java.util.Scanner
import java.util.UUID

// =============================================================================
// DOMAIN MODEL
// =============================================================================

enum UserCommand {
    case ViewHomePage
    case ViewTodoList  
    case AddTodo(String)
    case ToggleTodo(String)
    case DeleteTodo(String)
    case UnknownCommand
}

enum Todo with Eq, ToString {
    case Todo(String, String, Bool) // id, text, completed
}

mod Todo {
    pub def getId(todo: Todo): String = match todo {
        case Todo(id, _, _) => id
    }

    pub def getText(todo: Todo): String = match todo {
        case Todo(_, text, _) => text
    }

    pub def isCompleted(todo: Todo): Bool = match todo {
        case Todo(_, _, completed) => completed
    }

    pub def toggle(todo: Todo): Todo = match todo {
        case Todo(id, text, completed) => Todo(id, text, not completed)
    }
}

enum AppState with ToString {
    case AppState(List[Todo])
}

enum HttpResponse {
    case Ok(String, Map[String, String])
    case Error(Int32, String)
}

// =============================================================================
// EFFECTS
// =============================================================================

eff UserCommands {
    def getCurrentCommand(): UserCommand
}

eff TodoState {
    def getAllTodos(): List[Todo]
    def addTodo(text: String): Todo  
    def toggleTodo(id: String): Option[Todo]
    def deleteTodo(id: String): Bool
    def findTodo(id: String): Option[Todo]
}

eff View {
    def showMainPage(): Unit
    def showTodoList(todos: List[Todo]): Unit
    def showTodoItem(todo: Todo): Unit
    def showAddForm(): Unit
    def showError(message: String): Unit
    def showEmptyState(): Unit
}

eff HtmxRenderer {
    def renderAsHtml(content: String): Unit
    def renderPartialHtml(content: String): Unit
}

// =============================================================================
// BUSINESS LOGIC
// =============================================================================

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

// =============================================================================
// UI COMPONENTS
// =============================================================================

mod Components {
    pub def mainPageHtml(): String = String.unlines(List#{
        "<!DOCTYPE html>",
        "<html lang='en'>",
        "<head>",
        "  <meta charset='UTF-8'>",
        "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>",
        "  <title>Effect-Oriented Todo App</title>",
        "  <script src='https://unpkg.com/htmx.org@1.9.10'></script>",
        styles(),
        "</head>",
        "<body>",
        "  <div class='container'>",
        "    <h1>Effect-Oriented Todo App</h1>",
        "    <p class='subtitle'>UI as an Effect</p>",
        addFormHtml(),
        "    <div id='todo-list' hx-get='/todos' hx-trigger='load'>",
        "      Loading todos...",
        "    </div>",
        "  </div>",
        "</body>",
        "</html>"
    })

    pub def addFormHtml(): String = String.unlines(List#{
        "    <div class='add-form'>",
        "      <form class='input-group'",
        "            hx-post='/todos'",
        "            hx-target='#todo-list'",
        "            hx-swap='afterbegin'",
        "            hx-on::after-request='this.reset()'>",
        "        <input type='text' name='text' placeholder='What needs to be done?' required>",
        "        <button type='submit' class='btn'>Add Todo</button>",
        "      </form>",
        "    </div>"
    })

    pub def todoItemHtml(todo: Todo): String = {
        let id = Todo.getId(todo);
        let text = Todo.getText(todo);
        let completed = Todo.isCompleted(todo);
        let checkedAttr = if (completed) "checked" else "";
        let completedClass = if (completed) "completed" else "";

        String.unlines(List#{
            "<div class='todo-item ${completedClass}' id='todo-${id}'>",
            "  <input type='checkbox' ${checkedAttr}",
            "         hx-put='/todos/${id}'",
            "         hx-target='#todo-${id}'",
            "         hx-swap='outerHTML'>",
            "  <span class='todo-text ${completedClass}'>${text}</span>",
            "  <button class='delete-btn'",
            "          hx-delete='/todos/${id}'",
            "          hx-target='#todo-${id}'",
            "          hx-swap='outerHTML'",
            "          title='Delete todo'>",
            "    ✗",
            "  </button>",
            "</div>"
        })
    }

    pub def todoListHtml(todos: List[Todo]): String = {
        if (List.isEmpty(todos)) {
            emptyStateHtml()
        } else {
            let todoItems = List.map(todoItemHtml, List.reverse(todos));
            String.intercalate("", todoItems)
        }
    }

    pub def emptyStateHtml(): String = 
        "<div class='empty-state'>No todos yet. Add one above to get started!</div>"

    pub def errorHtml(message: String): String = 
        "<div class='error'>${message}</div>"

    def styles(): String = String.unlines(List#{
        "  <style>",
        "    body { font-family: 'Segoe UI', system-ui, sans-serif; margin: 0; padding: 0; background: #f8f9fa; }",
        "    .container { max-width: 600px; margin: 0 auto; padding: 2rem; }",
        "    h1 { color: #212529; margin-bottom: 0.5rem; text-align: center; }",
        "    .subtitle { text-align: center; color: #6c757d; margin-bottom: 2rem; }",
        "    .add-form { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); margin-bottom: 2rem; }",
        "    .input-group { display: flex; gap: 0.75rem; }",
        "    .input-group input { flex: 1; padding: 0.75rem; border: 2px solid #dee2e6; border-radius: 6px; font-size: 1rem; }",
        "    .input-group input:focus { outline: none; border-color: #0d6efd; }",
        "    .btn { padding: 0.75rem 1.5rem; background: #0d6efd; color: white; border: none; border-radius: 6px; font-size: 1rem; cursor: pointer; }",
        "    .btn:hover { background: #0b5ed7; }",
        "    .todo-item { background: white; border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); display: flex; align-items: center; gap: 0.75rem; }",
        "    .todo-item.completed { opacity: 0.7; }",
        "    .todo-text { flex: 1; font-size: 1rem; }",
        "    .todo-text.completed { text-decoration: line-through; color: #6c757d; }",
        "    .delete-btn { background: #dc3545; color: white; border: none; border-radius: 50%; width: 30px; height: 30px; cursor: pointer; display: flex; align-items: center; justify-content: center; }",
        "    .delete-btn:hover { background: #bb2d3b; }",
        "    .empty-state { text-align: center; color: #6c757d; padding: 3rem; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }",
        "    .error { color: #dc3545; padding: 1rem; background: #f8d7da; border: 1px solid #f5c2c7; border-radius: 6px; margin: 1rem 0; }",
        "  </style>"
    })
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
            let (maybeTodo, newTodos) = toggleTodoInList(todoId, todos);
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

def toggleTodoInList(todoId: String, todos: List[Todo]): (Option[Todo], List[Todo]) = {
    def helper(remaining, found, acc) = match remaining {
        case Nil => (found, List.reverse(acc))
        case todo :: rest => 
            if (Todo.getId(todo) == todoId) {
                let toggled = Todo.toggle(todo);
                helper(rest, Some(toggled), toggled :: acc)
            } else {
                helper(rest, found, todo :: acc)
            }
    };
    helper(todos, None, Nil)
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

// =============================================================================
// SERVER INFRASTRUCTURE
// =============================================================================

def createHandlerWithState(stateRef: Ref[AppState, r]): HttpHandler \ {IO} = new HttpHandler {
    def $handle(_this: HttpHandler, exchange: HttpExchange): Unit \ {r, IO, Net} = {
        processRequest(stateRef, exchange)
    }
}

def startServerWithState(stateRef: Ref[AppState, r], port: Int32): Unit \ {IO, Net} = {
    let addr = new InetSocketAddress(port);
    let server = JavaHttpServer.create(addr, 0);
    server.createContext("/", createHandlerWithState(stateRef));
    server.start()
}

def initialState(): AppState = AppState.AppState(List#{
    Todo.Todo("1", "Learn UI effects", false),
    Todo.Todo("2", "Separate concerns", false),
    Todo.Todo("3", "Build with effects", false)
})

def main(): Unit \ {IO, Net} =
    region rc {
        let stateRef = Ref.fresh(rc, initialState());
        
        run {
            Logger.info("Starting Effect-Oriented Todo server on port 8080...");
            startServerWithState(stateRef, 8080);
            Logger.info("Server ready! Visit http://localhost:8080");
            
            let currentThread = Thread.currentThread();
            try {
                currentThread.join()
            } catch {
                case _: InterruptedException => 
                    Logger.info("Server interrupted, shutting down...")
            }
            
        } with Logger.runWithIO
    }

// =============================================================================
// HTTP UTILITIES
// =============================================================================

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
