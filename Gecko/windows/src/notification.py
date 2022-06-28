import wx
import config
import os
import subprocess
import threading
import time
import textwrap


def notificationWindow_gtknotify(mw, name, text, buddy):
    import pynotify
    import cgi
    if not pynotify.is_initted():
        if not pynotify.init('Gecko'):
            raise Exception('gtknotify не поддерживается')
    pynotify.Notification(
        cgi.escape(name).encode('ascii', 'xmlcharrefreplace'), 
        cgi.escape(text).encode('ascii', 'xmlcharrefreplace')
    ).show()



