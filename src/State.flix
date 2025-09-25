enum AppState with ToString {
    case AppState(List[Todo])
}

def initialState(): AppState = AppState.AppState(List#{
    Todo.Todo("1", "Learn effect-oriented programming", false),
    Todo.Todo("2", "Separate business logic from infrastructure", false),
    Todo.Todo("3", "Build maintainable applications", false)
})

mod TodoState {
    import java.util.UUID

    pub def handleWithInMemory(stateRef: Ref[AppState, r], f: Unit -> a \ ef): a \ (ef - TodoStore + r + IO) =
        run {
            f()
        } with handler TodoStore {
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
                let result = toggleTodoInList(todoId, todos);
                let (updatedTodo, newTodos) = result;
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
}