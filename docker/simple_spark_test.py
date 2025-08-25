#!/usr/bin/env python3

from pyspark.sql import SparkSession

print("Creating Spark session with UI enabled...")

spark = (
    SparkSession.builder.appName("SimpleSparkTest")
    .config("spark.ui.enabled", "true")
    .config("spark.ui.port", "8080")
    .config("spark.ui.host", "0.0.0.0")
    .config("spark.driver.host", "0.0.0.0")
    .config("spark.sql.catalogImplementation", "in-memory")
    .getOrCreate()
)

print("Spark UI URL:", spark.sparkContext.uiWebUrl)
print("Spark Version:", spark.version)
print("Application ID:", spark.sparkContext.applicationId)
print("")
print("Spark UI should now be available at: http://localhost:8082")
print("")

print("Creating test DataFrame...")
data = [("ES", 25, "Engineer"), ("CO", 30, "Manager"), ("JE", 35, "Analyst")]
columns = ["name", "age", "job"]

df = spark.createDataFrame(data, columns)
print("DataFrame created successfully!")
df.show()

print("")
print("Spark session is running. Check http://localhost:8082 for the UI.")
print("Press Ctrl+C to stop...")

try:
    import time

    while True:
        time.sleep(30)
        print("Spark session still running... UI at http://localhost:8082")
except KeyboardInterrupt:
    print("\nStopping Spark session...")
    spark.stop()
    print("Stopped.")
