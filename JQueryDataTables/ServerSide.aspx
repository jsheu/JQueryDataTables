<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ServerSide.aspx.cs" Inherits="JQueryDataTables.ServerSide" %>
<!DOCTYPE html>
<html>
<head runat="server">
    <title></title>
    <link rel="stylesheet" type="text/css" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css" />
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/1.5.1/css/buttons.dataTables.min.css" />
    <link rel="Stylesheet" type="text/css" href="https://cdn.datatables.net/fixedheader/3.1.3/css/fixedHeader.dataTables.min.css" />
    <link rel="stylesheet" type="text/css" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">


	<script src="https://code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>
	<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU=" crossorigin="anonymous"></script>
	<script src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js" type="text/javascript"></script>
    <script src="https://cdn.datatables.net/buttons/1.5.1/js/dataTables.buttons.min.js" type="text/javascript"></script>
    <script src="https://cdn.datatables.net/fixedheader/3.1.3/js/dataTables.fixedHeader.min.js" type="text/javascript"></script>
    <script type="text/javascript">

		function inboxDataTable() {

			var colNum = {
				"Actions": 0
				, "Lead_ID": 1
				, "Priority": 2
				, "LeadStatusName": 3
				, "LastName": 4
				, "FirstName": 5
				, "LeadType": 6
				, "State": 7
				, "AssignedDate": 8
				, "LastCallTime": 9
				, "NextToDoDate": 10
				, "CurrentPromotion": 11
				, "Email": 12
				, "Comments": 13
			}

			var inboxList = $('#inbox-table').DataTable({
				"columnDefs": [
					//set classes
					{
						"targets": [colNum["Lead_ID"], colNum["Priority"], colNum["LeadStatusName"], colNum["LeadType"]
							, colNum["State"], colNum["AssignedDate"], colNum["LastCallTime"], colNum["NextToDoDate"]],
						"className": "dt-head-nowrap"
					}
					, {
						"targets": [colNum["Actions"]],
						"className": "dt-head-nowrap dt-body-nowrap"
					}
					, {
						"targets": [colNum["LastName"], colNum["FirstName"], colNum["CurrentPromotion"], colNum["Email"]],
						"className": "dt-head-nowrap dt-body-left"
					}

					//handle null date values
					, {
						"targets": [colNum["AssignedDate"], colNum["LastCallTime"], colNum["NextToDoDate"]],
						"defaultContent": "",
						"render": function (data, type, row, meta) {
							var date = new Date(data);
							if (date.toLocaleDateString() == '1/1/1') return '';
							else return getFormattedDate(date);
						}
					}
					//comments
					, {
						"targets": [colNum["Comments"]],
						"defaultContent": "",
						"render": function (data, type, row, meta) {
							return (data == null) ? '' : '<button class="comments-button" title="Click to see all comments.">Show</button>';
						}
					}
					, {
						"orderable": false,
						"targets": [colNum["Actions"], colNum["Comments"]]
					}
					/*
					, {
					"orderData": 0, 
					"targets": colNum["Lead_ID"]
					}
					, {
					"orderSequence": ["desc", "asc"],
					"targets": [colNum["Priority"], colNum["LeadStatusName"], colNum["LastName"], colNum["FirstName"]]
					}
					*/
					/*
					, {
					"defaultContent": "<nobr>asdf</nobr>",
					"targets": colNum["Actions"]
					"data": null
					}
					*/
					, {
						"searchable": true,
						"targets": [colNum["Lead_ID"], colNum["LastName"], colNum["FirstName"], colNum["Comments"], colNum["Email"]]
					}
					//set columns to date type
					, {
						"type": "date",
						"targets": [colNum["AssignedDate"], colNum["LastCallTime"], colNum["NextToDoDate"]]
					}
					, {
						"visible": false,
						"targets": colNum["Lead_ID"]
					}
				]
				, "deferRender": true
				, "destroy": true
				, "dom": 'ilBrtp' //default is 'lfrtip'
				, "fixedHeader": true
				, "info": true

				//reset button
				, "buttons": [
					{
						"text": 'Clear All Filters'
						, "action": function (e, dt, node, config) {
							$('.textbox-filter').val('');
							$('.select-filter').val('');
							this.search('').columns().search('').draw();
						}
					}
				]

				//create filter dropdowns in specific columns
				, "initComplete": function (settings, json) {

					//Lead_ID
					this.api().columns([colNum["Lead_ID"]]).every(function () {
						var column = this;
						var title = $(column.header()).text();
						$('<br />').appendTo($(column.header()));
						var textbox = $('<input type="text" class="textbox-filter leadid-textbox-filter" placeholder="Search" title="Filter by entered Lead ID value" />')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '.*' + val + '.*' : '', true, false)
									.draw();
							}
							);
					});


					//Priority
					this.api().columns([colNum["Priority"]]).every(function () {
						var column = this;
						$('<br />').appendTo($(column.header()));
						var select = $('<select class="select-filter" title="Filter by selected Priority option"><option value="">ALL</option></select>')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '$' : '', true, false)
									.draw();
							}
							);
						json.filterLists.priority.forEach(function (val) {
							select.append('<option value="' + val + '">' + val + '</option>');
						});
					});

					//LeadStatusName
					this.api().columns([colNum["LeadStatusName"]]).every(function () {
						var column = this;
						$('<br />').appendTo($(column.header()));
						var select = $('<select class="select-filter leadstatusname-select-filter" title="Filter by selected Lead Status option"><option value="">ALL</option></select>')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '$' : '', true, false)
									.draw();
							}
							);
						json.filterLists.leadStatusName.forEach(function (val) {
							select.append('<option value="' + val + '">' + val + '</option>');
						});
					});

					//LastName
					this.api().columns([colNum["LastName"]]).every(function () {
						var column = this;
						var title = $(column.header()).text();
						$('<br />').appendTo($(column.header()));
						var textbox = $('<input type="text" class="textbox-filter name-textbox-filter" placeholder="Search" title="Filter by entered Last Name value" />')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '.*' : '', true, false) //search only from beginning
									.draw();
							}
							);
					});

					//FirstName
					this.api().columns([colNum["FirstName"]]).every(function () {
						var column = this;
						var title = $(column.header()).text();
						$('<br />').appendTo($(column.header()));
						var textbox = $('<input type="text" class="textbox-filter name-textbox-filter" placeholder="Search" title="Filter by entered First Name value" />')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '.*' : '', true, false) //search only from beginning
									.draw();
							}
							);
					});

					//LeadType
					this.api().columns([colNum["LeadType"]]).every(function () {
						var column = this;
						$('<br />').appendTo($(column.header()));
						var select = $('<select class="select-filter leadtype-select-filter" title="Filter by selected Lead Type option"><option value="">ALL</option></select>')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '$' : '', true, false)
									.draw();
							}
							);
						json.filterLists.leadType.forEach(function (val) {
							select.append('<option value="' + val + '">' + val + '</option>');
						});
					});

					//State
					this.api().columns([colNum["State"]]).every(function () {
						var column = this;
						$('<br />').appendTo($(column.header()));
						var select = $('<select class="select-filter" title="Filter by selected State option">><option value="">ALL</option></select>')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '$' : '', true, false)
									.draw();
							}
							);
						json.filterLists.state.forEach(function (val) {
							select.append('<option value="' + val + '">' + val + '</option>');
						});
					});

					//AssignedDate
					this.api().columns([colNum["AssignedDate"]]).every(function () {
						var key = "assigneddate";
						var column = this;
						var title = $(column.header()).text();
						var divDateRange = $('<div class="table" />');
						var divFromRow = $('<div class="table-row" />');
						var divFromLabelCell = $('<div class="table-cell" />');
						var divFromTextboxCell = $('<div class="table-cell" />');
						var divToRow = $('<div class="table-row" />');
						var divToLabelCell = $('<div class="table-cell" />');
						var divToTextboxCell = $('<div class="table-cell" />');
						$('<label for="' + key + '-from">from</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divFromLabelCell);
						var fromTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Assigned Date later than this selected date" id="' + key + '-from" name="' + key + '-from" />')
							.appendTo(divFromTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $(this).val();
								var toVal = $('#' + key + '-to').val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								defaultDate: "-3m",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-to').datepicker("option", "minDate", selectedDate);
								}
							}
							);
						$('<label for="' + key + '-to">to</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divToLabelCell);
						var toTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Assigned Date earlier than this selected date" id="' + key + '-to" name="' + key + '-to" />')
							.appendTo(divToTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $('#' + key + '-from').val();
								var toVal = $(this).val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								//defaultDate: "+1w",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-from').datepicker("option", "maxDate", selectedDate);
								}
							}
							);
						divFromRow.append(divFromLabelCell).append(divFromTextboxCell);
						divToRow.append(divToLabelCell).append(divToTextboxCell);
						divDateRange.append(divFromRow).append(divToRow).appendTo($(column.header()));
					});

					//LastCallTime
					this.api().columns([colNum["LastCallTime"]]).every(function () {
						var key = "lastcalltime";
						var column = this;
						var title = $(column.header()).text();
						var divDateRange = $('<div class="table" />');
						var divFromRow = $('<div class="table-row" />');
						var divFromLabelCell = $('<div class="table-cell" />');
						var divFromTextboxCell = $('<div class="table-cell" />');
						var divToRow = $('<div class="table-row" />');
						var divToLabelCell = $('<div class="table-cell" />');
						var divToTextboxCell = $('<div class="table-cell" />');
						$('<label for="' + key + '-from">from</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divFromLabelCell);
						var fromTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Last Call Time later than this selected date" id="' + key + '-from" name="' + key + '-from" />')
							.appendTo(divFromTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $(this).val();
								var toVal = $('#' + key + '-to').val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								defaultDate: "-3m",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-to').datepicker("option", "minDate", selectedDate);
								}
							}
							);
						$('<label for="' + key + '-to">to</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divToLabelCell);
						var toTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Last Call Time earlier than this selected date" id="' + key + '-to" name="' + key + '-to" />')
							.appendTo(divToTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $('#' + key + '-from').val();
								var toVal = $(this).val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								//defaultDate: "+1w",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-from').datepicker("option", "maxDate", selectedDate);
								}
							}
							);
						divFromRow.append(divFromLabelCell).append(divFromTextboxCell);
						divToRow.append(divToLabelCell).append(divToTextboxCell);
						divDateRange.append(divFromRow).append(divToRow).appendTo($(column.header()));
					});

					//NextToDoDate
					this.api().columns([colNum["NextToDoDate"]]).every(function () {
						var key = "nexttododate";
						var column = this;
						var title = $(column.header()).text();
						var divDateRange = $('<div class="table" />');
						var divFromRow = $('<div class="table-row" />');
						var divFromLabelCell = $('<div class="table-cell" />');
						var divFromTextboxCell = $('<div class="table-cell" />');
						var divToRow = $('<div class="table-row" />');
						var divToLabelCell = $('<div class="table-cell" />');
						var divToTextboxCell = $('<div class="table-cell" />');
						$('<label for="' + key + '-from">from</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divFromLabelCell);
						var fromTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Next To Do Date later than this selected date" id="' + key + '-from" name="' + key + '-from" />')
							.appendTo(divFromTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $(this).val();
								var toVal = $('#' + key + '-to').val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								defaultDate: "-3m",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-to').datepicker("option", "minDate", selectedDate);
								}
							}
							);
						$('<label for="' + key + '-to">to</label>').on('click', function (e) { e.stopPropagation(); }).appendTo(divToLabelCell);
						var toTextbox = $('<input type="text" class="textbox-filter date-textbox-filter" title="Filter by Next To Do Date earlier than this selected date" id="' + key + '-to" name="' + key + '-to" />')
							.appendTo(divToTextboxCell)
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var fromVal = $('#' + key + '-from').val();
								var toVal = $(this).val();
								column
									.search('{ "from": "' + fromVal + '", "to": "' + toVal + '" }', false, false)
									.draw();
							})
							.datepicker({
								//defaultDate: "+1w",
								changeMonth: true,
								changeYear: true,
								yearRange: '2004:' + new Date().getFullYear(),
								onClose: function (selectedDate) {
									$('#' + key + '-from').datepicker("option", "maxDate", selectedDate);
								}
							}
							);
						divFromRow.append(divFromLabelCell).append(divFromTextboxCell);
						divToRow.append(divToLabelCell).append(divToTextboxCell);
						divDateRange.append(divFromRow).append(divToRow).appendTo($(column.header()));
					});

					//CurrentPromotion
					this.api().columns([colNum["CurrentPromotion"]]).every(function () {
						var column = this;
						$('<br />').appendTo($(column.header()));
						var select = $('<select class="select-filter currentpromotion-select-filter" title="Filter by selected Current Promotion option"><option value="">ALL</option></select>')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '^' + val + '$' : '', true, false)
									.draw();
							}
							);
						json.filterLists.currentPromotion.forEach(function (val) {
							select.append('<option value="' + val + '">' + val + '</option>');
						});
					});

					//Email
					this.api().columns([colNum["Email"]]).every(function () {
						var column = this;
						var title = $(column.header()).text();
						$('<br />').appendTo($(column.header()));
						var textbox = $('<input type="text" class="textbox-filter email-textbox-filter" placeholder="Search" title="Filter by entered Email Address value" />')
							.appendTo($(column.header()))
							.on('click', function (e) { e.stopPropagation(); })
							.on('keyup change', function () {
								var val = $.fn.dataTable.util.escapeRegex(
									$(this).val()
								);
								column
									.search(val ? '.*' + val + '.*' : '', true, false)
									.draw();
							}
							);
					});

				}
				, "language": {
					"emptyTable": 'No leads available'
					, "info": "Showing _START_ to _END_ of _TOTAL_ entries"
					, "infoEmpty": "Showing 0 to 0 of 0 entries"
					, "infoFiltered": "(Filtered from _MAX_ total entries)"
					, "lengthMenu": 'Show _MENU_ entries'
					, "loadingRecords": '<div class="fa fa-spinner fa-pulse fa-5x fa-fw processing"></div>'
					, "processing": '<div class="fa fa-spinner fa-pulse fa-5x fa-fw processing"></div>'
					, "search": 'Search for _INPUT_ in Lead ID, Last Name, First Name, Comments and Email' //This is hidden right now
					, "zeroRecords": 'No matching leads found'
				}
				, "lengthMenu": [[10, 25, 50, 100, 250, 500, 1000, -1], [10, 25, 50, 100, 250, 500, 1000, "All"]]
				, "order": [[colNum["Lead_ID"], "asc"]]
				, "pageLength": 50
				, "paging": true
				, "pagingType": "full_numbers"
				, "processing": true
				, "searching": true
				, "stateSave": false
				, "serverSide": true
				//AJAX call to WebMethod
				, "ajax": {
					"url": "<%= Request.Path.Replace(".aspx", "") %>.aspx/GetData"
					, "contentType": "application/json; charset=UTF-8"
					, "type": "POST"
					, "dataType": "json"
					//stringify the JSON data to be sent to the AJAX WebMethod
					, "data": function (d) {
						//d.foo = "bar"; //test data to send back
						return JSON.stringify(d);
					}

					//remove the JSON "d" wrapper from the AJAX WebMethod response
					, "dataFilter": function (response) {
						var parsed = JSON.parse(response);
						//console.log(parsed.d);
						this.filterLists = JSON.parse(parsed.d).filterLists;
						//console.log(this);
						return parsed.d;
					}

				}
				//match columns with AJAX WebMethod
				, "columns": [
					{ "data": null, "name": "Actions", defaultContent: '<button class="action-button view-button" title="Click to open lead data page.">View</button> <button class="action-button mail-button" title="Click to open mail window.">Mail</button>' }
					, { "data": "Lead_ID", "name": "Lead_ID" }
					, { "data": "Priority", "name": "Priority" }
					, { "data": "LeadStatusName", "name": "LeadStatusName" }
					, { "data": "LastName", "name": "LastName" }
					, { "data": "FirstName", "name": "FirstName" }
					, { "data": "LeadType", "name": "LeadType" }
					, { "data": "State", "name": "State" }
					, { "data": "AssignedDate", "name": "AssignedDate" }
					, { "data": "LastCallTime", "name": "LastCallTime" }
					, { "data": "NextToDoDate", "name": "NextToDoDate" }
					, { "data": "CurrentPromotion", "name": "CurrentPromotion" }
					, { "data": "Email", "name": "Email" }
					, { "data": "Comments", "name": "Comments" }
				]
			});
			return inboxList;
		}

		$(function () {
			var inboxList = inboxDataTable();

			$('#inbox-table tbody').on('click', '.view-button', function (e) {
				e.preventDefault();
				var lead_ID = inboxList.row($(this).parents('tr')).data().Lead_ID;
				openLeadPage(lead_ID);
			});

			$('#inbox-table tbody').on('click', '.mail-button', function (e) {
				e.preventDefault();
				var lead_ID = inboxList.row($(this).parents('tr')).data().Lead_ID;
				openMailPage(lead_ID);
			});

			$("#comments-dialog").dialog({
				autoOpen: false,
				modal: true,
				show: {
					effect: "blind",
					duration: 500
				},
				hide: {
					effect: "fade",
					duration: 500
				}
			});

			$('#inbox-table tbody').on('click', '.comments-button', function (e) {
				e.preventDefault();
				var lead_ID = inboxList.row($(this).parents('tr')).data().Lead_ID;
				var comments = inboxList.row($(this).parents('tr')).data().Comments;
				var commentsHtml = '<ul class="comments"><li><span>' + comments.split(':::').join('</span></li>\r\n<li><span>') + '</span></li></ul>';
				$('#comments-dialog').html(commentsHtml).dialog({ title: 'Lead ID ' + lead_ID + ' Comments' }).dialog('open');
			});

		});

		function openLeadPage(leadID) {
			alert('Open lead data page for lead #' + leadID);
			/*
			var leadWin = window.open('/Sales/LeadSearch.aspx?phonenum=' + leadID + '&type=i&L_Type=L', 'leadWin_' + leadID);
			leadWin.focus();
			*/
			return true;
		}

		function openMailPage(leadID) {
			alert('Open email page for lead #' + leadID);
			/*
			var userID = <%= userID %>;
			var w = 950;
			var h = 600;
			var l = (screen.availWidth - w) / 2;
			var t = (screen.availHeight - h) / 3;
			var f = 'left=' + l + ',top=' + t + ',width=' + w + ',height=' + h + ',status=1,menubar=1,scrollbars=1,resizable=1';
			var mailWin = window.open('/MailSend.aspx?lead_id=' + leadID + '&user_id=' + userID, 'mailWin_' + leadID, f);
			mailWin.focus();
			*/
			return true;
		}

		function getFormattedDate(date) {
			var year = date.getFullYear();

			var month = (1 + date.getMonth()).toString();
			month = month.length > 1 ? month : '0' + month;

			var day = date.getDate().toString();
			day = day.length > 1 ? day : '0' + day;

			return month + '/' + day + '/' + year;
		}


    </script>

