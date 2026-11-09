library(readxl)
library(stats)
#########################################
#
#           Assumptions I made while Coding-
#               Separate from paper assumptions
#
# 1.) Omitted Ci term in equation (2) from the paper because
#  I do not see an explicit calculation for it in the paper
#         - This is the "between-individual error term"
#             --> (random effects varying across the individual bidder but not the plant)
# 2.) We use a plant dummy variable while the paper gives plant types
#          - Data Dictionary for specific plants was not provided along with the data
# 
# 3.) Calculated WTP SE usin' delta-method, paper did not say how SEs were calculated.
#
# 4.) Calculated p-values usin' a Normal z-test, then used those p-values
#     to assign * confidence interval values, as their p-value procedure wasn't stated
#
# 5.) Dropped att_importance responses from the subgroup to avoid missing rows
#         - These are people who were indecisive about responding.
#
spa <- as.data.frame(read_excel(
  "data/SPA_combined_sample.xls"
))



# The paper says plant type is an attribute, so it's bein' treated
# as a qualitative variable, so usin' dummies. see: table 1
plant_controls <- model.matrix(~ factor(plant), spa)[, -1, drop = FALSE]
colnames(plant_controls) <- paste0("plant_code_", levels(factor(spa$plant))[-1])
# First plant is the reference
# basically just extractin' the columns from the original dataset to input 
# easier into the model

spa <- cbind(spa, plant_controls) # plugging the plant labels into the dataset

# The three different types of neonic's bein' tested, straight from the table/data
Label_columns <- c(
  "neonic_text",
  "neonic_logo",
  "neonic_treat"
)

# Settin' up the explanatory variables for the model
# which is creating "xij" in the paper, which was defined as:
# xij is a vector of plantattributes and individual characteristics that 
#  influence the consumer’s bidding price.

Model_columns <- c(
  Label_columns,
  "bio_pot", # biodegradable contrainer 
  colnames(plant_controls)
)

# Labels for recreatin' table 6
Diplay_labels <- c(
  "Neonicotinoid-free text label",
  "Neonicotinoid-free logo",
  "Neonicotinoid-treated text label"
)

#########################################
# Tobit modelin' equation 1 
#########################################

