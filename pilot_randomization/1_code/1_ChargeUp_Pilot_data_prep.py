#!/usr/bin/env python
# coding: utf-8

# In[32]:


#!/usr/bin/env python
import os, requests

# fetch personal API token stored in system environment variable
redcap_api_token = os.environ['rcapiChargeUpPilot']

data = {
    'token': redcap_api_token,
    'content': 'record',
    'action': 'export',
    'format': 'json',
    'type': 'flat',
    'csvDelimiter': '',
    'fields[0]': 'record_id',
    'fields[1]': 'dob',
    'fields[2]': 'preliminary_eligibility',
    'fields[3]': 'consent_date',
    'fields[4]': 'consent_complete',
    'fields[5]': 'gender_identity',
    'fields[6]': 'race',
    'fields[7]': 'ethnicity',
    'fields[8]': 'demographics_complete',
    'fields[9]': 'randomization_conf',
    'fields[10]': 'randomization_r1',
    'fields[11]': 'randomization_r1seed',
    'fields[12]': 'randomization_r1date',
    'exportSurveyFields': 'true',
    'exportDataAccessGroups': 'true',
    'exportBlankForGrayFormStatus': 'true',
    'outputMissingDataCodes': 'true',
    'filterLogic': "[consent_complete]=2 or [demographics_complete]=2"
}
r = requests.post('https://rc2.redcap.unc.edu/api/',data=data)
print('HTTP Status: ' + str(r.status_code))
#print(r.json())


# In[138]:


import pandas as pd

df_raw = pd.DataFrame(r.json())
#print(df_raw)
#df_raw.to_csv('C:/users/marcp/ChargeUp.csv', mode='w+')

df_raw = df_raw.drop(columns=['redcap_event_name', 'redcap_survey_identifier'])

## registration event variables and baseline event variables are in different rows
## prep each separately and then (re-)merge

# filter consented cases to those where "proceed with randomization" is confirmed
df_consent = df_raw[df_raw['randomization_conf']=='1']
df_consent = df_consent.drop(columns=['demographics_timestamp','gender_identity','race','ethnicity','demographics_complete'])
#print(df_consent)

df_baseline = df_raw[df_raw['demographics_complete']=='2']
df_baseline = df_baseline[['record_id','demographics_timestamp','gender_identity','race','ethnicity','demographics_complete']]
df_baseline = df_baseline.rename(columns={'race': 'race_redcap'})
#print(df_baseline)

df = df_consent.merge(df_baseline, left_on='record_id', right_on='record_id')
#print(df)


# In[139]:


'''
aiming for:
  * record_id: a unique identifier for each participant
  * num: a numeric variable indicating the rank order in which the participant was enrolled
  * avail_monday: a character variable taking values "yes" or "no" indicating whether the participant is available on monday
  * avail_wednesday: a character variable taking values "yes" or "no" indicating whether the participant is available on wednesday
  * age: the participant's age group (this should NOT be numeric)
  * gender: a character variable indicating the participant's gender
    >> revised 2024-07-08: 3 categories: man, woman, other
  * race: a character variable indicating the participant's race
    >> revised 2024-07-08: 3 categories: non-Hispanic Black, non-Hispanic Black, other
  * trt: a character variable indicating the treatment assignment for the participant. The expected values of this variable are:
      * "monday" for those already assigned to the treatment administered on mondays
      * "wednesday" for those already assigned to the treatment administered on wednesdays
      * "none" for those who have net yet been assigned a treatment
  * seed: a character variable indicating the seed value used to allocate treatment for each participant. This should be "none" for 
      all participants who have not yet been assigned treatment and should be a character variable consisting of no more than 4 digits 
      for those that have previously been assigned a treatment.
'''

# **num** - sort by form completion timestamps and enumerate to generate sequential "num" variable
df = df.sort_values(['consent_timestamp', 'demographics_timestamp'])
df['num'] = range(len(df))

# **avail_monday** - yes/no
# NOTE: for pilot, we are assuming availability, will address otherwise if needed.  This will be formalized for the full study.
df['avail_monday'] = 'yes'

# **avail_wednesday** - yes/no
df['avail_wednesday'] = 'yes'

# **age** - calculate age (provided date_start and date_end are between 1901 - 2099)
df['date_start'] = pd.to_datetime(df['dob'])
df['date_end'] = pd.to_datetime(df['consent_date'])
df['age_yrs'] = (df['date_end'].dt.year - df['date_start'].dt.year).astype(int)
df.loc[df['date_end'].dt.month < df['date_start'].dt.month, 'age_yrs'] = df['age_yrs'] - 1
df.loc[(df['date_end'].dt.month == df['date_start'].dt.month) & (df['date_end'].dt.day < df['date_start'].dt.day), 'age_yrs'] = df['age_yrs'] - 1

#a.k.a.
#df['age_yrs'] = (
#    df.date_end.dt.year - df.date_start.dt.year
#    -
#    (
#        (df.date_end.dt.month < df.date_start.dt.month)
#        |
#        (
#            (df.date_end.dt.month == df.date_start.dt.month)
#            &
#            (df.date_end.dt.day < df.date_start.dt.day)
#        )
#    ).astype(int)
#)

df = df.drop(['date_start', 'date_end'], axis=1)

# age groups for randomization -- I'm simply doing decadal categories for now (30s, 40s, 50s, etc.)
# what a ridiculous and embarrassing kludge, I know there's a better way...
df['age'] = (df['age_yrs'] - df['age_yrs'] % 10).astype(str) + '-' + (df['age_yrs'] - df['age_yrs'] % 10 + 9).astype(str)

# **gender**
df['gender'] = 'Other'
df.loc[df['gender_identity'] == '1', 'gender'] = 'Female'
df.loc[df['gender_identity'] == '2', 'gender'] = 'Male'

# **race**
# 1=non-Hispanic White, 2=non-Hispanic Black, 3=other
df['race'] = 'Other'
df.loc[(df['ethnicity']=='0') & (df['race_redcap']=='1'), 'race'] = 'Non-Hispanic White'
df.loc[(df['ethnicity']=='0') & (df['race_redcap']=='2'), 'race'] = 'Non-Hispanic Black'

# **trt** - monday/wednesday/none
df['trt'] = 'none'
df.loc[(df['randomization_r1']=='1'), 'trt'] = 'wednesday'
df.loc[(df['randomization_r1']=='2'), 'trt'] = 'monday'

# **seed**
df['seed'] = df['randomization_r1seed'].where(df['randomization_r1seed'] != '', 'none')
#print(df)


# In[145]:


import time

TodaysDate = time.strftime("%Y%m%d")
filename = f'ChargeUp_Pilot_to_randomize_{TodaysDate}.csv'

dfforcsv = df[['record_id', 'num', 'avail_monday', 'avail_wednesday', 'age', 'gender', 'race', 'trt', 'seed', 'randomization_r1date']]

dfforcsv.to_csv(filename, index=False, mode='w+')
#print(df)