<style type="text/css">

html, body, form
{
	width: 100%;
	height: 100%;
	margin: 0;
	font-family: Arial;
}

table.dataTable
{
	font-family: Verdana;
    font-size: 10px;
	background-color: White;
    border-color: #6699FF;
    border-width: 1px;
    border-style: None;
    border-collapse: collapse;
    margin: 0 0 10px 0;
}
table.dataTable caption 
{
	font-weight: bold;
}
table.dataTable th
{
	text-align: center;
	padding: 1px 18px 1px 1px !important;
	vertical-align: bottom;
}
table.dataTable td
, table.dataTable .sorting_disabled
{
	text-align: center;
	padding: 1px 1px !important;
}

table.dataTable.hover tbody tr:hover, table.dataTable.display tbody tr:hover
{
    background-color: #FFFF33;
    border-top: 1px double black;
    border-bottom: 1px double black;
    transition: all 0.15s ease-in;
    -webkit-transition: all 0.15s ease-in;
    -moz-transition: all 0.15s ease-in;
    -o-transition: all 0.15s ease-in;
}
table.dataTable tr:hover td:first-child
{
    border-left: 1px double black;
    transition: all 0.15s ease-in;
    -webkit-transition: all 0.15s ease-in;
    -moz-transition: all 0.15s ease-in;
    -o-transition: all 0.15s ease-in;
}
table.dataTable tr:hover td:last-child
{
    border-right: 1px double black;
    transition: all 0.15s ease-in;
    -webkit-transition: all 0.15s ease-in;
    -moz-transition: all 0.15s ease-in;
    -o-transition: all 0.15s ease-in;
}

