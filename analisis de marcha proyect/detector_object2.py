import pyrealsense2 as rs
import numpy as np
import cv2
import mediapipe as mp
import datetime

#from pyqtgraph.Qt import QtCore, QtGui
# from IPython import get_ipython
class Pose_Detector:
    
    def __init__(self, mode=False, upBody=False, smooth=True, detectionCon=0.7, trackCon=0.7):
        self.pipeline = rs.pipeline()
        self.config = rs.config()
        # Configuración de la cámara Intel RealSense
        # self.config.enable_stream(rs.stream.depth, 1280, 720, rs.format.z16, 30)  
        # self.config.enable_stream(rs.stream.color, 960,540, rs.format.bgr8, 60) 
        self.pipeline_wrapper = rs.pipeline_wrapper(self.pipeline)
        self.pipeline_profile = self.config.resolve(self.pipeline_wrapper)
        self.device = self.pipeline_profile.get_device()
        self.device_product_line = str(self.device.get_info(rs.camera_info.product_line))
        # Parámetros ajustados para mejorar precisión en la detección y estabilidad
        self.mpPose = mp.solutions.pose
        self.mpDraw = mp.solutions.drawing_utils
        self.pose = self.mpPose.Pose(
            static_image_mode=False,  # Modo de video en tiempo real
            model_complexity=2,  # Mayor precisión en el modelo
            smooth_landmarks=True,  # Suavizado temporal para mayor estabilidad
            min_detection_confidence=detectionCon,  # Confianza mínima para detección
            min_tracking_confidence=trackCon  # Confianza mínima para rastreo
        )

        self.List_Data = []
        self.Data_to_Excel = []  
        
        self.Data_hip_izq, self.Data_hip_dere, self.Data_knee_izq, self.Data_knee_dere, self.Data_ankle_dere = [], [], [], [], []
        self.Data_shoulder_izq, self.Data_shoulder_dere, self.Data_elbow_izq, self.Data_elbow_dere, self.Data_wrist_izq = [], [], [], [], []
        self.Data_ankle_izq, self.Data_wrist_dere = [], [] 
        #variables para graficar
        self.tiempo = []
        self.aux_hip_izq,self.temp_hip_izq = [],[]
        self.aux_hip_dere,self.temp_hip_dere = [],[]
        self.aux_knee_izq,self.temp_knee_izq = [],[]
        self.aux_knee_dere,self.temp_knee_dere = [],[]
        self.aux_ankle_dere,self.temp_ankle_dere = [],[]
        self.aux_ankle_izq,self.temp_ankle_izq = [],[]
        self.aux_shoulder_izq,self.temp_shoulder_izq = [],[]
        self.aux_shoulder_dere,self.temp_shoulder_dere = [],[]
        self.aux_elbow_izq,self.temp_elbow_izq = [],[]
        self.aux_elbow_dere,self.temp_elbow_dere = [],[]
    
    def get_stream_profiles(self):
        # Obtener los perfiles de transmisión disponibles para el dispositivo
        profiles = self.pipeline_profile.get_streams()
        stream_profiles = {}
        for profile in profiles:
            stream_type = str(profile.stream_type())
            format_type = str(profile.format())
            width = profile.as_video_stream_profile().width()
            height = profile.as_video_stream_profile().height()
            fps = profile.fps()
            # Almacenar los perfiles de transmisión en un diccionario
            if stream_type not in stream_profiles:
                stream_profiles[stream_type] = []
            stream_profiles[stream_type].append({
                "format": format_type,
                "width": width,
                "height": height,
                "fps": fps
            })
        return stream_profiles


    def start_pipeline(self, resolution, fps):
        try:
            width, height = map(int, resolution.split('x'))
            self.config.enable_stream(rs.stream.depth, 1280, 720, rs.format.z16, 30)
            self.config.enable_stream(rs.stream.color, width, height, rs.format.bgr8, fps)
            self.pipeline.start(self.config)
        except RuntimeError as e:
            raise RuntimeError(f"No se pudo iniciar el flujo de la cámara con la configuración solicitada. Detalle: {str(e)}") from e


    def get_frame(self):
        frames = self.pipeline.wait_for_frames()
        depth_frame = frames.get_depth_frame()
        color_frame = frames.get_color_frame()
        if not depth_frame or not color_frame:
            return False, None, None
        depth_image = np.asanyarray(depth_frame.get_data())
        color_image = np.asanyarray(color_frame.get_data())
        return True, depth_image, color_image

    def release(self):
        try:
            self.pipeline.stop()
        except RuntimeError:
            pass

    def find_Pose(self, color_frame, draw = True):
        imgRGB = cv2.cvtColor(color_frame, cv2.COLOR_BGR2RGB)
        self.results = self.pose.process(imgRGB)
        if self.results.pose_landmarks:
            self.posicion = True
            if draw:
                self.mpDraw.draw_landmarks(color_frame, self.results.pose_landmarks, self.mpPose.POSE_CONNECTIONS)
        else:
           
            self.posicion = False

        return color_frame

    def empty_angles(self):
        temp = str(datetime.datetime.now())
        values = [0.0] * 12
        self.List_Data = [temp] + values
        return (self.List_Data, temp, *values)

    def find_Position(self, color_frame, draw = True):
        LmList = []
        if self.posicion == True:
            h, w, c = color_frame.shape
            for id, lm in enumerate(self.results.pose_landmarks.landmark):
                cx = int(lm.x * w)
                cy = int(lm.y * h)
                cz = int(lm.z * c)
                LmList.append([id, cx, cy])
                if draw:
                    cv2.circle(color_frame, (cx, cy), 1, (0, 255, 0), cv2.FILLED)
                    # print('hi')
            #print(LmList)

        return LmList

    def angle_joint(self, LmList):
        self.List_Data = []
       
        if not self.posicion or len(LmList) < 33:
            return self.empty_angles()

        if self.posicion == True:
            temp = str(datetime.datetime.now())
            angle_hip_izq = angle_with_vertical(
                LmList[23][1], LmList[23][2],  # Cadera izquierda
                LmList[25][1], LmList[25][2],  # Rodilla izquierda
                lado="izquierdo"
            )
            angle_hip_dere = angle_with_vertical(
                LmList[24][1], LmList[24][2],  # Cadera derecha
                LmList[26][1], LmList[26][2],  # Rodilla derecha
                lado="derecho"
            )
            angle_knee_izq = knee_flexion_angle(LmList[27][1], LmList[27][2], LmList[25][1], LmList[25][2], LmList[23][1], LmList[23][2]) 
            angle_knee_dere = knee_flexion_angle(LmList[28][1], LmList[28][2], LmList[26][1], LmList[26][2], LmList[24][1], LmList[24][2])
            # angle_ankle_izq = signed_angle_three_points(LmList[29][1], LmList[29][2], LmList[27][1], LmList[27][2], LmList[25][1], LmList[25][2])# en x2, y2 usa coordenadas del talon 
            # angle_ankle_dere = signed_angle_three_points(LmList[30][1], LmList[30][2],LmList[28][1], LmList[28][2], LmList[26][1], LmList[26][2]) # en x2, y2 usa coordenadas del talon
            angle_ankle_dere = ankle_angle(
                LmList[32][1], LmList[32][2],  # Punta pie derecho
                LmList[30][1], LmList[30][2],  # Talón derecho
                LmList[28][1], LmList[28][2],  # Tobillo derecho
                LmList[26][1], LmList[26][2]   # Rodilla derecha
            )
            angle_ankle_izq = ankle_angle(
                LmList[31][1], LmList[31][2],  # Punta pie izquierdo
                LmList[29][1], LmList[29][2],  # Talón izquierdo
                LmList[27][1], LmList[27][2],  # Tobillo izquierdo
                LmList[25][1], LmList[25][2]   # Rodilla izquierda
            )

            #Calculo de los ángulos articulares de las extremidades superiores izquierda y derecha
            angle_shoulder_izq = angle_between_vectors(LmList[23][1], LmList[23][2], LmList[11][1], LmList[11][2], LmList[13][1], LmList[13][2])
            angle_shoulder_dere = angle_between_vectors(LmList[24][1], LmList[24][2], LmList[12][1], LmList[12][2], LmList[14][1], LmList[14][2]) 
            angle_elbow_izq = angle_between_vectors(LmList[15][1], LmList[15][2], LmList[13][1], LmList[13][2], LmList[11][1], LmList[11][2])
            angle_elbow_dere = angle_between_vectors(LmList[16][1], LmList[16][2], LmList[14][1], LmList[14][2], LmList[12][1], LmList[12][2])
            angle_wrist_izq = angle_between_vectors(LmList[19][1], LmList[19][2], LmList[15][1], LmList[15][2], LmList[13][1], LmList[13][2])  # Cambiar coordenadas            
            angle_wrist_dere = angle_between_vectors(LmList[20][1], LmList[20][2], LmList[16][1], LmList[16][2], LmList[14][1], LmList[14][2]) # Cambiar coordenadas 
                            
        
            self.List_Data = [temp,angle_hip_izq, angle_hip_dere, angle_knee_izq, 
                            angle_knee_dere, angle_ankle_izq, angle_ankle_dere, 
                            angle_shoulder_izq, angle_shoulder_dere, angle_elbow_izq, 
                            angle_elbow_dere, angle_wrist_izq, angle_wrist_dere]
            
            return  (self.List_Data, temp,angle_hip_izq, angle_hip_dere, angle_knee_izq, 
                     angle_knee_dere, angle_ankle_izq, angle_ankle_dere, angle_shoulder_izq, 
                     angle_shoulder_dere, angle_elbow_izq, angle_elbow_dere, angle_wrist_izq, 
                     angle_wrist_dere)

        
       
    def angles_to_Lists(self,temp,angle_hip_izq, angle_hip_dere, angle_knee_izq, angle_knee_dere, angle_ankle_izq, 
                        angle_ankle_dere, angle_shoulder_izq, angle_shoulder_dere, angle_elbow_izq,
                        angle_elbow_dere, angle_wrist_izq, angle_wrist_dere):


        self.tiempo.append(temp)                    
        self.Data_hip_izq.append(angle_hip_izq)
        self.Data_hip_dere.append(angle_hip_dere)
        self.Data_knee_izq.append(angle_knee_izq)
        self.Data_knee_dere.append(angle_knee_dere)
        self.Data_ankle_izq.append(angle_ankle_izq)
        self.Data_ankle_dere.append(angle_ankle_dere) 
        self.Data_shoulder_izq.append(angle_shoulder_izq)
        self.Data_shoulder_dere.append(angle_shoulder_dere)
        self.Data_elbow_izq.append(angle_elbow_izq)
        self.Data_elbow_dere.append(angle_elbow_dere)
        self.Data_wrist_izq.append(angle_wrist_izq)
        self.Data_wrist_dere.append(angle_wrist_dere)

    
