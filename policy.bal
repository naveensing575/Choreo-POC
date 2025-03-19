import ballerina/http;
import ballerina/log;
import choreo/mediation;

@mediation:RequestFlow
public function userTodosIn(mediation:Context ctx, http:Request req, string name, string value)
        returns http:Response|false|error|() {
    // Extract userId from query parameters
    string? userId = req.getQueryParamValue("userId");
    if userId is () {
        return error("Missing userId parameter");
    }
    return (); // Continue processing
}

@mediation:ResponseFlow
public function userTodosOut(mediation:Context ctx, http:Request req, http:Response res, string name, string value)
        returns http:Response|false|error|() {
    // Extract userId from query parameters
    string? userId = req.getQueryParamValue("userId");
    if userId is () {
        return error("Missing userId parameter");
    }

    // Define endpoints
    string userApiUrl = "https://jsonplaceholder.typicode.com/users/" + userId;
    string todosApiUrl = "https://jsonplaceholder.typicode.com/todos?userId=" + userId;

    // Create HTTP clients for the APIs
    http:Client userClient = check new (userApiUrl);
    http:Client todosClient = check new (todosApiUrl);

    // Fetch user details
    http:Response|error userResponse = userClient->get("");
    if userResponse is error {
        log:printError("Failed to fetch user data", 'error = userResponse);
        return error("Failed to fetch user data");
    }
    json userJson = check userResponse.getJsonPayload();

    // Fetch user todos
    http:Response|error todosResponse = todosClient->get("");
    if todosResponse is error {
        log:printError("Failed to fetch todos data", 'error = todosResponse);
        return error("Failed to fetch todos data");
    }
    json todosJson = check todosResponse.getJsonPayload();

    // Combine user and todos data
    json responsePayload = {"user": userJson, "todos": todosJson};

    // Respond with combined data
    check res.setJsonPayload(responsePayload);
    return res;
}

@mediation:FaultFlow
public function userTodosFault(mediation:Context ctx, http:Request req, http:Response? res, http:Response errFlowRes,
        error e, string name, string value) returns http:Response|false|error|() {
    log:printError("Error in mediation flow", 'error = e);
    return errFlowRes;
}