table.dataTable .collpase
{
    border-collapse: collapse;
}
table.dataTable .smaller
{
	font-size: 10px;
}
table.dataTable .nowrap
{
	white-space: nowrap;
}
table.dataTable td.dt-body-left
{
	padding: 1px 2px !important;
}
table.dataTable thead th
{
	color: #CCCCFF;
	background-color: #003399;
}

table.dataTable tfoot td {
    font-weight: bold;
    color: #003399;
    background-color: #99CCCC;
}
table.dataTable thead td,
table.dataTable tfoot td,
table.dataTable.no-footer
{
	border-bottom-color: #6699FF !important; /* overrive dataTable value */
}
table.dataTable tr.odd 
{
    background-color: #FFFFFF;
}
table.dataTable tr.even 
{
    background-color: #FFFFC0;
}

table.dataTable thead tr th.sorting_asc, 
table.dataTable tbody tr td.sorting_asc {
    background-color: green;
}

table.dataTable thead tr th.sorting_desc, 
table.dataTable tbody tr td.sorting_desc {
    background-color: red;
}
table.dataTable tr.selected
{
	font-weight: bold !important;
	color: Black !important;
	background-color: Yellow !important;
}

table.dataTable button, .dataTables_wrapper a.dt-button
{
    font-size: 10px;
    font-weight: bold;
    text-transform: uppercase;
    text-decoration: none; /* override */
    color: #FFFFFF;
    background-color: green;
    background-image: none; /* override */
    padding: 3px 6px;
    cursor: pointer;
    border: 0;
    -webkit-appearance: none;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
    border-radius: 3px;
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    box-sizing: border-box;
}
table.dataTable button:hover, .dataTables_wrapper a.dt-button:hover
{
	border: 0;
	background-color: #28A828;
	background-image: none;
}

