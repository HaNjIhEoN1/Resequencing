# Resequencing
본 script는 resequencing을 통한 유전분석을 위해 작성되었다. 필자가 배워가며 채우나가는 중....
 + 참조 1. https://thericejournal.springeropen.com/articles/10.1186/s12284-019-0356-0#ref-CR12
 + 참조 2. https://2wordspm.wordpress.com/2019/03/08/ngs-%EB%B6%84%EC%84%9D-%ED%8C%8C%EC%9D%B4%ED%94%84-%EB%9D%BC%EC%9D%B8%EC%9D%98-%EC%9D%B4%ED%95%B4-gatk-best-practice/
 + 참조 3. https://titanic1997.tistory.com/3	 절대, 상대 경로에 대해
 + SRA-Toolkit manual : https://github.com/ncbi/sra-tools/wiki/HowTo:-fasterq-dump 
 + BWA manual : https://bio-bwa.sourceforge.net/bwa.shtml
 + bcftools manual : https://samtools.github.io/bcftools/bcftools.html
 + parallel manual : https://bioinformatics.stackexchange.com/questions/13914/download-multiple-fastq-files-using-fastq-dump
 
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
	1. SRA-Toolkit download	
    	1.1. download directory를 우선 만들고 download directory로 진입
		1.2. wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.0.2/sratoolkit.3.0.2-ubuntu64.tar.gz
		1.3. tar.gz 파일로 다운이 진행 이를 압축해제하기 위한 ‘zxcf’ 옵션 사용
			tar –zxvf sratoolkit.3.0.2-ubuntu64.tar.gz 로 압축해제
		1.4. 압축해제된 파일 內 ‘bin’으로 진입
		1.5. pwd 명령어를 이용해 bin path 복사
		1.6. cd .. -> export PATH=$PATH:‘복사한 주소’
		+ 지역변수로 영구 적용하기 위해서 echo 'export PATH=$PATH:'복사 주소'' >> ~/.bashrc
		source ~/.bashrc
		> 바뀐 내용을 .bashrc에 적용하고 이를 반영한다는 의미. 
		++ 위 miniconda 설치과정 중에 자동으로 redirect 까지 적용해줌		
	2. BWA~bcf tools download
		google에 conda install ‘프로그램 이름’으로 검색 후 terminal에 ctrl +c,v
		
#### 0.3. 편의를 위한 shell 도구
	1. parellel – 설치 sudo apt–get install –y parallel      
		병렬 진행을 위한 command
		+ fasterq dump로 multiple sra files download
		case 1 : parellel –j n fasterq-dump –3 {} ::: ‘sra file run id들’
			n : 다운로드 받을 sra file 개수  
		case 2 : vi 또는 nano에 다운할 sra file run id 기입(enter로 구분)
		parellel –j n fasterq-dump –3 :::: ‘기입한 문서 이름’
	2. screen – 설치 sudo apt–get install screen
		background 실행을 위한 command
		ctrl + ad 탈출 / screen –S ‘이름’ : ‘이름’ screen 생성 
		screen –R ‘이름’ : ‘이름’ screen 진입 / screen 내에서 exit : 삭제
	3.  htop/ top – 설치 sudo apt–get install htop/top
		작업관리자 역할
    
### 1. SRA file download 
	1. SRA run id 정보 얻기
		1.1. ncbi에서 [krice core] 검색 > Bioproject 선택 > SRA 선택 > 
		화면 우측 상단의 ‘send to’ 선택 > run selector + go > download(metadata) > 
		다운받은 txt 파일을 엑셀로 연 후에 불필요한 정보 제거 후 사용할 id 기록
	*SRA data는 사라지지 않는 물리 저장고에 저장 본인 실습환경 안에서는 ‘/data’
	-> 서버를 사용하지 않는 컴퓨터라면 무관
	2. sra file 받을 directory 생성 후 작업
	3. fasterq-dump ‘run id’ -p --split –3
			* ‘-p’ = 진척도 확인 옵션 / ‘--split –3’는 sra file fastq파일로 분리(paired면 2)
			* 터미널에 fasterq-dump 로 각종 옵션 확인 가능
   
