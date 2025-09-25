// Todo.flix
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