import cv2
import time
from ultralytics import YOLO

# 1. 모델 로드
model = YOLO("../models/yolo26s-seg.engine")

# 2. GStreamer 파이프라인 (안정적인 720p 듀얼 모드 권장)
def get_pipeline(sensor_id):
    return (
        f"nvarguscamerasrc sensor-id={sensor_id} ! "
        "video/x-raw(memory:NVMM), width=1280, height=720, format=NV12, framerate=30/1 ! "
        "nvvidconv ! video/x-raw, format=BGRx ! "
        "videoconvert ! video/x-raw, format=BGR ! appsink drop=True"
    )

cap0 = cv2.VideoCapture(get_pipeline(0), cv2.CAP_GSTREAMER)
cap1 = cv2.VideoCapture(get_pipeline(1), cv2.CAP_GSTREAMER)

# FPS 계산을 위한 변수
prev_time = 0

print("🚀 성능 모니터링 모드 시작...")

while True:
    ret0, frame0 = cap0.read()
    ret1, frame1 = cap1.read()
    
    if not ret0 or not ret1:
        break

    # 가로로 두 영상 결합
    combined_frame = cv2.hconcat([frame0, frame1])
    
    # 3. YOLO26 추론 (GPU 강제 사용)
    results = model.predict(combined_frame, device=0, conf=0.3, verbose=False)
    annotated_frame = results[0].plot()

    # 4. FPS 계산
    curr_time = time.time()
    fps = 1 / (curr_time - prev_time)
    prev_time = curr_time

    # 5. 화면 라벨링 (FPS 및 프로세서 정보)
    # 현재 사용 중인 프로세서 확인 (torch가 GPU 사용 중인지 체크)
    import torch
    processor = "GPU: Jetson Orin Nano" if torch.cuda.is_available() else "CPU"
    
    label = f"FPS: {fps:.1f} | Device: {processor}"
    
    # 가독성을 위해 텍스트 배경(검은색)과 글자(네온 그린) 추가
    cv2.rectangle(annotated_frame, (10, 10), (450, 50), (0, 0, 0), -1)
    cv2.putText(annotated_frame, label, (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)

    # 결과 출력 (모니터 크기에 맞게 축소)
    display_frame = cv2.resize(annotated_frame, (1280, 480))
    cv2.imshow("SOC Safety Monitoring System", display_frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap0.release()
cap1.release()
cv2.destroyAllWindows()
