<%@ Page Language="C#" AutoEventWireup="false" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Xml" %>
<%@ Import Namespace="Bba.GclIntegrator.Configuration" %>
<%@ Import Namespace="SitefinityWebApp" %>
<%@ Import Namespace="Telerik.Sitefinity.Security" %>
<%@ Import Namespace="Telerik.Sitefinity.Security.Claims" %>
<%@ Import Namespace="SitefinityWebApp.EfData" %>
<%
    try
    {
        string iata;
        iata = Request.QueryString["iata"] + "";
        if (iata == "")
            iata = "anc"; // TO DO: redirect to home.
        List<SitefinityWebApp.EfData.Location> locs;
        List<ExclusivePromotion> promos;
        List<GetLocationContacts_Result> contacts;
        List<GetRegionsWithUSA_Result> regions;
        List<GetLocationExtraContent_Result> extraContents;
        List<AirnavComment> locComments;
        List<GetLocationVendors_Result> locVendors;
        List<LocationLogo> locLogos;

        using (var ctx = new SFS_Web_ContentEntities())
        {
            try
            {
                locs = ctx.Locations.Where(x => x.iata == iata).ToList();
                promos = ctx.LocationExclusivePromotions.Where(x => x.Location.iata == iata).Select(y => y.ExclusivePromotion).ToList();
                contacts = ctx.GetLocationContacts(iata).ToList();
                regions = ctx.GetRegionsWithUSA().ToList();
                extraContents = ctx.GetLocationExtraContent(iata, "LocationAlert").ToList();
                locComments = ctx.AirnavComments.Where(x => x.Location.iata == iata).ToList();
                locVendors = ctx.GetLocationVendors(iata).ToList();
                locLogos = ctx.LocationLogos.Where(x => x.Location.iata == iata).ToList();
            }
            catch (Exception exception)
            {
                Console.WriteLine(exception);
                return;
            }
        }

        if (locs.Any() == false) // no location found
            Response.Redirect("/", true);

        //Begin: PopulateLocationImages 
        var LocationImages = new Dictionary<string, List<string>>();
        var imgPath = MapPath(ConfigurationManager.AppSettings["LocationImagesUrl"]);
        if (string.IsNullOrEmpty(imgPath) || Directory.Exists(imgPath) == false) return;
        var imgDir = new DirectoryInfo(imgPath);
        locs.ForEach(l => LocationImages.Add(l.iata,
                                             imgDir.GetFiles()
                                                   .Where(fi => fi.Name.StartsWith(l.iata))
                                                   .Select(fi => fi.Name)
                                                   .ToList()));
        //End: PopulateLocationImages


        var locAttractions = locVendors.Where(x => x.vendorTypeId == "Area_Attraction").ToList();
        var locRestaurants = locVendors.Where(x => x.vendorTypeId == "Restaurant").ToList();
        var locCaterers = locVendors.Where(x => x.vendorTypeId == "Caterer").ToList();
        var locTransportation = locVendors.Where(x => x.vendorTypeId == "Limousine/Transportation").ToList();
        var locMaintenance = locVendors.Where(x => x.vendorTypeId == "Maintenance").ToList();

        // mobile
        rp_LocationDetailMobile.DataSource = locs;
        rp_LocationDetailMobile.DataBind();
        div_CarRental_m.Visible = locs[0].isShowCarRental;
        var rpPromos = (Repeater)rp_LocationDetailMobile.Items[0].FindControl("rp_promos");
        rpPromos.DataSource = promos;
        rpPromos.DataBind();
        var rpContacts = (Repeater)rp_LocationDetailMobile.Items[0].FindControl("rp_contacts");
        rpContacts.DataSource = contacts;
        rpContacts.DataBind();
        if (locAttractions.Any())
        {
            rp_attractions_m.Visible = true;
            rp_attractions_m.DataSource = locAttractions;
            rp_attractions_m.DataBind();
        }
        if (locRestaurants.Any())
        {
            rp_restaurants_m.Visible = true;
            rp_restaurants_m.DataSource = locRestaurants;
            rp_restaurants_m.DataBind();
        }
        if (locCaterers.Any())
        {
            rp_caterers_m.Visible = true;
            rp_caterers_m.DataSource = locCaterers;
            rp_caterers_m.DataBind();
        }
        if (locTransportation.Any())
        {
            rp_transportation_m.Visible = true;
            rp_transportation_m.DataSource = locTransportation;
            rp_transportation_m.DataBind();
        }
        if (locMaintenance.Any())
        {
            rp_maintenance_m.Visible = true;
            rp_maintenance_m.DataSource = locMaintenance;
            rp_maintenance_m.DataBind();
        }

        var w = new Bba.GclIntegrator.Worker();
        var ident = ClaimsManager.GetCurrentIdentity();
        List<Bba.GclIntegrator.Hotel> hotels;
        if (ident.IsAuthenticated)
        {
            try
            {
                var gclConfig = (GclConfigurationSection)ConfigurationManager.GetSection("GclConfigurationSection");
                BbaCommonContracts.ISignatureUser user = UserManager.GetManager().GetCrmUser();
                hotels = w.GetHotels(iata, user.UserId.ToString(), user.FirstName, user.LastName, user.EmailAddress, gclConfig.RedirectUrl).OrderBy(x => x.Miles).ToList();
            }
            catch (Exception exc)
            {
                hotels = w.GetHotels(iata).OrderBy(x => x.Miles).ToList();
            }
        }
        else
            hotels = w.GetHotels(iata).OrderBy(x => x.Miles).ToList();

        if (hotels.Any())
        {
            rp_hotels_m.Visible = true;
            rp_hotels_m.DataSource = hotels;
            rp_hotels_m.DataBind();
        }

        img_map1.ImageUrl = String.Format("{1}{0}-runway.jpg", iata, ConfigurationManager.AppSettings["LocationMapsUrl"]);
        img_map2.ImageUrl = String.Format("{1}{0}-map.jpg", iata, ConfigurationManager.AppSettings["LocationMapsUrl"]);

        // nav
        rp_nav.DataSource = regions;
        rp_nav.DataBind();

        // desktop
        rp_location_d.DataSource = locs;
        rp_location_d.DataBind();


        var rpPromosd = (Repeater)rp_location_d.Items[0].FindControl("rp_promos_d");
        rpPromosd.DataSource = promos;
        rpPromosd.DataBind();
        var rpContactsd = (Repeater)rp_location_d.Items[0].FindControl("rp_contacts_d");
        rpContactsd.DataSource = contacts;
        rpContactsd.DataBind();

        if (extraContents.Any())
        {
            var rpExtraContent = (Repeater)rp_location_d.Items[0].FindControl("rp_extraContent");
            rpExtraContent.Visible = true;
            rpExtraContent.DataSource = extraContents;
            rpExtraContent.DataBind();
        }


        if (locComments.Any())
        {
            var rpComments = (Repeater)rp_location_d.Items[0].FindControl("rp_comments");
            rpComments.Visible = true;
            rpComments.DataSource = locComments;
            rpComments.DataBind();
        }

        if (hotels.Any())
        {
            var rpHotelsd = (Repeater)rp_location_d.Items[0].FindControl("rp_hotels_d");
            rpHotelsd.Visible = true;
            rpHotelsd.DataSource = hotels;
            rpHotelsd.DataBind();
        }

        if (locAttractions.Any())
        {
            var rpAttractionsd = (Repeater)rp_location_d.Items[0].FindControl("rp_attractions_d");
            rpAttractionsd.Visible = true;
            rpAttractionsd.DataSource = locAttractions;
            rpAttractionsd.DataBind();
        }
        if (locRestaurants.Any())
        {
            var rpRestaurantsd = (Repeater)rp_location_d.Items[0].FindControl("rp_restaurants_d");
            rpRestaurantsd.Visible = true;
            rpRestaurantsd.DataSource = locRestaurants;
            rpRestaurantsd.DataBind();
        }
        if (locCaterers.Any())
        {
            var rpCaterersd = (Repeater)rp_location_d.Items[0].FindControl("rp_caterers_d");
            rpCaterersd.Visible = true;
            rpCaterersd.DataSource = locCaterers;
            rpCaterersd.DataBind();
        }
        if (locTransportation.Any())
        {
            var rpTransportationsd = (Repeater)rp_location_d.Items[0].FindControl("rp_transportation_d");
            rpTransportationsd.Visible = true;
            rpTransportationsd.DataSource = locTransportation;
            rpTransportationsd.DataBind();
        }
        if (locMaintenance.Any())
        {
            var rpMaintenanced = (Repeater)rp_location_d.Items[0].FindControl("rp_maintenance_d");
            rpMaintenanced.Visible = true;
            rpMaintenanced.DataSource = locMaintenance;
            rpMaintenanced.DataBind();
        }

        var divTime = (HtmlGenericControl)rp_location_d.Items[0].FindControl("div_time");
        var litTime = (Literal)rp_location_d.Items[0].FindControl("lit_time");

        //Begin: GetLocationTime
        string getVars = String.Format("?lat={0}&lng={1}&username=bbageo", locs[0].latitude.ToString(), locs[0].longitude.ToString());
        var timeUrl = string.Format("http://api.geonames.org/timezone{0}", getVars);
        try
        {
            string retVal = "unavailable";
            //Initialization, we use localhost, change if applicable
            var webReq = (HttpWebRequest)WebRequest.Create(timeUrl);
            webReq.Method = "GET";

            var webResp = (HttpWebResponse)webReq.GetResponse();
            //Let's show some information about the response
            //Console.WriteLine(WebResp.StatusCode);
            //Console.WriteLine(WebResp.Server);

            //Now, we read the response (the string), and output it.
            var answer = webResp.GetResponseStream();
            string respText;
            using (var answerReader = new StreamReader(answer))
            {
                respText = answerReader.ReadToEnd();
            }
            var xdLoginResponse = new XmlDocument();

            xdLoginResponse.LoadXml(respText);
            if (xdLoginResponse.DocumentElement != null)
            {
                if (xdLoginResponse.DocumentElement.FirstChild.Name != "status")
                {
                    var xnTime = xdLoginResponse.DocumentElement.FirstChild["time"];
                    if (xnTime != null)
                    {
                        var aDateAndTime = xnTime.InnerText.Split(' ');
                        var aDate = aDateAndTime[0].Split('-');
                        var aTime = aDateAndTime[1].Split(':');
                        retVal = String.Format("{0}:{1}", aTime[0], aTime[1]);
                    }
                }
            }

            litTime.Text = retVal;
        }
        catch (Exception exTime)
        {
            lblError.Text = String.Format("Failed in GetLocationTime: {2}<br />Message: {0}<br />Stack Trace:<br /><br />{1}<br /><br />", exTime.Message, exTime.StackTrace, timeUrl);
            litTime.Text = "FAILED";
        }

        //End: GetLocationTime

        if (litTime.Text == "unavailable")
            litTime.Visible = false;

        // company logo and location logo
        var divTopRightContent = (HtmlGenericControl)rp_location_d.Items[0].FindControl("div_RightTopContent");
        var divRightContent = (HtmlGenericControl)rp_location_d.Items[0].FindControl("div_RightContent");
        var imgCompanyLogo = (HtmlImage)rp_location_d.Items[0].FindControl("img_company");
        var imgLocationLogo = (HtmlImage)rp_location_d.Items[0].FindControl("img_logo");
        var lblCompanyName = (Label)rp_location_d.Items[0].FindControl("lbl_companyName");
        if (locLogos.Any() || locs[0].isSignatureSelect)
        {
            divRightContent.Attributes.Add("style", "padding-top:20px!important;");
            divTopRightContent.Visible = true;
            if (locLogos.Any())
            {
                imgLocationLogo.Src = ConfigurationManager.AppSettings["LocationLogosUrl"] + locLogos[0].imageName;
                imgLocationLogo.Attributes.Add("onclick", "window.open('" + locLogos[0].externalUrl + "', '_blank')");
                //lblCompanyName.Text = locs[0].locationName;
                imgLocationLogo.Visible = true;
            }
            if (locs[0].isSignatureSelect)
            {
                imgCompanyLogo.Src = "/img/ss_logo.png";
                imgCompanyLogo.Visible = true;
            }
        }

    }
    catch (Exception ex)
    {
        lblError.Text = String.Format("Message: {0}<br />Stack Trace:<br /><br />{1}<br /><br />", ex.Message, ex.StackTrace);
        //throw;
    }    
