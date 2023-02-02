# 실습에 사용된 organism은 rice(Oryza. sativa. L)이며 ref는 NCBI에서 download. 또한, download 받을 fastq는 krice core v3에서 선택

# merging by using bcftools
bcftools norm -f /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna -Oz -o /data/data/output/*.norm.gvcf.gz /data/data/output/*.call.gvcf.gz 

bcftools merge -g /data/data/assembly/GCF_001433935.1_IRGSP-1.0_genomic.fna -m both -Oz -o /data/data/norm/test_merged.vcf.gz /data/data/norm/*.norm.gvcf.gz

# filtering by using bcftools
bcftools view -i 'F_MISSING < 0.1 && MAF > 0.1 && N_ALT>0 && %QUAL>= 30 && MQ >= 20' -Oz -o /data/data/output/test_merged.i.vcf.gz /data/data/output/test_merged.vcf.gz
