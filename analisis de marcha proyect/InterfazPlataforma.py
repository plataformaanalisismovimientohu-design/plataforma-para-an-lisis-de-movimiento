import sys
import cv2
from PySide6.QtWidgets import (QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, 
                               QWidget, QPushButton, QLabel, QGridLayout, QComboBox, 
                               QMessageBox, QFormLayout, QSpacerItem, QSizePolicy,
                               QLineEdit, QSpinBox)
from PySide6.QtGui import QAction, QImage, QKeySequence, QPixmap
from PySide6.QtCore import Qt, QThread, Signal, Slot,QTimer
from ui_mainWindow import Ui_MainWindow
import random
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import time
import pyrealsense2 as rs
from realsense_depth import *
import mediapipe as mp
from detector_object2 import Pose_Detector
import pandas as pd
from datetime import datetime
from functools import partial
import numpy as np
import os, re


class Thread(QThread):
    updateFrame = Signal(QImage)
    updateData = Signal(float, float)
    finishedData = Signal(list)
    
    def __init__(self):
        super().__init__()
        self.status = True
        self.resolution = None
        self.fps = None
        self.detector = Pose_Detector()
        self.modo = "hombros"
        self.all_data = []
        self.frame_count = 0

    def setCameraParams(self, resolution, fps):
        self.resolution = resolution
        self.fps = fps

    def setFlagData(self, data):
        print("el modo de operacion  es:",data)
        self.modo = data
        
    def run(self):
        if self.resolution is None or self.fps is None:
            return
        
        try:
            self.detector.start_pipeline(self.resolution, self.fps)
        except RuntimeError as e:
            print("Error al iniciar cámara:", e)
            return

        while self.status:
            _, _, color_frame = self.detector.get_frame()

            # PROTECCIÓN 1: frame válido
            if color_frame is None:
                continue

            color_frame = self.detector.find_Pose(color_frame)
            LmList = self.detector.find_Position(color_frame)

            # PROTECCIÓN 2: landmarks válidos
            if not LmList:
                continue

            (List_Data, temp,
            a_hip_i, a_hip_d,
            a_knee_i, a_knee_d,
            a_ankle_i, a_ankle_d,
            a_sh_i, a_sh_d,
            a_el_i, a_el_d,
            a_wr_i, a_wr_d) = self.detector.angle_joint(LmList)

            self.detector.angles_to_Lists(
                temp,
                a_hip_i, a_hip_d,
                a_knee_i, a_knee_d,
                a_ankle_i, a_ankle_d,
                a_sh_i, a_sh_d,
                a_el_i, a_el_d,
                a_wr_i, a_wr_d
            )

            if List_Data is not None and self.detector.posicion and len(List_Data) == 13:
                self.all_data.append(List_Data)

            # seleccionar modo
            if self.modo == "tobillos":
                d1, d2 = a_ankle_i, a_ankle_d
            elif self.modo == "caderas":
                d1, d2 = a_hip_i, a_hip_d
            elif self.modo == "codos":
                d1, d2 = a_el_i, a_el_d
            elif self.modo == "hombros":
                d1, d2 = a_sh_i, a_sh_d
            elif self.modo == "rodillas":
                d1, d2 = a_knee_i, a_knee_d
            else:
                d1, d2 = a_wr_i, a_wr_d

            self.updateData.emit(d1, d2)

            frame = cv2.cvtColor(color_frame, cv2.COLOR_BGR2RGB)
            image = QImage(frame, frame.shape[1], frame.shape[0],
                        frame.strides[0], QImage.Format_RGB888)

            self.updateFrame.emit(image)

        self.detector.release()
        self.finishedData.emit(self.all_data)
 
class MplCanvas(FigureCanvas):

    def __init__(self, parent=None, width=5, height=4, dpi=100):
        fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = fig.add_subplot(111)
        super(MplCanvas, self).__init__(fig)

