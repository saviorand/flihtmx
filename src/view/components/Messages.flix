mod ViewComponents {
    pub def errorMessage(error: TodoError): String = 
        "<div class='error'>${error}</div>"
    
    pub def successMessage(message: String): String = 
        "<div class='success'>${message}</div>"
}