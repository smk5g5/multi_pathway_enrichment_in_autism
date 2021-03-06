library(KEGGREST)
load("C:/Users/saadkhan/kegg2entrez.RData")
#######convert gene to pathway matrix############
autism_gene_list <- read.table("case_control.pairs.large.txt",header = T,sep = "\t")
uni_gene <- unique(keggpathway2gene$gene_id) #uni gene should be all the genes in pathways (universal genes)
geneid <- union(autism_gene_list$Entrez1,autism_gene_list$Entrez2) #gene id should be all unique genes in autism results 
#subset_keggdf <- subset(keggpathway2gene, gene_id %in% uni_gene)
kegg_pathway_matrix <- as.matrix(xtabs(~pathway_id+gene_id,data=keggpathway2gene))
SigPairEnrich=function(autism_gene_list,geneid,uni_gene,kegg_pathway_matrix,FDR=0.05,fdrmethod=c('bonferroni')){
#---------------------------------------------------------
###--Sort gene in pathway
###
s=as.matrix(order(uni_gene)); #ordered indices of gene ids
UniG=as.matrix(uni_gene[s]); # sorted matrix of uni_gene 
Path=as.matrix(kegg_pathway_matrix[,s]);

#----------------------------------
# Profile Gene in pathway
IntG=as.matrix(sort(intersect(geneid,UniG)));#The genes involved in the pathway which contained in geneid
#---------------------------------------
# pathway gene in Profile
a=UniG %in% IntG; #IntG is all unique genes from autism results that have KEGG pathway assigned
Path=Path[,a];#IntG genes in profile
L=length(IntG);#background genes
m=autism_gene_list[,1] %in% IntG;
## Number of gene that intersect with intg that are there in entrez 1
n=autism_gene_list[,2] %in% IntG;
## Number of gene that intersect with intg that are there in entrez 2
k=(m+n)==2;
##Gene pairs that are present in the list of pathways at the same time 
L_sigP=sum(k);#Gene pairs involved in pathway,(num of interest pairs)
if(L_sigP==0){
    stop("There is no interest pairs involved in pathway");
}
BP=choose(L,2);#background pairs
#BP is the number of all possible combinations for pairwise background genes
#BP=nC2
##-----------------------------------------------------------
#--SigP enrich

LP=length(Path[,1]);#path num #total number of pathways
HyperP=matrix(,nrow=LP,ncol=6);#"pathway_index","p_value","adjusted p-value","k","n","m".
#create a hypergeometric distribution matrix with length LP(total number of pathways)
HyperP[,3]=L_sigP; #(Column 3 is gene pairs involved in one of the LP pathways)
HyperP[,4]=BP; #(#Column 4 all possible combination of background genes)

for (i in 1:LP){
  Temp1=Path[i,]; #
  TempG=IntG[which(Temp1==1),];
  HyperP[i,1]=i;
  if (length(TempG)<2){
    
    HyperP[i,2]=1;
    HyperP[i,5]=0;
    HyperP[i,6]=0;
    next;
  }else{
    BPinPath=choose(length(TempG),2); #this is x which is all possible combinations of pathways that may contain these genes
    HyperP[i,6]=BPinPath; #
    a=autism_gene_list[,1] %in% TempG;
    b=autism_gene_list[,2] %in% TempG;
    c=(a+b)==2;
    if (sum(c)==0){
      HyperP[i,2]=1;
      HyperP[i,5]=0;
      next;
    }else{
      L_sigPPath=sum(c);
      HyperP[i,5]=L_sigPPath;
    }
  }
  p1=matrix(1-phyper(L_sigPPath-1,BPinPath,BP-BPinPath,L_sigP));
  HyperP[i,2]=p1;
}
pathway_info <- keggList("pathway","hsa") #Getting Kegg pathway names using KEGGREST
selpathnames <- as.character(paste("path",rownames(Path),sep=":"))
pathway_info <- pathway_info[selpathnames]
q1=as.matrix(p.adjust(HyperP[,2],method="BH",length(HyperP[,2])),ncol=1);
SigPath=cbind(HyperP[,1:2],q1,HyperP[,3:6]);
q1fdr=(q1<=FDR);
SigPath_info=pathway_info[q1fdr];
SigPath_info <- unname(SigPath_info)
SigPath=SigPath[q1fdr,];
if(length(SigPath[,1])==0){
    print("Can't find the pathway for statistically significant enrichment under the threshold value FDR!\n");
}
else{
res=as.data.frame(cbind(SigPath_info,SigPath));
colnames(res)=c("pathway_name","pathway_index","p_value","adjusted p-value","k","n","x","m")
return(res);
}
} 
