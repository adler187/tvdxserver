var curDateTime = new Date()
var curHour = curDateTime.getHours()
var curMin = curDateTime.getMinutes()
var curAMPM = " AM"
var curTime = ""
if (curHour >= 12){
  curHour -= 12
  curAMPM = " PM"
}
if (curHour == 0) curHour = 12
curTime = curHour + ":" 
  + ((curMin < 10) ? "0" : "") + curMin + curAMPM
document.write(curTime)

var date = curDateTime.getDate()
var month = curDateTime.getMonth()
var year = curDateTime.getYear()
month = month + 1
if(year<1000) year+=1900
document.write(" " + month + "/" + date + "/" + year)
