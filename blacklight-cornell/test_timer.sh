#!/bin/bash

# Directory containing .feature files
FEATURES_DIR="features"

# Output files
OUTPUT_FILE="test_timer_times.csv"
TEMP_FILE="test_timer_temp.txt"

ERROR_FILE="test_timer_errors.txt"
echo '' > $ERROR_FILE

# Clear the output file
echo -e 'file\tscenario\ttime' > $OUTPUT_FILE

echo "Running tests..."

# Find all .feature files in the directory
for feature_file in $(find $FEATURES_DIR -name "*.feature"); do
    echo $feature_file
    # Find all line numbers with Scenarios or Scenario Outlines in the feature file
    for line_number in $(grep -n "^\s*Scenario\|Scenario Outline" $feature_file | cut -f1 -d:); do
        echo "Running Scenario on line $line_number of $feature_file"
        # Run the Scenario with Cucumber and time it, converting the time to seconds
        TIME=$( (time -p bundle exec cucumber $feature_file:$line_number 2>> $ERROR_FILE) 2>&1 | awk '/real/ {print $2}' )
        echo $TIME
        # Write the feature file path, the Scenario line number, and the time to the output file on the same line
        echo -e "$feature_file\t$line_number\t$TIME" >> $TEMP_FILE
    done
done

# Sort the output file by time in descending order
sort -nr -k3 -o $TEMP_FILE $TEMP_FILE

# Append the sorted output file to the main output file
cat $TEMP_FILE >> $OUTPUT_FILE