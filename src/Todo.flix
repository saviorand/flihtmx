
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

    pub def toggleTodoInList(todoId: String, todos: List[Todo]): (Option[Todo], List[Todo]) = {
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
}

///
/// Todo domain model and state management effect
///
eff TodoState {
    def getAllTodos(): List[Todo]
    def addTodo(text: String): Todo  
    def toggleTodo(id: String): Option[Todo]
    def deleteTodo(id: String): Bool
    def findTodo(id: String): Option[Todo]
}

enum Todo with Eq, ToString {
    case Todo(String, String, Bool) // id, text, completed
}

mod TodoState {
    import java.util.UUID

    ///
    /// In-memory state handler using a reference
    ///
    pub def handleWithInMemory(stateRef: Ref[AppState, r], f: Unit -> a \ ef): a \ (ef - TodoState + r + IO) =
        run {
            f()
        } with handler TodoState {
            def getAllTodos(_, k) = {
                let AppState.AppState(todos) = Ref.get(stateRef);
                k(todos)
            }
            def addTodo(text, k) = {
                let AppState.AppState(todos) = Ref.get(stateRef);
                let id = UUID.randomUUID().toString();
                let newTodo = Todo.Todo(id, text, false);
                let newState = AppState.AppState(newTodo :: todos);
                Ref.put(newState, stateRef);
                k(newTodo)
            }
            def toggleTodo(todoId, k) = {
                let AppState.AppState(todos) = Ref.get(stateRef);
                let (updatedTodo, newTodos) = Todo.toggleTodoInList(todoId, todos);
                Ref.put(AppState.AppState(newTodos), stateRef);
                k(updatedTodo)
            }
            def deleteTodo(todoId, k) = {
                let AppState.AppState(todos) = Ref.get(stateRef);
                let originalLen = List.length(todos);
                let newTodos = List.filter(todo -> Todo.getId(todo) != todoId, todos);
                let deleted = List.length(newTodos) < originalLen;
                if (deleted) {
                    Ref.put(AppState.AppState(newTodos), stateRef)
                } else ();
                k(deleted)
            }
            def findTodo(todoId, k) = {
                let AppState.AppState(todos) = Ref.get(stateRef);
                let maybeTodo = List.find(todo -> Todo.getId(todo) == todoId, todos);
                k(maybeTodo)
            }
        }
}
