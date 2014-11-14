<%@ Page Language="C#" AutoEventWireup="false" %>
<%@ Import Namespace="System.Net" %>
<%
if (txtLink.Text.Length > 0)
{
    using (var client = new WebClient())
    {
        try
        {
            var resp = client.DownloadString(txtLink.Text);
            lblResult.Text = "Got It!";
            preOutput.InnerText = resp;
        }
        catch (WebException e)
        {
            lblResult.Text = e.Message;
            preOutput.InnerText = "";
        }
        
    }
}
%>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Link Checker</title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
        Enter a link to check from the server:<br />
        <asp:TextBox runat="server" ID="txtLink" Width="500px"></asp:TextBox><br />
        <asp:Label runat="server" ID="lblResult"></asp:Label><br />
        <pre id="preOutput" runat="server">

        </pre>
    </div>
    </form>
</body>
</html>
