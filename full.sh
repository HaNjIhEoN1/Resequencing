parallel -j 1 fasterq-dump –3 :::: ‘srrlist2.txt’ &&

bwa mem –t 5 /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna /data/data/fastq/{.}_1.fastq /data/data/fastq/{.}_2.fastq -o ./data/data/test/sam/{.}.sam :::: srrlist2.txt &&

samtools fixmate -O bam sam/{}.sam bam/{}.bam :::: srrlist2.txt &&

sambamba sort -t 5 -o sortbam/{}.sort.bam bam/{}.bam --tmpdir ./tmp :::: srrlist2.txt &&

samtools markdup sortbam/{}.sort.bam markdup/{}.markdup.bam &&

bcftools mpileup -g 5 -Oz -o gvcf/{}.gvcf.gz -f assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna markdup/{}.markdup.bam:::: srrlist2.txt &&

bcftools call -g 5 -m -Oz -o gvcf/{}.call.gvcf.gz gvcf/{}.gvcf.gz :::: srrlist2.txt &&

bcftools norm -f /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna -Oz -o /data/data/output/{}.norm.gvcf.gz /data/data/output/{}.call.gvcf.gz :::: srrlist2.txt

bcftools index ./output/{}.norm.gvcf.gz :::: srrlist2.txt

echo "finish"

bcftools merge -g /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna -m both -Oz -o /data/data/norm/test_merged.vcf.gz /data/data/norm/*.norm.gvcf.gz

bcftools view -i 'F_MISSING < 0.25 && MAF > 0.05 && N_ALT>0 && %QUAL>= 30 && MQ >= 20' -Oz -o /data/data/output/test_merged.i.vcf.gz /data/data/output/test_merged.vcf.gz
