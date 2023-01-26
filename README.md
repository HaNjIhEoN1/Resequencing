# Resequencing
본 script는 resequencing을 통한 유전분석을 위해 작성되었다. 필자가 배워가며 채우나가는 중....
 + 참조 1. https://thericejournal.springeropen.com/articles/10.1186/s12284-019-0356-0#ref-CR12
 + 참조 2. https://2wordspm.wordpress.com/2019/03/08/ngs-%EB%B6%84%EC%84%9D-%ED%8C%8C%EC%9D%B4%ED%94%84-%EB%9D%BC%EC%9D%B8%EC%9D%98-%EC%9D%B4%ED%95%B4-gatk-best-practice/

## Index

0. 리눅스 환경조성 (프로그램 간 dependency 맞추기 위해)
1. NCBI에서의 SRA 파일을 통해 FASTQ 파일 다운로드 > SRA-Toolkit
2. FASTQ를 Ref에 맞추어 assembly(or alignment) 하는 과정 > BWA
3. Fixmate 과정으로 alignment의 오류 수정 및 pairing > SAM TOOLS
4. Sorting 1~3 과정을 지난 data 정렬 > SAMBAMBA
5. genotype 결정 > bcftools
6. Variant calling > bcftools             #1~6은 품종당 하나
7. merge > bcftools
8. filtering (quality check) > bcftools    #7~8은 취합 과정
9. python을 통해 결과 해석 > python

### 0. 리눅스 분석환경 조성 
#### 0.1. miniconda 설치
	이유 : 필수적인 기능들은 갖추고 있으며 상대적으로 가벼워서
	1. miniconda download 링크 복사 -> wget miniconda download link
	2. bash miniconda + tab
	3. source ~/.bashrc – path 설정(root 계정이 아닌 다른 계정에서도 사용을 위해)

	환경 조성 – conda 이용
	1. conda create –n 이름 -> 이름을 가진 환경 생성
	2. conda activate 이름 -> 이름 환경으로 진입

#### 0.2. 분석에 필요한 프로그램 다운로드
	1. SRA-Toolkit download        https://github.com/ncbi/sra-tools/wiki/HowTo:-fasterq-dump  참조
    1.1. download directory를 우선 만들고 download directory로 진입
		1.2. wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.0.2/sratoolkit.3.0.2-ubuntu64.tar.gz
		1.3. tar.gz 파일로 다운이 진행 이를 압축해제하기 위한 ‘zxcf’ 옵션 사용
			tar –zxvf sratoolkit.3.0.2-ubuntu64.tar.gz 로 압축해제
		1.4. 압축해제된 파일 內 ‘bin’으로 진입
		1.5. pwd 명령어를 이용해 bin path 복사
		1.6. cd .. -> export PATH=$PATH:‘복사한 주소’
	2. BWA~bcf tools download
		google에 conda install ‘프로그램 이름’으로 검색 후 terminal에 ctrl +c,v
    
### 1. SRA file download 
	1. SRA run id 정보 얻기
		1.1. ncbi에서 [krice core] 검색 > Bioproject 선택 > SRA 선택 > 
		화면 우측 상단의 ‘send to’ 선택 > run selector + go > download(metadata) > 
		다운받은 txt 파일을 엑셀로 연 후에 불필요한 정보 제거 후 사용할 id 기록
	*SRA data는 사라지지 않는 물리 저장고에 저장 본인 실습환경 안에서는 ‘/data’
	-> 서버를 사용하지 않는 컴퓨터라면 무관
	2. sra file 받을 directory 생성 후 작업
	3. faster-dump ‘run id’ -p --split –3
			* ‘-p’ = 진척도 확인 옵션 / ‘--split –3’는 sra file fastq파일로 분리(paired면 2)
			* 터미널에 fasterq-dump 로 각종 옵션 확인 가능
		# parellel – 설치 sudo apt–get install –y parallel      
				병렬 진행을 위한 command  download multiple sra files 참조
		# screen – 설치 sudo apt–get install screen
				background 실행을 위한 command
				ctrl + ad 탈출 / screen –S ‘이름’ : ‘이름’ screen 생성 
				screen –R ‘이름’ : ‘이름’ screen 진입 / screen 내에서 exit : 삭제
		# htop/ top – 설치 sudo apt–get install htop/top
				작업관리자
		3.1. faster dump로 multiple sra files download
		case 1 : parellel –j n fasterq-dump –3 {} ::: ‘sra file run id들’
				n : 다운로드 받을 sra file 개수  
		case 2 : vi 또는 nano에 다운할 sra file run id 기입(enter로 구분)
			parellel –j n fasterq-dump –3 :::: ‘기입한 문서 이름’
   
### 2. BWA      
