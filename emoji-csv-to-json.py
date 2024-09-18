import csv
import json
import re
import argparse

# Function to clean up the "U+XXXX" Unicode notation into actual emoji characters
def unicode_to_emoji(unicode_str):
    code_points = unicode_str.replace("U+", "").split()
    emoji_chars = [chr(int(cp, 16)) for cp in code_points]
    return ''.join(emoji_chars)

# Function to process a section or subsection title into tags
def section_to_tags(section_title):
    tags = re.split(r'[\s&-]', section_title.strip().lower())
    return [tag for tag in tags if tag]

# Main function to process the CSV and convert it to JSON
def convert_csv_to_json(input_csv_file, output_json_file, version):
    # List to hold the processed emoji data
    emoji_data = []

    # Current section and subsection tags
    current_section_tags = []
    current_subsection_tags = []

    # Open and read the CSV file
    with open(input_csv_file, "r", encoding="utf-8") as csvfile:
        reader = csv.reader(csvfile)

        for row in reader:
            # Skip empty rows
            if not row or not any(row):
                continue

            # Detect new section
            if row[0] and not row[1] and not row[2]:
                # A new section header (like "Smileys & Emotion")
                current_section_tags = section_to_tags(row[0])
                continue

            # Detect new subsection
            if row[0] and not row[1] and row[2] == "":
                # A new subsection header (like "face-smiling")
                current_subsection_tags = section_to_tags(row[0])
                continue

            # Skip header lines
            if row[0] == "№" or row[0].startswith("№"):
                continue

            # Parse emoji data row
            if row[1].startswith("U+"):
                emoji = unicode_to_emoji(row[1])
                description = row[3]
                
                # Combine section and subsection tags
                tags = current_section_tags + current_subsection_tags

                # Append to the emoji_data list
                emoji_data.append({
                    "emoji": emoji,
                    "description": description,
                    "tags": tags
                })

    # Create the final JSON structure with a version
    output_data = {
        "version": version,
        "emoji_data": emoji_data
    }

    # Save the processed data to a JSON file
    with open(output_json_file, "w", encoding="utf-8") as jsonfile:
        json.dump(output_data, jsonfile, ensure_ascii=False, indent=4)

    print(f"Emoji data saved to {output_json_file} with version {version}")

# Argument parser setup
def main():
    parser = argparse.ArgumentParser(description="Convert emoji CSV data into JSON format for loading into a database.")
    parser.add_argument("input_csv_file", help="Path to the input CSV file")
    parser.add_argument("output_json_file", help="Path to the output JSON file")
    parser.add_argument("--version", required=True, help="Version of the emoji data")
    args = parser.parse_args()

    # Call the conversion function with the provided arguments
    convert_csv_to_json(args.input_csv_file, args.output_json_file, args.version)

if __name__ == "__main__":
    main()