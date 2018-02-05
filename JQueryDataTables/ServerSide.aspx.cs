using System;
using System.Web.Caching;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Services;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;

namespace JQueryDataTables
{
	public partial class ServerSide : System.Web.UI.Page
	{
		/*
		 */
		/// <summary>
		///		Data model for items in the Inbox list returned from data source.
		/// </summary>
		public class InboxItem
		{
			public int Lead_ID { get; set; }
			public string Priority { get; set; }
			public string LeadStatusName { get; set; }
			public string LastName { get; set; }
			public string FirstName { get; set; }
			public string LeadType { get; set; }
			public string State { get; set; }
			public DateTime AssignedDate { get; set; }
			public DateTime LastCallTime { get; set; }
			public DateTime NextToDoDate { get; set; }
			public string Comments { get; set; }
			public string CurrentPromotion { get; set; }
			public string Email { get; set; }
		}

		/// <summary>
		///		Data model for response to DataTables AJAX request.
		/// </summary>
		public class DataTablesData
		{
			public int draw { get; set; }
			public int recordsTotal { get; set; }
			public int recordsFiltered { get; set; }
			public List<InboxItem> data { get; set; }
			//Lists for all the filter options for all columns.
			public Dictionary<string, List<string>> filterLists = new Dictionary<string, List<string>>();
		}


		//parameters received from DataTables AJAX call
		//See https://reformatcode.com/code/c/web-api-server-side-processing-and-datatables-parameters
		//https://datatables.net/forums/discussion/40690/sample-implementation-of-serverside-processing-in-c-mvc-ef-with-paging-sorting-searching
		/*
		 * These data models are used in the JSON data provided with the Datatables AJAX request
		 */
		/// <summary>
		///		Order data model received from DataTables AJAX request.
		/// </summary>
		public class Order
		{
			public int column { get; set; }
			public string dir { get; set; }
		}

		/// <summary>
		///		Column data model received from DataTables AJAX request.
		/// </summary>
		public class Column
		{
			public string data { get; set; }
			public string name { get; set; }
			public bool searchable { get; set; }
			public bool orderable { get; set; }
			public Search search { get; set; }
		}

		/// <summary>
		///		Search data model received from DataTables AJAX request.
		/// </summary>
		public class Search
		{
			public string value { get; set; }
			public bool regex { get; set; }
		}

		/// <summary>
		///		DateRange data model received from DataTables AJAX request. This was created to handle date range filtering.
		/// </summary>
		public class DateRange
		{
			public string from { get; set; }
			public string to { get; set; }
		}

		public int userID = 101;

		protected void Page_Load(object sender, EventArgs e)
		{
			/*
			//TESTING
			//DataTable inboxList_DataTable = ReadTabDelimitedFile(HttpContext.Current.Server.MapPath("inbox-data.txt"));
			DataTable inboxList_DataTable = GetDataTableFromExcel(HttpContext.Current.Server.MapPath("inbox-data.xlsx"));
			List<InboxItem> inboxList = ConvertToList<InboxItem>(inboxList_DataTable);
			Response.Write("GOT THE FILE");
			Response.End();
			*/

			//CheckSession();
			if (!IsPostBack)
			{
				if (Convert.ToString(Request.QueryString["clear"]) == "1")
				{
					//int userID = Convert.ToInt32(Session["Employee_ID"]);
					Cache.Remove(CacheKey(userID));
				}
			}
		}

		/// <summary>
		///	    Returns the unique key for caching the inbox list.
		///		<param name="userID">The User ID of the user of the inbox list.</param>
		/// </summary>
		private static string CacheKey(int userID)
		{
			string key = String.Format("inboxList_DataTable_{0}", userID);
			return key;
		}


		//http://www.c-sharpcorner.com/UploadFile/ee01e6/different-way-to-convert-datatable-to-list/
		/// <summary>
		///		Convert a DataTable object into a List object of generic items.
		///		<param name="dt">DataTable object.</param>
		/// </summary>
		private static List<T> ConvertToList<T>(DataTable dt)
		{
			List<T> data = new List<T>();
			foreach (DataRow row in dt.Rows)
			{
				T item = GetItem<T>(row);
				data.Add(item);
			}
			return data;
		}

