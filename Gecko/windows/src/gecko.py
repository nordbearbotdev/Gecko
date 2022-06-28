import config
import wxversion
if config.isMac():
    if wxversion.checkInstalled('3.9'):
        wxversion.select('3.9') 
    else:
        print "(1) wxPython-3.9 не установлен"
        
else:
    try:
        if wxversion.checkInstalled('3.8'):
            wxversion.select('3.8') 
        else:
            print "(1) wxPython-3.8 не установлен"
        
    except:
     
        print ""

import wx
import os
import tc_client
import tc_gui
        
def main():
    print "(2) wxPython версия %s" % wx.version()
    if config.isMac():
        import tc_mac
        app = tc_mac.App(redirect=False)
    else:
        app = wx.App(redirect=False)
    
    interface = config.get("client", "listen_interface")
    port = config.getint("client", "listen_port")
    print "(1) %s:%s" % (interface, port)
    listen_socket = tc_client.tryBindPort(interface, port)
    if not listen_socket:
        print "(1) %s:%s готов к использованию" % (interface, port)
        wx.MessageBox(tc_gui.lang.D_WARN_USED_PORT_MESSAGE % (interface, port),
                      tc_gui.lang.D_WARN_USED_PORT_TITLE)
        return
    else:
        print "(1) %s:%s" % (interface, port)
    
    print "(1) Начать инициализацию главного окна"
    app.mw = tc_gui.MainWindow(listen_socket)
    app.SetTopWindow(app.mw)
    print "(1) Инициализация главного окна "
    print "(1) Вход в основной цикл"
    app.MainLoop()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        tc_client.stopPortableTor()
