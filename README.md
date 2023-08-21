# Google Search Console Data Unification

This dbt package is for Data Unification of Google Search Console ingested data by [Daton](https://sarasanalytics.com/daton/). [Daton](https://sarasanalytics.com/daton/) is the Unified Data Platform for Global Commerce with 100+ pre-built connectors and data sets designed for accelerating the eCommerce data and analytics journey by [Saras Analytics](https://sarasanalytics.com/).

### Supported Data Warehouses
- BigQuery
- Snowflake

#### Typical challenges with raw data are:
- Array/Nested Array columns which makes queries for Data Analytics complex
- Data duplication due to look back period while fetching report data from Google Search Console
- Separate tables at marketplaces/Store, brand, account level for same kind of report/data feeds

Data Unification simplifies Data Analytics by doing:

- Consolidation - Different marketplaces/Store/account & different brands would have similar raw Daton Ingested tables, which are consolidated into one table with column distinguishers brand & store
- Deduplication - Based on primary keys, the data is De-duplicated and the latest records are only loaded into the consolidated stage tables
- Incremental Load - Models are designed to include incremental load which when scheduled would update the tables regularly
- Standardization -
    - Currency Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local currency of the corresponding marketplace/store/account. Values that are in local currency are Standardized by converting to desired currency using Daton Exchange Rates data. Prerequisite - Exchange Rates connector in Daton needs to be present - Refer [this](https://github.com/saras-daton/currency_exchange_rates)
    - Time Zone Conversion (Optional) - Raw Tables data created at Marketplace/Store/Account level may have data in local timezone of the corresponding marketplace/store/account. DateTime values that are in local timezone are Standardized by converting to specified timezone using input offset hours.

#### Prerequisite
Daton Integrations for

- Google Search Console
- Exchange Rates(Optional, if currency conversion is not required)

*Note: Please select 'Do Not Unnest' option while setting up Daton Integrataion*

# Configuration

## Required Variables

This package assumes that you have an existing dbt project with a BigQuery/Snowflake profile connected & tested. Source data is located using the following variables which must be set in your `dbt_project.yml` file.

```yaml
vars:
    raw_database: "your_database"
    raw_schema: "your_schema"
```

## Setting Target Schema

Models will be create unified tables under the schema (<target_schema>_stg_googlesearchconsole). In case, you would like the models to be written to the target schema or a different custom schema, please add the following in the dbt_project.yml file.

```yaml
models:
  GoogleSearchConsole:
    +schema: custom_schema_extension
```

## Optional Variables

Package offers different configurations which must be set in your `dbt_project.yml` file. These variables can be marked as True/False based on your requirements. Details about the variables are given below.

### Currency Conversion 

To enable currency conversion, which produces two columns - exchange_currency_rate & exchange_currency_code, please mark the currency_conversion_flag as True. By default, it is False.
Prerequisite - Daton Exchange Rates Integration

Example:
```yaml
vars:
    currency_conversion_flag: True
```

### Timezone Conversion

To enable timezone conversion, which converts the timezone columns from UTC timezone to local timezone, please mark the timezone_conversion_flag as True in the dbt_project.yml file, by default, it is False. Additionally, you need to provide offset hours between UTC and the timezone you want the data to convert into for each raw table for which you want timezone converison to be taken into account.

Example:
```yaml
vars:
timezone_conversion_flag: True
  raw_table_timezone_offset_hours: {
    "edm-saras.EDM_Daton.Brand_US_GoogleSearchConsole_Sitemaps":-7,
    "edm-saras.EDM_Daton.Brand_US_GoogleSearchConsole_sites":-7
  }
```
Here, -7 represents the offset hours between UTC and PDT considering we are sitting in PDT timezone and want the data in this timezone

### Table Exclusions

If you need to exclude any of the models, declare the model names as variables and mark them as False. Refer the table below for model details. By default, all tables are created.

Example:
```yaml
vars:
Sites: False
```

## Models

This package contains models from the Google Search Console API which includes reports on {{GscDataAggByCountry, GscDataAggByDate, GscDataAggByDevice, GscDataAggByPage, GscDataAggByQuery, Sitemaps, Sites}}. The primary outputs of Sites package are described below.

| **Category**                 | **Model**  | **Description** | **Unique Key** | **Partition Key** | **Cluster Key** |
| :--   | ---------- | --------------------- | --------------------- | --------------------- | --------------------- |
| Google Search Console | [GscDataAggByCountry](models/GoogleSearchConsole/GscDataAggByCountry.sql)  | A detailed report giving details about the google search console data by Country | country,start_date,end_date | start_date | country,start_date,end_date |
| Google Search Console | [GscDataAggByDate](models/GoogleSearchConsole/GscDataAggByDate.sql)  | A detailed report giving details about the google search console data by Date | date,start_date,end_date | start_date | date,start_date,end_date |
| Google Search Console | [GscDataAggByDevice](models/GoogleSearchConsole/GscDataAggByDevice.sql)  | A detailed report giving details about the google search console data by Device | device,start_date,end_date | start_date | device,start_date,end_date |
| Google Search Console | [GscDataAggByPage](models/GoogleSearchConsole/GscDataAggByPage.sql)  | A detailed report giving details about the google search console data by Page | page,start_date,end_date | start_date | page,start_date,end_date |
| Google Search Console | [GscDataAggByQuery](models/GoogleSearchConsole/GscDataAggByQuery.sql)  | A detailed report giving details about the google search console data by Query | query,start_date,end_date | start_date | query,start_date,end_date |
| Google Search Console | [Sitemaps](models/GoogleSearchConsole/Sitemaps.sql)  | A detailed report giving details about the google search data by Sitemaps | path | start_date | path |
| Google Search Console | [Sites](models/GoogleSearchConsole/Sites.sql)  | A detailed report giving details about the google search data by Sites | siteUrl | start_date | siteUrl |

## DBT Tests

The tests property defines assertions about a column, table, or view. The property contains a list of generic tests, referenced by name, which can include the four built-in generic tests available in dbt. For example, you can add tests that ensure a column contains no duplicates and zero null values. Any arguments or configurations passed to those tests should be nested below the test name.

| **Tests**  | **Description** |
| :--  | ------------------------------------------- |
| [Not Null Test](https://docs.getdbt.com/reference/resource-properties/tests#testing-an-expression)  | This test validates that there are no null values present in a column |
| [Data Recency Test](https://github.com/dbt-labs/dbt-utils/blob/main/macros/generic_tests/recency.sql)  | This is used to check for issues with data refresh within {{ x }} days, please specify the value of number of days at {{ x }} |
| [Accepted Value Test](https://docs.getdbt.com/reference/resource-properties/tests#accepted_values)  | This test validates that all of the values in a column are present in a supplied list of values. If any values other than those provided in the list are present, then the test will fail, by default it consists of default values and this needs to be changed based on the project |
| [Uniqueness Test](https://docs.getdbt.com/reference/resource-properties/tests#testing-an-expression)  | This test validates that there are no duplicate values present in a field |

### Table Name: Brand_US_GoogleSearchConsole_gsc_data_agg_by_country

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     query     `|        Yes        |                       |                         |                     |
| `    device     `|        Yes        |                       |                         |                     |
| `     date      `|        Yes        |                       |                         |                     |
| `     page      `|        Yes        |                       |                         |                     |
| `    country    `|        Yes        |                       |                         |         Yes         |
| `   start_date  `|        Yes        |                       |                         |         Yes         |
| `   end_date    `|        Yes        |                       |                         |         Yes         |
| `    clicks     `|        Yes        |                       |                         |                     |
| `  impressions  `|        Yes        |                       |                         |                     |
| `      ctr      `|        Yes        |                       |                         |                     |
| `   position    `|        Yes        |                       |                         |                     |
| `  searchType   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_gsc_data_agg_by_date

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     query     `|        Yes        |                       |                         |                     |
| `    device     `|        Yes        |                       |                         |                     |
| `     date      `|        Yes        |                       |                         |         Yes         |
| `     page      `|        Yes        |                       |                         |                     |
| `    country    `|        Yes        |                       |                         |                     |
| `   start_date  `|        Yes        |                       |                         |         Yes         |
| `   end_date    `|        Yes        |                       |                         |         Yes         |
| `    clicks     `|        Yes        |                       |                         |                     |
| `  impressions  `|        Yes        |                       |                         |                     |
| `      ctr      `|        Yes        |                       |                         |                     |
| `   position    `|        Yes        |                       |                         |                     |
| `  searchType   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_gsc_data_agg_by_device

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     query     `|        Yes        |                       |                         |                     |
| `    device     `|        Yes        |                       |                         |         Yes         |
| `     date      `|        Yes        |                       |                         |                     |
| `     page      `|        Yes        |                       |                         |                     |
| `    country    `|        Yes        |                       |                         |                     |
| `   start_date  `|        Yes        |                       |                         |         Yes         |
| `   end_date    `|        Yes        |                       |                         |         Yes         |
| `    clicks     `|        Yes        |                       |                         |                     |
| `  impressions  `|        Yes        |                       |                         |                     |
| `      ctr      `|        Yes        |                       |                         |                     |
| `   position    `|        Yes        |                       |                         |                     |
| `  searchType   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_gsc_data_agg_by_page

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     query     `|        Yes        |                       |                         |                     |
| `    device     `|        Yes        |                       |                         |                     |
| `     date      `|        Yes        |                       |                         |                     |
| `     page      `|        Yes        |                       |                         |         Yes         |
| `    country    `|        Yes        |                       |                         |                     |
| `   start_date  `|        Yes        |                       |                         |         Yes         |
| `   end_date    `|        Yes        |                       |                         |         Yes         |
| `    clicks     `|        Yes        |                       |                         |                     |
| `  impressions  `|        Yes        |                       |                         |                     |
| `      ctr      `|        Yes        |                       |                         |                     |
| `   position    `|        Yes        |                       |                         |                     |
| `  searchType   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_gsc_data_agg_by_query

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     query     `|        Yes        |                       |                         |         Yes         |
| `    device     `|        Yes        |                       |                         |                     |
| `     date      `|        Yes        |                       |                         |                     |
| `     page      `|        Yes        |                       |                         |                     |
| `    country    `|        Yes        |                       |                         |                     |
| `   start_date  `|        Yes        |                       |                         |         Yes         |
| `   end_date    `|        Yes        |                       |                         |         Yes         |
| `    clicks     `|        Yes        |                       |                         |                     |
| `  impressions  `|        Yes        |                       |                         |                     |
| `      ctr      `|        Yes        |                       |                         |                     |
| `   position    `|        Yes        |                       |                         |                     |
| `  searchType   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_sitemaps

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `     path      `|        Yes        |                       |                         |         Yes         |
| ` lastSubmitted `|        Yes        |                       |                         |                     |
| `   isPending   `|        Yes        |                       |                         |                     |
| `isSitemapsIndex`|        Yes        |                       |                         |                     |
| `     type      `|        Yes        |                       |                         |                     |
| ` lastDownloaded`|        Yes        |                       |                         |                     |
| `   warnings    `|        Yes        |                       |                         |                     |
| `     errors    `|        Yes        |                       |                         |                     |
| `    contents   `|        Yes        |                       |                         |                     |


### Table Name: Brand_US_GoogleSearchConsole_sites

|   **Columns**    | **Not Null Test** | **Data Recency Test** | **Accepted Value Test** | **Uniqueness Test** |
|       :--        |        :-:        |          :-:          |           :-:           |         :-:         |
| `    siteUrl    `|        Yes        |                       |                         |         Yes         |
| `permissionLevel`|        Yes        |                       |                         |                     |


### For details about default configurations for Table Primary Key columns, Partition columns, Clustering columns, please refer the properties.yaml used for this package as below.

`You can overwrite these default configurations by using your project specific properties yaml.`

```yaml
version: 2
models:
  - name: GscDataAggByCountry
    description: A detailed report giving details about the google search console data by country
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['country','start_date','end_date']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['country','start_date','end_date']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - country
            - start_date
            - end_date
    columns:
      - name: query
        tests:
          - not_null:
              config:
                severity: error
      - name: device
        tests:
          - not_null:
              config:
                severity: error
      - name: date
        tests:
          - not_null:
              config:
                severity: error
      - name: page
        tests:
          - not_null:
              config:
                severity: error
      - name: country
        tests:
          - not_null:
              config:
                severity: error
      - name: start_date
        tests:
          - not_null:
              config:
                severity: error
      - name: end_date
        tests:
          - not_null:
              config:
                severity: error
      - name: clicks
        tests:
          - not_null:
              config:
                severity: error
      - name: impressions
        tests:
          - not_null:
              config:
                severity: error
      - name: ctr
        tests:
          - not_null:
              config:
                severity: error
      - name: position
        tests:
          - not_null:
              config:
                severity: error
      - name: searchType
        tests:
          - not_null:
              config:
                severity: error
  - name: GscDataAggByDate
    description: A detailed report giving details about the google search console data by date
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['date','start_date','end_date']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['date','start_date','end_date']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - date
            - start_date
            - end_date
    columns:
      - name: query
        tests:
          - not_null:
              config:
                severity: error
      - name: device
        tests:
          - not_null:
              config:
                severity: error
      - name: date
        tests:
          - not_null:
              config:
                severity: error
      - name: page
        tests:
          - not_null:
              config:
                severity: error
      - name: country
        tests:
          - not_null:
              config:
                severity: error
      - name: start_date
        tests:
          - not_null:
              config:
                severity: error
      - name: end_date
        tests:
          - not_null:
              config:
                severity: error
      - name: clicks
        tests:
          - not_null:
              config:
                severity: error
      - name: impressions
        tests:
          - not_null:
              config:
                severity: error
      - name: ctr
        tests:
          - not_null:
              config:
                severity: error
      - name: position
        tests:
          - not_null:
              config:
                severity: error
      - name: searchType
        tests:
          - not_null:
              config:
                severity: error
  - name: GscDataAggByDevice
    description: A detailed report giving details about the google search console data by device
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['device','start_date','end_date']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['device','start_date','end_date']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - device
            - start_date
            - end_date
    columns:
      - name: query
        tests:
          - not_null:
              config:
                severity: error
      - name: device
        tests:
          - not_null:
              config:
                severity: error
      - name: date
        tests:
          - not_null:
              config:
                severity: error
      - name: page
        tests:
          - not_null:
              config:
                severity: error
      - name: country
        tests:
          - not_null:
              config:
                severity: error
      - name: start_date
        tests:
          - not_null:
              config:
                severity: error
      - name: end_date
        tests:
          - not_null:
              config:
                severity: error
      - name: clicks
        tests:
          - not_null:
              config:
                severity: error
      - name: impressions
        tests:
          - not_null:
              config:
                severity: error
      - name: ctr
        tests:
          - not_null:
              config:
                severity: error
      - name: position
        tests:
          - not_null:
              config:
                severity: error
      - name: searchType
        tests:
          - not_null:
              config:
                severity: error
  - name: GscDataAggByPage
    description: A detailed report giving details about the google search console data by page
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['page','start_date','end_date']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['page','start_date','end_date']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - page
            - start_date
            - end_date
    columns:
      - name: query
        tests:
          - not_null:
              config:
                severity: error
      - name: device
        tests:
          - not_null:
              config:
                severity: error
      - name: date
        tests:
          - not_null:
              config:
                severity: error
      - name: page
        tests:
          - not_null:
              config:
                severity: error
      - name: country
        tests:
          - not_null:
              config:
                severity: error
      - name: start_date
        tests:
          - not_null:
              config:
                severity: error
      - name: end_date
        tests:
          - not_null:
              config:
                severity: error
      - name: clicks
        tests:
          - not_null:
              config:
                severity: error
      - name: impressions
        tests:
          - not_null:
              config:
                severity: error
      - name: ctr
        tests:
          - not_null:
              config:
                severity: error
      - name: position
        tests:
          - not_null:
              config:
                severity: error
      - name: searchType
        tests:
          - not_null:
              config:
                severity: error
  - name: GscDataAggByQuery
    description: A detailed report giving details about the google search console data by query
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['query','start_date','end_date']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['query','start_date','end_date']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - query
            - start_date
            - end_date
    columns:
      - name: query
        tests:
          - not_null:
              config:
                severity: error
      - name: device
        tests:
          - not_null:
              config:
                severity: error
      - name: date
        tests:
          - not_null:
              config:
                severity: error
      - name: page
        tests:
          - not_null:
              config:
                severity: error
      - name: country
        tests:
          - not_null:
              config:
                severity: error
      - name: start_date
        tests:
          - not_null:
              config:
                severity: error
      - name: end_date
        tests:
          - not_null:
              config:
                severity: error
      - name: clicks
        tests:
          - not_null:
              config:
                severity: error
      - name: impressions
        tests:
          - not_null:
              config:
                severity: error
      - name: ctr
        tests:
          - not_null:
              config:
                severity: error
      - name: position
        tests:
          - not_null:
              config:
                severity: error
      - name: searchType
        tests:
          - not_null:
              config:
                severity: error
  - name: Sitemaps
    description: A detailed report giving details about the google search console data by sitemaps
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['path']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['path']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - path
    columns:
      - name: path
        tests:
          - not_null:
              config:
                severity: error
      - name: lastSubmitted
        tests:
          - not_null:
              config:
                severity: error
      - name: isPending
        tests:
          - not_null:
              config:
                severity: error
      - name: isSitemapsIndex
        tests:
          - not_null:
              config:
                severity: error
      - name: type
        tests:
          - not_null:
              config:
                severity: error
      - name: lastDownloaded
        tests:
          - not_null:
              config:
                severity: error
      - name: warnings
        tests:
          - not_null:
              config:
                severity: error
      - name: errors
        tests:
          - not_null:
              config:
                severity: error
      - name: contents
        tests:
          - not_null:
              config:
                severity: error
  - name: Sites
    description: A detailed report giving details about the google search console data by sites
    config:
      materialized: incremental
      incremental_strategy: merge
      unique_key: ['siteUrl']
      partition_by: { 'field': 'start_date', 'data_type': 'date', 'granularity': 'day' }
      cluster_by: ['siteUrl']
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - siteUrl
    columns:
      - name: siteUrl
        tests:
          - not_null:
              config:
                severity: error
      - name: permissionLevel
        tests:
          - not_null:
              config:
                severity: error
```

## Resources:
- Have questions, feedback, or need [help](https://calendly.com/srinivas-janipalli/30min)? Schedule a call with our data experts or email us at info@sarasanalytics.com.
- Learn more about Daton [here](https://sarasanalytics.com/daton/).
- Refer [this](https://youtu.be/6zDTbM6OUcs) to know more about how to create a dbt account & connect to {{Bigquery/Snowflake}}