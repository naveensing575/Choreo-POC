import ballerina/http;
import ballerina/log;
import choreo/mediation;

@mediation:RequestFlow
public function userTodosIn(mediation:Context ctx, http:Request req)
        returns http:Response|false|error|() {
    string? userId = req.getQueryParamValue("userId");
    if userId is () {
        return error("Missing userId parameter");
    }
    ctx.put("userId", userId);
    return ();
}

@mediation:ResponseFlow
public function userTodosOut(mediation:Context ctx, http:Request req, http:Response res)
        returns http:Response|false|error|() {
    string userId = <string>ctx.get("userId");

    http:Client userClient = check new ("https://jsonplaceholder.typicode.com/users");
    http:Client todosClient = check new ("https://jsonplaceholder.typicode.com/todos");

    http:Response|error userResponse = userClient->get("/" + userId);
    if userResponse is error {
        log:printError("Failed to fetch user data", 'error = userResponse);
        return error("User data fetch failed");
    }
    json userJson = check userResponse.getJsonPayload();

    http:Response|error todosResponse = todosClient->get("?userId=" + userId);
    if todosResponse is error {
        log:printError("Failed to fetch todos data", 'error = todosResponse);
        return error("Todos fetch failed");
    }
    json todosJson = check todosResponse.getJsonPayload();

    json responsePayload = { "user": userJson, "todos": todosJson };
    res.setJsonPayload(responsePayload);
    return res;
}

@mediation:FaultFlow
public function userTodosFault(mediation:Context ctx, http:Request req, http:Response? res, http:Response errFlowRes, error e)
        returns http:Response|false|error|() {
    log:printError("Error in mediation flow", 'error = e);
    return errFlowRes;
}
