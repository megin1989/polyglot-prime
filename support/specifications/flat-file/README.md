
# CSV Validation via Frictionless

## Overview

This project leverages the [Frictionless Data](https://frictionlessdata.io/) library to validate CSV files against predefined schemas, ensuring data quality and consistency. The validation process checks data integrity, format adherence, and schema compliance to streamline data workflows.

It supports CSV validation for social determinants of health (SDOH) data files that follow a strict structure and naming convention.


## File Format and Naming Convention  

The CSV file names in this project follow a strict naming convention to ensure consistency and compatibility with the validation process. Each file name is structured as follows:  

**`SDOH_<DATA_CATEGORY>_{OrganizationName}_{groupIdentifier}.csv`**  

All CSV files are **comma-separated (comma-delimited)** to maintain uniformity in data formatting, and they must be encoded in **UTF-8** to ensure proper validation and data processing. Additionally, field names are case-sensitive and must be written in **capital letters** (uppercase).

### Components of the File Name  

1. **`<DATA_CATEGORY>`**:  
   - This is the predefined and mandatory part of the file name. It indicates the category of data contained in the file and must remain unchanged.  
   - Examples of valid values:  
     - `SDOH_PtInfo` - Represents patient information data.  
     - `SDOH_QEadmin` - Represents quality entity administration data.  
     - `SDOH_ScreeningProf` - Represents screening profile data.  
     - `SDOH_ScreeningObs` - Represents screening observation data.  

2. **`{OrganizationIdentifier}`**:  
   - This represents the organization identifier but **does not** contain the actual name of the organization. Instead, it is a predefined identifier assigned to the organization (e.g., `CareRidgeSCN`).  

3.  **`{groupIdentifier}`**:
    * This component links related files. All CSV files that belong to a single set (like `QEadmin`, `PtInfo`, `ScreeningObs`, and `ScreeningProf`) **must share the exact same group identifier**. This ensures they're processed as one unit and converted into a valid FHIR bundle.

    * The `groupIdentifier` can be any unique string, such as a **UUID**, a **job ID**, or a manually assigned name (e.g., `testcase1`). While it's not strictly mandatory, appending a timestamp (e.g., `YYYYMMDDhhmmss`) can help ensure uniqueness—particularly when files are generated dynamically as part of a batch process.
   If you choose to include a timestamp in the `groupIdentifier`, it is important to ensure that the same timestamp value is used consistently across all files within that group. This allows the system to correctly recognize and associate the files as part of a single logical group. In our examples, we sometimes use timestamps to demonstrate how a dynamically generated `groupIdentifier` might look, but the key requirement is consistency across the grouped files.    


### Example File Names  

- `SDOH_QEadmin_CareRidgeSCN_testcase1_20250312040214.csv`  
- `SDOH_ScreeningProf_CareRidgeSCN_testcase1_20250312040214.csv`  
- `SDOH_ScreeningObs_CareRidgeSCN_testcase1_20250312040214.csv`  
- `SDOH_PtInfo_CareRidgeSCN_testcase1_20250312040214.csv`  

By following this structured naming convention, we ensure consistency, clarity, and efficient data processing across all CSV files.




## Folder Structure

This section outlines the location of key files and their purpose within the project directory.

- **`support/specifications/flat-file`**
  - `datapackage-nyher-fhir-ig-equivalent.json`: Schema specification for validating CSV files.
  - `validate-nyher-fhir-ig-equivalent.py`: Python script to validate CSV files against the schema.
  - **`1115_SDOH.Template_v3-4_20250418.xlsx`**: **Excel file that defines the structure, required fields, rules, and field-level data references for creating all related CSV files.**  
- **`nyher-fhir-ig-example/`**: Folder containing sample CSV files for validation.
  - `SDOH_PtInfo_CareRidgeSCN_testcase1_20250312040214.csv `: Demographic information data.
  - `SDOH_QEadmin_CareRidgeSCN_testcase1_20250312040214.csv`: QE administration data.
  - `SDOH_ScreeningProf_CareRidgeSCN_testcase1_20250312040214.csv`: Primary screening profile data.
  - `SDOH_ScreeningObs_CareRidgeSCN_testcase1_20250312040214.csv`: Primary screening observation data.
  - `Consolidated NYHER FHIR IG Examples.xlsx`: Excel file with consolidated sheets of the CSV data and change log. 

- **`documentation.auto.md`**
  - Auto-generated documentation detailing the schema, validation process, and CSV contents for easier understanding.


## Prerequisites

Before running the validation scripts locally with Frictionless, ensure the following are installed:


- **Python 3.x**:
  Ensure that Python 3 is installed on your system. You can check if Python 3 is already installed by running the following command:

  ```bash
  python3 --version
  ```
  If Python 3 is not installed, follow the instructions below to install it:
    - Ubuntu/Debian-based systems:
      ```bash
      sudo apt update
      sudo apt install python3
      ```
    - macOS (using Homebrew):
      ```bash
      brew install python
    - Windows: Download and install the latest version of Python from the official website: https://www.python.org/downloads/

- **pip (Python Package Installer)**: pip is the package manager for Python and is needed to install libraries like Frictionless.

  Check if pip is installed by running:
  ```bash
  python3 -m pip --version
  ```
  If pip is not installed, follow these steps:
    - On Ubuntu/Debian-based systems:
      ```bash
        sudo apt install python3-pip
      ```
    - On macOS (using Homebrew):
      ```bash
        brew install pip
      ```
    - On Windows: If pip isn't already installed with Python, you can get it from the [official Python pip installation guide](https://pip.pypa.io/en/stable/installation/).

  ***Troubleshooting***: 
    If you encounter errors like No module named ensurepip, it's possible that your Python installation is missing the ensurepip module, which is typically used to install pip. In this case, install pip manually using the package manager for your operating system, as described above. Alternatively, you can use the following command to install pip if it's missing:
      ```bash
        python3 -m ensurepip --upgrade
      ```


- **Frictionless**: Once Python 3 and pip are set up, you can install the Frictionless library by running the following command:
  ```bash
  pip install frictionless
  ```
  Visit the [Frictionless Documentation](https://framework.frictionlessdata.io/docs/getting-started.html) for more information.

## Validation Process

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/tech-by-design/polyglot-prime.git
   cd polyglot-prime/support/specifications
   ```

2. **Run the Validation Script**:
   Use the provided `validate-nyher-fhir-ig-equivalent.py` script to validate all CSV files in the `flat-file/nyher-fhir-ig-example/` directory. Replace filenames as necessary, but **ensure that the file order remains unchanged**. The order of files is mandatory for the validation process.

   ```bash
   python3 validate-nyher-fhir-ig-equivalent.py datapackage-nyher-fhir-ig-equivalent.json nyher-fhir-ig-example/SDOH_QEadmin_CareRidgeSCN_testcase1_20250312040214.csv nyher-fhir-ig-example/SDOH_ScreeningProf_CareRidgeSCN_testcase1_20250312040214.csv nyher-fhir-ig-example/SDOH_ScreeningObs_CareRidgeSCN_testcase1_20250312040214.csv nyher-fhir-ig-example/SDOH_PtInfo_CareRidgeSCN_testcase1_20250312040214.csv
   ```

3. **Review Validation Results**:
   Validation results will be saved in `output.json`, detailing any schema mismatches, errors, or warnings.

4. **Understanding `documentation.auto.md`**:
   - The `documentation.auto.md` file is auto-generated and provides a breakdown of the schema's structure, constraints, and expected field details.
   - Use this file as a reference to interpret validation results and align your CSV data with the schema requirements.

## Notes

- The `datapackage-nyher-fhir-ig-equivalent.json` defines schema expectations, including data types, constraints, and relationships.
- The `validate-nyher-fhir-ig-equivalent.py` script integrates with Frictionless for accurate and detailed validation.
- The `output.json` file provides a machine-readable validation report. To understand its structure, refer to the [Frictionless JSON documentation][(https://framework.frictionlessdata.io/docs/guides/validate](https://framework.frictionlessdata.io/docs/guides/validating-data.html)).


## Field Descriptions

Field descriptions for each field are documented in the `documentation.auto.md` file. These descriptions include detailed information such as:

- **Description**: The exact path in the FHIR resource from where the field is derived.
- **Example Fields**:
  - **`PATIENT_MR_ID_VALUE`**:
    - **Description**: `Bundle.entry.resource.where(resourceType = 'Patient').identifier.where(type.coding.code = 'MR').value` 
  - **`FACILITY_NAME`**:
    - **Description**: `Bundle.entry.resource.where(resourceType = 'Organization').name` 

Refer to `documentation.auto.md` for the complete set of field descriptions, including FHIR File Paths.

### Generating Documentation Automatically

The `documentation.auto.md` file is automatically generated using the `describe` method from the Frictionless library. This method extracts metadata from the data package and converts it into Markdown format.

### How to Regenerate:

1. Use the Frictionless library to describe the data package.
2. Convert the metadata to Markdown format.
3. Save the output as `documentation.auto.md`.

This ensures that the field descriptions, including FHIR File Paths, remain up-to-date and consistent with the data package.

This naming convention helps organize files systematically and allows easy identification of the data source, purpose, and context.


### Migration Plan

The migration plan from Winter'24 CSV to 1115-SDOH-Template CSV is detailed [here](https://github.com/tech-by-design/polyglot-prime/blob/main/support/specifications/flat-file/winter24-to-1115-sdoh-template-migration-document.md).

### Notes

- **Mandatory Prefix**: The `<DATA_TYPE>` section of the file name is predefined and must not be altered.
- **Customizable Group Identifier**: The `<GROUP_IDENTIFIER>` section can be customized as per the data submission or testing requirements but must adhere to the format `QE-Name-Date-TestCase`.

This naming convention helps ensure files are easily identifiable and properly linked to their corresponding data specifications in validation and analysis.

## Tools for Data Validation and Exploration

 Additionally, tools  for non-technical users to assist with schema creation and editing.
👉 [View Tools for Data Validation and Exploration](https://github.com/tech-by-design/polyglot-prime/blob/main/support/specifications/flat-file/csv-validation-tools.md)

For further assistance, raise a query in the project's [GitHub Issues](https://github.com/tech-by-design/polyglot-prime/issues).
