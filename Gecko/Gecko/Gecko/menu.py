# Импорты
from PyQt5 import QtCore, QtGui, QtWidgets


class AddContact(CenteredWidget): # Создаем класс с добавлением контактов в Geckp
 

    def __init__(self, gecko_id=''):
        super(AddContact, self).__init__()
        self.initUI(gecko_id)
        self._adding = False
