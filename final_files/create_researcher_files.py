import pandas as pd
import numpy as np

# file path to unfiltered csv file
csv_file_path = '/home/ec2-user/summative_work/final_files/unfiltered_collated_results.csv'

unfiltered_df = pd.read_csv(csv_file_path)


# hits_output.csv creation
hits_output_df = unfiltered_df.iloc[:, :2]
hits_output_df.to_csv('hits_output.csv', index=False)



# profile_output.csv file creation

#replace 'nan' with NaN 
unfiltered_df.replace("nan", np.nan, inplace=True)

# remove rows with NaN
df_cleaned = unfiltered_df.iloc[:, 2:]
print(df_cleaned.head())
df_cleaned = df_cleaned.dropna()    
print(df_cleaned.shape)

# get the last 2 columns
column_averages = df_cleaned.mean()

#create average csv file
average_df = pd.DataFrame({
    'ave_std': [column_averages['score_std']],  
    'ave_gmean': [column_averages['score_gmean']]  
})
average_df.to_csv('profile_output.csv', index=False)