### 2. BWA      
	prerequisite : 종의 ref으로 사용될 fasta, fastq files을 위한 디렉토리, sra files 한 쌍당 하나의 디렉토리
		모든 작업은 screen을 만들어 background 실행을 기본으로 한다(장기간 작업이 진행되므로)
		모르는 옵션은 program command option으로 확인하자
		*실습에 사용된 ref은 NCBI에서 제공하는 rice genome fasta data(GCF~)
	1. BWA에 사용될려면 ref fasta를 indexing 해야한다. 
	   bwa index GCF_001433935.1_IRGSP-1.0_genomic.fna
	2. bwa mem –t ‘thread’ ‘ref 파일 위치’/‘ref 파일 이름’ ‘fastq direc 위치’/‘fastq_1’ ‘fastq direc 위치’/‘fastq_2’ -o ‘해당 fastq의 sra run id direc’/‘해당 fastq의 sra run id.sam’				
	+ ‘-o’는 output 값 저장 형식 위치를 위한 옵션 / ‘mem’ bwa 알고리즘 종류 / 
	++ -t ‘10’ 사용할 thread 개수 (thread 수는 htop로 확인)
	3. cat ‘샘플이름’.sam | grep –v ‘@’ | head -5 로 파일 확인 
	+ ‘grep –v ’@’는 @을 제외한 행 열람이고 sam의 header 및 meta정보는 @ > 필요없기에 생략
	++ ‘head –5’는 앞부분 5행 출력

### 3. Samtools  
	1. samtools fixmate -O bam ‘sam 파일 위치’/SAMPLENAME.sam ‘bam 파일 위치’/SAMPLENAME.bam 
	+ ‘-O’는 output 값 저장 형식 위치를 위한 옵션 
	
### 4. Sambamba  
	1. 개별 sra run id directory에 mkdir sortBam로 sorting된 파일 넣을 directory 만들기
	2. sambamba sort –t ‘thread’ –o ‘위치/’샘플이름‘.sort.bam ’위치‘/’샘플이름’.bam --tmpdir ./tmp
	+ ‘-t 10’ thread 10개 사용 의미 / ‘-o’는 output 값 저장 형식 위치를 위한 옵션 
	+ ‘—tmpdir’은 임시 directory을 사용하여 저장하는 옵션, sort 중간과정을 위한 directory 생성
	
### 5. bcftools 
	1. Generate VCF containing genotype likelihoods for one or multiple alignment (BAM or CRAM) files.
		1-1. 개별 sra run id directory에 mkdir gvcf directory 만들기
		1-2. bcftools mpileup –g ‘depth’ -Oz -o ./gvcf/샘플이름.gvcf.gz -f REF경로 ./sortBam/샘플이름.sort.bam
		+ ‘-g’ output gVCF형태로 파일 생성 depth 설정하여 그 이상의 것만을 생성, vcf는 일치하는 부분을 생략하기에 				일치 부분 생략 없이 표현하는 gvcf을 선택
		++ ‘-Oz –o’는 Oz는 압축형식으로 o는 output 값 저장 형식 위치를 위한 옵션 
		+++ ‘-f’는 ref을 위한 것

	2. SNP/indel calling
		2-1. bcftools call –g ‘depth’ -m -Oz –o ‘위치’/샘플이름.call.gvcf.gz ‘위치’/샘플이름.gvcf.gz
		+  ‘-g’ output gVCF형태로 파일 생성 depth 설정하여 그 이상의 것만을 생성, vcf는 일치하는 
		부분을 생략하기에 일치 부분 생략 없이 표현하는 gvcf을 선택
		++ ‘-Oz –o’는 Oz는 압축형식으로 o는 output 값 저장 형식 위치를 위한 옵션 
		+++ ‘-m’ varinat calling을 위한 옵션
		2-2. zcat ‘샘플이름’.call.gvcf.gz | grep –v ‘#’ | head -5 로 파일 확인 
		+ ‘zcat’는 확장자 gz인 파일 열람
		++ ‘grep –v ’#’는 #을 제외한 행 열람이고 call.gvcf.gz의 header 및 meta정보는 # > 
		필요없기에 생략
		+++ ‘head –5’는 앞부분 5행 출력

	3. indexing
		3-1. bcftools index ‘위치/샘플이름’.call.gvcf.gz
		+ ‘parallel’ command 이용해 동시 진행

	4. merging
		4-1. bcftools norm –f ‘ref 파일 경로’ -Oz –o ‘output 파일 경로’ ‘input 파일 경로’
		+ ‘-f’ reference genome을 제공한다는 의미
		4-2. bcftools merge –g ‘ref 파일경로’ -m both -Oz –o ‘output 파일 경로’ ‘input 파일 경로’	
		+ ‘-g’는 gvcf 파일을 사용하는 옵션이고 ref이 있는 경우 작성한다.
		++ ‘-m both’ indels과 snp모두 노출하는 옵션
	
	5. filtering
		5-1. bcftools view –i 'filter criteria' -Oz –o ‘output파일경로’ ‘input 파일경로’
		+ ‘-i’는 포함 조건의미 ‘filter criteria’칸 안에 조건을 기입한다. 조건 사이는 &&로 잇는다.
		++ ‘-Oz –o’는 파일 저장 형식과 위치를 위한 옵션
		+++ ‘F_MISSING’는 정보가 null인 값을 의미, ‘N_ALT’는 number of alternation alleles 의미
		
