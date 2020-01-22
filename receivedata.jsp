<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8" %>
<%@ page import="basBeanFile.*,java.util.*"%>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql"%>
<%@ page errorPage="Error.jsp" %>
	<%
		/*보낸 자료들 파싱*/
		request.setCharacterEncoding("UTF-8");
		String start = request.getParameter("start");	
		String week = request.getParameter("week");
		int hour = Integer.parseInt(request.getParameter("hour"));
		int minute = Integer.parseInt(request.getParameter("minute"));
		int depart_time = hour * 60 + minute;
		String location = request.getParameter("location");
		double lat = Double.parseDouble(request.getParameter("lat"));
		double lng = Double.parseDouble(request.getParameter("lng"));	
		
		if(location.equals("지도에서 검색")) 
		{
			location="삼성전자 DSR C타워";
			lat=37.225536329479645;
			lng=127.07123083210143;
		}		
		/*start값에 따라 버스시작 lat lng 설정 */
		double start_lat = 0;
		double start_lng = 0;
		if (start.equals("H1")) {
			start_lat = 37.2242830904676;
			start_lng = 127.067962031843;
		} else if (start.equals("H2")) {
			start_lat = 37.21755075007767;
			start_lng = 127.07054056355753;
		} else if (start.equals("K1")) {
			start_lat = 37.227662241383676;
			start_lng = 127.08185758255234;
		}
		/*지하철 좌표 데이터 가져오기 */
		subwaylatlng=Get_subway_latlng();
		set_hash();	//역 이름 해싱.
		/*도착지에서 가까운 지하철 역 5개의 정보를 저장*/
		ArrayList<NearSubwayBean> nearsubway = new ArrayList<NearSubwayBean>();
		nearsubway.add(new NearSubwayBean());
		for (int i = 0; i < subwaylatlng.size(); i++) {
			int tmp = calcDistance(lat, lng, subwaylatlng.get(i).getLat(), subwaylatlng.get(i).getLng());
			for (int j = 0; j < 5; j++) {
				if (tmp < nearsubway.get(j).getDist()) {
					nearsubway.add(j, new NearSubwayBean(subwaylatlng.get(i).getName(),
							subwaylatlng.get(i).getLat(), subwaylatlng.get(i).getLng(), tmp));
					break;
				}
			}
		}
		int walk = calcElapsedTime(calcDistance(start_lat, start_lng, lat, lng));

		/* 최단시간 및 이동경로 배열선언. 기본적으로 도보로 간 걸로 이니셜라이즈 되어있다. */
		int totalmintime[] = new int[6];
		ArrayList<RouteBean> totalroute = new ArrayList<RouteBean>();
		totalmintime[0]=walk;
		totalroute.add(new RouteBean(depart_time,"",-1));
		//// 도착 : 0 // 도보 : 1  // 버스 : 2 // 지하철 :3
		totalroute.get(0).addLocation(new LocationBean(start, start_lat, start_lng), 0, 1);
		totalroute.get(0).addLocation(new LocationBean(location, lat, lng), walk, 0);
		for (int i = 1; i < 6; i++) {
			totalmintime[i] = Integer.MAX_VALUE;
			totalroute.add(new RouteBean(depart_time,"",-1));
			totalroute.get(i).addLocation(new LocationBean(start, start_lat, start_lng), 0, 1);
			totalroute.get(i).addLocation(new LocationBean(location, lat, lng), walk, 0);
		}
		
		/* 최단거리를 계산해내는 곳 */
		for(int gatenum=1;gatenum<40;gatenum++)
		{
			ArrayList<BusStopBean> busstop = Get_bus_info(start,week,depart_time,gatenum);
			out.println(busstop.size());
			int mintime[]=new int[3];
			ArrayList<RouteBean> route = new ArrayList<RouteBean>();
			for (int i = 0; i < 3; i++) {
				mintime[i] = Integer.MAX_VALUE;
				route.add(new RouteBean(depart_time,"",-1));
				route.get(i).addLocation(new LocationBean(start, start_lat, start_lng), 0, 1);
				route.get(i).addLocation(new LocationBean(location, lat, lng), walk, 0);
			}
			for (int i = 0; i < busstop.size(); i++) {
				//1. 버스->도보
				int lastwalk = calcElapsedTime(
						calcDistance(busstop.get(i).getLat(), busstop.get(i).getLng(), lat, lng));
				int bus_start_time = busstop.get(i).getStart_time();
				int bus_time = (bus_start_time - depart_time) + busstop.get(i).getElapsed_time();
				int tmptime = bus_time + lastwalk;
				for (int k = 0; k < 2; k++) {
					if (tmptime < mintime[k]) {
						for (int m = 1; m >= k; m--) {
							mintime[m + 1] = mintime[m];
						}
						mintime[k] = tmptime;
						route.add(k, new RouteBean(bus_start_time,busstop.get(i).getLine_name(),busstop.get(i).getGate_number()));
						route.get(k).addLocation(new LocationBean(start, start_lat, start_lng),
								bus_start_time - depart_time, 2);
						route.get(k).addLocation(new LocationBean(busstop.get(i).getName(), busstop.get(i).getLat(),
								busstop.get(i).getLng()), busstop.get(i).getElapsed_time(), 1);
						route.get(k).addLocation(new LocationBean(location, lat, lng), lastwalk, 0);
						break;
					}
				}			
				//2. 버스->지하철->도보
				int snum = Find_subway_info(busstop.get(i).getNearest_station());
				if(snum==-1) continue;	
				int bus_station_time = calcElapsedTime(calcDistance(subwaylatlng.get(snum).getLat(),
						subwaylatlng.get(snum).getLng(), busstop.get(i).getLat(), busstop.get(i).getLng()))+2;
				tmptime = bus_time + bus_station_time;
				// 가장 빠른 출발 시간 고려한다면 추가. 지금은 없음.
				// int time = 가장 가까운 열차 출발시간.
				// tmptime += time-tmptime;
				for (int j = 0; j < nearsubway.size(); j++) {
					String subwaydata[]	= Get_subway_mintime(busstop.get(i).getNearest_station(),nearsubway.get(j).getName());	//버스에서 가장 가까운역과 도착역에서 가장가까운 역 사이의 최단거리.
					if(subwaydata==null) continue;
					int station_time = Integer.parseInt(subwaydata[0]);			
					lastwalk = calcElapsedTime(nearsubway.get(j).getDist());
					int ttmptime = tmptime + station_time + lastwalk;
					for (int k = 0; k < 2; k++) {
						if (ttmptime < mintime[k]) {
							for (int m = 1; m >= k; m--) {
								mintime[m + 1] = mintime[m];
							}
							mintime[k] = ttmptime;
							route.add(k, new RouteBean(bus_start_time,busstop.get(i).getLine_name(),busstop.get(i).getGate_number()));
						//// 도착 : 0 // 도보 : 1  // 버스 : 2 // 지하철 :3
							route.get(k).addLocation(new LocationBean(start, start_lat, start_lng),bus_start_time - depart_time, 2);
							route.get(k).addLocation(new LocationBean(busstop.get(i).getName(), busstop.get(i).getLat(),busstop.get(i).getLng()), busstop.get(i).getElapsed_time(), 1);
							route.get(k).addLocation(
											new LocationBean(subwaylatlng.get(snum).getName(),
													subwaylatlng.get(snum).getLat(), subwaylatlng.get(snum).getLng()),
											bus_station_time, 3);
							// 여기에 환승 역 정보 입력.
							for(int m=0; m<=(subwaydata.length-2)/3;m++)
							{							
								String name= subwaydata[(m+1)*3];
								int tmp=Find_subway_info(name);
								out.println(tmp+"<br>");
								if(tmp==-1) continue;
								double translat=subwaylatlng.get(tmp).getLat();
								double translng=subwaylatlng.get(tmp).getLng();
								if(m!=(subwaydata.length-2)/3) route.get(k).addLocation(new LocationBean(name,translat,translng),Integer.parseInt(subwaydata[(m+1)*3-1]),3);
								else route.get(k).addLocation(new LocationBean(name,translat,translng),Integer.parseInt(subwaydata[(m+1)*3-1]),1);
							}
							route.get(k).addLocation(new LocationBean(location, lat, lng), lastwalk, 0);
							break;
						}
					}
				}		
			}
			for (int i = 0; i < 2; i++)
			{
				for(int k=0; k<5;k++)
				{
					if(totalmintime[k]>mintime[i])
					{
						for (int m = 4; m >= k; m--) {
							totalmintime[m + 1] = totalmintime[m];
						}
						totalmintime[k]=mintime[i];
						totalroute.add(k,(RouteBean)route.get(i).clone());
						break;
					}
				}
			}		
		}
		request.setAttribute("route", totalroute);
		request.setAttribute("mintime", totalmintime);
		request.setAttribute("inittime", depart_time);
		
		request.setAttribute("start",start);
		request.setAttribute("week",week);
		request.setAttribute("destination",location);
		request.setAttribute("dest_lat",lat);
		request.setAttribute("dest_lng",lng);
		RequestDispatcher dispatcher = request.getRequestDispatcher("ResultPageSample.jsp");
		dispatcher.forward(request, response);
	%>
