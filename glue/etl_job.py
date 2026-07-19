import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Glue passes arguments into the script — this is how we receive them
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'source_path', 'target_path'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Step 1: Read the raw file from S3 as a Spark DataFrame
df = spark.read.option("header", "true").option("inferSchema", "true").csv(args['source_path'])

print(f"Row count before transform: {df.count()}")

# Step 2: Basic data quality check — drop rows missing critical fields
# (In a real pipeline, you'd log/quarantine bad rows instead of silently dropping — 
# we'll improve this in the next pass)
df_clean = df.dropna(how="any")

print(f"Row count after dropping nulls: {df_clean.count()}")

# Step 3: Example transformation — add a processing timestamp column
from pyspark.sql.functions import current_timestamp
df_transformed = df_clean.withColumn("processed_at", current_timestamp())

# Step 4: Write result to S3 in Parquet format (columnar, efficient for analytics)
df_transformed.write.mode("overwrite").parquet(args['target_path'])

job.commit()