enum AppState with ToString {
    case AppState(List[Todo])
}

def initialState(): AppState = AppState.AppState(List#{
    Todo.Todo("1", "Learn UI effects", false),
    Todo.Todo("2", "Separate concerns", false),
    Todo.Todo("3", "Build with effects", false)
})