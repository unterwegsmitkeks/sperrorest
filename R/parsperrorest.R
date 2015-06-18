#' Perform parallelized spatial error estimation and variable importance assessment
#'
#' \code{parsperrorest} is a flexible interface for multiple types of spatial and non-spatial cross-validation 
#' and bootstrap error estimation and permutation-based assessment of spatial variable importance.
#' @inheritParams partition.cv
#' @param data a \code{data.frame} with predictor and response variables. Training and test samples 
#' will be drawn from this data set by \code{train.fun} and \code{test.fun}, respectively.
#' @param formula A formula specifying the variables used by the \code{model}. Only simple formulas 
#' without interactions or nonlinear terms should be used, e.g. \code{y~x1+x2+x3} but not 
#' \code{y~x1*x2+log(x3)}. Formulas involving interaction and nonlinear terms may possibly work 
#' for error estimation but not for variable importance assessment, but should be used with caution.
#' @param coords vector of length 2 defining the variables in \code{data} that contain the x and y coordinates of sample locations
#' @param model.fun Function that fits a predictive model, such as \code{glm} or \code{rpart}. The 
#' function must accept at least two arguments, the first one being a formula and the second a 
#' data.frame with the learning sample.
#' @param model.args Arguments to be passed to \code{model.fun} (in addition to the \code{formula} and \code{data} argument, which are provided by \code{sperrorest})
#' @param pred.fun Prediction function for a fitted model object created by \code{model}. 
#' Must accept at least two arguments: the fitted \code{object} and a \code{data.frame} \code{newdata} with data 
#' on which to predict the outcome.
#' @param pred.args (optional) Arguments to \code{pred.fun} (in addition to the fitted model object and the \code{newdata} argument, which are provided by \code{sperrorest})
#' @param smp.fun A function for sampling training and test sets from \code{data}. E.g., \code{\link{partition.kmeans}} for spatial cross-validation using spatial \emph{k}-means clustering.
#' @param smp.args (optional) Arguments to be passed to \code{est.fun}
#' @param train.fun (optional) A function for resampling or subsampling the training sample in order to achieve, e.g., uniform sample sizes on all training sets, or maintaining a certain ratio of positives and negatives in training sets. E.g., \code{\link{resample.uniform}} or \code{\link{resample.strat.uniform}}
#' @param train.param (optional) Arguments to be passed to \code{resample.fun}
#' @param test.fun (optional) Like \code{train.fun} but for the test set.
#' @param test.param (optional) Arguments to be passed to \code{test.fun}
#' @param err.fun A function that calculates selected error measures from the known responses in \code{data} and the model predictions delivered by \code{pred.fun}. E.g., \code{\link{err.default}} (the default). See example and details below.
#' @param err.unpooled logical (default: \code{TRUE} if \code{importance} is \code{TRUE}, otherwise \code{FALSE}): calculate error measures on each fold within a resampling repetition
#' @param err.pooled logical (default: \code{TRUE}): calculate error measures based on the pooled predictions of all folds within a resampling repetition
#' @param err.train logical (default: \code{TRUE}): calculate error measures on the training set (in addition to the test set estimation)
#' @param imp.variables (optional; used if \code{importance=TRUE}) Variables for which permutation-based variable importance assessment is performed. If \code{importance=TRUE} and \code{imp.variables} is \code{NULL}, all variables in \code{formula} will be used.
#' @param imp.permutations (optional; used if \code{importance=TRUE}) Number of permutations used for variable importance assessment.
#' @param importance logical: perform permutation-based variable importance assessment?
#' @param ... currently not used
#' @param distance logical (default: \code{FALSE}): if \code{TRUE}, calculate mean nearest-neighbour distances from test samples to training samples using \code{\link{add.distance.represampling}}
#' @param do.gc numeric (default: 1): defines frequency of memory garbage collection by calling \code{\link{gc}}; if \code{<1}, no garbage collection; if \code{>=1}, run a \code{gc()} after each repetition; if \code{>=2}, after each fold
#' @param do.try logical (default: \code{FALSE}): if \code{TRUE} [untested!!], use \code{\link{try}} to robustify calls to \code{model.fun} and \code{err.fun}; use with caution!
#' @param silent If \code{TRUE}, show progress on console (in Windows Rgui, disable 'Buffered output' in 'Misc' menu)
#' @return A list (object of class \code{sperrorest}) with (up to) four components:
#' \item{error}{a \code{sperroresterror} object containing predictive performances at the fold level}
#' \item{represampling}{a \code{\link{represampling}} object}
#' \item{pooled.error}{a \code{sperrorestpoolederror} object containing predictive performances at the repetition level}
#' \item{importance}{a \code{sperrorestimportance} object containing permutation-based variable importances at the fold level}
#' @return An object of class \code{sperrorest}, i.e. a list with components \code{error} (of class \code{sperroresterror}), \code{represampling} (of class \code{represampling}), \code{pooled.error} (of class \code{sperrorestpoolederror}) and \code{importance} (of class \code{sperrorestimportance}).
#' @note To do: (1) Parallelize the code; (2) Optionally save fitted models, training and test samples in the results object; (3) Optionally save intermediate results in some file, and enable the function to continue an interrupted sperrorest call where it was interrupted. (3) Optionally have sperrorest dump the result of each repetition into a file, and to skip repetitions for which a file already exists. (4) Save sperrorest version number in results object.
#' @references Brenning, A. 2012. Spatial cross-validation and bootstrap for the assessment of prediction rules in remote sensing: the R package 'sperrorest'. 2012 IEEE International Geoscience and Remote Sensing Symposium (IGARSS), 23-27 July 2012, p. 5372-5375.
#'
#' Brenning, A. 2005. Spatial prediction models for landslide hazards: review, comparison and evaluation. Natural Hazards and Earth System Sciences, 5(6): 853-862.
#'
#' Brenning, A., S. Long & P. Fieguth. Forthcoming. Detecting rock glacier flow structures using Gabor filters and IKONOS imagery. Submitted to Remote Sensing of Environment.
#'
#' Russ, G. & A. Brenning. 2010a. Data mining in precision agriculture: Management of spatial information. In 13th International Conference on Information Processing and Management of Uncertainty, IPMU 2010; Dortmund; 28 June - 2 July 2010.  Lecture Notes in Computer Science, 6178 LNAI: 350-359.
#'
#' Russ, G. & A. Brenning. 2010b. Spatial variable importance assessment for yield prediction in Precision Agriculture. In Advances in Intelligent Data Analysis IX, Proceedings, 9th International Symposium, IDA 2010, Tucson, AZ, USA, 19-21 May 2010.  Lecture Notes in Computer Science, 6065 LNCS: 184-195.
#' @seealso \pkg{ipred}
#' @aliases sperroresterror sperrorestimportance
#' @examples
#' data(ecuador) # Muenchow et al. (2012), see ?ecuador
#' fo = slides ~ dem + slope + hcurv + vcurv + 
#'      log.carea + cslope
#' 
#' # Example of a classification tree fitted to this data:
#' library(rpart)
#' ctrl = rpart.control(cp = 0.005) # show the effects of overfitting
#' fit = rpart(fo, data = ecuador, control = ctrl)
#' par(xpd = TRUE)
#' plot(fit, compress = TRUE, main = "Stoyan's landslide data set")
#' text(fit, use.n = TRUE)
#'
#' # Non-spatial 5-repeated 10-fold cross-validation:
#' mypred.rpart = function(object, newdata) predict(object, newdata)[,2]
#' nspres = sperrorest(data = ecuador, formula = fo,
#'     model.fun = rpart, model.args = list(control = ctrl),
#'     pred.fun = mypred.rpart,
#'     smp.fun = partition.cv, smp.args = list(repetition=1:5, nfold=10))
#' summary(nspres$error)
#' summary(nspres$represampling)
#' plot(nspres$represampling, ecuador)
#'
#' # Spatial 5-repeated 10-fold spatial cross-validation:
#' spres = sperrorest(data = ecuador, formula = fo,
#'     model.fun = rpart, model.args = list(control = ctrl),
#'     pred.fun = mypred.rpart,
#'     smp.fun = partition.kmeans, smp.args = list(repetition=1:5, nfold=10))
#' summary(spres$error)
#' summary(spres$represampling)
#' plot(spres$represampling, ecuador)
#' 
#'  smry = data.frame(
#'      nonspat.training = unlist(summary(nspres$error,level=1)$train.auroc),
#'      nonspat.test     = unlist(summary(nspres$error,level=1)$test.auroc),
#'      spatial.training = unlist(summary(spres$error,level=1)$train.auroc),
#'      spatial.test     = unlist(summary(spres$error,level=1)$test.auroc))
#' boxplot(smry, col = c("red","red","red","green"), 
#'      main = "Training vs. test, nonspatial vs. spatial",
#'      ylab = "Area under the ROC curve")
#' @export
parsperrorest = function(formula, data, coords = c("x", "y"),
                      model.fun, model.args = list(),
                      pred.fun = NULL, pred.args = list(),
                      smp.fun = partition.loo, smp.args = list(),
                      train.fun = NULL, train.param = NULL,
                      test.fun = NULL, test.param = NULL,
                      err.fun = err.default,
                      err.unpooled = importance,
                      err.pooled = TRUE,
                      err.train = TRUE,
                      imp.variables = NULL,
                      imp.permutations = 1000,
                      importance = !is.null(imp.variables),
                      distance = FALSE,
                      do.gc = 1,
                      do.try = FALSE,
                      silent = FALSE,
                      mc.cores = detectCores(), ...)
{
  # Some checks:
  if (missing(model.fun)) stop("'model.fun' is a required argument")
  if (as.character(attr(terms(formula),"variables"))[3] == "...")
    stop("formula of the form lhs ~ ... not accepted by 'sperrorest'\nspecify all predictor variables explicitly")
  stopifnot(is.function(model.fun))
  stopifnot(is.function(smp.fun))
  if (!is.null(train.fun)) stopifnot(is.function(train.fun))
  if (!is.null(test.fun)) stopifnot(is.function(test.fun))
  stopifnot(is.function(err.fun))
  if (importance) {
    if (!err.unpooled) {
      warning("'importance=TRUE' currently only supported with 'err.unpooled=TRUE'.\nUsing 'importance=FALSE'")
      importance = FALSE
    }
    stopifnot(is.numeric(imp.permutations))
    if (!is.null(imp.variables)) stopifnot(is.character(imp.variables))
  }
  stopifnot(is.character(coords))
  stopifnot(length(coords) == 2)
  if (importance & !err.unpooled)
    stop("variable importance assessment currently only supported at the unpooled level")
  
  # Check if user is trying to bypass the normal mechanism for generating training and test data sets 
  # and for passing formulas:
  if (any(names(model.args) == "formula")) stop("'model.args' cannot have a 'formula' element")
  if (any(names(model.args) == "data")) stop("'model.args' cannot have a 'data' element")
  if (any(names(pred.args) == "object")) stop("'pred.args' cannot have an 'object' element:\nthis will be generated by 'sperrorest'")
  if (any(names(pred.args) == "newdata")) stop("'pred.args' cannot have a 'newdata' element:\nthis will be generated by 'sperrorest'")
  
  # Some checks related to recent changes in argument names:
  dots.args = list(...)
  if (length(dots.args) > 0) {
    if (any(names(dots.args) == "predfun")) stop("sorry: argument names have changed; 'predfun' is now 'pred.fun'")
    if (any(names(dots.args) == "model")) stop("sorry: argument names have changed; 'model' is now 'model.fun'")
    if (any(names(dots.args) == "err.combined")) stop("sorry: argument names have changed; 'err.combined' is now 'err.pooled'")
    if (any(names(dots.args) == "err.uncombined")) stop("sorry: argument names have changed; 'err.uncombined' is now 'err.unpooled'")
    warning("'...' arguments currently not supported:\nuse 'model.args' to pass list of additional arguments to 'model.fun'")
  }
  
  # Name of response variable:
  response = as.character(attr(terms(formula),"variables"))[2]
  
  smp.args$data = data
  smp.args$coords = coords
  
  resamp = do.call(smp.fun, args = smp.args)
  if (distance)
    # Parallelize this function???
    resamp = add.distance(resamp, data, coords = coords, fun = mean)
  
  if (err.unpooled) {
    res = lapply(resamp, unclass)
    class(res) = "sperroresterror"
  } else res = NULL
  pooled.err = NULL
  # required to be able to assign levels to predictions if appropriate:
  is.factor.prediction = NULL
  
  ### Permutation-based variable importance assessment (optional):
  impo = NULL
  if (importance) {
    # Importance of which variables:
    if (is.null(imp.variables))
      imp.variables = strsplit(as.character(formula)[3]," + ",fixed=TRUE)[[1]]
    # Dummy data structure that will later be populated with the results:
    impo = resamp
    # Create a template that will contain results of variable importance assessment:
    imp.one.rep = as.list( rep(NA, length(imp.variables)) )
    names(imp.one.rep) = imp.variables
    tmp = as.list(rep(NA, imp.permutations))
    names(tmp) = as.character(1:imp.permutations)
    for (vnm in imp.variables) imp.one.rep[[vnm]] = tmp
    rm(tmp)
  }
  
  #message to make sure local source files are being used
  print("This is not the original sperrorest package code.")
  
  #runreps function for lapply()
  runreps = function(currentSample){
    #if (!silent) cat(date(), "Repetition", names(resamp)[i], "\n")
    #output data structures
    currentRes = NULL
    currentImpo = NULL
    currentPooled.err = NULL
    
    if (err.unpooled) {
      currentRes = lapply(currentSample, unclass)
      class(currentRes) = "sperroresterror"
    } else currentRes = NULL
    
    # Collect pooled results in these data structures:
    if (err.train) pooled.obs.train = pooled.pred.train = c()
    pooled.obs.test = pooled.pred.test = c()
    
    # Parallelize this???
    # For each fold:
    for (j in 1:length(currentSample))
    {
      if (!silent) cat(date(), "- Fold", j, "\n")
      
      # Create training sample:
      nd = data[ currentSample[[j]]$train , ]
      if (!is.null(train.fun))
        nd = train.fun(data = nd, param = train.param)
      
      # Train model on training sample:
      margs = c( list(formula = formula, data = nd), model.args )
      
      if (do.try) {
        fit = try(do.call(model.fun, args = margs), silent = silent)
        
        # Error handling:
        if (class(fit) == "try-error") {
          fit = NULL
          if (err.unpooled) {
            if (err.train) currentRes[[j]]$train = NULL #res[[i]][[j]]$train = NULL
            currentRes[[j]]$test = NULL #res[[i]][[j]]$test = 
            if (importance) currentImpo[[j]] = c() # ???
          }
          if (do.gc >= 2) gc()
          next # skip this fold
        }
        
      } else {
        fit = do.call(model.fun, args = margs)
      }
      
      if (err.train) {
        # Apply model to training sample:
        pargs = c( list(object = fit, newdata = nd), pred.args )
        if (is.null(pred.fun)) {
          pred.train = do.call(predict, args = pargs)
        } else {
          pred.train = do.call(pred.fun, args = pargs)
        }
        rm(pargs)
        
        # Calculate error measures on training sample:
        if (err.unpooled)
          if (do.try) {
            err.try = try(err.fun(nd[,response], pred.train), silent = silent)
            if (class(err.try) == "try-error") err.try = NULL # ???
            currentRes[[j]]$train = err.try #res[[i]][[j]]$train = err.try
          } else {
            currentRes[[j]]$train = err.fun(nd[,response], pred.train) #res[[i]][[j]]$train = err.fun(nd[,response], pred.train)
          }
        if (err.pooled) {
          pooled.obs.train = c( pooled.obs.train, nd[,response] )
          pooled.pred.train = c( pooled.pred.train, pred.train )
        }
      } else {
        if (err.unpooled) currentRes[[j]]$train = NULL #res[[i]][[j]]$train = NULL
      }
      
      # Create test sample:
      nd = data[ currentSample[[j]]$test , ]
      if (!is.null(test.fun))
        nd = test.fun(data = nd, param = test.param)
      # Create a 'backup' copy for variable importance assessment:
      if (importance) nd.bak = nd
      # Apply model to test sample:
      pargs = c( list(object = fit, newdata = nd), pred.args )
      if (is.null(pred.fun)) {
        pred.test  = do.call(predict, args = pargs)
      } else {
        pred.test  = do.call(pred.fun, args = pargs)
      }
      rm(pargs)
      
      # Calculate error measures on test sample:
      if (err.unpooled) {
        if (do.try) {
          err.try = try(err.fun(nd[,response], pred.test), silent = silent)
          if (class(err.try) == "try-error") err.try = NULL # ???
          currentRes[[j]]$test = err.try #res[[i]][[j]]$test = err.try
        } else {
          currentRes[[j]]$test = err.fun(nd[,response], pred.test) #res[[i]][[j]]$test  = err.fun(nd[,response], pred.test)
        }
      }
      if (err.pooled) {
        pooled.obs.test = c( pooled.obs.test, nd[,response] )
        pooled.pred.test = c( pooled.pred.test, pred.test )
        is.factor.prediction = is.factor(pred.test)
      }
      
      ### Permutation-based variable importance assessment:
      if (importance & err.unpooled) {
        
        #if (is.null(res[[i]][[j]]$test)) {
        if(is.null(currentRes[[j]]$test)){
          currentImpo[[j]] = c()
          if (!silent) cat(date(), "-- skipping variable importance\n")
        } else {
          
          if (!silent) cat(date(), "-- Variable importance\n")
          imp.temp = imp.one.rep
          
          # Parallelize this: ???
          for (cnt in 1:imp.permutations) {
            # Some output on screen:
            if (!silent & (cnt>1))
              if (log10(cnt)==floor(log10(cnt))) 
                cat(date(), "   ", cnt, "\n")
            
            # Permutation indices:
            permut = sample(1:nrow(nd), replace = FALSE)
            
            # For each variable:
            for (vnm in imp.variables) {
              # Get undisturbed backup copy of test sample:
              nd = nd.bak
              # Permute variable vnm:
              nd[,vnm] = nd[,vnm][permut]
              # Apply model to perturbed test sample:
              pargs = c( list(object = fit, newdata = nd), pred.args )
              if (is.null(pred.fun)) {
                pred.test  = do.call(predict, args = pargs)
              } else {
                pred.test  = do.call(pred.fun, args = pargs)
              }
              rm(pargs)
              
              # Calculate variable importance:
              if (do.try) {
                permut.err = try(err.fun(nd[,response], pred.test), silent = silent)
                if (class(permut.err) == "try-error") {
                  imp.temp[[vnm]][[cnt]] = c() # ???
                } else {
                  imp.temp[[vnm]][[cnt]] = 
                    as.list( unlist(currentRes[[j]]$test) - unlist(permut.err) )
                  #as.list( unlist(res[[i]][[j]]$test) - unlist(permut.err) )
                  # (apply '-' to corresponding list elements; only works
                  # if all list elements are scalars)
                }
              } else {
                permut.err = err.fun(nd[,response], pred.test)
                imp.temp[[vnm]][[cnt]] = 
                  as.list( unlist(currentRes[[j]]$test) - unlist(permut.err) )
                #as.list( unlist(res[[i]][[j]]$test) - unlist(permut.err) )
                # (apply '-' to corresponding list elements; only works
                # if all list elements are scalars)
              }
            }
          }
          # average the results obtained in each permutation:
          currentImpo[[j]] = as.data.frame(
            t(sapply(imp.temp, 
                     function(y) sapply(as.data.frame(t(
                       sapply( y, as.data.frame ))), 
                       function(x) mean(unlist(x)) ))))
          rm(nd.bak, nd) # better safe than sorry...
        } # end of else if (!is.null(res[[i]][[j]]$test))
      }
      
    }
    
    # Put the results from the pooled estimation into the pooled.err data structure:
    if (err.pooled) {
      if (is.factor(data[,response])) {
        lev = levels(data[,response])
        if (err.train) pooled.obs.train = factor(lev[pooled.obs.train], levels = lev)
        pooled.obs.test = factor(lev[pooled.obs.test], levels = lev)
        if (is.factor.prediction) {
          if (err.train) pooled.pred.train = factor(lev[pooled.pred.train], levels = lev)
          pooled.pred.test = factor(lev[pooled.pred.test], levels = lev)
        }
      }
      pooled.err.train = NULL
      if (err.train)
        pooled.err.train = err.fun( pooled.obs.train, pooled.pred.train )
      
      currentPooled.err = t(unlist( list( train = pooled.err.train,
                                          test  = err.fun( pooled.obs.test,  pooled.pred.test ) ) ))
      
      #if (i == 1) {
      #  pooled.err = t(unlist( list( train = pooled.err.train,
      #                               test  = err.fun( pooled.obs.test,  pooled.pred.test ) ) ))
      #} else {
      #  pooled.err = rbind( pooled.err, 
      #                      unlist( list( train = pooled.err.train,
      #                                    test  = err.fun( pooled.obs.test,  pooled.pred.test ) ) ) )
      #}
      
      if (do.gc >= 2) gc()
    } # end for each fold
    
    if ((do.gc >= 1) & (do.gc < 2)) gc()
    return(list(error = currentRes, pooled.error = currentPooled.err, importance = currentImpo))
  }
  
  # For each repetition:
  myRes = mclapply(resamp, FUN = runreps, mc.cores = mc.cores)
  #   for(myI in 1:length(resamp)){
  #     runreps(resamp[[myI]])
  #   }
  #print(myRes)
  
  #transfer results of lapply() to respective data objects
  for(i in 1:length(myRes)){
    if (i == 1) {
      pooled.err = myRes[[i]]$pooled.error
      impo[[i]] = myRes[[i]]$importance
      res[[i]] = myRes[[i]]$error
    } else {
      pooled.err = rbind( pooled.err, myRes[[i]]$pooled.error )
      impo[[i]] = myRes[[i]]$importance
      res[[i]] = myRes[[i]]$error
      #impo = rbind( impo, myRes[[i]]$importance )
      #res = rbind( res, myRes[[i]]$error )
    }
  }
  
  # convert matrix(?) to data.frame:
  if (err.pooled) {
    pooled.err = as.data.frame(pooled.err)
    rownames(pooled.err) = NULL
    class(pooled.err) = "sperrorestpoolederror"
  }
  
  if (!silent) cat(date(), "Done.\n")
  
  if (importance) class(impo) = "sperrorestimportance"
  
  RES = list(
    error = res, 
    represampling = resamp, 
    pooled.error = pooled.err,
    importance = impo )
  class(RES) = "sperrorest"
  
  return( RES )
}