import os
from pathlib import Path

def merge_sysml_files(target_dir="."):
    # 절대 경로로 변환하여 정확한 폴더명을 추출
    folder = Path(target_dir).resolve()
    
    # 폴더명을 파일명으로 사용 (예: 폴더명이 'MSG_Model'이면 'MSG_Model.txt')
    output_filename = f"{folder.name}.txt"
    output_path = folder / output_filename
    
    # .sysml 파일만 검색
    sysml_files = list(folder.glob("*.sysml"))
    
    if not sysml_files:
        print(f"'{folder.name}' 폴더에 .sysml 파일이 없습니다.")
        return

    # 텍스트 파일로 병합
    with open(output_path, 'w', encoding='utf-8') as outfile:
        for sysml_file in sysml_files:
            with open(sysml_file, 'r', encoding='utf-8') as infile:
                outfile.write(infile.read())
                outfile.write("\n\n") # 패키지 간의 최소한의 줄바꿈만 추가

    print(f"총 {len(sysml_files)}개의 파일이 '{output_filename}'로 병합되었습니다.")

if __name__ == "__main__":
    # 코드가 있는 현재 폴더를 기준으로 실행
    merge_sysml_files()