def angle_between_vectors(x2, y2, x1, y1, x0, y0):
    v1 = np.array([x0 - x1, y0 - y1])
    v2 = np.array([x2 - x1, y2 - y1])

    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)

    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0

    cross = v1[0] * v2[1] - v1[1] * v2[0] # Producto cruzado en 2D, determina el sentido de giro entre dos vectores
    dot = np.dot(v1, v2)

    angle = np.rad2deg(np.arctan2(cross, dot))
    angle = -angle

    return angle

def knee_flexion_angle(x2, y2, x1, y1, x0, y0):
    v1 = np.array([x0 - x1, y0 - y1])
    v2 = np.array([x2 - x1, y2 - y1])

    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)

    if norm_v1 == 0 or norm_v2 == 0:
        return 0.0

    v1 = v1 / norm_v1
    v2 = v2 / norm_v2

    cross = v1[0] * v2[1] - v1[1] * v2[0]
    dot = np.dot(v1, v2)

    angle = np.rad2deg(np.arctan2(cross, dot))

    flexion = 180 - abs(angle)

    return flexion

def ankle_angle(x_toe, y_toe, x_heel, y_heel,
                         x_ankle, y_ankle,
                         x_knee, y_knee):

    v_tibia = np.array([
        x_knee - x_ankle,
        y_knee - y_ankle
    ])

    v_foot = np.array([
        x_toe - x_heel,
        y_toe - y_heel
    ])

    norm_tibia = np.linalg.norm(v_tibia)
    norm_foot = np.linalg.norm(v_foot)

    if norm_tibia == 0 or norm_foot == 0:
        return 0.0

    v_tibia = v_tibia / norm_tibia
    v_foot = v_foot / norm_foot

    cross = (
        v_tibia[0] * v_foot[1]
        - v_tibia[1] * v_foot[0]
    )

    dot = np.dot(v_tibia, v_foot)

    angle = np.rad2deg(np.arctan2(cross, dot))

    # Conversión clínica
    ankle = 90 - angle

    return ankle

def angle_with_vertical(x_hip, y_hip, x_knee, y_knee, lado="izquierdo"):
    """
    Calcula el ángulo firmado de la cadera respecto a la vertical.
    Similar al criterio usado en Kinovea:
    línea vertical desde la cadera vs línea cadera-rodilla.
    """

    dx = x_knee - x_hip
    dy = y_knee - y_hip

    if dx == 0 and dy == 0:
        return 0.0

    angle = np.rad2deg(np.arctan2(dx, dy))
    angle = -angle

    return angle