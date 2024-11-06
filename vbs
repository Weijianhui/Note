set ws=WScript.CreateObject("WScript.Shell")
ws.run "cmd /c start-sx-webapp.bat",0 #后台运行bat
set ws2=WScript.CreateObject("WScript.Shell")
ws2.run "cmd /c start-ai.bat",0
dim ws3
set ws3=WScript.CreateObject("WScript.Shell")
WScript.Sleep(3000)
ws3.run "E:\sx\sx-test\sx\sx\client\Sx.Teach.WebShell.exe",false,false #前台运行程序