table.dataTable input.textbox-filter
{
	font-family: Arial;
	font-size: 10px;
	width: 100px;
	text-align: center;
	height: 9px;
}
table.dataTable input.leadid-textbox-filter
{
	width: 45px;
}
table.dataTable input.name-textbox-filter
{
	width: 55px;
}
table.dataTable input.date-textbox-filter
{
	width: 55px;
	height: 7px;
}
table.dataTable input.email-textbox-filter
{
	width: 100px;
}

table.dataTable select.select-filter
{
	font-size: 10px;
	text-align-last: center;
}

table.dataTable select.leadstatusname-select-filter
{
	width: 110px;
}
table.dataTable select.leadtype-select-filter
{
	width: 100px;
}
table.dataTable select.currentpromotion-select-filter
{
	width: 100px;
}

table.dataTable .comments
{
	display: none;
	margin: 0;
    padding-left: 10px;
    list-style: none;
}
table.dataTable .comments li
{
}
table.dataTable .comments li:before
{
    content: "»";
    float: left;
    position: relative;
    left: -10px;
    text-align: center;
    color: black;
    width: 0;
}
table.dataTable .comments span
{
}

.dataTables_wrapper
{
	font-size: 11px;
}

.dataTables_wrapper .dataTables_info
{
	float: left;
    padding: 4px 0 10px 0;
}