%>    

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Location Data Test</title>
    <link rel="stylesheet" href="/files/Styles/normalize.css" />
    <link rel="stylesheet" href="/files/Styles/style.css" />
    <link rel="stylesheet" href="/files/Styles/jquery.selectbox.css" />
    <link rel="stylesheet" href="/files/Scripts/projekktor/theme/maccaco/projekktor.style.css" type="text/css" media="screen" />    
    <!-- Stylesheet for exteral fonts from Fonts.com -->
    <link type="text/css" rel="stylesheet" href="//fast.fonts.net/cssapi/359bda7c-efc0-4894-b63a-d56802f6e833.css" />
    <script src="/files/Scripts/bxslider/jquery.bxslider.min.js"></script>
</head>
<body>
    <asp:Label runat="server" class="sfError" ID="lblError"></asp:Label>
    <form id="form1" runat="server">
<div class="hideInDesk container100 whiteBk" >

    <asp:Repeater runat="server" ID="rp_LocationDetailMobile">
        <ItemTemplate>
            <asp:Repeater runat="server" ID="rp_LocationImages">
                <HeaderTemplate>
                    <ul id='<%# string.Format("{0}{1}", "bxSlider-Images", Eval("iata")) %>'>
                </HeaderTemplate>
                <ItemTemplate>
                    <li>
                        <img src='<%# Eval("image") %>' alt="">
                    </li>
                </ItemTemplate>
                <FooterTemplate>
                    </ul>
                    <script>
                        $(function () {
                            var container = $('#<%# string.Format("{0}{1}", "bxSlider-Images", Eval("iata")) %>');
                            if (container.find('img').length > 1) {
                                container.bxSlider({
                                    controls: false,
                                    pager: false
                                }).startAuto();
                            }
                        });
                    </script>
                </FooterTemplate>
            </asp:Repeater>	        

	        <div style="margin:0 auto; width:90%;">
		        <h1 class="textNeueTh" style="font-size:90px;line-height:80px;margin:0;padding:0;"><%# Eval("Iata") %></h1>
		        <span style="font-size:20px;"><%# Eval("AirportName") %></span>
	        </div>

	        <div style="width:100%;">
		        <div class="floatL" style="width:50%;"><a href='tel:<%# Eval("Phone") %>'><img src="/img/butn_mob_loc_callUs.gif" alt=""></a></div>
		        <div class="floatL" style="width:50%;"><a href='mailto:<%# Eval("Email") %>'><img src="/img/butn_mob_loc_emailUs.gif" alt=""></a></div>
	        </div>
            <asp:Repeater runat="server" ID="rp_promos">
                <ItemTemplate>
                    <div class="col1Bk white" style="padding:15px;margin-bottom:15px;clear:both;">		                        
                                <%# Eval("StartDate", "{0:MMM d}") %>-<%# Eval("EndDate", "{0:MMM d, yyyy}") %>
                                <br>
		                        <span class="textNeueTh" style="font-size:20px;"><%# Eval("Description") %></span>
	                </div>
                    <%--<div class="col1Bk white" style="padding:15px;">
                        <%# Eval("StartDate", "{0:MMM d}") %>-<%# Eval("EndDate", "{0:MMM d, yyyy}") %>
                        <br>
		                <span class="textNeueTh" style="font-size:20px;"><%# Eval("Title") %></span>
	                </div>--%>
                </ItemTemplate>
            </asp:Repeater>
	        
            <div style="margin-bottom:15px;clear:both;"></div>

	        <div style="margin:0 auto; width:90%;">
		        <p>
			        <a href='mailto:<%# Eval("Email") %>'><%# Eval("Email") %></a><br>
			        P <%# Eval("Phone") %><br>
			        F <%# Eval("Fax") %><br>
			        <%# Eval("Hours") %><br>
			        <asp:Repeater runat="server" ID="rp_contacts">
                        <ItemTemplate>
                            <%# "<a href='mailto:"+ Eval("email") +"'>"+ Eval("name") + "</a><br>" + Eval("jobTitle") + "<br>" %>
                        </ItemTemplate>
			        </asp:Repeater>
			        <a href='http://maps.google.com/maps?q=<%# ""+Eval("latitude")+","+Eval("longitude") %>' target="maps" ><%# Eval("StreetNumber") %> <%# Eval("Street") %><br>
			        <%# Eval("City") %>, <%# Eval("State") %> <%# Eval("PostalCode") %></a><br>
			        UNICOM: <%# Eval("UNICOM") %><br>
			        ARINC: <%# Eval("ARINC") %><br>
                    VHF: <%# Eval("VHF") %><br>
		        </p>

		        <p>
			        <%# Eval("MainDescription") %>
		        </p>

		        <strong>Features</strong><br>
		        <p class="">
			        <%# Eval("Features") %>
		        </p>

		        <strong>Support Services</strong><br>
		        <p class="">
			        <%# Eval("SupportServices") %>
		        </p>

		        <strong>Specialties</strong><br>
		        <p class="">
			        <%# Eval("Specialties") %>
		        </p> 
	        </div>
        </ItemTemplate>
    </asp:Repeater>


	<div class="locLineBottom">
		<p style="padding:17px 0 5px 15px;margin:0;"><strong>Local Services</strong></p>
	</div>
	<div>
        <asp:Repeater runat="server" ID="rp_hotels_m" Visible="false">            
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Hotels</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate>  
	                    <div class="mobNavLocDrop <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : "pointer" %>" <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : ("onclick=\"window.open('"+ Eval("url") + "', '_blank');\"") %>>
	                        <div class="dropButn <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : "iconSpanFBOSide pointer" %>"></div>
	                        <span><%# Eval("name") %>
                                <%# ((decimal)Eval("miles") < 0) ? "" : "<br />" + Eval("miles", "{0:F2}") + " miles" %>
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
          	        </div>
        	    </div>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Repeater runat="server" ID="rp_attractions_m" Visible="false">
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Attractions</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate> 
                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                        <div class="dropButn iconSpanFBOSide"></div>
	                        <span><%# Eval("VendorName") %>                                                
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
                    </div>
        	    </div>
             </FooterTemplate>
        </asp:Repeater>

        <asp:Repeater runat="server" ID="rp_restaurants_m" Visible="false">
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Restaurants</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate> 
                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                        <div class="dropButn iconSpanFBOSide"></div>
	                        <span><%# Eval("VendorName") %>                                                
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
                    </div>
        	    </div>
             </FooterTemplate>
        </asp:Repeater>

        <asp:Repeater runat="server" ID="rp_caterers_m" Visible="false">
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Caterers</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate> 
                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                        <div class="dropButn iconSpanFBOSide"></div>
	                        <span><%# Eval("VendorName") %>                                                
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
                    </div>
        	    </div>
             </FooterTemplate>
        </asp:Repeater>

        <asp:Repeater runat="server" ID="rp_transportation_m" Visible="false">
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Transportation</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate> 
                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                        <div class="dropButn iconSpanFBOSide"></div>
	                        <span><%# Eval("VendorName") %>                                                
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
                    </div>
        	    </div>
             </FooterTemplate>
        </asp:Repeater>

        <asp:Repeater runat="server" ID="rp_maintenance_m" Visible="false">
            <HeaderTemplate>
                <div class="mobNavLocFBOSide clearfix">
	                <span class="mobSubnavLink">Maintenance</span> 
	                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                <div class="dropdownDiv whiteBk">
            </HeaderTemplate>
            <ItemTemplate> 
                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                        <div class="dropButn iconSpanFBOSide"></div>
	                        <span><%# Eval("VendorName") %>                                                
	                        </span>
	                    </div>
            </ItemTemplate>
            <FooterTemplate>
                    </div>
        	    </div>
             </FooterTemplate>
        </asp:Repeater>

	    <div class="mobNavLocFBOSide clearfix">
	        <span class="mobSubnavLink">Maps</span> 
	        <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	        <div class="dropdownDiv whiteBk">
	            <div class="mobNavLocDrop">	                
	                <span><asp:Image runat="server" ID="img_map1" /></span>
	            </div>
	            <div class="mobNavLocDrop">	                
	                <span><asp:Image runat="server" ID="img_map2" /></span>
	            </div>
	        </div>
        </div>
	</div>
    <div style="text-align:center;" runat="server" id="div_CarRental_m"><a href='<%# ConfigurationManager.AppSettings["NationalCarRentalUrl"] %>'><img src="/img/butn_national_emerald_club.gif" alt="National Emerald Club"></a></div>
