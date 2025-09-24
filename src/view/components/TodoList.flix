mod Components {
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
}