class MainWindow(QMainWindow):
    flagArm = Signal(str)

    def __init__(self):
        super(MainWindow, self).__init__()
        self.setWindowTitle("Sistema P.A.M")

        n_data = 30
        self.xdata = list(range(n_data))
        
        self.ydata = [0] * n_data
        self.ydata_2 = [0] * n_data

        # Crear el layout principal
        main_layout = QHBoxLayout()  # Dividir en 3/4 y 1/4

        # Layout izquierdo con frames de cámara y gráficas (3/4 del ancho)
        left_layout = QVBoxLayout()

        # Frame para la cámara (parte superior izquierda, 1/2 del alto)
        self.camera_label = QLabel("Frame de la cámara")
        self.camera_label.setFixedSize(960, 540)  # Tamaño fijo para la cámara, 3/4 del ancho
        self.camera_label.setStyleSheet("background-color: black;")
        left_layout.addWidget(self.camera_label)

        # Gráficas izquierda y derecha (parte inferior izquierda, 1/2 del alto)
        graph_layout = QHBoxLayout()

        # Gráfica izquierda
        self.canvas1 = MplCanvas(self, width=5, height=2, dpi=100)
        self.canvas1.axes.set_title("Articulación Izquierda")
        self.canvas1.axes.set_ylabel("Ángulo (°)")
        self.line1, = self.canvas1.axes.plot(self.xdata, self.ydata, color='blue')
        self.canvas1.axes.set_ylim(-180, 180)
        self.canvas1.draw()
        graph_layout.addWidget(self.canvas1)

        # Gráfica derecha
        self.canvas2 = MplCanvas(self, width=5, height=2, dpi=100)
        self.canvas2.axes.set_title("Articulación Derecha")
        self.canvas2.axes.set_ylabel("Ángulo (°)")        
        self.line2, = self.canvas2.axes.plot(self.xdata, self.ydata_2, color='red')
        self.canvas2.axes.set_ylim(-180, 180)
        self.canvas2.draw()
        graph_layout.addWidget(self.canvas2)
        

        # Añadir el layout de gráficas al layout izquierdo
        left_layout.addLayout(graph_layout)

        # Añadir el layout izquierdo al layout principal
        main_layout.addLayout(left_layout, 3)  # Ocupa 3/4 del ancho de la ventana

        # Layout derecho para controles (1/4 del ancho)
        right_layout = QVBoxLayout()

        # Usar QFormLayout para etiquetas y botones desplegables
        form_layout = QFormLayout()

        # Ajustar el espaciado
        form_layout.setHorizontalSpacing(10)
        form_layout.setVerticalSpacing(5)

        self.input_nombre = QLineEdit()
        self.input_intento = QSpinBox()
        self.input_intento.setMinimum(1)
        form_layout.addRow("Voluntario", self.input_nombre)
        form_layout.addRow("Intento", self.input_intento)

        # Botón desplegable para seleccionar el plano
        self.combo_plano = QComboBox()
        self.combo_plano.addItems(["Plano Frontal", "Plano Sagital"])
        self.combo_plano.setFixedWidth(150)
        form_layout.addRow("Seleccionar Plano", self.combo_plano)

        # Botón desplegable para seleccionar el tipo de cámara
        self.combo_camera = QComboBox()
        self.combo_camera.addItems(["D435I", "D455"])
        self.combo_camera.setFixedWidth(150)
        form_layout.addRow("Cámara", self.combo_camera)

        # Botón desplegable para seleccionar la resolución
        self.combo_resolution = QComboBox()
        self.combo_resolution.setFixedWidth(150)
        form_layout.addRow("Resolución", self.combo_resolution)

        # Botón desplegable para seleccionar FPS
        self.combo_fps = QComboBox()
        self.combo_fps.setFixedWidth(150)
        form_layout.addRow("FPS de la cámara", self.combo_fps)

        # Conectar el cambio de cámara para actualizar las opciones de resolución y FPS
        self.combo_camera.currentIndexChanged.connect(self.update_camera_options)
        self.update_camera_options()

        # Añadir el form_layout al layout derecho
        right_layout.addLayout(form_layout)

        # Lista de botones de articulaciones
        self.buttons = {
            'hombros': QPushButton("Hombro"),
            'caderas': QPushButton("Cadera"),
            'codos': QPushButton("Codo"),
            'rodillas': QPushButton("Rodilla"),
            'muñecas': QPushButton("Muñeca"),
            'tobillos': QPushButton("Tobillo")
        }

        # Añadir botones de articulaciones en una cuadrícula, ajustando el espaciado
        articulations_layout = QGridLayout()
        articulations_layout.setHorizontalSpacing(5)
        articulations_layout.setVerticalSpacing(5)
        articulations_layout.setContentsMargins(0, 0, 0, 0)  # Sin márgenes para minimizar la separación

        for i, (key, button) in enumerate(self.buttons.items()):
            row = i // 2
            col = i % 2
            articulations_layout.addWidget(button, row, col)
            button.clicked.connect(partial(self.setFlagArm, key))

        # Añadir el layout de botones de articulaciones al layout derecho
        right_layout.addLayout(articulations_layout)

        # Botones de iniciar y detener
        control_layout = QHBoxLayout()
        self.start_button = QPushButton("Iniciar")
        self.stop_button = QPushButton("Detener")
        control_layout.addWidget(self.start_button)
        control_layout.addWidget(self.stop_button)

        # Añadir los botones de control al layout derecho
        right_layout.addLayout(control_layout)

        # Añadir el layout derecho al layout principal
        main_layout.addLayout(right_layout, 1)  # Ocupa 1/4 del ancho de la ventana

        # Crear un contenedor central para el layout principal
        central_widget = QWidget()
        central_widget.setLayout(main_layout)
        self.setCentralWidget(central_widget)

        # Cambia de color el fondo de la Ventana principal
        self.setStyleSheet("""
            QMainWindow {
                background-color: #FFFFFF;
            }
            """)

        # Conectar los botones de control
        self.start_button.clicked.connect(self.start)
        self.stop_button.clicked.connect(self.kill_thread)      

    def save_to_Excel(self, data):

        nombre = self.input_nombre.text()
        intento = self.input_intento.value()
        plano = self.combo_plano.currentText()

        nombre = re.sub(r'\s+', '_', nombre.strip())
        plano = plano.replace(" ", "_")

        fecha = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

        # NUEVA RUTA
        carpeta = os.path.join("Datos", nombre)
        os.makedirs(carpeta, exist_ok=True)

        archivo = f"{nombre}_Intento{intento}_{plano}_{fecha}.csv"
        ruta = os.path.join(carpeta, archivo)

        if len(data) < 50:
            QMessageBox.warning(self, "Error", "Cantidad de Datos insuficiente")
            return

        df = pd.DataFrame(data, columns=[
            'Tiempo','Ang_Cade_iz','Ang_Cade_der','Ang_Rod_iz','Ang_Rod_der',
            'Ang_Tob_iz','Ang_Tob_der','Ang_Hombro_iz','Ang_Hombro_der',
            'Ang_Codo_iz','Ang_Codo_der','Ang_Muneca_iz','Ang_Muneca_der'
        ])

        df.to_csv(ruta, index=False, sep=';')
        print("Guardado en:", ruta)

    def update_camera_options(self):
        """Actualiza las opciones de resolución y FPS según el tipo de cámara seleccionado."""
        camera_type = self.combo_camera.currentText()

        # Limpiar las opciones actuales
        self.combo_resolution.clear()
        self.combo_fps.clear()

        # Resoluciones y FPS para la D435l
        if camera_type == "D435I":
            self.resolution_fps_mapping = {
                "320x180": [6, 30, 60],
                "320x240": [6, 30, 60],
                "424x240": [6, 15, 30, 60],
                "640x360": [6, 15, 30, 60],
                "640x480": [6, 15, 30, 60],
                "848x480": [6, 15, 30, 60],
                "960x540": [6, 30, 60],
                "1280x720": [6, 15, 30],
                "1920x1080": [6, 15, 30]
            }
            self.combo_resolution.addItems(self.resolution_fps_mapping.keys())

        # Resoluciones y FPS para la D455
        elif camera_type == "D455":
            self.resolution_fps_mapping = {
                "424x240": [5, 15, 30, 60, 90],
                "480x270": [5, 15, 30, 60, 90],
                "640x360": [5, 15, 30, 60, 90],
                "640x480": [5, 15, 30, 60],
                "848x480": [5, 15, 30, 60],
                "1280x720": [5, 10, 15, 30],
                "1280x800": [5, 10, 15, 30]
            }
            self.combo_resolution.addItems(self.resolution_fps_mapping.keys())
        
        try:
            self.combo_resolution.currentIndexChanged.disconnect()
        except:
            pass

        # Conectar el cambio de resolución para actualizar las opciones de FPS
        self.combo_resolution.currentIndexChanged.connect(self.update_fps_options)

        # Actualizar los FPS cuando se cambie la resolución
        self.update_fps_options()

    def update_fps_options(self):
        """Actualiza las opciones de FPS basadas en la resolución seleccionada."""
        selected_resolution = self.combo_resolution.currentText()

        # Limpiar las opciones de FPS
        self.combo_fps.clear()

        if selected_resolution in self.resolution_fps_mapping:
            fps_options = self.resolution_fps_mapping[selected_resolution]
            self.combo_fps.addItems(map(str, fps_options))


    def updateButtonStyles(self, active_button):
        # Cambiar el color del botón presionado
        for key, button in self.buttons.items():
            if key == active_button:
                button.setStyleSheet("background-color: green; color: white;") # Cambiar a verde
            else:
                button.setStyleSheet("") # Restablecer a color original

    def kill_thread(self):
        if hasattr(self, 'th') and self.th.isRunning():
            self.th.status = False
            self.th.wait()

            print("Transmisión detenida")

            self.camera_label.clear()

            self.ydata = [0] * len(self.xdata)
            self.ydata_2 = [0] * len(self.xdata)

            self.line1.set_ydata(self.ydata)
            self.line2.set_ydata(self.ydata_2)

            self.canvas1.draw_idle()
            self.canvas2.draw_idle()

            self.updateButtonStyles(None)
            self.enable_dropdowns()
   

    @Slot()
    def start(self):
        if hasattr(self, 'th') and self.th.isRunning():
            self.kill_thread()
            return

        #  Validar nombre del participante
        nombre = self.input_nombre.text().strip()
        if not nombre:
            QMessageBox.warning(
                self,
                "Advertencia",
                "Ingrese el nombre del participante."
            )
            self.input_nombre.setFocus()
            return

        #  Validar FPS
        fps_text = self.combo_fps.currentText()
        if not fps_text:
            QMessageBox.warning(self, "Advertencia", "Seleccione FPS.")
            return

        #  Validar resolución
        res = self.combo_resolution.currentText()
        if not res:
            QMessageBox.warning(self, "Advertencia", "Seleccione resolución.")
            return

        # Validar dispositivo conectado
        try:
            self.th = Thread()
            camera_selected = self.combo_camera.currentText()
            camera_connected = self.th.detector.device.get_info(rs.camera_info.name)

        except Exception:
            QMessageBox.warning(
                self,
                "Advertencia",
                "No se detectó ningún dispositivo Intel RealSense.\n\nConecte la cámara e intente nuevamente."
            )
            return

        # Validar que la cámara seleccionada coincida con la conectada
        if camera_selected not in camera_connected:
            QMessageBox.warning(
                self,
                "Cámara incorrecta",
                f"Seleccionó {camera_selected}, pero la cámara conectada es: {camera_connected}"
            )
            return

        fps = int(fps_text)

        # Conectar señales
        self.th.updateData.connect(self.update_plot)
        self.th.updateFrame.connect(self.setImage)
        self.th.finishedData.connect(self.save_to_Excel)

        # Configurar cámara
        self.th.setCameraParams(res, fps)

        # Preparar interfaz
        self.camera_label.clear()
        self.disable_dropdowns()

        # Iniciar transmisión
        self.th.start()

      
    def disable_dropdowns(self):
        self.combo_plano.setEnabled(False)
        self.combo_camera.setEnabled(False)
        self.combo_resolution.setEnabled(False)
        self.combo_fps.setEnabled(False)
        self.input_nombre.setEnabled(False)
        self.input_intento.setEnabled(False)

    def enable_dropdowns(self):
        self.combo_plano.setEnabled(True)
        self.combo_camera.setEnabled(True)
        self.combo_resolution.setEnabled(True)
        self.combo_fps.setEnabled(True)
        self.input_nombre.setEnabled(True)
        self.input_intento.setEnabled(True)

    # Función para actualizar la imagen de la cámara
    @Slot(QImage)
    def setImage(self, image):
        pix = QPixmap.fromImage(image)
        self.camera_label.setPixmap(pix.scaled(self.camera_label.size(), Qt.KeepAspectRatio))

    def update_plot(self, d1, d2):
        self.ydata.append(d1)
        self.ydata.pop(0)

        self.ydata_2.append(d2)
        self.ydata_2.pop(0)

        self.line1.set_ydata(self.ydata)
        self.line2.set_ydata(self.ydata_2)

        self.canvas1.draw_idle()
        self.canvas2.draw_idle()

    # cambia los limites del eje y segun el boton presionado
    def adjustYAxis(self, modo):
        if modo == "rodillas":
            ymin, ymax = -10, 70
            ticks = [-10, 0, 20, 40, 60, 70]

        elif modo == "tobillos":
            ymin, ymax = -30, 30
            ticks = [-30, -20, -10, 0, 10, 20, 30]

        elif modo == "caderas":
            ymin, ymax = -40, 50
            ticks = [-40, -20, 0, 20, 40, 50]

        elif modo in ["hombros", "codos", "muñecas"]:
            ymin, ymax = -180, 180
            ticks = [-180, -90, 0, 90, 180]

        else:
            ymin, ymax = -180, 180
            ticks = [-180, -90, 0, 90, 180]

        self.canvas1.axes.set_ylim(ymin, ymax)
        self.canvas2.axes.set_ylim(ymin, ymax)

        self.canvas1.axes.set_yticks(ticks)
        self.canvas2.axes.set_yticks(ticks)

        self.canvas1.draw_idle()
        self.canvas2.draw_idle()


    # Cambiar el color del botón presionado 
    @Slot(str)
    def setFlagArm(self, _data):
        if hasattr(self, 'th') and self.th.isRunning():
            self.th.setFlagData(_data)

        self.updateButtonStyles(_data)
        self.adjustYAxis(_data)



if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())