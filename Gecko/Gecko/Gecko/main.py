# Импорть
import sys
from PyQt5 import QtCore, QtGui, QtWidgets


class Gecko: # Создаем класс Gecko
  
  
    def __init__(self, path_or_uri=None):
        super(Gecko, self).__init__()
        self.tox = self.ms = self.init = self.app = self.tray = self.mainloop = self.avloop = None
        if path_or_uri is None:
            self.uri = self.path = None
        elif path_or_uri.startswith('tox:'):
            self.path = None
            self.uri = path_or_uri[4:]
        else:
            self.path = path_or_uri
            self.uri = None

    def enter_pass(self, data): # Показать пароль
      
        tmp = [data]
        p = PasswordScreen(toxes.ToxES.get_instance(), tmp)
        p.show()
        self.app.lastWindowClosed.connect(self.app.quit)
        self.app.exec_()
        if tmp[0] == data:
            raise SystemExit()
        else:
            return tmp[0]