</div>

<!-- Static locations nav -->
<div class="container100 col1Bk locHeadContainer clearfix hideInMob"> <!-- Allows for background colors -->
	<asp:Repeater runat="server" ID="rp_nav">
        <HeaderTemplate>
            <div class="innerContainer clearfix"> <!-- Width of website -->
		        <div class="contentDiv"> <!-- Width of content. Less than 100% allows for left/right white space. -->
		            <div class="row clearfix">

			            <div class="spacerDiv col">&nbsp;</div> <!-- spacer Div -->
			            <div class="fullWidth col">
				            <h1 class="locHead textNeueTh white">Locations</h1>

				            <!-- Desktop navigation -->
				            <ul class="locSingleCategories">
        </HeaderTemplate>
        <ItemTemplate>  
                                <li>
						            <a href='locations?rid=<%# Eval("regionId")%>'><%# Eval("regionName")%></a>
						            <img src="/img/graphic_triangle_blue.png" alt="" />
					            </li>
        </ItemTemplate>
        <FooterTemplate>
                            </ul>		
			            </div>
			            <div class="spacerDiv col">&nbsp;</div> <!-- spacer Div -->

		            </div> <!-- /row -->
		        </div> <!-- /contentDiv -->
	        </div> <!-- /innerContainer -->
        </FooterTemplate>
    </asp:Repeater>
