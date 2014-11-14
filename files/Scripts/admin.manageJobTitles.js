var ManageJobTitles = function($) {

    var oTableJobTitles;
    var jobTitlesTableId = "#tblJobTitles";
    var baseUrl = "/api/JobTitles/";
    var currentData;

    $(document).ready(function () {
        init();
    });

    function init() {
        refreshJobTitleData();
        $("#btnAddJobTitle").on("click", function(e) {
            var value = $("#jobTitleValue").val();
            var text = $("#jobTitleText").val();
            var dataItem = { ddlText: text, ddlValue: value };
            insertJobTitle(dataItem);
        });
    }

    function refreshJobTitleData() {
        $.ajax({
            type: "Get",
            url: baseUrl,
            contentType: "application/json; charset=utf-8"
        })
        .fail(function (response, status, text) {
            $(jobTitlesTableId + " td.dataTables_empty").html("Unable to load data.");
        })
        .done(function (data) {
            currentData = data;
            bindJobTitles(data);
        });
    }

    function bindJobTitles(dataset) {
        if (oTableJobTitles) {
            oTableJobTitles.fnClearTable();
        }
        if (!oTableJobTitles) {
            oTableJobTitles = $(jobTitlesTableId).dataTable({
                "bRetrieve": true,
                "bJQueryUI": true,
                "bProcessing": true,
                "bPaginate": false,
                "sScrollY": "250px",
                "aaData": dataset,
                "aaSorting": [],
                "fnRowCallback": function(nRow, aData, iDisplayIndex, iDisplayIndexFull) {
                    $(nRow).addClass("selectable");
                    $(nRow).data("ddlDataId", aData["ddlDataId"]);
                },
                "aoColumns": [
                    { "mDataProp": "ddlValue" },
                    { "mDataProp": "ddlText" }
                ],
                "aoColumnDefs": [
                    {
                        //Make the second column editable
                        "aTargets": [1],
                        "sClass": "editable"
                    }
                ]
            });
            $("thead input.dataTableFilter").on("keyup", function () {
                /* Filter on the column (the index) of this element */
                oTableJobTitles.fnFilter(this.value, $("thead input.dataTableFilter").index(this));
            });
            $(".dataTables_filter").hide();
        } else {
            oTableJobTitles.fnClearTable();
            oTableJobTitles.fnAddData(dataset);
        }
        oTableJobTitles.$("td.editable").editable(function (value, settings) {
            var dataItem = oTableJobTitles.fnGetData(this.parentNode);
            dataItem.ddlText = value;
            updateJobTitle(dataItem);
        }, {
            type: 'text',
            submit: 'OK'
        });
    }

    function insertJobTitle(dataItem) {
        var blanks = (dataItem.ddlValue == "" || dataItem.ddlText == "");
        if (blanks) {
            alert("Value and Display Text are required.");
        } else {            
            var exists = false;
            if (currentData) {
                $.each(currentData, function (i, elem) {
                    if (elem.ddlValue === dataItem.ddlValue) {
                        exists = true;
                        return false;
                    }
                });
            }
            if (exists) {
                alert("An item with the same Value already exists.");
            } else {
                $.ajax({
                    type: "POST",
                    data: JSON.stringify(dataItem),
                    url: baseUrl,
                    contentType: "application/json; charset=utf-8"
                })
                    .fail(function (response, status, text) {
                        alert("Unable to save.");
                    })
                    .done(function (msg) {
                        $("#jobTitleValue").val("");
                        $("#jobTitleText").val("");
                        refreshJobTitleData();
                    });
            }
        }

    }

    function updateJobTitle(dataItem) {
        $.ajax({
                type: "PUT",
                data: JSON.stringify(dataItem),
                url: baseUrl,
                contentType: "application/json; charset=utf-8"
            })
            .fail(function(response, status, text) {
                alert("Unable to save.");
            })
            .done(function(msg) {
                refreshJobTitleData();
            });
    }

}(jQuery)