		/// <summary>
		///		Convert a DataRow object into a generic item.
		///		<param name="dr">DataRow object.</param>
		/// </summary>
		private static T GetItem<T>(DataRow dr)
		{
			Type temp = typeof(T);
			T obj = Activator.CreateInstance<T>();

			foreach (DataColumn column in dr.Table.Columns)
			{
				foreach (System.Reflection.PropertyInfo pro in temp.GetProperties())
				{
					//if (pro.Name == column.ColumnName)
					//	pro.SetValue(obj, (dr[column.ColumnName] == DBNull.Value) ? null : dr[column.ColumnName], null);
					if (pro.Name == column.ColumnName)
					{
						try
						{
							var value = dr[column.ColumnName];
							if (!pro.PropertyType.IsAssignableFrom(value.GetType()))
								value = Convert.ChangeType(value, pro.PropertyType);
							//|| String.Compare(Convert.ToString(dr[column.ColumnName]), "null", true) 
							pro.SetValue(obj, (
							(dr[column.ColumnName] == DBNull.Value) || Convert.ToString(dr[column.ColumnName]).Equals("null", StringComparison.OrdinalIgnoreCase)
								) ? null : value, null);
						}
						catch (Exception)
						{
							pro.SetValue(obj, null, null);
						}
					}
					else
						continue;
				}
			}
			return obj;
		}

		/*
		 * D
		 */
		/// <summary>
		///		Return the list filtered by search value of the specified column.  Seacrh rules for each column are defined here.
		///		<param name="columnName">The name of the column.</param>
		///		<param name="value">The search value of the column.</param>
		///		<param name="useRegex">Indication for using regular expressions.</param>
		///		<param name="dataList">List of InboxItem objects.</param>
		/// </summary>
		private static List<InboxItem> FilterByColumn(string columnName, string value, bool useRegex, List<InboxItem> dataList)
		{
			Regex regex = new Regex(value, RegexOptions.IgnoreCase);
			List<InboxItem> filteredDataList = new List<InboxItem>();
			//            try
			{
				DateRange jsonObj = new DateRange();
				string from;
				DateTime? dateFrom = null;
				string to;
				DateTime? dateTo = null;

				switch (columnName)
				{
					case "Lead_ID":
						filteredDataList = dataList.Where(p => ((useRegex) ? regex.IsMatch(p.Lead_ID.ToString()) : p.Lead_ID.ToString().Contains(value))).ToList();
						break;
					case "Priority":
						filteredDataList = dataList.Where(p => (p.Priority != null && ((useRegex) ? regex.IsMatch(p.Priority) : p.Priority.Contains(value)))).ToList();
						break;
					case "LeadStatusName":
						filteredDataList = dataList.Where(p => (p.LeadStatusName != null && ((useRegex) ? regex.IsMatch(p.LeadStatusName) : p.LeadStatusName.Contains(value)))).ToList();
						break;
					case "LastName":
						filteredDataList = dataList.Where(p => (p.LastName != null && ((useRegex) ? regex.IsMatch(p.LastName) : p.LastName.Contains(value)))).ToList();
						break;
					case "FirstName":
						filteredDataList = dataList.Where(p => (p.FirstName != null && ((useRegex) ? regex.IsMatch(p.FirstName) : p.FirstName.Contains(value)))).ToList();
						break;
					case "LeadType":
						filteredDataList = dataList.Where(p => (useRegex) ? (p.LeadType != null && regex.IsMatch(p.LeadType)) : (p.LeadType != null && p.LastName.Contains(value))).ToList();
						break;
					case "State":
						filteredDataList = dataList.Where(p => (useRegex) ? (p.State != null && regex.IsMatch(p.State)) : (p.State != null && p.State.Contains(value))).ToList();
						break;
					case "AssignedDate":
						jsonObj = JsonConvert.DeserializeObject<DateRange>(value);
						from = jsonObj.from;
						dateFrom = null;
						if (!String.IsNullOrEmpty(from) && !String.IsNullOrWhiteSpace(from)) dateFrom = DateTime.Parse(from);
						to = jsonObj.to;
						dateTo = null;
						if (!String.IsNullOrEmpty(to) && !String.IsNullOrWhiteSpace(to)) dateTo = DateTime.Parse(to);
						filteredDataList = dataList.Where(p => p.AssignedDate != null && (dateFrom == null || dateFrom <= p.AssignedDate) && (dateTo == null || p.AssignedDate <= dateTo)).ToList();
						break;
					case "LastCallTime":
						jsonObj = JsonConvert.DeserializeObject<DateRange>(value);
						from = jsonObj.from;
						dateFrom = null;
						if (!String.IsNullOrEmpty(from) && !String.IsNullOrWhiteSpace(from)) dateFrom = DateTime.Parse(from);
						to = jsonObj.to;
						dateTo = null;
						if (!String.IsNullOrEmpty(to) && !String.IsNullOrWhiteSpace(to)) dateTo = DateTime.Parse(to);
						filteredDataList = dataList.Where(p => p.LastCallTime != null && (dateFrom == null || dateFrom <= p.LastCallTime) && (dateTo == null || p.LastCallTime <= dateTo)).ToList();
						break;
					case "NextToDoDate":
						jsonObj = JsonConvert.DeserializeObject<DateRange>(value);
						from = jsonObj.from;
						dateFrom = null;
						if (!String.IsNullOrEmpty(from) && !String.IsNullOrWhiteSpace(from)) dateFrom = DateTime.Parse(from);
						to = jsonObj.to;
						dateTo = null;
						if (!String.IsNullOrEmpty(to) && !String.IsNullOrWhiteSpace(to)) dateTo = DateTime.Parse(to);
						filteredDataList = dataList.Where(p => p.NextToDoDate != null && (dateFrom == null || dateFrom <= p.NextToDoDate) && (dateTo == null || p.NextToDoDate <= dateTo)).ToList();
						break;
					case "Comments":
						filteredDataList = dataList.Where(p => (useRegex) ? (p.Comments != null && regex.IsMatch(p.Comments)) : (p.Comments != null && p.Comments.Contains(value))).ToList();
						break;
					case "CurrentPromotion":
						filteredDataList = dataList.Where(p => (useRegex) ? (p.CurrentPromotion != null && regex.IsMatch(p.CurrentPromotion)) : (p.CurrentPromotion != null && p.CurrentPromotion.Contains(value))).ToList();
						break;
					case "Email":
						filteredDataList = dataList.Where(p => (useRegex) ? (p.Email != null && regex.IsMatch(p.Email)) : (p.Email != null && p.Email.Contains(value))).ToList();
						break;
					default:
						filteredDataList = dataList.ToList();
						break;
				}
			}/*
            catch (Exception)
            {
            }*/
			return filteredDataList;
		}