</div> <!-- /container100 -->


<!-- Middle Section -->
<div class="container100 whiteBk clearfix"> <!-- Allows for background colors -->
    <asp:Repeater runat="server" ID="rp_location_d">
        <ItemTemplate>
	<div class="innerContainer clearfix"> <!-- Width of website -->
		<div class="contentDiv"> <!-- Width of content. Less than 100% allows for left/right white space. -->


		<div class="row clearfix hideInMob">

			<div class="spacerDiv col">&nbsp;</div> <!-- spacer Div -->
			<div class="locMidLeft col">

				<div class="locLtCol clearfix">
					<h1 class="textNeueTh" style="font-size:90px;line-height:80px;margin:0;padding:0;"><%# Eval("iata") %></h1>
					<span style="font-size:20px;"><%# Eval("airportName") %></span>
                    <asp:Repeater runat="server" ID="rp_LocationImages">
                        <HeaderTemplate>
                            <div id='<%# string.Format("{0}{1}", "bxSlider-Images-Desk-", Eval("iata")) %>'>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <div>
                                <img src='<%# Eval("image") %>' alt="" class="marBot25 marTop15">
                            </div>
                        </ItemTemplate>
                        <FooterTemplate>
                            </div>
                            <script>
                                $(function() {
                                    var container = $('#<%# string.Format("{0}{1}", "bxSlider-Images-Desk-", Eval("iata")) %>');
                                    if (container.find('img').length > 1) {
                                        container.bxSlider({
                                            controls: false,
                                            pager: false
                                        }).startAuto();
                                    }
                                });
                            </script>
                        </FooterTemplate>
                    </asp:Repeater>
					<div class="locInfoDiv">
						<p class="text13">
							<a href='mailto:<%# Eval("Email") %>'><%# Eval("Email") %></a><br>
			                P <%# Eval("Phone") %><br>
			                F <%# Eval("Fax") %><br>
			                <%# Eval("Hours") %><br>
			                <asp:Repeater runat="server" ID="rp_contacts_d">
                                <ItemTemplate>
                                    <%# "<a href='mailto:"+ Eval("email") +"'>"+ Eval("name") + "</a><br>" + Eval("jobTitle") + "<br>" %>
                                </ItemTemplate>
			                </asp:Repeater>
			                <a href='http://maps.google.com/maps?q=<%# ""+Eval("latitude")+","+Eval("longitude") %>' target="maps"><%# Eval("StreetNumber") %> <%# Eval("Street") %><br>
			                <%# Eval("City") %>, <%# Eval("State") %> <%# Eval("PostalCode") %></a><br>
			                UNICOM: <%# Eval("UNICOM") %><br>
			                ARINC: <%# Eval("ARINC") %><br>
                            VHF: <%# Eval("VHF") %><br>
						</p>
					</div>
					<div style="float:left;width:30%;">
						<img class="marBot15" src="/img/logo_daasp.gif" alt="DAASP Logo" runat="server" visible='<%# Eval("IsDASSP") %>'>
						<div class="floatL locButnDiv" style='width:100%;cursor: pointer; display:<%# (bool)Eval("isAvailableRealEstate") ? "block" : "none" %>;' onClick="location.href='http://hangarnetwork.com/search/<%# Eval("iata") %>';">
							Available Real Estate
						</div>
					</div>

					<asp:Repeater runat="server" ID="rp_promos_d">
                        <ItemTemplate>
                            <div class="col1Bk white" style="padding:15px;margin-bottom:15px;clear:both;">		                        
                                <%# Eval("StartDate", "{0:MMM d}") %>-<%# Eval("EndDate", "{0:MMM d, yyyy}") %>
                                <br>
		                        <span class="textNeueTh" style="font-size:20px;"><%# Eval("Description") %></span>
	                        </div>
                        </ItemTemplate>
                    </asp:Repeater>

					<span runat="server" id="div_CarRental_d" visible='<%# Eval("isShowCarRental") %>'><a href='<%# ConfigurationManager.AppSettings["NationalCarRentalUrl"] %>'><img class="marBot15" src="/img/butn_national_emerald_club.gif" alt="National Emerald Club"></a></span>

					<div style="clear:both;"></div>
					<div class="floatL locButnDiv" style="margin-right:3%; cursor: pointer;" onClick="location.href='http://www.fltplan.com';">
						Fltplan
					</div>
					<div class="floatL locButnDiv" style="margin-right:3%; cursor: pointer;" onClick="location.href='http://www.airnav.com';">
						AirNav
					</div>
					<div class="floatL locButnDiv" style="cursor: pointer;" onClick="location.href='http://www.foreflight.com';">
						ForeFlight
					</div>
				</div>

			</div>
			<div class="locMidRight col">
				<div class="locMidCol floatL clearfix" runat="server" id="div_RightContent">
                    <div runat="server" id="div_RightTopContent" style="text-align:center;">
                        <img runat="server" ID="img_company" Visible="false" />
                        <img runat="server" ID="img_logo" Visible="false" class="pointer" />
                        <p><asp:Label runat="server" ID="lbl_companyName" ></asp:Label></p>
                    </div>
					<div class="floatL locButnDiv" style='margin-right:3%; cursor: pointer; display:<%# (bool)Eval("isCalculateFuel") ? "block" : "none" %>;' onclick="window.open('<%# ConfigurationManager.AppSettings["FuelCalculatorUrl"] %>','detail','left=500,top=200,scrollbars=0,width=480,height=640,toolbar=0,menubar=0,resizable=0');" >
						<p>Calculate Fuel Prices</p>
					</div>
					<div class="floatL locButnDiv" style="margin-right:3%; cursor: pointer;" onClick="location.href='/reservations';" runat="server" visible='<%# Eval("isShowReservationButton") %>'>
						<p>Make a Reservation</p>
					</div>
					<div class="floatL locButnDiv" style="cursor: pointer;" onClick="location.href='http://www.fltplan.com';">
						<p>File Your Flight Plan</p>
					</div>

					<br style="clear:both;">

					<div>
						<p>
							<%# Eval("MainDescription") %>
						</p>
					</div>

                    <asp:Repeater runat="server" ID="rp_extraContent">
                        <ItemTemplate>  
                            <strong><%# Eval("title") %></strong><br>
					        <p class="text13">
						        <%# Eval("content") %>
					        </p>
                        </ItemTemplate>
                    </asp:Repeater>

					<div class="floatL locFeaturesL">
						<strong>Features</strong><br>
						<p class="text13">
							<%# Eval("Features") %>
						</p>

						<strong>Support Services</strong><br>
						<p class="text13">
							<%# Eval("SupportServices") %>
						</p>
					</div>

					<div class="floatL locFeaturesR">
						<strong>Specialties</strong><br>
						<p class="text13">
							<%# Eval("Specialties") %>
						</p> 
					</div>

					<br style="clear:both;">
                    
										
					<asp:Repeater runat="server" ID="rp_comments" Visible="false">
                        <HeaderTemplate>
                            <strong>Customer Voices</strong>
                            <ul class="bxslider">
                        </HeaderTemplate>
                        <ItemTemplate>  
                            <li>
                            <p class="text13" style="text-indent:-0.5em;margin-left:0.5em;margin-bottom:0;">
						        <%# Eval("comment") %>
					        </p>
					        <p class="text13" style="text-align:right;">
						        <%# Eval("personName") %><br>
						        <%# Eval("commentDate", "{0:d-MMM-yyyy}") %>
					        </p>
                            </li>
                        </ItemTemplate>                                            
                        <FooterTemplate>
                            </ul><br />
                            <script>
                                $(function () {
                                    $('.bxslider').bxSlider({
                                        controls: false,
                                        pager: false
                                    }).startAuto();
                                });
                            </script>    
                        </FooterTemplate>
                    </asp:Repeater>
				</div> <!-- /locMidCol -->
                
                <div class="locRtCol floatR col3Bk" style="">
                    <div class="locLineBottom">
                        <div style="display:block;margin:0px auto;" class="locationTime" id="div_time">
                            <div style="float:left;margin-left:10px;">
                                <span id="span_TimeLocal"><asp:Literal runat="server" ID="lit_time" /></span>
                                <span id="span_TimeUtc" style="display:none;"><%=DateTime.UtcNow.ToString("HH:mm") %></span>
                            </div>
                            <div style="float:left;padding:7px 0px 28px 5px;line-height:30px;" ><img class="pointer" onclick="TimeUtcClick()" src="/img/local.gif" id="img_TimeButton" /></div>
                            <div style="clear:both;"></div>
                        </div>
                    </div>
                    <div class="locLineBottom" style="padding: 15px 0;overflow:hidden;height:125px;">
                        <iframe id="forecast_embed" type="text/html" frameborder="0" height="190" width="230" src='//forecast.io/embed/#lat=<%# Eval("latitude") %>&lon=<%# Eval("longitude") %>&name=<%# Eval("city") %>'> </iframe> 
                    </div>

                    <div class="locLineBottom">
                        <p style="padding:17px 0 5px 15px;margin:0;"><strong>Local Services</strong></p>
                    </div>
                    <div>
                        <asp:Repeater runat="server" ID="rp_hotels_d" Visible="false" >
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Hotels</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate>  
	                                    <div class="mobNavLocDrop <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : "pointer" %>" <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : "onclick=\"window.open('"+ Eval("url") + "', '_blank');\"" %>>
	                                        <div class="dropButn <%# String.IsNullOrEmpty(Eval("Url") as string) ? "" : "iconSpanFBOSide pointer" %>"></div>
	                                        <span><%# Eval("name") %>
                                                <%# ((decimal)Eval("miles") < 0) ? "" : "<br />" + Eval("miles", "{0:F2}") + " miles" %>
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
          	                        </div>
        	                    </div>                                
                            </FooterTemplate>
                        </asp:Repeater>

                        <asp:Repeater runat="server" ID="rp_attractions_d" Visible="false">
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Attractions</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate> 
                                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                                        <div class="dropButn iconSpanFBOSide"></div>
	                                        <span><%# Eval("VendorName") %>                                                
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
                                    </div>
        	                    </div>
                            </FooterTemplate>
                        </asp:Repeater>

                        <asp:Repeater runat="server" ID="rp_restaurants_d" Visible="false">
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Restaurants</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate> 
                                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                                        <div class="dropButn iconSpanFBOSide"></div>
	                                        <span><%# Eval("VendorName") %>                                                
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
                                    </div>
        	                    </div>
                                </FooterTemplate>
                        </asp:Repeater>

                        <asp:Repeater runat="server" ID="rp_caterers_d" Visible="false">
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Caterers</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate> 
                                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                                        <div class="dropButn iconSpanFBOSide"></div>
	                                        <span><%# Eval("VendorName") %>                                                
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
                                    </div>
        	                    </div>
                                </FooterTemplate>
                        </asp:Repeater>

                        <asp:Repeater runat="server" ID="rp_transportation_d" Visible="false">
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Transportation</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate> 
                                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                                        <div class="dropButn iconSpanFBOSide"></div>
	                                        <span><%# Eval("VendorName") %>                                                
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
                                    </div>
        	                    </div>
                                </FooterTemplate>
                        </asp:Repeater>

                        <asp:Repeater runat="server" ID="rp_maintenance_d" Visible="false">
                            <HeaderTemplate>
                                <div class="mobNavLocFBOSide clearfix">
	                                <span class="mobSubnavLink">Maintenance</span> 
	                                <div class="dropButn iconSpanFBOSide plusSign pointer"></div>
	                                <div class="dropdownDiv whiteBk">
                            </HeaderTemplate>
                            <ItemTemplate> 
                                        <div class="mobNavLocDrop pointer" onclick="window.open('<%# Eval("website") %>');">
	                                        <div class="dropButn iconSpanFBOSide"></div>
	                                        <span><%# Eval("VendorName") %>                                                
	                                        </span>
	                                    </div>
                            </ItemTemplate>
                            <FooterTemplate>
                                    </div>
        	                    </div>
                                </FooterTemplate>
                        </asp:Repeater>

                    </div>
                    <div class="locLineBottom">
                        <img src='<%# ConfigurationManager.AppSettings["LocationMapsUrl"] + Eval("iata") %>-runway.jpg' alt="" style="display:block;margin:20px auto;" >
                    </div>
                    <div>
                        <img src='<%# ConfigurationManager.AppSettings["LocationMapsUrl"] + Eval("iata") %>-map.jpg' alt="" style="display:block;margin:30px auto 50px auto;" >
                    </div>
                </div> <!-- /locRtCol -->

			</div> <!-- /col -->
			<div class="spacerDiv col">&nbsp;</div> <!-- spacer Div -->

		</div> <!-- /row -->

		</div> <!-- /contentDiv -->
	</div> <!-- /innerContainer -->
        </ItemTemplate>
    </asp:Repeater>
</div> <!-- /container100 -->

    </form>
</body>
</html>
