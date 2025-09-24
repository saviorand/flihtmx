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