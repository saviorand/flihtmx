///
/// Effect-Oriented Todo Application with HTMX
/// 
/// This application demonstrates effect-oriented programming principles:
/// 1. Pure business logic
/// 2. Separation of concerns via algebraic effects
/// 3. Clean composition of effect handlers
///
def main(): Unit \ {IO, Net} =
    run {
        startServer(8080)
    } with Logger.runWithIO