tobit_results <- function(data) {
  X <- cbind(
    1, # intercept column, constant 1 
    as.matrix(data[Model_columns]) # adds the explanatory data
  ) # joins everything into one object
  
  # obtainin' the bids from the dataset 
  
  bid <- as.numeric(data$bid)
  zero_bid <- bid == 0

  # Equation 1, found under table 5- simplified to:
  # bid = max(0, X beta + u)
  negative_log_likelihood <- function(theta) { # tobit models use likelihood
    beta <- theta[-length(theta)] # estimated effect from explanatory variables
    sigma <- exp(theta[length(theta)]) # spread of error terms
    xb <- drop(X %*% beta) # predict bid amount

    # Probability contribution of zero bids
    zero_part <- -sum(pnorm(-xb[zero_bid] / sigma, log.p = TRUE))
    # stores observations where people bid above 0
    positive_part <- sum(
      0.5 * ((bid[!zero_bid] - xb[!zero_bid]) / sigma)^2 +
      log(sigma) + 0.5 * log(2 * pi)
    ) # this come's from normal PDF formula, AI usage to assemble this calc
    # Note for write-up: this uses the same assumption from the paper, 
    # that the error term is normally distributed (look equation 1)
    zero_part + positive_part
  }
  # this runs a linear regression to guess at the coefficient values
  # uses OLS to minimize to start up the tobit model
  start_beta <- coef(lm.fit(
    X[!zero_bid, , drop = FALSE],
    bid[!zero_bid]
  ))

  fit <- optim(
    c(start_beta, 0), # merges 1-d arrays together
    negative_log_likelihood,
    method = "BFGS", # this converges toward a lower likelihood,
    hessian = TRUE
    # like how the value function converges to a fixed point
  )

  theta <- fit$par # gettin' the parameter values from the optimization above
  covariance <- solve(fit$hessian) # the is used to calculate standard error
  # for WTP later, but tis just an approximation since the paper didn't explicitly state 
  # how they did it.

#########################################
# Tobit model equation 2 work
#########################################
  
  # wtp function is recreatin' equation 2 from the paper
  
  wtp <- function(theta, k) {  # k is the WTP attribute to calculate, will loop through 'em 
    beta <- theta[-length(theta)] # gets the parameters
    sigma <- exp(theta[length(theta)]) # gets the tobit error spread
    # since we have log(theta) given the model is in log, takin' exp undos it 
    mean(pnorm(drop(X %*% beta) / sigma) * beta[k]) # recreation of the equation
  }
  # Note !!! This doesn't include Ci term, which accounts for people's preferences
  # Reasonin' being: paper doesn't explain how to reconstruct it
  
  results <- list()

  # The first three coefficients after the intercept are the three labels
  
  for (k in 2:4) { # Goes through the labels
    estimate <- wtp(theta, k) # matches the tobit parameters w/ a specific label

    # WTP Standard Error
    # Delta-method standard error, tis the standard way of doin' it
    
    gradient <- numeric(length(theta)) 
    
    # Gradient measures how much WTP changes when each Tobit parameter changes
    # Used for the standard error calculation below
    
    for (j in seq_along(theta)) {  # loops through all of the parameters
      change <- numeric(length(theta))
      change[j] <- 1e-5

      gradient[j] <- ( # this is the small parameter adjustment, inc and dec
        wtp(theta + change, k) -
        wtp(theta - change, k)
      ) / (2e-5)
    }

    se <- sqrt(max(drop(t(gradient) %*% covariance %*% gradient), 0))

    p_value <- 2 * pnorm(-abs(estimate / se)) # Two-sided p-value from a z-test
    # loops through each p_value to assign confidence interval stars
    if (p_value < 0.001) {
      stars <- "***"
    } else if (p_value < 0.01) {
      stars <- "**"
    } else if (p_value < 0.05) {
      stars <- "*"
    } else {
      stars <- ""
    }

    results[[k-1]] <- c(estimate, stars, se)
  }

  results
}


#########################################
# Table Creation
#########################################

groups <- list(
  "Sample Total" = spa,
  "Attitude toward pollinator: Agree Group" = spa[spa$att_polen == 1, ],
  "Attitude toward pollinator: Disagree Group" = spa[spa$att_polen == 0, ],
  "Attitude toward neonicotinoid regulation: Agree Group" = spa[spa$att_regulation == 1, ],
  "Attitude toward neonicotinoid regulation: Disagree Group" = spa[spa$att_regulation == 0, ],
  "Attitude toward labeling importance: Important Group" = spa[!is.na(spa$att_importance) & spa$att_importance == 1, ],
  "Attitude toward labeling importance: Unimportant Group" = spa[!is.na(spa$att_importance) & spa$att_importance == 0, ],
  "Overall PEB attitude: PEB Group" = spa[spa$att_overall == 1, ],
  "Overall PEB attitude: Non-PEB Group" = spa[spa$att_overall == 0, ]
)

rows <- list()

for (group_name in names(groups)) {
  group_data <- groups[[group_name]]
  rows[[length(rows) + 1]] <- c(group_name, "", "", "")

  for (i in seq_along(Diplay_labels)) {
    rows[[length(rows) + 1]] <- c(Diplay_labels[i], tobit_results(group_data)[[i]])
  }
}

tobit_table6 <- as.data.frame(
  do.call(rbind, rows),
  stringsAsFactors = FALSE
)

colnames(tobit_table6) <- c(
  "Experimental Auction / Tobit",
  "WTP Mean",
  "Significance",
  "SE"
)

for (column in c("WTP Mean", "SE")) {
  values <- suppressWarnings(as.numeric(tobit_table6[[column]]))
  tobit_table6[[column]] <- ifelse(
    is.na(values), "", format(round(values, 3), nsmall = 3)
  )
}


# Save newly estimated results when source data is available.
write.csv(tobit_table6, "outputs/tobit_table6.csv", row.names = FALSE)
print(tobit_table6)
