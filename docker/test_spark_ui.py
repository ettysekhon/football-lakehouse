#!/usr/bin/env python3

from pyspark.sql import SparkSession

spark = (
    SparkSession.builder.appName("FootballAnalyticsTest")
    .config("spark.ui.enabled", "true")
    .config("spark.ui.port", "8080")
    .config("spark.ui.host", "0.0.0.0")
    .config("spark.driver.host", "0.0.0.0")
    .config("spark.driver.port", "7077")
    .config("spark.driver.blockManager.port", "7078")
    .getOrCreate()
)

print("Spark UI should be available at http://localhost:8082")
print("Spark Application UI URL:", spark.sparkContext.uiWebUrl)
print("Spark Version:", spark.version)
print("Application ID:", spark.sparkContext.applicationId)

# Keep the session alive
print("Spark session created. Press Ctrl+C to exit...")
try:
    data = [("ES", 25), ("CO", 30), ("JE", 35)]
    df = spark.createDataFrame(data, ["name", "age"])
    df.show()

    # Keep running
    input("Press Enter to stop the Spark session...")
except KeyboardInterrupt:
    print("\nStopping Spark session...")
finally:
    spark.stop()
