import socket
import json
import uuid
import time


# 내 컴퓨터의 고유 지문(MAC 주소)을 진짜처럼 뽑아내는 함수
def get_mac_address():
    mac_num = hex(uuid.getnode()).replace('0x', '').upper()
    mac = ':'.join(mac_num[i: i + 2] for i in range(0, 12, 2))
    return mac


def start_heartbeat():
    server_ip = '127.0.0.1'  # 내 컴퓨터(로컬 백엔드) 주소
    server_port = 5001  # 우리가 뚫어놓은 소켓 포트
    my_mac = get_mac_address()

    print(f"가짜 Jetson 부팅 완료. (내 MAC 주소: {my_mac})")
    print("백엔드로 10초마다 생존 신고를 시작합니다...")

    while True:
        try:
            # 1. 백엔드 서버에 소켓 연결 시도!
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect((server_ip, server_port))

            # 2. 내 정보(MAC 주소)를 JSON으로 묶어서 발사!
            data = json.dumps({"mac": my_mac, "status": "alive"})
            client.send(data.encode('utf-8'))

            # 3. 백엔드가 잘 받았다고 하는 대답 듣기
            response = client.recv(1024).decode('utf-8')
            print(f"[백엔드 응답] {response}")

            client.close()
        except Exception as e:
            # 백엔드 서버(run.py)를 안 켰을 때 나는 에러입니다.
            print(f" 백엔드 연결 실패 (서버가 켜져 있나요?): {e}")

        # 너무 무리하지 않게 10초 쉬고 다시 보냄
        time.sleep(10)


if __name__ == '__main__':
    start_heartbeat()