<%!
	ArrayList<SubwayLatLngBean> subwaylatlng;
	int hashtable[]= new int[2018];
	
	private void set_hash()
	{
		for(int i=0;i<2017;i++) hashtable[i]=-1;
		for(int i=0; i<subwaylatlng.size();i++)
		{
			String Name=subwaylatlng.get(i).getName();
			int key = Name.hashCode()%1009+1009;
			while(hashtable[key]!=-1)
			{
				key=(key+7)%2018;
			}
			hashtable[key]=i;
		}	
	}

	private int calcDistance(double lat1, double lon1, double lat2, double lon2) {
		double EARTH_R, Rad, radLat1, radLat2, radDist;
		double distance, ret;
		EARTH_R = 6371000.0;
		Rad = Math.PI / 180;
		radLat1 = Rad * lat1;
		radLat2 = Rad * lat2;
		radDist = Rad * (lon1 - lon2);
		distance = Math.sin(radLat1) * Math.sin(radLat2);
		distance = distance + Math.cos(radLat1) * Math.cos(radLat2) * Math.cos(radDist);
		ret = EARTH_R * Math.acos(distance);
		double rtn = Math.round(ret);
		int rrtn = (int) rtn;
		return rrtn;
	}

	private int calcElapsedTime(int dist) {
		// 도보의 시속은 평균 4km/h 이고 도보의 분속은 67m/min입니다.
		int time = Math.round(dist / 67);
		return time;	
	}	
	
	private int Find_subway_info(String station)
	{
		int key=station.hashCode()%1009+1009;
		while(hashtable[key]!=-1)
		{
			if(subwaylatlng.get(hashtable[key]).getName().equals(station)) return hashtable[key];
			key=(key+7)%2018;
		}
		return -1;
	}
	
	private String[] Get_subway_mintime(String station1, String station2) throws Exception 
	{
		Connection conn = null;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		String a="";
		try {  
			Context initCtx = new InitialContext();
			DataSource ds = (DataSource)initCtx.lookup("java:comp/env/jdbc/mariadb");	
			conn = ds.getConnection();
	  		pstmt = conn.prepareStatement("SELECT TimeInterval, TotalRoute FROM 지하철소요시간  WHERE Departure = '"+ station1+"' AND Destination = '" + station2 +"'");
	  		rs = pstmt.executeQuery(); 
	  		while(rs.next()) {
	  			a=a+rs.getString("TimeInterval") + "," + rs.getString("TotalRoute")+",";
	  		} 	  		
		}
		catch (Exception e) {  
		    e.printStackTrace(); 
		} 
		finally {
			if (rs != null) rs.close();
			if (pstmt != null) pstmt.close();
			if (conn != null) conn.close();		
		}
		String a_split[]=null;
		if (a!="") a_split=a.split(",");
		return a_split;
	}
	private ArrayList<SubwayLatLngBean> Get_subway_latlng() throws Exception
	{
		Connection conn = null;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		ArrayList<SubwayLatLngBean> ret= new ArrayList<SubwayLatLngBean>();
		try{
			Context initCtx = new InitialContext();
			DataSource ds = (DataSource)initCtx.lookup("java:comp/env/jdbc/mariadb");	
			conn = ds.getConnection();
	  		pstmt = conn.prepareStatement("SELECT StationName, Latitude, Longitude FROM 지하철위치정보");
	  		rs = pstmt.executeQuery(); 
	  		while(rs.next())
	  		{
	  			double lat=rs.getDouble("Latitude");
	  			double lng=rs.getDouble("Longitude");
	  			String name=rs.getString("StationName");
	  			ret.add(new SubwayLatLngBean(name,lat,lng));
	  		}
		}
		catch (Exception e) {  
		    e.printStackTrace(); 
		} 
		finally {
			if (rs != null) rs.close();
			if (pstmt != null) pstmt.close();
			if (conn != null) conn.close();		
		}
		return ret;
	}
	private ArrayList<BusStopBean> Get_bus_info(String Departure, String Week, int time,int gatenum) throws Exception
	{
		Connection conn = null;
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		ArrayList<BusStopBean> ret= new ArrayList<BusStopBean>();
		String Depart_time1=(time/60)+":"+(time%60);
		time+=60;//분단위로 버스 출발시간 범위 조절.
		String Depart_time2=(time/60)+":"+(time%60);
		try{
			Context initCtx = new InitialContext();
			DataSource ds = (DataSource)initCtx.lookup("java:comp/env/jdbc/mariadb");	
			conn = ds.getConnection();
//			pstmt = conn.prepareStatement("SELECT Destination, LineName, Gate, DepartTime, TimeInterval, Latitude, Longitude, metro FROM 버스  WHERE Departure ='"+ Departure+"'");
			pstmt = conn.prepareStatement("SELECT Destination, LineName, Gate, DepartTime, TimeInterval, Latitude, Longitude, metro FROM 버스  WHERE Departure ='"+ Departure+"' AND Gate ='"+ gatenum+"' AND Week ='"+ Week +"' AND DepartTime BETWEEN '"+ Depart_time1+"' AND '"+ Depart_time2+ "'");
			
			rs = pstmt.executeQuery(); 
	  		while(rs.next())
	  		{
	  			double lat=rs.getDouble("Latitude");
	  			double lng=rs.getDouble("Longitude");
	  			String name=rs.getString("Destination");
	  			String line_name= rs.getString("LineName");
	  			int gate_number=rs.getInt("Gate");
	  			String tmp=rs.getString("DepartTime");
	  			String[] tmp_s=tmp.split(":");
	  			int start_time=Integer.parseInt(tmp_s[0])*60+Integer.parseInt(tmp_s[1]);
	  			int elapsed_time = rs.getInt("TimeInterval");
	  			String metro=rs.getString("metro");
	  			ret.add(new BusStopBean(name,line_name,gate_number,lat,lng,start_time,elapsed_time,metro));
	  		}
		}
		catch (Exception e) {  
		    e.printStackTrace(); 
		} 
		finally {
			if (rs != null) rs.close();
			if (pstmt != null) pstmt.close();
			if (conn != null) conn.close();		
		}
		return ret;
	}
%>
