<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" %>
<%@ page import="basBeanFile.*,java.util.*"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %> 
<%@ taglib uri="http://java.sun.com/jsp/jstl/sql" prefix="sql" %>    
<%
//최단경로의 모든 구간들이 저장되어있다.
	ArrayList<RouteBean> route=(ArrayList<RouteBean>)request.getAttribute("route");
//최단시간이 저장되어있다.
	int mintime[]=(int[])request.getAttribute("mintime");
	int inittime = (int)request.getAttribute("inittime");
	int inithour=Math.round(inittime/60);
	int initmin =inittime%60;
	String loca[] = new String[5];
	int hour[]=new int[5];
	int min[] =new int[5];
	for(int i=0;i<5;i++)
	{
		loca[i]=route.get(i).getLocation()[0].getName();
		hour[i]=Math.round(route.get(i).getStart_time()/60);
		min[i]=route.get(i).getStart_time()%60;
	}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<style>
.dot {overflow:hidden;float:left;width:12px;height:12px;background: url('http://t1.daumcdn.net/localimg/localimages/07/mapapidoc/mini_circle.png');}    
.dotOverlay {position:relative;bottom:10px;border-radius:6px;border: 1px solid #ccc;border-bottom:2px solid #ddd;float:left;font-size:12px;padding:5px;background:#fff;}
.dotOverlay:nth-of-type(n) {border:0; box-shadow:0px 1px 2px #888;}    
.number {font-weight:bold;color:#ee6152;}
.location {font-weight:bold;color:#ee6152;}
.destination {font-weight:bold;color:#aa4132;}
.shortway {font-weight:bold;color:#cc5142;}
.dotOverlay:after {content:'';position:absolute;margin-left:-6px;left:50%;bottom:-8px;width:11px;height:8px;background:url('http://t1.daumcdn.net/localimg/localimages/07/mapapidoc/vertex_white_small.png')}
.distanceInfo {position:relative;top:5px;left:5px;list-style:none;margin:0;}
.distanceInfo .label {display:inline-block;width:50px;}
.distanceInfo:after {content:none;}
</style>
</head>
<body>

<!-- 최단 거리 테이블 -->
<table border="1">
<tr>
<th>
<h1><%=inithour%>시 <%=initmin %>분 기준<br> 최적 경로 안내</h1>
</th>
</tr>
<tr>
<td onclick="changeRoute(0)" width="300px" height="50px">
1번 경로 . <%=loca[0] %>에서 <%=hour[0]%>시 <%=min[0]%>분에 출발. <br> 
소요시간 : <%=mintime[0]%>분</td>
</tr>
<tr>
<td onclick="changeRoute(1)" width="300px" height="50px">
2번 경로 . <%=loca[1] %>에서 <%=hour[1]%>시 <%=min[1]%>분에 출발. <br> 
소요시간 : <%=mintime[1]%>분</td>
</tr>
<tr>
<td onclick="changeRoute(2)" width="300px" height="50px">
3번 경로 . <%=loca[2] %>에서 <%=hour[2]%>시 <%=min[2]%>분에 출발. <br> 
소요시간 : <%=mintime[2]%>분</td>
</tr>
<tr>
<td onclick="changeRoute(3)" width="300px" height="50px">
4번 경로 . <%=loca[3] %>에서 <%=hour[3]%>시 <%=min[3]%>분에 출발. <br> 
소요시간 : <%=mintime[3]%>분</td>
</tr>
<tr>
<td onclick="changeRoute(4)" width="300px" height="50px">
5번 경로 . <%=loca[4] %>에서 <%=hour[4]%>시 <%=min[4]%>분에 출발. <br> 
소요시간 : <%=mintime[4]%>분</td>
</tr>
</table>

<!-- 지도가 들어갈 영역. -->
<div id="map" style="width:550px;height:550px; float:left;margin-right:20px"></div>  


<!-- 최단거리 세부정보가 들어갈 영역. -->
<div id="shortway" style="width:550px;height:550px;float:left;"></div>


<!-- 지도 정보. -->
<script type="text/javascript" src="//dapi.kakao.com/v2/maps/sdk.js?appkey=4ac39ad7824ced1e734d0b09f8be5262"></script>
<script>
var mapContainer = document.getElementById('map'), // 지도를 표시할 div  
mapOption = { 
    center: new kakao.maps.LatLng(37.490176,127.019539), // 지도의 중심좌표
    level: 3 // 지도의 확대 레벨
};
var map = new kakao.maps.Map(mapContainer, mapOption); // 지도를 생성합니다
var distanceOverlay; // 정보를 표시할 커스텀오버레이.
var dots = []; // 찍힌 점들  저장. (점을 삭제할때 필요함)
var infos = [];// 찍힌 정보들 저장. (정보를 삭제할때 필요함)
var path=[];	//선을 그릴 좌표 저장.

// 아래는 결과 창으로 넘어올 전체 데이터 파싱하는 부분 //
var stop = [ <% for(int i=0; i<5;i++) out.print("'"+route.get(i).getNum()+"',"); %> ];
var gate = [ <% for(int i=0; i<5;i++) out.print("'"+route.get(i).getGate_number()+"',"); %> ];
var linename = [ <% for(int i=0; i<5;i++) out.print("'"+route.get(i).getLine_name()+"',"); %> ];
var inittime = '<%=inithour%>'+"시 "+'<%=initmin%>'+"분";
var loc=[<%
		for(int j=0;j<route.size();j++){
			out.print("[");
			for(int i=0; i<route.get(j).getNum();i++) out.print("'"+route.get(j).getLocation()[i].getName()+"',");
			out.print("],");
		}%>];
var lat=[<%
	for(int j=0;j<route.size();j++){
		out.print("[");
		for(int i=0; i<route.get(j).getNum();i++) out.print("'"+route.get(j).getLocation()[i].getLat()+"',");
		out.print("],");
	}%>];
var lng=[<%
	for(int j=0;j<route.size();j++){
		out.print("[");
		for(int i=0; i<route.get(j).getNum();i++) out.print("'"+route.get(j).getLocation()[i].getLng()+"',");
		out.print("],");
	}%>];
var elapsed=[<%
	for(int j=0;j<route.size();j++){
		out.print("[");
		for(int i=0; i<route.get(j).getNum();i++) out.print("'"+route.get(j).getElapsed_time()[i]+"',");
		out.print("],");
	}%>];
var method=[<%
	for(int j=0;j<route.size();j++){
		out.print("[");
		for(int i=0; i<route.get(j).getNum();i++) out.print("'"+route.get(j).getMethod()[i]+"',");
		out.print("],");
	}%>];
//여기까지 결과 창으로 넘어올 전체 데이터 파싱하는 부분 완료 //	

var clickLine = new kakao.maps.Polyline({
    map: map, // 선을 표시할 지도입니다 
    path: null, // 선을 구성하는 좌표 배열입니다 클릭한 위치를 넣어줍니다
    strokeWeight: 3, // 선의 두께입니다 
    strokeColor: '#bb00bb', // 선의 색깔입니다	//완료된 색.
    strokeOpacity: 1, // 선의 불투명도입니다 0에서 1 사이값이며 0에 가까울수록 투명합니다
    strokeStyle: 'solid' // 선의 스타일입니다
});

//경로를 다시 그리는 함수 "num번째 최단거리"를 그려준다.
function changeRoute(num)
{
	path=[];
	var totaltime=0;
	deleteCircleDot();
	for(i=0;i<stop[num];i++) 
	{
		path.push(new kakao.maps.LatLng(lat[num][i],lng[num][i]));
		totaltime+=Number(elapsed[num][i]);
		displayCircleDot(path[i],loc[num][i],method[num][i],totaltime);//메소드 처리 해야함.
	}
	clickLine.setPath(path);
	setBounds();
	var message="";
	// 경로 보여주기.
	/*
	if(stop[num]==2)
	{
		message+=loc[num][0]+"정류장에서 출발<br>"
		message+="도보로 "+ elapsed[num][1] + "분 이동 후 목적지 "+ loc[num][1]+"에 도착.<br>"; 
	}
	else if(stop[num]==3)
	{
		message+=loc[num][0]+"정류장 "+gate[num]+"번 게이트에서 "+ inittime+"에 출발하는 "+ linename[num]+" 버스 탑승.<br>";
		message+="버스로 "+elapsed[num][1]+"분 이동 후 "+ loc[num][1]+"에서 하차.<br>";
		message+="도보로 "+ elapsed[num][2] + "분 이동 후 목적지 "+ loc[num][2]+"에 도착.<br>"; 
	}
	else
	{
		message+=loc[num][0]+"정류장 "+gate[num]+"번 게이트에서 "+ inittime+"에 출발하는 "+ linename[num]+" 버스 탑승.<br>";
		message+="버스로 "+elapsed[num][1]+"분 이동 후 "+ loc[num][1]+"에서 하차.<br>";
		message+="도보로 "+elapsed[num][2]+"분 이동 후 "+ loc[num][2]+"에서 지하철 탑승.<br>";
		for(i=3;i<stop[num]-2;i++)
		{
			message+="지하철로 "+elapsed[num][i]+"분 이동 후 "+ loc[num][i]+"에서 지하철 환승.<br>";
		}
		message+="지하철로 "+elapsed[num][stop[num]-2]+"분 이동 후 "+ loc[num][stop[num]-2]+"에서 하차.<br>";
		message+="도보로 "+ elapsed[num][stop[num]-1] + "분 이동 후 목적지 "+ loc[num][stop[num]-1]+"에 도착.<br>"; 
	}
	*/
	if(stop[num]==2)
	{
		message+="<span class='shortway'>"+loc[num][0]+"</span>정류장에서 출발<br>";
		message+="<span class='shortway'>도보</span>로 <span class='shortway'>"+ elapsed[num][1] + "</span>분 이동 후 목적지 <span class='destination'>"+ loc[num][1]+"</span>에 도착.<br>"; 
	}
	else if(stop[num]==3)
	{
		message+="<span class='shortway'>"+loc[num][0]+"</span>정류장  <span class='shortway'>"+gate[num]+"</span>번 게이트에서 <span class='shortway'>"+ inittime+"</span>에 출발하는 <span class='shortway'>"+ linename[num]+"</span>행 버스 탑승.<br>";
		message+="<span class='shortway'>버스</span>로 <span class='shortway'>"+elapsed[num][1]+"</span>분 이동 후 <span class='shortway'>"+ loc[num][1]+"</span>에서 하차.<br>";
		message+="<span class='shortway'>도보</span>로 <span class='shortway'>"+elapsed[num][2]+"</span>분 이동 후 목적지 <span class='destination'>"+ loc[num][2]+"</span>에 도착.<br>"; 
	}
	else
	{
		message+="<span class='shortway'>"+loc[num][0]+"</span>정류장  <span class='shortway'>"+gate[num]+"</span>번 게이트에서 <span class='shortway'>"+ inittime+"</span>에 출발하는 <span class='shortway'>"+ linename[num]+"</span>행 버스 탑승.<br>";
		message+="<span class='shortway'>버스</span>로 <span class='shortway'>"+elapsed[num][1]+"</span>분 이동 후 <span class='shortway'>"+ loc[num][1]+"</span>에서 하차.<br>";
		message+="<span class='shortway'>도보</span>로 <span class='shortway'>"+elapsed[num][2]+"</span>분 이동 후 <span class='shortway'>"+ loc[num][2]+"</span>에서 지하철 탑승.<br>";
		for(i=3;i<stop[num]-2;i++)
		{
			message+="<span class='shortway'>지하철</span>로 <span class='shortway'>"+elapsed[num][i]+"</span>분 이동 후 <span class='shortway'>"+ loc[num][i]+"</span>에서 환승.<br>";
		}
		message+="<span class='shortway'>지하철</span>로 <span class='shortway'>"+elapsed[num][stop[num]-2]+"</span>분 이동 후 <span class='shortway'>"+ loc[num][stop[num]-2]+"</span>에서 하차.<br>";
		message+="<span class='shortway'>도보</span>로 <span class='shortway'>"+ elapsed[num][stop[num]-1] + "</span>분 이동 후 목적지 <span class='destination'>"+ loc[num][stop[num]-1]+"</span>에 도착.<br>"; 
	}
	
	document.getElementById('shortway').innerHTML=message; 
}

function displayCircleDot(position,loca,method,time) {
	// 지도에 점찍기
    var circleOverlay = new kakao.maps.CustomOverlay({
        content: '<span class="dot"></span>',
        position: position,
        zIndex: 1
    });
    circleOverlay.setMap(map);
    var bmw;	//bus metro walk. 
    //// 도착: 0 // 도보 : 1  // 버스 : 2 // 지하철 :3
	if(method == 1) bmw="도보";
	else if(method ==2) bmw="버스";
	else if(method ==3) bmw="지하철";
	else bmw="목적지";
    //지도에 정보표시
    var content="";
    if(method!=0)
    	content='<div class="dotOverlay">위치 : <span class="location">' + loca  +'</span><br>시간 : <span class="number">' + time + '</span>분<br> 방법 : <span class="location">'+bmw+'</span></div>';
    else
    	content= '<div class="dotOverlay"><span class="destination">'+bmw+'</span><br> 위치 : <span class="location">' + loca  +'</span><br>시간 : <span class="number">' + time + '</span>분</div>';
    var distanceOverlay = new kakao.maps.CustomOverlay({
	        content: content,
	        position: position,
	        yAnchor: 1,
	        zIndex: 2
	    });
    distanceOverlay.setMap(map);  
    dots.push(circleOverlay);
    infos.push(distanceOverlay); 
}

function deleteCircleDot() {
    for (var i = 0; i < dots.length; i++ ){
        if (dots[i]) { dots[i].setMap(null);
        }
        if (infos[i]) { infos[i].setMap(null);
        }
    }
    dots = [];
    infos = [];
}
function setBounds() {
    // LatLngBounds 객체에 추가된 좌표들을 기준으로 지도의 범위를 재설정.
    // 이때 지도의 중심좌표와 레벨이 변경될 수 있습니다
	var bounds = new kakao.maps.LatLngBounds();  
	for (var i = 1; i < path.length; i++) {
	    // LatLngBounds 객체에 좌표를 추가합니다
	    bounds.extend(path[i]);
	}
    map.setBounds(bounds);
}

</script>
<!--  지도 정보 끝 -->
</body>
</html>
