#' Normalize Infinium HumanMethylation450 BeadChips
#'
#' Normalize a set of samples using their normalization objects.
#'
#' @param objects A list or sublist returned by \code{\link{meffil.normalize.objects}()}.
#' @param beta If \code{TRUE} (default), then the function returns
#' the normalized matrix of methylation levels; otherwise, it returns
#' the normalized matrices of methylated and unmethylated signals.
#' @param pseudo Value to add to the denominator to make the methylation
#' estimate more stable when calculating methylation levels (Default: 100).
#' @param probes Probe annotation used to construct the control matrix
#' (Default: \code{\link{meffil.probe.info}()}).
#' @param verbose If \code{TRUE}, then detailed status messages are printed during execution (Default: \code{FALSE}).
#' @param ... Arguments passed to \code{\link[parallel]{mclapply}()}
#' except for \code{ret.bytes}.
#' @return Matrix of normalized methylation levels if \code{beta} is \code{TRUE};
#' otherwise matrices of normalized methylated and unmethylated signals.
#' Matrices returned have one column per sample and one row per CpG site.
#' Methylation levels are values between 0 and 1
#' equal to methylated signal/(methylated + unmethylated signal + pseudo).
#'
#' @export
meffil.normalize.samples <- function(objects, beta=T, pseudo=100,
                                     probes=meffil.probe.info(), verbose=F, ...) {
    stopifnot(length(objects) >= 2)

    probe.names <- unique(probes$name)
    n.sites <- length(probe.names)
    if (beta) {
        example <- rep(NA_real_, n.sites)
        names(example) <- probe.names
        ret.bytes <- as.integer(object.size(example))
        
        ret <- do.call(cbind, meffil.mclapply(objects, function(object) {
            msg("Normalizing", object$basename, verbose=verbose)
            ret <- meffil.normalize.sample(object, probes=probes, verbose=verbose)
            ret <- meffil.get.beta(ret, pseudo)
        }, ret.bytes=ret.bytes, ...))
        colnames(ret) <- sapply(objects, function(object) object$basename)
        ret
    }
    else {
        example <- list(rep(NA_real_, n.sites), rep(NA_real_, n.sites))
        names(example[[1]]) <- names(example[[2]]) <- probe.names
        ret.bytes <- as.integer(object.size(example))
        
        ret <- meffil.mclapply(objects, function(object) {
            msg("Normalizing", object$basename, verbose=verbose)
            meffil.normalize.sample(object, probes=probes, verbose=verbose)
        }, ret.bytes=ret.bytes, ...)
        names(ret) <- sapply(objects, function(object) object$basename)
        list(M=sapply(ret, function(x) x$M),
             U=sapply(ret, function(x) x$U))
    }
}