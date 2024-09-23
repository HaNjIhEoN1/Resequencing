# 실습에 사용된 organism은 rice(Oryza. sativa. L)이며 ref는 NCBI에서 download. 또한, download 받을 fastq는 krice core v3에서 선택

# varinats calling by using bcftools
bcftools mpileup –g 5 -Oz –o /data/data/SRR12701911/gvcf/SRR12701911.gvcf.gz –f /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna  /data/data/SRR12701911/sortBam/SRR12701911.markdup.bam

bcftools call -g 5 -m -Oz -o gvcf/SRR12701911.call.gvcf.gz gvcf/SRR12701911.gvcf.gz

bcftools index gvcf/SRR12701911.call.gvcf.gz