.dataTables_wrapper .dataTables_length
{
	float: left;
    padding: 2px 0 10px 20px;
}

.dataTables_wrapper .dataTables_length select
{
	font-size: 11px;
}

.dataTables_wrapper .dt-buttons
{
	padding: 0 0 0 20px;
}

.dataTables_wrapper .dataTables_paginate
{
	float: none;
	text-align: left;
}

.fixedHeader-floating 
{
	/* work around shifting issue */
	margin-left: 0 !important;
}

.dataTables_wrapper .dataTables_processing
{
	position: fixed;
	height: 100vh;
	width: 100vw;
	left: 0;
	top: 0;
	margin: 0;
	padding: 0;
	opacity: 0.5;
}
.processing
{
	position: absolute;
    top: 40%;
    left: 50%;
    transform: translate(-50%, -50%);
}
.narrow
{
}
.table
{
	display: table;
}
.table-row
{
	display: table-row;
}
.table-cell
{
	display: table-cell;
	background-clip: padding-box;
	border-right: 5px solid transparent;
}
.table-cell:last-child {
	border-right: 0 none;
}
</style>

</head>
<body>

    <form id="form1" runat="server">
    <div>

		<h1>Server-Side DataTable</h1>

		<p>
			DataTables typically are used in client-side mode.  But if there are a large number of records, the filtering and sorting features can suffer in performance.  
			With server-side mode, the filtering and sorting is performed in the code-behind for faster responses.  In production, the data comes from the SQL database.  
			In this demo, the data comes from an Excel spreadsheet.  Also in production, the action buttons open other form pages for the selected record. 
		</p>


        <!-- columns should match in javsacript above -->
        <table cellspacing="0" rules="all" border="1" id="inbox-table" class="compact stripe hover row-border">
		    <thead>
			    <tr class="sort-arrows">
                    <th scope="col">Actions</th>
                    <th scope="col">Lead ID</th>
                    <th scope="col">Follow Up<br />Priority</th>
                    <th scope="col">Lead Status</th>
                    <th scope="col">Last Name</th>
                    <th scope="col">First Name</th>
                    <th scope="col">Lead Type</th>
                    <th scope="col">State</th>
                    <th scope="col">Assigned Date</th>
                    <th scope="col">Last Called Time</th>
                    <th scope="col">Next To Do Date</th>
                    <th scope="col">Current Promotion</th>
                    <th scope="col">Email Address</th>
                    <th scope="col">Comments</th>
			    </tr>
		    </thead>
        </table>

<div id="comments-dialog" title="Comments"></div>

    </div>

    </form>
</body>
</html>
