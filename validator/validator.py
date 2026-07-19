import sys
import csv

REQUIRED_COLUMNS = {"id", "name", "value"}

def validate_file(filepath):
    with open(filepath, newline='') as f:
        reader = csv.DictReader(f)
        columns = set(reader.fieldnames or [])

        if not REQUIRED_COLUMNS.issubset(columns):
            missing = REQUIRED_COLUMNS - columns
            print(f"FAILED: missing required columns: {missing}")
            sys.exit(1)

        row_count = sum(1 for _ in reader)
        if row_count == 0:
            print("FAILED: file has no data rows")
            sys.exit(1)

        print(f"PASSED: {row_count} valid rows, all required columns present")
        sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python validate.py <file.csv>")
        sys.exit(1)
    validate_file(sys.argv[1])