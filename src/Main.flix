def main(): Unit \ {IO, Net} =
    region rc {
        let stateRef = Ref.fresh(rc, initialState());
        
        run {
            Logger.info("Starting Effect-Oriented Todo server on port 8080...");
            startServerWithStateRef(stateRef, 8080);
            Logger.info("Server ready! Visit http://localhost:8080")
        } with Logger.runWithIO
    }