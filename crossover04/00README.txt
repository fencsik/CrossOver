Readme for crossover04

Contains the experiment that was written up in the Crossover paper.

NOTE: Within R, calling source("refresh.r") will run all completed
analyses.

Analyses:
 - data.txt: Raw data file with subject, condition, setsize, and counts of
   target-present, target-absent, hit, and correct-rejection trials.
 - data00.r: Loads data file and adds hit and false-alarm proportions, and
   standard SDT measures of performance.
 - FitMaxSSE.r: Fits an unlimited-capacity max-rule search model to the
   data by minimizing sum-squared error.
 - FitMaxCapSSE.r: Fits a limited-capacity max-rule search model to the
   data by minimizing sum-squared error.
 - FitMaxCritSSE.r: Fits an unlimited-capacity max-rule search model to the
   data by minimizing SSE and allowing criterion to vary with setsize.
 - FitMaxCapCritSSE.r: Fits a limited-capacity max-rule search model to the
   data by minimizing SSE and allowing criterion to vary with setsize.
 - FitMaxML.r: Fits an unlimited-capacity max-rule search model to the data
   using a maximum likelihood procedure.
 - FitMaxCapML.r: Fits a limited-capacity max-rule search model to the data
   using a maximum likelihood procedure.
 - FitMaxPaper.r: Fits an unlimited-capacity max-rule search model using
   the parameters listed in Table 1 of the first submitted draft of the
   Crossover paper.
 - FitMaxCapPaper.r: Same as above, but for the limited-capacity model.
 - TestFits.r: Runs various goodness-of-fit tests comparing the
   limited-capacity models to the unlimited capacity models.
 - PlotFits.r: Plots the observed and predicted hit rates and false-alarm
   rates from all the fitting procedures.

Support files:
 - maxdprime.r: Computes the underlying sensitivity and criterion for a
   max-rule search model based on a set of hit rates and false-alarm rates
   at one or more setsizes.  Optionally includes a capacity limit.
 - maxrule.r: Computes the hit rates and false-alarm rates predicted by a
   max-rule search model based on a sensitivity and criterion at several
   setsizes.  Optionally includes a capacity limit.
 - maxrulelike.r: Computes the likelihood of observing a set of hit rates
   and false-alarm rates under a max-rule search model, given a particular
   sensitivity, criterion, and, optionally a capacity limit.

To-do:
 - Plot individual fits.
 - Fit models to averaged data instead of individual data.  This could be
   tricky: it's unclear how to compute the likelihood of the model because
   averaging across subjects yields non-integer values, and you can't just
   sum up totals across subjects.
 - Fit models using a genetic algorithm instead of gradient descent.
 - In the variable criterion model, what the heck is going on with RER?
