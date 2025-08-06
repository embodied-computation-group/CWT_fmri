library(lme4)
library(lmerTest)
library(ordinal)
library(glmmTMB)
library(tidyverse)
library(DHARMa)
library(sjPlot)
library(sjmisc)

##
source("getdata.R")

df$RawConfidence <- df$RawConfidence/100 

df$Accuracy <- factor(df$Accuracy, 
                      levels = c(0, 1), 
                      labels = c("miss", "hit"))

df$TrialValidity2_numeric <- recode(df$TrialValidity2, 
                                    "Valid" = 1, 
                                    "non-predictive" = 0, 
                                    "Invalid" = -1)


# Assuming df is your data frame
df <- df %>%
  mutate(SignaledFace = case_when(
    TrialValidity == "Valid" & CueImg == "0" ~ as.character(FaceEmot),   # CueImg = 0 signals FaceEmot directly when valid
    TrialValidity == "Valid" & CueImg == "1" ~ as.character(FaceEmot),   # CueImg = 1 signals FaceEmot directly when valid
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Happy" ~ "Angry",  # CueImg = 0 signals the opposite when invalid
    TrialValidity == "Invalid" & CueImg == "0" & FaceEmot == "Angry" ~ "Happy",  # CueImg = 0 signals the opposite when invalid
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Happy" ~ "Angry",  # CueImg = 1 signals the opposite when invalid
    TrialValidity == "Invalid" & CueImg == "1" & FaceEmot == "Angry" ~ "Happy",  # CueImg = 1 signals the opposite when invalid
    TRUE ~ NA_character_  # Handle cases where the condition doesn't match
  ))

# Convert SignaledFace to a factor with levels "Happy" and "Angry"
df$SignaledFace <- factor(df$SignaledFace, levels = c("Happy", "Angry"))

df <- df %>%
  group_by(SubNo) %>%
  mutate(TrialsSinceRev_scaled = scale(TrialsSinceRev, center = TRUE, scale = TRUE)) %>%
  ungroup()

#f$TrialsSinceRev_scaled <- scale(df$TrialsSinceRev, center = TRUE, scale = TRUE)


control_options <- glmmTMBControl(
  optimizer = optim,
  optArgs = list(method = "BFGS"),
  optCtrl = list(maxit = 10000)  # Set the maximum number of iterations
)


# changing optimizer seemed to help convergence

## confidence ordered beta

conf_fit_trial <- glmmTMB(RawConfidence ~ TrialNo + (1 + TrialNo| SubNo),
                     data=df,
                     family=ordbeta(),
                     start=list(psi = c(0, 1)))


conf_fit1 <- glmmTMB(RawConfidence ~ TrialValidity2_numeric*TrialsSinceRev*StimNoise*Accuracy + (1 + Accuracy + StimNoise + TrialValidity2_numeric  | SubNo),
                    data=df,
                    family=ordbeta(),
                    start=list(psi = c(0, 1)), 
                    control = control_options)

model <- glmmTMB(
  RawConfidence ~ TrialValidity2_numeric * StimNoise * TrialsSinceRev_scaled+ 
    (1 + TrialValidity2_numeric + StimNoise + TrialsSinceRev_scaled | SubNo),
  data = df,
  family = ordbeta(),
  start=list(psi = c(0, 1)), 
  control = control_options)


conf_fit2 <- glmmTMB(RawConfidence ~ TrialsSinceRev*CueValidity + (1 + StimNoise | SubNo),
                     data=df,
                     family=ordbeta(),
                     start=list(psi = c(0, 1)), 
                     control = control_options)

summary(conf_fit1)
tab_model(conf_fit1)
anova(conf_fit1, conf_fit2)

plot_model(model, type = "pred", terms = c("TrialsSinceRev_scaled","TrialValidity2_numeric", "StimNoise", "Accuracy"))



# accuracy model - simple with only random offsets - subjects nested within sessions
model <- glmmTMB(Accuracy ~ TrialValidity2*StimNoise + FaceEmot + CueImg + (1+ FaceEmot + CueImg | SubNo),
                 data = df, 
                 family = binomial(link = "logit"), 
                 control = control_options)
summary(model)

modelplot <- plot_model(model, 
                        type = "pred", 
                        terms = c( "TrialValidity2", "StimNoise"),
                        title = "Interaction Effect ")

modelplot + theme_minimal()  



# RTs
df_rt <- df %>% 
  na.omit(). # seems to need to happen for it to work

rtmodel <- glmmTMB(ResponseRT ~ StimNoise * TrialValidity2  +
                                          (1 +FaceEmot + StimNoise | SubNo ), 
                                        data = df_rt, 
                                        family = Gamma(link = "log"))

summary(rtmodel)


modelplot <- plot_model(rtmodel, 
                        type = "eff", 
                        terms = c("TrialValidity2", "StimNoise"),
                        title = "Interaction Effect ")

modelplot + theme_minimal()  


modelplot <- plot_model(rtmodel, 
                        type = "eff", 
                        terms = c("TrialsSinceRev", "TrialValidity2"),
                        title = "Interaction Effect ")

modelplot + theme_minimal() 



confmodel <- glmmTMB(Confidence ~  TrialValidity2*StimNoise  +
                     (1 +FaceEmot | SubNo ), 
                   data = df)

summary(confmodel)

modelplot <- plot_model(confmodel, 
                        type = "eff", 
                        terms = c("TrialValidity2","StimNoise"),
                        title = "Interaction Effect ")

modelplot + theme_minimal() 


## choice model
df_filt <- df %>% 
  filter(StimNoise == "high noise")

# accuracy model - simple with only random offsets - subjects nested within sessions
choice_model <- glmmTMB(FaceResponse ~ SignaledFace * FaceEmot *TrialsSinceRev + (1 + FaceEmot   | SubNo),
                 data = df_filt, 
                 family = binomial(link = "logit"), 
                 control = control_options)

summary(choice_model)


modelplot <- plot_model(choice_model, 
                        type = "eff", 
                        terms = c("TrialsSinceRev","SignaledFace", "FaceEmot"),
                        title = "Interaction Effect: Signaled vs Shown Face ")

modelplot + theme_minimal()  + 
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) + # Scale from 0% to 100%
  labs(y = "Percentage Happy Response") # Label the y-axis accordingly


