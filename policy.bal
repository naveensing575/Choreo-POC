import ballerina/http;
import ballerina/log;

service /userTodos on new http:Listener(8090) { 
    resource function get .(http:Caller caller, http:Request req) returns error? {
        // Extract userId from query parameters
        string? userId = req.getQueryParamValue("userId");
        if userId is () {
            log:printError("Missing userId parameter");
            return caller->respond({"error": "Missing userId parameter"});
        }

        // Define external API endpoints
        string userApiUrl = "https://jsonplaceholder.typicode.com/users/" + userId;
        string todosApiUrl = "https://jsonplaceholder.typicode.com/todos?userId=" + userId;

        // Fetch user details
        http:Client userClient = check new ("https://jsonplaceholder.typicode.com");
        http:Response|error userResponse = userClient->get("/users/" + userId);
        if userResponse is error {
            log:printError("Failed to fetch user data", 'error = userResponse);
            return caller->respond({"error": "Failed to fetch user data"});
        }
        json userJson = check userResponse.getJsonPayload();

        // Fetch user todos
        http:Response|error todosResponse = userClient->get("/todos?userId=" + userId);
        if todosResponse is error {
            log:printError("Failed to fetch todos data", 'error = todosResponse);
            return caller->respond({"error": "Failed to fetch todos data"});
        }
        json todosJson = check todosResponse.getJsonPayload();

        // Combine user and todos data
        json responsePayload = {"user": userJson, "todos": todosJson};

        check caller->respond(responsePayload);
    }
}