		/// <summary>
		///		Return the list sorted by column.  Sorting rules for each column are defined here.
		///		<param name="order">The number of the soruce column determining the sort.</param>
		///		<param name="orderDir">The direction of the sort.</param>
		///		<param name="dataList">List of InboxItem objects.</param>
		/// </summary>
		private static List<InboxItem> SortByColumnWithOrder(int order, string orderDir, List<InboxItem> dataList)
		{
			// Initialization  
			List<InboxItem> sortedDataList = new List<InboxItem>();
			try
			{
				// Sorting
				switch (order)
				{
					case 0: //ignore actions column
						break;
					case 1:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.Lead_ID).ToList();
						break;
					case 2:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.Priority).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.Priority).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 3:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.LeadStatusName).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.LeadStatusName).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 4:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.LastName).ThenBy(p => p.FirstName).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.LastName).ThenBy(p => p.FirstName).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 5:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.FirstName).ThenBy(p => p.LastName).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.FirstName).ThenBy(p => p.LastName).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 6:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.LeadType).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.LeadType).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 7:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.State).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.State).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 8:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.AssignedDate).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.AssignedDate).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 9:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.LastCallTime).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.LastCallTime).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 10:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.NextToDoDate).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.NextToDoDate).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 11:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.Comments).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.Comments).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 12:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.CurrentPromotion).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.CurrentPromotion).ThenBy(p => p.Lead_ID).ToList();
						break;
					case 13:
						sortedDataList = orderDir.Equals("DESC", StringComparison.CurrentCultureIgnoreCase) ?
							dataList.OrderByDescending(p => p.Email).ThenBy(p => p.Lead_ID).ToList() : dataList.OrderBy(p => p.Email).ThenBy(p => p.Lead_ID).ToList();
						break;
					default:
						break;
				}
			}
			catch (Exception)
			{
			}
			return sortedDataList;
		}

		/// <summary>
		///		Return the DataTable object of the inbox list data.
		///		<param name="userID">The User ID of the user of the inbox list.</param>
		/// </summary>
		public static DataTable GetInboxDataTable(int userID)
		{
			DataTable inboxList_DataTable = new DataTable();

			string key = CacheKey(userID);

			if (HttpRuntime.Cache[key] == null)
			{
				inboxList_DataTable = GetDataTableFromExcel(HttpContext.Current.Server.MapPath("server-data.xlsx"));
				//Cache absolutely for 5 minutes
				HttpRuntime.Cache.Add(key, inboxList_DataTable, null, DateTime.Now.AddMinutes(5), Cache.NoSlidingExpiration, CacheItemPriority.Normal, null);
			}
			else
			{
				inboxList_DataTable = (DataTable)HttpRuntime.Cache[key];
			}
			return inboxList_DataTable;
		}

		/// <summary>
		///		Return the data for the DataTables AJAX request.
		/// </summary>
		[WebMethod]
		[ScriptMethod(ResponseFormat = ResponseFormat.Json)]
		public static string GetData(
				int draw,
				int start,
				int length,
				Search search,
				Order[] order,
				Column[] columns)
		{
			int userID = 101;
			DataTable inboxList_DataTable = GetInboxDataTable(userID);

			List<InboxItem> inboxList = ConvertToList<InboxItem>(inboxList_DataTable);

			//total count
			int recordsTotal = inboxList.Count;

			// Apply column filters
			foreach (Column column in columns)
			{
				if (!String.IsNullOrEmpty(column.search.value) && !String.IsNullOrWhiteSpace(column.search.value))
				{
					inboxList = FilterByColumn(column.name, column.search.value, column.search.regex, inboxList);
				}
			}

			//filtered count
			int recordsFiltered = inboxList.Count;

			//sorting
			inboxList = SortByColumnWithOrder(order[0].column, order[0].dir, inboxList);

			//apply pagination
			//inboxList_DataTable = inboxList_DataTable.AsEnumerable().Skip(start).Take(length).CopyToDataTable();
			inboxList = inboxList.Skip(start).Take(length).ToList();

			Regex startWithLetterRegex = new Regex(@"^[a-z].*", RegexOptions.IgnoreCase);

			Dictionary<string, List<string>> filterLists = new Dictionary<string, List<string>>();
			filterLists["priority"] = inboxList_DataTable.AsEnumerable()
				.Where(x => x.Field<string>("Priority") != null && x.Field<string>("Priority") != "NULL")
				.OrderBy(x => x.Field<string>("Priority"))
				.Select(x => x.Field<string>("Priority")).Distinct().ToList();
			filterLists["leadStatusName"] = inboxList_DataTable.AsEnumerable()
				.OrderBy(x => x.Field<string>("LeadStatusName"))
				.Select(x => x.Field<string>("LeadStatusName")).Distinct().ToList();
			filterLists["leadType"] = inboxList_DataTable.AsEnumerable()
				.OrderBy(x => x.Field<string>("LeadType"))
				.Select(x => x.Field<string>("LeadType")).Distinct().ToList();
			filterLists["state"] = inboxList_DataTable.AsEnumerable()
				.Where(x => x.Field<string>("State") != null && x.Field<string>("State").Length == 2)
				.OrderBy(x => x.Field<string>("State")).Select(x => x.Field<string>("State").ToUpper()).Distinct().ToList();
			filterLists["currentPromotion"] = inboxList_DataTable.AsEnumerable()
				.Where(x => x.Field<string>("CurrentPromotion") != null && x.Field<string>("CurrentPromotion") != "NULL")
				.OrderBy(x => x.Field<string>("CurrentPromotion")).Select(x => x.Field<string>("CurrentPromotion").ToUpper()).Distinct().ToList();

			DataTablesData DataTablesData = new DataTablesData();
			DataTablesData.draw = draw;
			DataTablesData.recordsTotal = recordsTotal;
			DataTablesData.recordsFiltered = recordsFiltered;
			DataTablesData.data = inboxList;
			DataTablesData.filterLists = filterLists;
			string DataTablesData_jsonString = JsonConvert.SerializeObject(DataTablesData);
			return DataTablesData_jsonString;
		}

		/// <summary>
		///		Return the DataTable object of the inbox list data.
		///		<param name="userID">The User ID of the user of the inbox list.</param>
		/// </summary>
		public static DataTable GetDataTableFromExcel(string path, bool hasHeader = true)
		{
			using (var pck = new OfficeOpenXml.ExcelPackage())
			{
				using (var stream = File.OpenRead(path))
				{
					pck.Load(stream);
				}
				var ws = pck.Workbook.Worksheets.First();
				DataTable tbl = new DataTable();
				foreach (var firstRowCell in ws.Cells[1, 1, 1, ws.Dimension.End.Column])
				{
					tbl.Columns.Add(hasHeader ? firstRowCell.Text : string.Format("Column {0}", firstRowCell.Start.Column));
				}
				var startRow = hasHeader ? 2 : 1;
				for (int rowNum = startRow; rowNum <= ws.Dimension.End.Row; rowNum++)
				{
					var wsRow = ws.Cells[rowNum, 1, rowNum, ws.Dimension.End.Column];
					DataRow row = tbl.Rows.Add();
					foreach (var cell in wsRow)
					{
						row[cell.Start.Column - 1] = cell.Text;
					}
				}
				return tbl;
			}
		}
	}
}