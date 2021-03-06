# Micro haplo plot to genepop conversion
#' @title Convert to genepop from micro haplo plot file format.
#' @description Function makes a genepop file.
#' @param microhp This is a file path to the micro-haplo-plot file. See update for link to this file format.
#' @param path the filepath and filename of output.
#' @importFrom data.table melt
#' @importFrom stringr str_pad
#' @export

micro_genepop <- function(microhp, path){

  #if(getRversion() >= "2.15.1")  utils::globalVariables(c("."))

  ## Read in the microhapplot data
  hap_dat <- read.csv(microhp, header = TRUE, stringsAsFactors = FALSE)

  ## Remove unneeded columns
  hap_dat <- hap_dat[, c(2, 3, 4, 5, 6)]

  ## find unique loci
  to_find_alleles <- data.table::melt(data = hap_dat, id.vars = "locus", measure.vars = c("haplotype.1", "haplotype.2"))
  to_get_loci <- unique(to_find_alleles[c("locus")])

  ### loop to look for the unique alleles of each loci, rename them as numbers

  for(i in 1:nrow(to_get_loci)){
    hold.levels <- data.frame(value = unique(to_find_alleles[to_find_alleles$locus == to_get_loci[i,], ]$value), allele =     as.numeric(as.factor(unique(to_find_alleles[to_find_alleles$locus == to_get_loci[i,], ]$value))))

    hold.levels$value = as.character(hold.levels$value)

    # j = 1
    for(j in 1:nrow(hold.levels)){

      if(length(hap_dat[hap_dat$locus == to_get_loci$locus[i] & hap_dat$haplotype.1 == hold.levels$value[j], ]$haplotype.1) > 0){
        hap_dat[hap_dat$locus == to_get_loci$locus[i] & hap_dat$haplotype.1 == hold.levels$value[j], ]$haplotype.1 = hold.levels$allele[j]
      }
      if(length(hap_dat[hap_dat$locus == to_get_loci$locus[i] & hap_dat$haplotype.2 == hold.levels$value[j], ]$haplotype.2) > 0){
        hap_dat[hap_dat$locus == to_get_loci$locus[i] & hap_dat$haplotype.2 == hold.levels$value[j], ]$haplotype.2 = hold.levels$allele[j]
      }
    }
  }


  ## make each alelle call three digits by adding zeroes
  hap_dat$haplotype.1 <- stringr::str_pad(string = hap_dat$haplotype.1, width = 3, pad = "0", side = "left")
  hap_dat$haplotype.2 <- stringr::str_pad(string = hap_dat$haplotype.2, width = 3, pad = "0", side = "left")

  ## aggregate the two column loci call into a single column
  hap_dat$GENOTYPE <- paste0(hap_dat$haplotype.1, hap_dat$haplotype.2)

  ## remove unneeded columns, make into a flat dataframe for genepopunflatten
  hap_dat_form <- hap_dat[, c(1, 2, 6)]

  ## go from long to wide format
  hap_dat_FLAT=stats::reshape(hap_dat_form, idvar = "indiv.ID", timevar = "locus", direction = "wide")
  names(hap_dat_FLAT) <- gsub(pattern = "GENOTYPE.",replacement = "",x = names(hap_dat_FLAT))
  #hap_dat_FLAT <- tidyr::spread(data = hap_dat_form, key = locus, value = GENOTYPE)

  #Replace NA values with 000000
  hap_dat_FLAT[is.na(hap_dat_FLAT)]=000000

  ### genepopunlfatten out
  genepopedit::genepop_unflatten(df = hap_dat_FLAT, path = path)

}

