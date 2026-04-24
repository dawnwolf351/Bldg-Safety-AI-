import cv2

def get_pipeline(sensor_id=0):
    # 'appsink' 부분에 drop=True와 max-buffers를 추가하여 병목을 방지합니다.
    return (
        f"nvarguscamerasrc sensor-id={sensor_id} ! "
        "video/x-raw(memory:NVMM), width=1280, height=720, format=NV12, framerate=30/1 ! "
        "nvvidconv ! video/x-raw, format=BGRx ! "
        "videoconvert ! video/x-raw, format=BGR ! "
        "appsink drop=True max-buffers=1 wait-on-eos=false"
    )

# CAP_GSTREAMER 플래그를 명시적으로 사용
cap = cv2.VideoCapture(get_pipeline(0), cv2.CAP_GSTREAMER)

if not cap.isOpened():
    print("❌ 여전히 열리지 않습니다. 환경 변수를 점검합니다.")
    # 현재 시스템에서 OpenCV가 GStreamer를 지원하는지 다시 한 번 내부 체크
    import os
    print(f"현재 작업 디렉토리: {os.getcwd()}")
else:
    print("✅ 성공! 영상을 출력합니다.")
    while True:
        ret, frame = cap.read()
        if not ret: break
        cv2.imshow("Stream Test", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'): break
    cap.release()
    cv2.destroyAllWindows()
