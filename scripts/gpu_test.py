import torch
import time

def run_gpu_test():
    print("--- Jetson Orin Nano GPU 연산 테스트 ---")
    
    # 1. GPU 장치 정보 확인
    if torch.cuda.is_available():
        device_name = torch.cuda.get_device_name(0)
        print(f"[성공] 사용 가능한 GPU: {device_name}")
        print(f"[정보] CUDA 버전: {torch.version.cuda}")
    else:
        print("[실패] GPU를 찾을 수 없습니다. 설정을 다시 확인하세요.")
        return

    # 2. 텐서 생성 및 GPU 전송 테스트
    try:
        print("\n[진행] 1000x1000 행렬 생성 및 GPU 전송 중...")
        start_time = time.time()
        
        # GPU 메모리에 직접 생성
        x = torch.ones(1000, 1000, device='cuda')
        y = torch.ones(1000, 1000, device='cuda')
        
        # 행렬 곱셈 연산
        z = torch.matmul(x, y)
        
        # 연산 결과 확인 (동기화)
        torch.cuda.synchronize()
        end_time = time.time()
        
        print(f"[성공] GPU 연산 완료! (소요 시간: {end_time - start_time:.4f}초)")
        print(f"[결과] 결과 행렬의 합: {z.sum().item()}")
        
        print("\n모든 GPU 테스트가 성공적으로 마무리되었습니다.")
        
    except Exception as e:
        print(f"\n[에러] 연산 중 오류 발생: {e}")

if __name__ == "__main__":
    run_gpu_test()

