import pyarrow.parquet as pq

schema = pq.read_schema('local_check.parquet')
print(schema)