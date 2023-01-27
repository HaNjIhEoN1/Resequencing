parallel -j 1 parellel –j n fasterq-dump –3 :::: ‘srrlist2.txt’ &&

bwa mem –t 5 /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna /data/data/fastq/{.}_1.fastq /data/data/fastq/{.}_2.fastq -o ./data/data/test/sam/{.}.sam :::: srrlist2.txt &&

samtools fixmate -O bam sam/{}.sam bam/{}.bam :::: srrlist2.txt &&

sambamba sort -t 5 -o sortbam/{}.sort.bam bam/{}.bam --tmpdir ./tmp :::: srrlist2.txt &&

bcftools mpileup -g 5 -Oz -o gvcf/{}.gvcf.gz -f assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna sortbam/{}.sort.bam:::: srrlist2.txt &&

bcftools call -g 5 -m -Oz -o gvcf/{}.call.gvcf.gz gvcf/{}.gvcf.gz :::: srrlist2.txt &&

bcftools index ./output/{}.call.gvcf.gz :::: srrlist2.txt
