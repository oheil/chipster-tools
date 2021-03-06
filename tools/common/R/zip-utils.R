# Utilities for dealing with compressed files
# MK: This is a copy from a file which can be found in the R-2.12 folder

unzipIfGZipFile <- function(file.name) {
	
	# if gzip, unzip it
	if (isGZipFile(file.name)) {
		zipfile.name <- paste(file.name, ".gz", sep="")
		system(paste("mv", file.name, zipfile.name, "; gzip -df", zipfile.name))
	}
}


isGZipFile <- function(file.name) {
	
	# get file type with the unix file command
	file.type = system(paste("file -Lb --mime", file.name), intern=TRUE)
	
	if (!is.na(pmatch("application/x-gzip", file.type))) {
		return(TRUE);
	} else { 
		return(FALSE);
	}
}
