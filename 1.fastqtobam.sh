# 실습에 사용된 organism은 rice(Oryza. sativa. L)이며 ref는 NCBI에서 download. 또한, download 받을 fastq는 krice core v3에서 선택

# SRA file download
fasterq-dump 'SRR12701911' -p --split -3 # 단일 run id download 시
parallel -j n fasterq-dump -3 {} ::: SRR12701911, SRR12701922, SRR12701933, SRR12701944 # simple multiple download
vi srridlist
parallel -j n fasterq-dump -3 {} :::: srridlist # list에 download 받을 id 기입 후 일괄 download

# fasterq to sam by using bwa
bwa index GCF_001433935.1_IRGSP-1.0_genomic.fna
bwa mem  -t 10 /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna /data/data/fastq/SRR12701911_1.fastq /data/data/fastq/SRR12701911_2.fastq –o ./data/data/SRR12701911/SRR12701911.sam 

# fixmating process by using samtools
samtools fixmate -O bam /data/data/SRR12701911/SRR12701911.sam /data/data/SRR12701911/SRR12701911.bam

# sorting bam by using sambamba
sambamba sort –t 10 –o ‘/data/data/SRR12701911/sortBam/SRR12701911.sort.bam /data/data/SRR12701911/SRR12701911.bam —tmpdir ./tmp
