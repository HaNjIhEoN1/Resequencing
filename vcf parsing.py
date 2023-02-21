import pandas as pd

df = pd.read_csv('test_merged4.i.vcf.gz', sep='\t', comment='#', header=None)
c = ! zcat test_merged4.i.vcf.gz | grep "#CHROM"
df.columns = [i.split('/')[-1].split('.')[0] for i in c[0].split('\t')]

dic = {'NC_029256.1' : 'chr01','NC_029257.1' : 'chr02','NC_029258.1' : 'chr03','NC_029259.1': 'chr04','NC_029260.1' : 'chr05','NC_029261.1' : 'chr06','NC_029262.1' : 'chr07','NC_029263.1' : 'chr08','NC_029264.1' : 'chr09','NC_029265.1' : 'chr10','NC_029266.1' : 'chr11','NC_029267.1' : 'chr12'}

c = []
for i in df['#CHROM']:
    try:
        c.append(dic[i])
    except:
        c.append(i)

df['#CHROM'] = 'chr01'

with open('test.vcf', 'w')as f:
    f.write('\t'.join(df.columns) + '\n')
    for i in df.values:
        f.write('\t'.join(list(map(str, i))) + "\n")
