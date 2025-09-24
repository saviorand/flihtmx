mod Components {

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
}