<%@ Page Language="C#" AutoEventWireup="false" %>
<%
var ipFwd = HttpContext.Current.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];
var ipRemote = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"];
%>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>My IP</title>
</head>
<body>
    <div>
        <label>HTTP X FORWARDED FOR:</label> <%=ipFwd%>
    </div>
    <div>
        <label>REMOTE ADDR:</label> <%=ipRemote%>
    </div>
</body>
</html>
